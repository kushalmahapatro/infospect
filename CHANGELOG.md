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