# Migrating from Infospect 0.1.5 → 0.2.0

This guide covers what **consumer apps** must change when upgrading from `infospect` **0.1.5** to **0.2.0**.

Core APIs (`Infospect.ensureInitialized`, `Infospect.instance.run`, Dio/http interceptors, `addLog`, `InfospectInvoker`) still work the same way. The breaking work is mostly **Flutter / SDK floor**, **desktop multi-window**, and **removing obsolete IPC glue**.

---

## 1. Bump the dependency and toolchains

```yaml
dependencies:
  infospect: ^0.2.0
```

Then:

```bash
flutter pub upgrade infospect
```

**0.2.0 requires:**

| Constraint | Minimum |
|---|---|
| Dart SDK | `>=3.10.0` |
| Flutter | `>=3.38.2` |

Upgrade your Flutter SDK before (or as part of) the Infospect bump. Mobile-only apps that already meet these floors mainly need the dependency update plus the Dart cleanup in §3.

If your app depended on `desktop_multi_window` **only** for Infospect, remove that direct dependency — Infospect now uses [`multiview_desktop`](https://pub.dev/packages/multiview_desktop).

---

## 2. Desktop hosts: apply `multiview_desktop` runner setup

`desktop_multi_window` (separate Flutter engine / isolate per window + IPC) is replaced by `multiview_desktop` (one engine, one isolate, native multi-view).

Secondary Infospect windows **will not work** on desktop until you update the host runners below for every desktop platform you ship (macOS, Windows, Linux).

Also useful:

- Package README: [multiview_desktop](https://pub.dev/packages/multiview_desktop)
- Working reference: this repo’s `example/macos`, `example/windows`, `example/linux`

After native edits, regenerate plugins / rebuild:

```bash
flutter clean
flutter pub get
# macOS
cd macos && pod install && cd ..
flutter run -d macos   # or windows / linux
```

---

### macOS

#### `macos/Runner/MainFlutterWindow.swift`

Create a shared `FlutterEngine`, call `MultiviewDesktopPlugin.prepareEngine`, then attach `FlutterViewController` to that engine (instead of the default single-view controller):

```swift
import Cocoa
import FlutterMacOS
import multiview_desktop

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let engine = FlutterEngine(
      name: "main_flutter_engine",
      project: nil,
      allowHeadlessExecution: true
    )
    MultiviewDesktopPlugin.prepareEngine(engine, window: self)

    let flutterViewController =
      FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: false)

    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()
  }
}
```

#### `macos/Runner/AppDelegate.swift`

Forward terminate / reopen / dock-menu handling to `MultiviewDesktopPlugin`:

```swift
import Cocoa
import FlutterMacOS
import multiview_desktop

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(
      _ sender: NSApplication
  ) -> Bool {
    return MultiviewDesktopPlugin.applicationShouldTerminateAfterLastWindowClosed()
  }

  override func applicationShouldHandleReopen(
      _ sender: NSApplication,
      hasVisibleWindows flag: Bool
  ) -> Bool {
    if MultiviewDesktopPlugin.applicationShouldHandleReopen(
      sender,
      hasVisibleWindows: flag
    ) {
      return true
    }
    return super.applicationShouldHandleReopen(sender, hasVisibleWindows: flag)
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication)
      -> Bool
  {
    return true
  }

  override func applicationShouldTerminate(_ sender: NSApplication)
      -> NSApplication.TerminateReply
  {
    return MultiviewDesktopPlugin.applicationShouldTerminate(sender)
  }

  override func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
    return MultiviewDesktopPlugin.applicationDockMenu(sender)
  }
}
```

---

### Windows

#### `windows/runner/flutter_window.h`

Keep only `project_` — remove `flutter_controller_` / `FlutterViewController` (the plugin owns the engine):

```cpp
#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>

#include <memory>

#include "win32_window.h"

class FlutterWindow : public Win32Window {
 public:
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  flutter::DartProject project_;
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
```

#### `windows/runner/flutter_window.cpp`

Replace standard Flutter view-controller setup with the multiview API:

```cpp
#include "flutter_window.h"

#include <optional>

#include <multiview_desktop/multi_view_desktop_plugin.h>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();
  const int width = frame.right - frame.left;
  const int height = frame.bottom - frame.top;

  MultiViewDesktopPrepareEngine(project_, GetHandle());
  MultiViewDesktopCreateMainView(GetHandle(), width, height);
  const HWND flutter_hwnd =
      MultiViewDesktopGetFlutterHwnd(MultiViewDesktopGetMainViewId());
  if (flutter_hwnd != nullptr) {
    SetChildContent(flutter_hwnd);
  }
  CenterOnScreen();

  return true;
}

void FlutterWindow::OnDestroy() {
  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  LRESULT result = 0;
  if (message == WM_FONTCHANGE) {
    FlutterDesktopEngineReloadSystemFonts(MultiViewDesktopGetEngineRef());
  }
  if (MultiViewDesktopHandleWindowProc(hwnd, message, wparam, lparam,
                                       &result)) {
    return result;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
```

> `CenterOnScreen()` is optional (native pre-center before Dart runs). If your template does not have it yet, either add it from the [multiview_desktop Windows setup](https://pub.dev/packages/multiview_desktop) or remove that call.

#### `windows/runner/main.cpp`

Initialize shell / taskbar integration, forward jump-list activations, and set `SetQuitOnClose(false)` so closing the main OS window does not kill the process while Infospect secondary windows may still be open:

```cpp
#include <flutter/dart_project.h>
#include <flutter/flutter_engine.h>
#include <flutter/generated_plugin_registrant.h>
#include <multiview_desktop/multi_view_desktop_plugin.h>
#include <windows.h>

#include <optional>

#include "flutter_window.h"
#include "utils.h"
#include "win32_window.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  MultiViewDesktopInitializeShellIntegration();

  if (MultiViewDesktopTryForwardTaskbarMenuActivation()) {
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(0, 0);
  Win32Window::Size size(800, 600);
  if (!window.Create(L"your_app_name", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(false);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
```

Replace `your_app_name` with your window title / app name.

---

### Linux

Update `linux/runner/my_application.cc` (and ensure `my_application_new` does **not** use `G_APPLICATION_NON_UNIQUE`).

Key pieces to add/change:

1. Include the runner header.
2. Show the primary window on the first Flutter frame (do not `gtk_widget_show` the window immediately).
3. Call `install` → `prepare_dart_project` → `register_primary`.

```cpp
#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <multiview_desktop/multiview_desktop_runner.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  multiview_desktop_linux_runner_install(GTK_APPLICATION(application));

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // ... keep your existing header-bar / title setup ...

  gtk_window_set_default_size(window, 800, 600);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  multiview_desktop_linux_runner_prepare_dart_project(project);
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders (do not gtk_widget_show(window) here).
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  multiview_desktop_linux_runner_register_primary(window, view);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}
```

In `my_application_new`, register a normal unique `GApplication` (required for dock/taskbar menu integration):

```cpp
MyApplication* my_application_new() {
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     nullptr));
}
```

Do **not** pass `"flags", G_APPLICATION_NON_UNIQUE`.

Full reference: `example/linux/runner/my_application.cc`.

---

## 3. Dart entrypoint: drop multi-window IPC

### Before (0.1.5)

```dart
void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();

  Infospect.ensureInitialized(logAppLaunch: true)
      .handleMainWindowReceiveData();

  Infospect.instance.run(args, myApp: const MainApp());
}
```

`Infospect.instance.run` used `args` to detect a `multi_window` child process started by `desktop_multi_window`. Child windows had their own isolate and relied on `sendNetworkCalls` / `sendLogs` / `sendThemeMode` / `handleMultiWindowReceivedData`.

### After (0.2.0)

```dart
void main(List<String> args) {
  Infospect.ensureInitialized(logAppLaunch: true);
  Infospect.instance.run(args, myApp: const MainApp());
}
```

`run` still accepts `args` for compatibility, but they are unused on desktop with `multiview_desktop`. Network calls, logs, and theme are shared in-process — no IPC. Obsolete `multi_window` CLI / second-isolate entry is not the Multiview model.

`Infospect.instance.run` and `Infospect.bootstrapMultiViewApp` share one helper that
configures `MultiAppConfig.globalWindowOptions` with `titleBarStyle: TitleBarStyle.normal`
and `windowButtonVisibility: true`. Without that, `multiview_desktop` resets the host OS
window and hides minimize / maximize / close.

### Multiview host safety (desktop)

After Multiview native runners are wired:

| Do | Don't |
|---|---|
| `Infospect.instance.run(...)` or `Infospect.bootstrapMultiViewApp(...)` | Plain `runApp` on desktop |
| Forward macOS AppDelegate terminate / reopen / dock menu to `MultiviewDesktopPlugin` | Leave Multiview AppDelegate without Dart `runMultiApp` (quit stays `.terminateCancel`) |
| Prefer Multiview `WindowOptions` / `MultiViewDesktop` for window chrome | Rely on `window_manager` 0.3.x `registrar.view` for the primary macOS window (hang / `UE`) |

`Infospect.bootstrapMultiViewApp` does **not** require `ensureInitialized` — use it when
production builds skip Infospect logging but still ship Multiview natives.

### Obsolete APIs (remove when convenient)

These remain as **deprecated no-ops** so existing call sites compile, but you should delete them:

| Method | Action |
|---|---|
| `handleMainWindowReceiveData()` | Remove |
| `handleMultiWindowReceivedData(context)` | Remove |
| `sendNetworkCalls()` | Remove |
| `sendLogs([...])` | Remove |
| `sendThemeMode(isDarkTheme: ...)` | Remove |

**Unchanged (typical consumer path):**

```dart
Infospect.ensureInitialized(...);
Infospect.instance.run(args, myApp: ...);
Infospect.instance.dioInterceptor;
Infospect.instance.httpClientInterceptor(client: client);
Infospect.instance.addLog(...);
InfospectInvoker(...);
```

---

## 4. Platform checklist

| App type | Required work |
|---|---|
| **Mobile only** (iOS / Android) | Flutter ≥ 3.38.2, bump `infospect`, remove obsolete IPC calls if present |
| **Desktop** (macOS / Windows / Linux) | All of the above **plus** `multiview_desktop` runner setup |
| **Direct `desktop_multi_window` usage** outside Infospect | Migrate that usage separately, or keep `desktop_multi_window` as your own dependency — Infospect no longer brings it in |

---

## 5. Behavior changes worth knowing (no code changes required)

- Infospect desktop window opens via shared-isolate multi-view (`openWindow`) with live network/log state.
- Desktop Network / Logs tabs can be popped out into separate windows.
- JSON bodies gain beautified / tree views and desktop “open in new window”.
- Mobile shell uses a compact Network \| Logs switcher (Material 3); bottom-bar dependency removed internally.
- Scroll position is preserved on long lists; jump-to-newest control when viewing older entries.

None of these require consumer code changes beyond the migration steps above.

---

## 6. Quick verification

1. App builds on your target platforms with Flutter ≥ 3.38.2.
2. Invoker / shortcut still opens Infospect.
3. Dio / http traffic and `addLog` appear in the inspector.
4. **Desktop:** secondary Infospect window opens, stays in sync without restarting the main app, and closes cleanly.
5. No remaining references to `desktop_multi_window` or the obsolete IPC methods (except intentional temporary no-op calls).

---

## Further reading

- [CHANGELOG.md](CHANGELOG.md) — full 0.2.0 release notes
- [README.md](README.md) — current usage
- [multiview_desktop on pub.dev](https://pub.dev/packages/multiview_desktop) — native runner details
