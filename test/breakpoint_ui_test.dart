import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_network_breakpoint.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoint_intercept_screen.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoints_list_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';
import 'package:infospect/styling/themes/infospect_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final navigatorKey = GlobalKey<NavigatorState>();

  setUpAll(() {
    Infospect.ensureInitialized(navigatorKey: navigatorKey);
    Infospect.instance.preferInAppBreakpointDialogs = true;
  });

  setUp(() {
    Infospect.instance.clearBreakpoints();
    Infospect.instance.preferInAppBreakpointDialogs = true;
  });

  Widget wrap(Widget child, {ThemeData? theme, Size size = const Size(390, 844)}) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: theme ?? InfospectTheme.lightTheme,
      darkTheme: InfospectTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: child,
      ),
    );
  }

  group('BreakpointsListScreen UI', () {
    testWidgets('shows empty state and can add a breakpoint rule', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(wrap(const BreakpointsListScreen(embedded: true)));
      await tester.pumpAndSettle();

      expect(find.text('No breakpoints yet'), findsOneWidget);
      expect(find.text('Breakpoints'), findsOneWidget);

      await expectLater(
        find.byType(BreakpointsListScreen),
        matchesGoldenFile('goldens/breakpoints_list_empty.png'),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Add breakpoint'));
      await tester.pumpAndSettle();

      expect(find.text('Add breakpoint'), findsWidgets);
      await tester.enterText(find.byType(TextField).first, '/api/users');
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();

      expect(Infospect.instance.breakpoints, hasLength(1));
      expect(Infospect.instance.breakpoints.first.endpoint, '/api/users');
      expect(find.textContaining('/api/users'), findsOneWidget);
      expect(find.text('No breakpoints yet'), findsNothing);

      await expectLater(
        find.byType(BreakpointsListScreen),
        matchesGoldenFile('goldens/breakpoints_list_with_rule.png'),
      );
    });

    testWidgets('can open management screen from Navigator.push path', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => BreakpointsListScreen.open(context),
                  child: const Text('Open breakpoints'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open breakpoints'));
      await tester.pumpAndSettle();

      expect(find.byType(BreakpointsListScreen), findsOneWidget);
      expect(find.text('Breakpoints'), findsOneWidget);
    });
  });

  group('BreakpointInterceptScreen UI', () {
    testWidgets('request editor continues with edited body and headers', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      InfospectBreakpointPayload? continued;

      await tester.pumpWidget(
        wrap(
          BreakpointInterceptScreen(
            phase: InfospectBreakpointPhase.request,
            initialPayload: const InfospectBreakpointPayload(
              method: 'POST',
              uri: 'https://example.com/api/users?page=1',
              endpoint: '/api/users',
              headers: {'content-type': 'application/json', 'x-debug': '1'},
              queryParameters: {'page': '1'},
              body: '{\n  "name": "Ada"\n}',
            ),
            onContinue: (payload) => continued = payload,
            onAbort: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Breakpoint'), findsOneWidget);
      expect(find.textContaining('POST'), findsWidgets);
      expect(find.text('Headers'), findsOneWidget);
      expect(find.text('Query'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);

      await expectLater(
        find.byType(BreakpointInterceptScreen),
        matchesGoldenFile('goldens/breakpoint_request_headers.png'),
      );

      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BreakpointInterceptScreen),
        matchesGoldenFile('goldens/breakpoint_request_body.png'),
      );

      await tester.enterText(
        find.byKey(const Key('breakpoint_body_field')),
        '{\n  "name": "Grace"\n}',
      );
      await tester.tap(find.byKey(const Key('breakpoint_continue')));
      await tester.pumpAndSettle();

      expect(continued, isNotNull);
      expect(continued!.body, contains('Grace'));
      expect(continued!.headers['content-type'], 'application/json');
      expect(continued!.queryParameters['page'], '1');
    });

    testWidgets('response editor shows status and aborts when requested', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      InfospectBreakpointPayload? aborted;

      await tester.pumpWidget(
        wrap(
          BreakpointInterceptScreen(
            phase: InfospectBreakpointPhase.response,
            initialPayload: const InfospectBreakpointPayload(
              method: 'GET',
              uri: 'https://example.com/api/users/1',
              endpoint: '/api/users/1',
              headers: {'content-type': 'application/json'},
              body: '{\n  "id": 1,\n  "name": "Ada"\n}',
              statusCode: 200,
            ),
            onContinue: (_) {},
            onAbort: (payload) => aborted = payload,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Response Breakpoint'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.byKey(const Key('breakpoint_status_field')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('breakpoint_status_field')))
            .controller!
            .text,
        '200',
      );
      expect(find.text('Query'), findsNothing);

      await expectLater(
        find.byType(BreakpointInterceptScreen),
        matchesGoldenFile('goldens/breakpoint_response.png'),
      );

      await tester.tap(find.byKey(const Key('breakpoint_abort')));
      await tester.pumpAndSettle();

      expect(aborted, isNotNull);
      expect(aborted!.statusCode, 200);
    });

    testWidgets('dark theme request breakpoint golden', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          BreakpointInterceptScreen(
            phase: InfospectBreakpointPhase.request,
            initialPayload: const InfospectBreakpointPayload(
              method: 'PUT',
              uri: 'https://example.com/api/users/1',
              endpoint: '/api/users/1',
              headers: {'authorization': 'Bearer token'},
              queryParameters: {},
              body: '{\n  "name": "Updated"\n}',
            ),
            onContinue: (_) {},
            onAbort: (_) {},
          ),
          theme: InfospectTheme.darkTheme,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(BreakpointInterceptScreen),
        matchesGoldenFile('goldens/breakpoint_request_body_dark.png'),
      );
    });
  });

  group('Breakpoint intercept integration', () {
    testWidgets('pauses request, applies edits, then pauses response', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Infospect.instance.addBreakpoint(
        const InfospectNetworkBreakpoint(
          id: 'it-1',
          endpoint: '/api/checkout',
          method: 'POST',
        ),
      );

      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: Center(child: Text('Host app')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final requestFuture = Infospect.instance.interceptRequestIfNeeded(
        method: 'POST',
        endpoint: '/api/checkout',
        uri: 'https://shop.test/api/checkout',
        headers: {'content-type': 'application/json'},
        queryParameters: {'coupon': 'SAVE'},
        body: {'total': 10},
      );

      await tester.pumpAndSettle();
      expect(find.text('Request Breakpoint'), findsOneWidget);
      expect(find.textContaining('/api/checkout'), findsWidgets);

      await expectLater(
        find.byType(Dialog),
        matchesGoldenFile('goldens/breakpoint_integration_request_dialog.png'),
      );

      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('breakpoint_body_field')),
        '{\n  "total": 42\n}',
      );
      await tester.tap(find.byKey(const Key('breakpoint_continue')));
      await tester.pumpAndSettle();

      final requestResult = await requestFuture;
      expect(requestResult, isNotNull);
      expect(requestResult!.aborted, isFalse);
      expect(requestResult.payload.body, contains('42'));
      expect(requestResult.payload.queryParameters['coupon'], 'SAVE');

      final responseFuture = Infospect.instance.interceptResponseIfNeeded(
        method: 'POST',
        endpoint: '/api/checkout',
        uri: 'https://shop.test/api/checkout',
        headers: {'content-type': 'application/json'},
        body: {'ok': true},
        statusCode: 201,
      );

      await tester.pumpAndSettle();
      expect(find.text('Response Breakpoint'), findsOneWidget);
      expect(find.text('201'), findsOneWidget);

      await expectLater(
        find.byType(Dialog),
        matchesGoldenFile('goldens/breakpoint_integration_response_dialog.png'),
      );

      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('breakpoint_body_field')),
        '{\n  "ok": true,\n  "patched": true\n}',
      );
      await tester.tap(find.byKey(const Key('breakpoint_continue')));
      await tester.pumpAndSettle();

      final responseResult = await responseFuture;
      expect(responseResult, isNotNull);
      expect(responseResult!.aborted, isFalse);
      expect(responseResult.payload.body, contains('patched'));
      expect(responseResult.payload.statusCode, 201);
    });

    testWidgets('non-matching calls are not intercepted', (tester) async {
      Infospect.instance.addEndpointBreakpoint(
        endpoint: '/api/users',
        method: 'GET',
      );

      await tester.pumpWidget(wrap(const Scaffold(body: Text('Host'))));
      await tester.pumpAndSettle();

      final result = await Infospect.instance.interceptRequestIfNeeded(
        method: 'POST',
        endpoint: '/api/users',
        uri: 'https://example.com/api/users',
        headers: const {},
        queryParameters: const {},
        body: null,
      );

      expect(result, isNull);
      expect(find.text('Request Breakpoint'), findsNothing);
    });

    testWidgets('abort cancels the intercepted request', (tester) async {
      Infospect.instance.addEndpointBreakpoint(endpoint: '/api/pay');

      await tester.pumpWidget(wrap(const Scaffold(body: Text('Host'))));
      await tester.pumpAndSettle();

      final future = Infospect.instance.interceptRequestIfNeeded(
        method: 'POST',
        endpoint: '/api/pay',
        uri: 'https://example.com/api/pay',
        headers: const {},
        queryParameters: const {},
        body: {'amount': 5},
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('breakpoint_abort')));
      await tester.pumpAndSettle();

      final result = await future;
      expect(result!.aborted, isTrue);
    });
  });

  group('Artifact export', () {
    test('golden PNGs exist for UI review after update-goldens', () {
      // Goldens live next to this test file under test/goldens/.
      final candidates = <String>[
        'goldens/breakpoints_list_empty.png',
        'goldens/breakpoints_list_with_rule.png',
        'goldens/breakpoint_request_headers.png',
        'goldens/breakpoint_request_body.png',
        'goldens/breakpoint_response.png',
        'goldens/breakpoint_request_body_dark.png',
        'goldens/breakpoint_integration_request_dialog.png',
        'goldens/breakpoint_integration_response_dialog.png',
      ];

      for (final relative in candidates) {
        final file = File('test/$relative');
        expect(
          file.existsSync(),
          isTrue,
          reason: '${file.path} should be generated via --update-goldens',
        );
      }
    });
  });
}
