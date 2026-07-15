
## 0.3.0

### Features
- Proxyman-style network breakpoints without a proxy: match by endpoint (optional method), pause request and/or response, edit headers / query params / body, then Continue or Abort
- **Breakpoint conditions (AND):** query params, request headers, request/response body text or JSON path, response status (exact or range) — configurable in UI and via `addEndpointBreakpoint(conditions: …)`
- **JSON body editing** in intercept dialogs: dual-mode Text (syntax highlight, line numbers, smart indent) + editable Tree (keys/values/types, add/remove); Format / Minify when in Text mode; raw-text fallback for invalid JSON
- Breakpoints management UI from the Network overflow menu; desktop context menu can add a breakpoint for a call
- Request breakpoint editors open as a fullscreen dialog on mobile and a native desktop window on desktop; response editors follow the same pattern after the server replies
- Public API: `addEndpointBreakpoint`, `addBreakpoint`, `updateBreakpoint`, `removeBreakpoint`, `clearBreakpoints`, and `breakpoints`
- Breakpoint edits persist **original vs edited** snapshots on each network call (`requestBreakpointEdit` / `responseBreakpointEdit`) for URL, query params, headers, body, and response status — shown as an Original / Edited compare section in call details (mobile and desktop)
- **Multiview host bootstrap:** `Infospect.bootstrapMultiViewApp` / `InfospectDesktopBootstrap.runAppOrMultiApp` (and top-level helpers) call `runMultiApp` on desktop **without** requiring Infospect logging/`ensureInitialized` — hosts with Multiview natives must not use plain `runApp` on desktop. `Infospect.instance.run` uses the same helper.
- **Desktop Infospect menu bar & shortcuts:** in-window Material menu on all platforms (native `PlatformMenuBar` is unavailable for Multiview secondary windows). Trailing shortcut labels; focus-gated `HardwareKeyboard` handlers. ⌘W / Ctrl+W closes every Infospect-opened window via `InfospectDesktopWindowShortcuts`. Host merge helpers: `mergePlatformMenus`, `mergeBarButtons`, `mergeTaskbarMenus`

### Tests
- Widget / integration coverage for breakpoint list management, request/response editors, Continue/Abort, and matching rules
- Unit coverage for condition matching (query, JSON path, status range, response-only deferral)
- Golden screenshots under `test/goldens/` for empty list, populated list, request/response editors, and intercept dialogs
- Coverage for breakpoint edit traces, original/edited snapshots, and non-success (error-path) response breakpoints
- Unit coverage for Multiview desktop bootstrap gating (`isMultiViewDesktopBootstrapRequired`)
- Coverage for desktop menu merge helpers and Infospect-window shortcut bindings

### Fixes
- Mobile Network overflow → Breakpoints now navigates correctly (sheet no longer pops the new route)
- Response breakpoints also apply for non-2xx Dio responses that arrive via `onError`
- Compact native-feeling breakpoint list and intercept editors (bottom sheet on mobile, Scaffold + summary bar on desktop); mobile Breakpoints / details / intercept chrome aligned with the compact main Infospect toolbar (shared back button, 40px height)
- Desktop Breakpoints management uses a table + inspector pane (not mobile list/sheets); reopen focuses the existing window; condition count column + wider editor for filters
- Concurrent intercept windows keep their edit state across multiview rebuilds
- Desktop network details use a side-by-side Original vs Edited diff panel with top spacing and flex layout (no overflow when expanded)
- Desktop host and Infospect windows keep native title-bar buttons (minimize / maximize / close) via `windowButtonVisibility: true` in `MultiAppConfig` / `WindowOptions`
- Network call rows show BP / BP✎ traces when a breakpoint hit or edited the request/response
- Mobile Breakpoints toolbar pads under the status bar like AppBar; smaller desktop menu bar text for a denser native feel

### Docs
- README / MIGRATION: Multiview entry must use Infospect bootstrap/`run` (never plain `runApp` on desktop); macOS AppDelegate terminate forwarding; `window_manager` + Multiview hang warning; obsolete multi_window args path
- README: breakpoint conditions + JSON body editing examples
- **[DESKTOP_COMPATIBILITY.md](DESKTOP_COMPATIBILITY.md)** — Multiview consumer hazards (`window_manager` / `registrar.view`, feature-flagged Infospect, quit lifecycle, `hiddenWindowAtLaunch`, plugin safety)
- `InfospectDesktopBootstrap` (`isDesktopMultiViewRequired` / `runAppOrMultiApp`) for flag-off Multiview hosts
- [AGENTS.md](AGENTS.md) + Cursor rule for Multiview consumer footguns

## 0.2.0

> Consumer migration steps: see [MIGRATION.md](MIGRATION.md) (0.1.5 → 0.2.0).

### Breaking
- Replaced `desktop_multi_window` with [`multiview_desktop`](https://pub.dev/packages/multiview_desktop) ^1.2.0 (native Flutter multi-view API, single engine / isolate)
- Raised SDK constraint to `>=3.10.0` and Flutter to `>=3.38.2`
- Desktop hosts must apply [multiview_desktop runner setup](https://pub.dev/packages/multiview_desktop) (macOS / Windows / Linux)
- `handleMainWindowReceiveData` / `handleMultiWindowReceivedData` / `sendNetworkCalls` / `sendLogs` / `sendThemeMode` are deprecated no-ops (shared-isolate state); remove them when migrating

### Features
- Infospect desktop window opens via `openWindow` with live shared network/log state (no IPC serialization)
- Desktop Network and Logs tabs can be popped out into separate windows (hover pop-out control or double-tap); closing the window restores the tab
- Desktop network call list can be sorted by Time (click the Time header to toggle ascending/descending)
- Request/response JSON bodies support Beautified and foldable Tree View modes, plus open-in-new-window on desktop
- Body popout windows include call metadata (method, URL, headers, timing) alongside the JSON viewer
- Desktop inspector list state is preserved when opening secondary windows
- Logs list uses console-style full-content rows (level pill, selectable message/error/stack) with desktop hover/selection polish
- Logs and network lists preserve scroll position when viewing older entries; a floating control jumps back to the newest
- Mobile logs open a dedicated details screen on tap; empty and no-match states for both platforms
- Mobile network calls list and details polished to match console-style logs (status pills, call header, empty states, softer sections)
- Mobile network details use a compact top tab strip, denser key/value rows, and collapse Overview/Summary by default
- Filter and overflow menus use native cascading MenuAnchor on desktop and bottom sheets on mobile
- Mobile shell uses Material 3 NavigationBar; compact list app bars and shared filter chip strip; removed `cuberto_bottom_bar`
- Mobile shell replaces bottom navigation with a compact top Network | Logs segmented switcher
- Floating InfospectInvoker can be dragged to any screen edge, long-pressed to hide, and restored from the edge nub
- Revealing the invoker from the hidden edge nub auto-hides it again after 5 seconds of inactivity

## 0.1.5

### Features
- Added timestamp to shared log and network call filenames for better organization

### Fixes
- Fixed HTTP client interceptor to show proper client type name

### Dependencies
- Updated `desktop_multi_window` from ^0.2.0 to ^0.3.0
- Upgrade all the dependencies to their latest versions
- Added `intl` ^0.20.2 for timestamp formatting
- Removed `bloc` and `provider`

## 0.1.4
##### Fixes
- Bumped some outdated dependencies

## 0.1.3
##### Fixes
- Bumped version of cuberto_bottom_bar to 3.1.0 to address the issue with bottom navigation bar selection index. [Fluter issue](https://github.com/flutter/flutter/issues/148983) 
- Back button in Desktop layout of Infospect for Tabs
- Fixed width for row cell added to Desktop layout of Infospect
- Upgraded the version of archive

## 0.1.2
##### Fixes
- Fixes for issue [#3](https://github.com/kushalmahapatro/infospect/issues/3)

##### Added
- Infospect desktop sub-window restricted to be opened only once

## 0.1.1
##### Added
- Http and Dio interceptor added in example
- Readme updated with InfospectInvoker functionality and usage

## 0.1.0
##### Added

- Documentation
- Gif preview of iOS, macOs, Linux (Ubuntu VM in mac) and Windows 10 (VM in mac)

##### Fixes

- Analysis issue fixes

## 0.0.1-alpha
#### Initial version.

##### Added

- Network Calls
  - Interception for Dio and http
  - Filtering the calls based on Success/Error and also the method type
  - Sharing of respective network call with CURL data
  - Details screen with request , response and error
  - Filtering of the network call with the searched text (matching to the url)
- Logs
  - capturing of logs and showing them in list
  - Filtering out the logs based on the DiagnosticLevel like info, debug, warning, error, hint, summary, fine , hidden, off.
  - Filtering of the logs with the searched text (matching to the log message/error/stacktrace)
- Invoker
  - Widget to open the Infospect screen from anywhere in the app
  - Multi-window support in desktop and invoking the Infospect screen in the same window in mobile
  - Shortcut to invoke the infospect screen in Desktop app (Ctrl + Shift + I), and also an option provided to open up within the app.