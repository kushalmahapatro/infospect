import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/utils/common_widgets/infospect_toast.dart';

void main() {
  testWidgets('InfospectToast shows a desktop-style notification card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => InfospectToast.show(
                  context,
                  'Breakpoint added for POST /api/pay',
                  icon: Icons.crisis_alert_outlined,
                ),
                child: const Text('Notify'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Notify'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Breakpoint added for POST /api/pay'), findsOneWidget);
    expect(find.byIcon(Icons.crisis_alert_outlined), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Dismiss via close control.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Breakpoint added for POST /api/pay'), findsNothing);
  });
}
