import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/utils/infospect_desktop_window.dart';
import 'package:multiview_desktop/multiview_desktop.dart';

void main() {
  test('infospectDesktopWindowOptions enables native title-bar buttons', () {
    final options = infospectDesktopWindowOptions(title: 'Test');
    expect(options.titleBarStyle, TitleBarStyle.normal);
    expect(options.windowButtonVisibility, isTrue);
    expect(options.title, 'Test');
  });

  test('infospectMultiAppConfig keeps host window buttons visible', () {
    final config = infospectMultiAppConfig();
    expect(config.globalOptions.titleBarStyle, TitleBarStyle.normal);
    expect(config.globalOptions.windowButtonVisibility, isTrue);
  });
}
