// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equatable/equatable.dart';

void main() {
  test('TestNotifier emits correct state when update is called', () {
    final notifier = TestNotifier();

    // Track state changes
    final states = <TestState>[];
    notifier.addListener(() {
      states.add(notifier.state);
    });

    // Initial state
    expect(
        notifier.state,
        const TestState([
          A([B(0)])
        ]));

    // Update state
    notifier.updateState(1);

    // Verify state changed
    expect(states, [
      const TestState([
        A([B(1)])
      ])
    ]);

    notifier.dispose();
  });
}

class TestNotifier extends ChangeNotifier {
  TestState _state = const TestState([
    A([B(0)])
  ]);

  TestState get state => _state;

  void updateState(int id) {
    _state = _state.copyWith(a: [
      A([B(id)])
    ]);
    notifyListeners();
  }
}

class TestState extends Equatable {
  final List<A> a;

  const TestState(this.a);

  TestState copyWith({List<A>? a}) {
    return TestState(a ?? this.a);
  }

  @override
  List<Object?> get props => [a];
}

class A extends Equatable {
  final List<B> b;
  const A(this.b);
  @override
  List<Object?> get props => [b];

  @override
  String toString() {
    return 'A{b: $b}';
  }
}

class B extends Equatable {
  final int id;
  const B(this.id);

  @override
  List<Object?> get props => [id];
}
