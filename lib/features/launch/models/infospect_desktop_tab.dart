/// Desktop inspector tabs that can be shown in the main window or popped out.
enum InfospectDesktopTab {
  network(0, 'Network calls'),
  logs(1, 'Logs');

  const InfospectDesktopTab(this.tabIndex, this.windowTitle);

  /// Matches [NavigationTabData.tabs] ordering.
  final int tabIndex;
  final String windowTitle;

  static InfospectDesktopTab? fromTabIndex(int tabIndex) {
    for (final tab in values) {
      if (tab.tabIndex == tabIndex) return tab;
    }
    return null;
  }
}
