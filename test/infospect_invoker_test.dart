import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/infospect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Infospect.ensureInitialized();
  });

  Future<void> pumpInvoker(
    WidgetTester tester, {
    required InvokerState state,
    required InvokerEdge edge,
  }) async {
    const surface = Size(400, 800);
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: surface),
        child: MaterialApp(
          home: InfospectInvoker(
            state: state,
            initialEdge: edge,
            initialAlign: 0.5,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('collapsed invoker docks flush to the right edge', (tester) async {
    await pumpInvoker(
      tester,
      state: InvokerState.collapsible,
      edge: InvokerEdge.right,
    );

    final positioned = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned),
    );
    expect(positioned.left, isNotNull);
    expect(positioned.width, isNotNull);
    // Hit target sits flush: left + width == viewport width.
    expect(positioned.left! + positioned.width!, 400);
    // Touch target is at least ~44 logical pixels thick.
    expect(positioned.width!, greaterThanOrEqualTo(44));
  });

  testWidgets('collapsed invoker docks flush to the left edge', (tester) async {
    await pumpInvoker(
      tester,
      state: InvokerState.collapsible,
      edge: InvokerEdge.left,
    );

    final positioned = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned),
    );
    expect(positioned.left, 0);
    expect(positioned.width!, greaterThanOrEqualTo(44));
  });

  testWidgets('expanded invoker keeps a margin from the edge', (tester) async {
    await pumpInvoker(
      tester,
      state: InvokerState.alwaysOpened,
      edge: InvokerEdge.right,
    );

    final positioned = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned),
    );
    expect(positioned.left! + positioned.width!, lessThan(400));
    expect(400 - (positioned.left! + positioned.width!), 8);
  });

  testWidgets('vertical initialEdge falls back to the right side', (tester) async {
    await pumpInvoker(
      tester,
      state: InvokerState.collapsible,
      edge: InvokerEdge.top,
    );

    final positioned = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned),
    );
    // Treated as right: flush to the right edge, not the top.
    expect(positioned.left! + positioned.width!, 400);
    expect(positioned.top, greaterThan(0));
  });

  testWidgets('drag release snaps to a horizontal edge only', (tester) async {
    await pumpInvoker(
      tester,
      state: InvokerState.alwaysOpened,
      edge: InvokerEdge.right,
    );

    final handle = find.byType(GestureDetector).last;
    await tester.drag(handle, const Offset(-180, -300));
    await tester.pumpAndSettle();

    final positioned = tester.widget<AnimatedPositioned>(
      find.byType(AnimatedPositioned),
    );
    final left = positioned.left!;
    final right = left + positioned.width!;
    // Docked to left or right — not floating mid-screen or on top/bottom.
    final onLeft = left == 8;
    final onRight = right == 392; // 400 - 8 margin
    expect(onLeft || onRight, isTrue);
  });
}
