import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/utils/infospect_desktop_bootstrap.dart';
import 'package:infospect/utils/infospect_multiview_bootstrap.dart';

void main() {
  group('isMultiViewDesktopBootstrapRequired', () {
    test('is false on web even if desktop OS is claimed', () {
      expect(
        isMultiViewDesktopBootstrapRequired(isWeb: true, desktopOs: true),
        isFalse,
      );
    });

    test('is true on desktop OS when not web', () {
      expect(
        isMultiViewDesktopBootstrapRequired(isWeb: false, desktopOs: true),
        isTrue,
      );
    });

    test('is false on mobile OS when not web', () {
      expect(
        isMultiViewDesktopBootstrapRequired(isWeb: false, desktopOs: false),
        isFalse,
      );
    });

    test('uses defaultTargetPlatform when desktopOs is omitted', () {
      final withoutOverride =
          isMultiViewDesktopBootstrapRequired(isWeb: false);
      expect(
        isMultiViewDesktopBootstrapRequired(
          isWeb: false,
          desktopOs: withoutOverride,
        ),
        withoutOverride,
      );
    });
  });

  group('InfospectDesktopBootstrap', () {
    test('isDesktopMultiViewRequired mirrors top-level predicate', () {
      expect(
        InfospectDesktopBootstrap.isDesktopMultiViewRequired(
          isWeb: true,
          desktopOs: true,
        ),
        isFalse,
      );
      expect(
        InfospectDesktopBootstrap.isDesktopMultiViewRequired(
          isWeb: false,
          desktopOs: true,
        ),
        isTrue,
      );
      expect(
        InfospectDesktopBootstrap.isDesktopMultiViewRequired(
          isWeb: false,
          desktopOs: false,
        ),
        isFalse,
      );
    });

    test('flag-off Multiview path requires desktop bootstrap', () {
      // Hosts that gate Infospect off must still Multiview-bootstrap on desktop.
      const infospectEnabled = false;
      final needsMultiView = InfospectDesktopBootstrap.isDesktopMultiViewRequired(
        isWeb: false,
        desktopOs: true,
      );
      expect(infospectEnabled, isFalse);
      expect(needsMultiView, isTrue);
      // API surface for the flag-off branch:
      expect(InfospectDesktopBootstrap.runAppOrMultiApp, isA<Function>());
    });
  });

  group('bootstrapMultiViewApp aliases', () {
    test('bootstrapDesktopApp is an alias for bootstrapMultiViewApp', () {
      expect(bootstrapDesktopApp, isA<Function>());
      expect(bootstrapMultiViewApp, isA<Function>());
    });
  });
}
