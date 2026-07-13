
## 0.3.0

### Features
- Proxyman-style network breakpoints without a proxy: match by endpoint (optional method), pause request and/or response, edit headers / query params / body, then Continue or Abort
- Breakpoints management UI from the Network overflow menu; desktop context menu can add a breakpoint for a call
- Request breakpoint editors open as a fullscreen dialog on mobile and a new window on desktop; response editors follow the same pattern after the server replies
- Public API: `addEndpointBreakpoint`, `addBreakpoint`, `updateBreakpoint`, `removeBreakpoint`, `clearBreakpoints`, and `breakpoints`

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