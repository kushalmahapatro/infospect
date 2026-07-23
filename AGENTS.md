# Agent notes (Infospect)

Infospect is a **generic** Flutter package for network/log inspection. Do not
assume a specific host application, product name, or proprietary channel.

## Desktop / Multiview

- Desktop uses [`multiview_desktop`](https://pub.dev/packages/multiview_desktop):
  one Flutter engine / isolate; secondary windows via `openWindow`.
- Host Dart entry on desktop must use Multiview bootstrap:
  - `Infospect.instance.run` when the inspector is enabled
  - `Infospect.bootstrapMultiViewApp` /
    `InfospectDesktopBootstrap.runAppOrMultiApp` when Infospect is gated **off**
    but Multiview natives are still installed
- **Never** recommend plain `runApp` on desktop after Multiview runners are wired.

## Known consumer footguns

Before changing desktop bootstrap, runner examples, or window APIs, read:

1. [DESKTOP_COMPATIBILITY.md](DESKTOP_COMPATIBILITY.md)
2. [MIGRATION.md](MIGRATION.md) (0.1.5 → 0.2.0 Multiview runners)

Footguns:

| Hazard | Effect |
|---|---|
| `window_manager` 0.3.x + Multiview (`registrar.view` unwrap) | Platform-thread hang / invisible window / immortal process |
| Feature-flagged Infospect → plain `runApp` with Multiview natives | Hidden window; quit cancelled forever |
| Forward macOS terminate to Multiview before Dart `runMultiApp` | Unkillable process |
| `hiddenWindowAtLaunch` on Multiview hosts | Double-hide fights Multiview `orderOut` |
| Plugins that force-unwrap `registrar.view` | Crash / hang under `enableMultiView` |

Infospect does **not** vendor or patch `window_manager` — document host-side
mitigation only.

## Do not regress

- [`lib/utils/infospect_share.dart`](lib/utils/infospect_share.dart) macOS
  Multiview fallbacks for `share_plus` (`registrar.view` crash).
- Default Multiview `WindowOptions` with `windowButtonVisibility: true`
  ([`lib/utils/infospect_desktop_window.dart`](lib/utils/infospect_desktop_window.dart)).
- Example `macos/Runner` Multiview `prepareEngine` + AppDelegate forwarding.

## Scope

- Prefer package-local fixes and docs over host-specific patches.
- Do not paste proprietary host code or product names into this repo.
- Keep interceptor / invoker / `ensureInitialized` APIs stable unless the task
  explicitly changes them.
