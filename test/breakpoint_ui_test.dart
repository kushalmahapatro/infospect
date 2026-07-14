import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_edit.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_session.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_network_breakpoint.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoint_intercept_screen.dart';
import 'package:infospect/features/network/breakpoints/ui/breakpoints_list_screen.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/features/network/ui/details/components/interceptor_details_request.dart';
import 'package:infospect/features/network/ui/details/models/details_topic_data.dart';
import 'package:infospect/features/network/ui/details/screen/desktop_details_screen.dart';
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
    Infospect.instance.clearAllNetworkCalls();
    Infospect.instance.preferInAppBreakpointDialogs = true;
  });

  Widget wrap(
    Widget child, {
    ThemeData? theme,
    Size size = const Size(390, 844),
  }) {
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

      await tester.pumpWidget(wrap(const BreakpointsListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No breakpoints yet'), findsOneWidget);
      expect(find.text('Breakpoints'), findsOneWidget);

      await expectLater(
        find.byType(BreakpointsListScreen),
        matchesGoldenFile('goldens/breakpoints_list_empty.png'),
      );

      await tester.tap(find.text('Add breakpoint').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Add breakpoint'), findsWidgets);
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

    testWidgets('desktop breakpoints window uses table + inspector pane',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(780, 560));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        wrap(
          const BreakpointsListScreen(embedded: true),
          size: const Size(780, 560),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No breakpoints'), findsOneWidget);

      await expectLater(
        find.byType(BreakpointsListScreen),
        matchesGoldenFile('goldens/breakpoints_desktop_empty.png'),
      );

      await tester.tap(find.text('Add breakpoint').last);
      await tester.pumpAndSettle();

      expect(find.text('New rule'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, '/api/orders*');
      await tester.tap(find.widgetWithText(FilledButton, 'Add').last);
      await tester.pumpAndSettle();

      expect(Infospect.instance.breakpoints, hasLength(1));
      expect(find.text('/api/orders*'), findsWidgets);
      expect(find.text('Edit rule'), findsOneWidget);

      await expectLater(
        find.byType(BreakpointsListScreen),
        matchesGoldenFile('goldens/breakpoints_desktop_with_rule.png'),
      );
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
        requestId: 101,
      );

      await tester.pumpAndSettle();
      expect(find.text('Request Breakpoint'), findsOneWidget);
      expect(find.textContaining('/api/checkout'), findsWidgets);

      await expectLater(
        find.byType(BreakpointInterceptScreen),
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
        statusCode: 500,
        requestId: 101,
      );

      await tester.pumpAndSettle();
      expect(find.text('Response Breakpoint'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('breakpoint_status_field')))
            .controller!
            .text,
        '500',
      );

      await expectLater(
        find.byType(BreakpointInterceptScreen),
        matchesGoldenFile('goldens/breakpoint_integration_response_dialog.png'),
      );

      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('breakpoint_body_field')),
        '{\n  "ok": true,\n  "patched": true\n}',
      );
      await tester.enterText(
        find.byKey(const Key('breakpoint_status_field')),
        '200',
      );
      await tester.tap(find.byKey(const Key('breakpoint_continue')));
      await tester.pumpAndSettle();

      final responseResult = await responseFuture;
      expect(responseResult, isNotNull);
      expect(responseResult!.aborted, isFalse);
      expect(responseResult.payload.body, contains('patched'));
      expect(responseResult.payload.statusCode, 200);
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

    testWidgets('stores original and edited request/response snapshots', (tester) async {
      Infospect.instance.addCall(
        InfospectNetworkCall(88).copyWith(
          method: 'POST',
          endpoint: '/orders',
          uri: 'https://example.com/orders?x=1',
          request: InfospectNetworkRequest(
            headers: const {'content-type': 'application/json'},
            queryParameters: const {'x': '1'},
            body: '{"total":1}',
          ),
        ),
      );
      Infospect.instance.addEndpointBreakpoint(endpoint: '/orders');

      await tester.pumpWidget(wrap(const Scaffold(body: Text('Host'))));
      await tester.pumpAndSettle();

      final requestFuture = Infospect.instance.interceptRequestIfNeeded(
        method: 'POST',
        endpoint: '/orders',
        uri: 'https://example.com/orders?x=1',
        headers: const {'content-type': 'application/json'},
        queryParameters: const {'x': '1'},
        body: '{"total":1}',
        requestId: 88,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Query'));
      await tester.pumpAndSettle();

      // Edit the query value field (second text field in the row after key).
      final queryValueFields = find.byType(TextField);
      await tester.enterText(queryValueFields.at(1), '99');
      await tester.tap(find.text('Body'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('breakpoint_body_field')),
        '{"total":99}',
      );
      await tester.tap(find.byKey(const Key('breakpoint_continue')));
      await tester.pumpAndSettle();
      await requestFuture;

      // Apply the same storage path the interceptors use.
      Infospect.instance.applyRequestBreakpointEdit(
        requestId: 88,
        edit: InfospectBreakpointEdit(
          original: const InfospectBreakpointPayload(
            method: 'POST',
            uri: 'https://example.com/orders?x=1',
            endpoint: '/orders',
            headers: {'content-type': 'application/json'},
            queryParameters: {'x': '1'},
            body: '{"total":1}',
          ),
          edited: const InfospectBreakpointPayload(
            method: 'POST',
            uri: 'https://example.com/orders?x=99',
            endpoint: '/orders',
            headers: {'content-type': 'application/json'},
            queryParameters: {'x': '99'},
            body: '{"total":99}',
          ),
        ),
      );

      final call = Infospect.instance.networkCallsSubject.value
          .firstWhere((c) => c.id == 88);
      expect(call.requestBreakpointEdit, isNotNull);
      expect(call.requestBreakpointEdit!.original.queryParameters['x'], '1');
      expect(call.requestBreakpointEdit!.edited.queryParameters['x'], '99');
      expect(call.requestBreakpointEdit!.original.body, contains('"total":1'));
      expect(call.requestBreakpointEdit!.edited.body, contains('"total":99'));
      expect(call.request!.queryParameters['x'], '99');
      expect(call.uri, contains('x=99'));

      Infospect.instance.applyResponseBreakpointEdit(
        requestId: 88,
        edit: const InfospectBreakpointEdit(
          original: InfospectBreakpointPayload(
            method: 'POST',
            uri: 'https://example.com/orders?x=99',
            endpoint: '/orders',
            headers: {'content-type': 'application/json'},
            body: '{"ok":false}',
            statusCode: 500,
          ),
          edited: InfospectBreakpointPayload(
            method: 'POST',
            uri: 'https://example.com/orders?x=99',
            endpoint: '/orders',
            headers: {'content-type': 'application/json'},
            body: '{"ok":true}',
            statusCode: 200,
          ),
        ),
      );

      final updated = Infospect.instance.networkCallsSubject.value
          .firstWhere((c) => c.id == 88);
      expect(updated.responseBreakpointEdit, isNotNull);
      expect(updated.responseBreakpointEdit!.original.statusCode, 500);
      expect(updated.responseBreakpointEdit!.edited.statusCode, 200);
      expect(updated.responseBreakpointEdit!.original.body, contains('false'));
      expect(updated.responseBreakpointEdit!.edited.body, contains('true'));
    });

    testWidgets('request details show Original vs Edited compare section',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final call = InfospectNetworkCall(91).copyWith(
        method: 'GET',
        endpoint: '/items',
        uri: 'https://example.com/items?page=2',
        server: 'example.com',
        loading: false,
        request: InfospectNetworkRequest(
          headers: const {'x-token': 'new'},
          queryParameters: const {'page': '2'},
          body: '',
        ),
        requestEditedAtBreakpoint: true,
        hadRequestBreakpoint: true,
        requestBreakpointEdit: const InfospectBreakpointEdit(
          original: InfospectBreakpointPayload(
            method: 'GET',
            uri: 'https://example.com/items?page=1',
            endpoint: '/items',
            headers: {'x-token': 'old'},
            queryParameters: {'page': '1'},
          ),
          edited: InfospectBreakpointPayload(
            method: 'GET',
            uri: 'https://example.com/items?page=2',
            endpoint: '/items',
            headers: {'x-token': 'new'},
            queryParameters: {'page': '2'},
          ),
        ),
      );

      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: InterceptorDetailsRequest(
              call,
              infospect: Infospect.instance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Breakpoint edits'), findsOneWidget);
      expect(find.text('Original'), findsWidgets);
      expect(find.text('Edited'), findsWidgets);
      expect(find.textContaining('page=1'), findsWidgets);
      expect(find.textContaining('page=2'), findsWidgets);
    });

    testWidgets('desktop details show Original vs Edited for request/response',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      final call = InfospectNetworkCall(92).copyWith(
        method: 'POST',
        endpoint: '/checkout',
        uri: 'https://example.com/checkout?v=2',
        server: 'example.com',
        loading: false,
        request: InfospectNetworkRequest(
          headers: const {'content-type': 'application/json'},
          queryParameters: const {'v': '2'},
          body: '{"ok":true}',
        ),
        response: InfospectNetworkResponse(
          status: 200,
          headers: const {'content-type': 'application/json'},
          body: '{"ok":true}',
        ),
        requestEditedAtBreakpoint: true,
        responseEditedAtBreakpoint: true,
        hadRequestBreakpoint: true,
        hadResponseBreakpoint: true,
        requestBreakpointEdit: const InfospectBreakpointEdit(
          original: InfospectBreakpointPayload(
            method: 'POST',
            uri: 'https://example.com/checkout?v=1',
            endpoint: '/checkout',
            headers: {'content-type': 'application/json'},
            queryParameters: {'v': '1'},
            body: '{"ok":false}',
          ),
          edited: InfospectBreakpointPayload(
            method: 'POST',
            uri: 'https://example.com/checkout?v=2',
            endpoint: '/checkout',
            headers: {'content-type': 'application/json'},
            queryParameters: {'v': '2'},
            body: '{"ok":true}',
          ),
        ),
        responseBreakpointEdit: const InfospectBreakpointEdit(
          original: InfospectBreakpointPayload(
            method: 'POST',
            uri: 'https://example.com/checkout?v=2',
            endpoint: '/checkout',
            headers: {'content-type': 'application/json'},
            body: '{"ok":false}',
            statusCode: 500,
          ),
          edited: InfospectBreakpointPayload(
            method: 'POST',
            uri: 'https://example.com/checkout?v=2',
            endpoint: '/checkout',
            headers: {'content-type': 'application/json'},
            body: '{"ok":true}',
            statusCode: 200,
          ),
        ),
      );

      final topicHelper = RequestDetailsTopicHelper(call);
      final responseHelper = ResponseDetailsTopicHelper(call);

      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: DesktopDetailsScreen(
              infospect: Infospect.instance,
              selectedCall: call,
              topicHelper: topicHelper,
              responseTopicHelper: responseHelper,
              selectedTopic: topicHelper.desktopTopics.first,
              selectedResponseTopic: responseHelper.desktopTopics.first,
              onTopicSelected: (_) {},
              onResponseTopicSelected: (_) {},
            ),
          ),
          size: const Size(1280, 800),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Original vs Edited'), findsNWidgets(2));
      expect(find.text('BP✎'), findsOneWidget);
      expect(find.textContaining('Original:'), findsWidgets);
      expect(find.text('edited'), findsWidgets);
      expect(find.text('Expand'), findsWidgets);

      await tester.tap(find.text('Original vs Edited').first);
      await tester.pumpAndSettle();

      expect(find.text('Collapse'), findsOneWidget);
      expect(find.text('Original'), findsWidgets);
      expect(find.text('Edited'), findsWidgets);
      expect(find.text('Field'), findsOneWidget);
    });

    testWidgets('desktop intercept screen uses native chrome', (tester) async {
      await tester.binding.setSurfaceSize(const Size(720, 580));
      await tester.pumpWidget(
        wrap(
          BreakpointInterceptScreen(
            phase: InfospectBreakpointPhase.request,
            initialPayload: const InfospectBreakpointPayload(
              method: 'GET',
              uri: 'https://example.com/native',
              endpoint: '/native',
              headers: {'accept': 'application/json'},
              queryParameters: {'q': '1'},
              body: '',
            ),
            desktop: true,
            onContinue: (_) {},
            onAbort: (_) {},
          ),
          size: const Size(720, 580),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Request Breakpoint'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Abort'), findsOneWidget);
      expect(find.textContaining('https://example.com/native'), findsOneWidget);

      await expectLater(
        find.byType(BreakpointInterceptScreen),
        matchesGoldenFile('goldens/breakpoint_desktop_request.png'),
      );
    });
  });

  group('Artifact export', () {
    test('golden PNGs exist for UI review after update-goldens', () {
      final candidates = <String>[
        'goldens/breakpoints_list_empty.png',
        'goldens/breakpoints_list_with_rule.png',
        'goldens/breakpoints_desktop_empty.png',
        'goldens/breakpoints_desktop_with_rule.png',
        'goldens/breakpoint_request_headers.png',
        'goldens/breakpoint_request_body.png',
        'goldens/breakpoint_response.png',
        'goldens/breakpoint_request_body_dark.png',
        'goldens/breakpoint_integration_request_dialog.png',
        'goldens/breakpoint_integration_response_dialog.png',
        'goldens/breakpoint_desktop_request.png',
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
