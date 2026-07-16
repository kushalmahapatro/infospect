import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/features/network/models/infospect_network_call.dart';
import 'package:infospect/features/network/models/infospect_network_request.dart';
import 'package:infospect/features/network/models/infospect_network_response.dart';
import 'package:infospect/features/network/ui/list/components/infospect_endpoint_label.dart';
import 'package:infospect/features/network/ui/list/components/network_call_item.dart';

void main() {
  testWidgets('network call item shows a long endpoint without ellipsis dots',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const path =
        '/api/v1/organizations/acme-corp/projects/mobile-app/users/42/settings/notifications/preferences';
    final call = InfospectNetworkCall(1).copyWith(
      method: 'GET',
      endpoint: path,
      server: 'api.example.com',
      uri: 'https://api.example.com$path',
      duration: 42,
      loading: false,
      request: InfospectNetworkRequest(
        size: 128,
        requestTime: DateTime(2026, 1, 1, 12, 0, 0),
      ),
      response: InfospectNetworkResponse(status: 200, size: 256),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NetworkCallItem(
            networkCall: call,
            onItemClicked: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(InfospectEndpointLabel), findsWidgets);
    expect(find.textContaining('preferences'), findsOneWidget);
    // Endpoint itself should not use ellipsis truncation glyphs.
    final endpointTexts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(InfospectEndpointLabel).first,
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join();
    expect(endpointTexts, contains(path));
    expect(endpointTexts, isNot(contains('…')));
  });

  testWidgets('endpoint label scroll mode keeps a single-line full URL',
      (tester) async {
    const url =
        'https://api.example.com/api/v1/very/long/path/that/exceeds/narrow/width';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            child: InfospectEndpointLabel(
              text: url,
              mode: InfospectEndpointOverflowMode.scroll,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(url), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
