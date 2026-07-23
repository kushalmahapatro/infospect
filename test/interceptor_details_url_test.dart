import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/features/network/ui/details/notifier/interceptor_details_notifier.dart';
import 'package:infospect/features/network/ui/details/screen/interceptor_details_screen.dart';
import 'package:infospect/helpers/infospect_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final navigatorKey = GlobalKey<NavigatorState>();

  setUpAll(() {
    Infospect.ensureInitialized(navigatorKey: navigatorKey);
  });

  testWidgets('mobile details header shows the complete wrapped URL',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const uri =
        'https://api.example.com/api/v1/organizations/acme/projects/mobile/users/42/settings?tab=notifications&verbose=true';
    final call = InfospectNetworkCall(7).copyWith(
      method: 'GET',
      endpoint: '/api/v1/organizations/acme/projects/mobile/users/42/settings',
      uri: uri,
      server: 'api.example.com',
      loading: false,
      duration: 120,
      request: InfospectNetworkRequest(size: 64),
      response: InfospectNetworkResponse(status: 200, size: 512),
    );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: InterceptorDetailsScreen(
          Infospect.instance,
          call: call,
          notifier: InterceptorDetailsNotifier(),
        ),
      ),
    );
    await tester.pump();

    final urlText = tester.widget<SelectableText>(
      find.ancestor(
        of: find.textContaining('verbose=true'),
        matching: find.byType(SelectableText),
      ),
    );
    expect(urlText.data, uri);
    expect(urlText.maxLines, isNull);
    expect(find.textContaining(uri), findsOneWidget);
  });
}
