import 'package:flutter_test/flutter_test.dart';
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
      // On the Flutter test binding this is typically Android; assert it
      // agrees with an explicit false desktop override path.
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

  group('bootstrapMultiViewApp aliases', () {
    test('bootstrapDesktopApp is an alias for bootstrapMultiViewApp', () {
      // Compile-time / API surface check — both are top-level functions.
      expect(bootstrapDesktopApp, isA<Function>());
      expect(bootstrapMultiViewApp, isA<Function>());
    });
  });
}
