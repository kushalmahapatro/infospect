import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_network_breakpoint.dart';

void main() {
  group('InfospectNetworkBreakpoint matching', () {
    test('matches any method when method is null', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
      );

      expect(
        rule.matches(requestMethod: 'GET', requestEndpoint: '/api/users'),
        isTrue,
      );
      expect(
        rule.matches(requestMethod: 'POST', requestEndpoint: '/api/users'),
        isTrue,
      );
    });

    test('matches only the configured method', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        method: 'POST',
      );

      expect(
        rule.matches(requestMethod: 'POST', requestEndpoint: '/api/users'),
        isTrue,
      );
      expect(
        rule.matches(requestMethod: 'GET', requestEndpoint: '/api/users'),
        isFalse,
      );
    });

    test('supports trailing wildcard prefix match', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users*',
      );

      expect(
        rule.matches(requestMethod: 'GET', requestEndpoint: '/api/users'),
        isTrue,
      );
      expect(
        rule.matches(requestMethod: 'GET', requestEndpoint: '/api/users/1'),
        isTrue,
      );
      expect(
        rule.matches(requestMethod: 'GET', requestEndpoint: '/api/orders'),
        isFalse,
      );
    });

    test('ignores disabled rules', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        enabled: false,
      );

      expect(
        rule.matches(requestMethod: 'GET', requestEndpoint: '/api/users'),
        isFalse,
      );
    });

    test('parses full URIs as path endpoints', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: 'https://example.com/api/users',
      );

      expect(
        rule.matches(requestMethod: 'GET', requestEndpoint: '/api/users'),
        isTrue,
      );
    });
  });

  group('InfospectBreakpointManager', () {
    late InfospectBreakpointManager manager;

    setUp(() {
      manager = InfospectBreakpointManager();
    });

    tearDown(() {
      manager.dispose();
    });

    test('findMatch returns the first matching enabled rule', () {
      manager.addBreakpoint(
        const InfospectNetworkBreakpoint(
          id: 'a',
          endpoint: '/other',
          method: 'GET',
        ),
      );
      manager.addBreakpoint(
        const InfospectNetworkBreakpoint(
          id: 'b',
          endpoint: '/api/users',
          method: 'POST',
        ),
      );

      final match = manager.findMatch(
        method: 'POST',
        endpoint: '/api/users',
      );

      expect(match?.id, 'b');
    });

    test('setEnabled toggles matching', () {
      manager.addBreakpoint(
        const InfospectNetworkBreakpoint(
          id: 'a',
          endpoint: '/api/users',
        ),
      );

      expect(
        manager.findMatch(method: 'GET', endpoint: '/api/users'),
        isNotNull,
      );

      manager.setEnabled('a', false);
      expect(
        manager.findMatch(method: 'GET', endpoint: '/api/users'),
        isNull,
      );
    });

    test('stringifyBody pretty-prints JSON maps', () {
      final text = InfospectBreakpointManager.stringifyBody({'a': 1});
      expect(text, contains('"a": 1'));
    });

    test('parseBody decodes JSON when possible', () {
      final value = InfospectBreakpointManager.parseBody('{"a":1}');
      expect(value, isA<Map>());
      expect((value as Map)['a'], 1);
    });
  });
}
