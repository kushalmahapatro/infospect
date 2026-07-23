import 'package:flutter_test/flutter_test.dart';
import 'package:infospect/features/network/breakpoints/infospect_breakpoint_manager.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_breakpoint_condition.dart';
import 'package:infospect/features/network/breakpoints/models/infospect_network_breakpoint.dart';

InfospectBreakpointMatchContext ctx({
  String method = 'GET',
  String endpoint = '/api/users',
  Map<String, dynamic> query = const <String, dynamic>{},
  Map<String, dynamic> headers = const <String, dynamic>{},
  dynamic body,
  int? status,
  dynamic responseBody,
  bool responsePhase = false,
}) {
  return InfospectBreakpointMatchContext(
    method: method,
    endpoint: endpoint,
    queryParameters: query,
    requestHeaders: headers,
    requestBody: body,
    statusCode: status,
    responseBody: responseBody,
    isResponsePhase: responsePhase,
  );
}

void main() {
  group('InfospectNetworkBreakpoint matching', () {
    test('matches any method when method is null', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
      );

      expect(rule.matches(ctx(method: 'GET')), isTrue);
      expect(rule.matches(ctx(method: 'POST')), isTrue);
    });

    test('matches only the configured method', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        method: 'POST',
      );

      expect(rule.matches(ctx(method: 'POST')), isTrue);
      expect(rule.matches(ctx(method: 'GET')), isFalse);
    });

    test('supports trailing wildcard prefix match', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users*',
      );

      expect(rule.matches(ctx(endpoint: '/api/users')), isTrue);
      expect(rule.matches(ctx(endpoint: '/api/users/1')), isTrue);
      expect(rule.matches(ctx(endpoint: '/api/orders')), isFalse);
    });

    test('ignores disabled rules', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        enabled: false,
      );

      expect(rule.matches(ctx()), isFalse);
    });

    test('parses full URIs as path endpoints', () {
      const rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: 'https://example.com/api/users',
      );

      expect(rule.matches(ctx(endpoint: '/api/users')), isTrue);
    });

    test('round-trips conditions through toMap/fromMap', () {
      final rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        conditions: [
          InfospectBreakpointCondition(
            id: 'c1',
            target: InfospectBreakpointMatchTarget.queryParam,
            op: InfospectBreakpointMatchOp.equals,
            key: 'debug',
            value: '1',
          ),
        ],
      );

      final restored = InfospectNetworkBreakpoint.fromMap(rule.toMap());
      expect(restored.conditions, hasLength(1));
      expect(restored.conditions.first.key, 'debug');
      expect(restored.conditions.first.value, '1');
    });
  });

  group('breakpoint conditions', () {
    test('query param equals / exists', () {
      final rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        conditions: [
          InfospectBreakpointCondition(
            id: 'c1',
            target: InfospectBreakpointMatchTarget.queryParam,
            op: InfospectBreakpointMatchOp.equals,
            key: 'debug',
            value: '1',
          ),
        ],
      );

      expect(
        rule.matches(ctx(query: {'debug': '1'})),
        isTrue,
      );
      expect(
        rule.matches(ctx(query: {'debug': '0'})),
        isFalse,
      );
      expect(
        rule.matches(ctx()),
        isFalse,
      );
    });

    test('request JSON path equals', () {
      final rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        conditions: [
          InfospectBreakpointCondition(
            id: 'c1',
            target: InfospectBreakpointMatchTarget.requestBodyJson,
            op: InfospectBreakpointMatchOp.equals,
            key: 'user.id',
            value: '42',
          ),
        ],
      );

      expect(
        rule.matches(ctx(body: '{"user":{"id":42}}')),
        isTrue,
      );
      expect(
        rule.matches(ctx(body: {'user': {'id': 42}})),
        isTrue,
      );
      expect(
        rule.matches(ctx(body: '{"user":{"id":7}}')),
        isFalse,
      );
    });

    test('response-only status does not match at request phase', () {
      final rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        conditions: [
          InfospectBreakpointCondition(
            id: 'c1',
            target: InfospectBreakpointMatchTarget.responseStatus,
            op: InfospectBreakpointMatchOp.equals,
            value: '500',
          ),
        ],
      );

      expect(rule.matches(ctx()), isFalse);
      expect(
        rule.matches(ctx(status: 500, responsePhase: true)),
        isTrue,
      );
      expect(
        rule.matches(ctx(status: 200, responsePhase: true)),
        isFalse,
      );
    });

    test('status range 500-599', () {
      final rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        conditions: [
          InfospectBreakpointCondition(
            id: 'c1',
            target: InfospectBreakpointMatchTarget.responseStatus,
            op: InfospectBreakpointMatchOp.inRange,
            value: '500-599',
          ),
        ],
      );

      expect(
        rule.matches(ctx(status: 503, responsePhase: true)),
        isTrue,
      );
      expect(
        rule.matches(ctx(status: 404, responsePhase: true)),
        isFalse,
      );
    });

    test('response body JSON path', () {
      final rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        conditions: [
          InfospectBreakpointCondition(
            id: 'c1',
            target: InfospectBreakpointMatchTarget.responseBodyJson,
            op: InfospectBreakpointMatchOp.contains,
            key: 'error.message',
            value: 'timeout',
          ),
        ],
      );

      expect(
        rule.matches(
          ctx(
            responseBody: '{"error":{"message":"request timeout"}}',
            responsePhase: true,
          ),
        ),
        isTrue,
      );
      expect(
        rule.matches(
          ctx(
            responseBody: '{"error":{"message":"ok"}}',
            responsePhase: true,
          ),
        ),
        isFalse,
      );
    });

    test('AND-combines multiple conditions', () {
      final rule = InfospectNetworkBreakpoint(
        id: '1',
        endpoint: '/api/users',
        conditions: [
          InfospectBreakpointCondition(
            id: 'c1',
            target: InfospectBreakpointMatchTarget.queryParam,
            op: InfospectBreakpointMatchOp.equals,
            key: 'env',
            value: 'staging',
          ),
          InfospectBreakpointCondition(
            id: 'c2',
            target: InfospectBreakpointMatchTarget.requestHeader,
            op: InfospectBreakpointMatchOp.exists,
            key: 'X-Debug',
          ),
        ],
      );

      expect(
        rule.matches(
          ctx(
            query: {'env': 'staging'},
            headers: {'X-Debug': '1'},
          ),
        ),
        isTrue,
      );
      expect(
        rule.matches(ctx(query: {'env': 'staging'})),
        isFalse,
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
        ctx(method: 'POST', endpoint: '/api/users'),
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

      expect(manager.findMatch(ctx()), isNotNull);

      manager.setEnabled('a', false);
      expect(manager.findMatch(ctx()), isNull);
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
