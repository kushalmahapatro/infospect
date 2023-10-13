// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:bloc_test/bloc_test.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  blocTest<TestBloc, TestState>(
    'emits [MyState] when MyEvent is added.',
    build: () => TestBloc(),
    act: (bloc) => bloc.add(const TestEvent(1)),
    expect: () => const <TestState>[
      TestState(<A>[
        A(<B>[B(1)])
      ])
    ],
  );
}

class TestBloc extends Bloc<TestEvent, TestState> {
  TestBloc()
      : super(const TestState([
          A([B(0)])
        ])) {
    on<TestEvent>(
      (event, emit) {
        emit(state.copyWith(a: [
          A([B(event.id)])
        ]));
      },
    );
  }
}

class TestEvent {
  final int id;
  const TestEvent(this.id);
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
