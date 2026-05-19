import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:test/test.dart';

void main() {
  group('JsonRpcRequest', () {
    test('constructs with required method', () {
      final request = JsonRpcRequest(method: 'tools/call', id: 1);
      expect(request.jsonrpc, '2.0');
      expect(request.method, 'tools/call');
      expect(request.id, 1);
      expect(request.params, {});
    });

    test('asserts on empty method', () {
      expect(() => JsonRpcRequest(method: ''), throwsA(isA<AssertionError>()));
    });

    test('parses a standard tools/call request from JSON', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
          "name": "list_workspaces",
          "arguments": {}
        }
      }
      ''';
      final request = JsonRpcRequest.fromJson(jsonDecode(json));
      expect(request.jsonrpc, '2.0');
      expect(request.method, 'tools/call');
      expect(request.id, 1);
      expect(request.params['name'], 'list_workspaces');
    });

    test('parses an initialize request without id', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "method": "initialize",
        "params": {
          "clientInfo": {"name": "test-client"}
        }
      }
      ''';
      final request = JsonRpcRequest.fromJson(jsonDecode(json));
      expect(request.method, 'initialize');
      expect(request.id, isNull);
      expect(request.params['clientInfo'], isA<Map>());
    });

    test('has default jsonrpc version', () {
      const json = r'''
      {
        "method": "tools/list",
        "params": {},
        "id": 2
      }
      ''';
      final request = JsonRpcRequest.fromJson(jsonDecode(json));
      expect(request.jsonrpc, '2.0');
    });

    test('defaults params to empty map when missing from JSON', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "method": "ping",
        "id": 99
      }
      ''';
      final request = JsonRpcRequest.fromJson(jsonDecode(json));
      expect(request.params, {});
    });

    test('serializes to JSON with toJson', () {
      final request = JsonRpcRequest(
        method: 'test',
        params: {'key': 'value'},
        id: 42,
      );
      final json = request.toJson();
      expect(json['jsonrpc'], '2.0');
      expect(json['method'], 'test');
      expect(json['params'], {'key': 'value'});
      expect(json['id'], 42);
    });

    test('toJson round-trips through fromJson', () {
      final original = JsonRpcRequest(
        method: 'tools/call',
        params: {
          'name': 'hello',
          'arguments': {'text': 'world'},
        },
        id: 'req-1',
      );
      final json = original.toJson();
      final restored = JsonRpcRequest.fromJson(json);
      expect(restored.method, original.method);
      expect(restored.id, original.id);
      expect(restored.params['name'], 'hello');
      expect(restored, equals(original));
    });

    test('supports string IDs', () {
      final request = JsonRpcRequest(method: 'init', id: 'abc-123');
      expect(request.id, 'abc-123');
    });

    test('equality', () {
      final a = JsonRpcRequest(method: 'test', params: {'x': 1}, id: 1);
      final b = JsonRpcRequest(method: 'test', params: {'x': 1}, id: 1);
      final c = JsonRpcRequest(method: 'test', params: {'x': 2}, id: 1);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith overrides fields', () {
      final original = JsonRpcRequest(method: 'old', params: {'a': 1}, id: 10);

      final updated = original.copyWith(method: 'new', params: {'b': 2});

      expect(updated.method, 'new');
      expect(updated.params, {'b': 2});
      expect(updated.id, 10);
      expect(updated.jsonrpc, '2.0');
    });

    test('copyWith removes id when removeId is true', () {
      final original = JsonRpcRequest(method: 'test', id: 123);

      final updated = original.copyWith(removeId: true);
      expect(updated.id, isNull);
    });

    test('copyWith preserves id when null is passed without removeId', () {
      final original = JsonRpcRequest(method: 'test', id: 123);

      final updated = original.copyWith(id: null);
      expect(updated.id, 123);
    });

    test('toString includes all fields', () {
      final request = JsonRpcRequest(method: 'test', params: {'k': 'v'}, id: 1);
      final str = request.toString();
      expect(str, contains('JsonRpcRequest'));
      expect(str, contains('method: test'));
      expect(str, contains('id: 1'));
    });

    test('handles null params from JSON gracefully', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "method": "notify",
        "params": null,
        "id": 7
      }
      ''';
      final request = JsonRpcRequest.fromJson(jsonDecode(json));
      expect(request.params, {});
    });
  });

  group('JsonRpcResponse', () {
    test('constructs with required result', () {
      final response = JsonRpcResponse(result: {'key': 'value'}, id: 1);
      expect(response.jsonrpc, '2.0');
      expect(response.result, {'key': 'value'});
      expect(response.id, 1);
    });

    test('asserts on empty result', () {
      expect(() => JsonRpcResponse(result: {}), throwsA(isA<AssertionError>()));
    });

    test('serializes a successful result', () {
      final response = JsonRpcResponse(result: {'tools': []}, id: 1);
      final json = response.toJson();
      expect(json['jsonrpc'], '2.0');
      expect(json['result'], {'tools': []});
      expect(json['id'], 1);
    });

    test('parses from JSON with fromJson', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "result": {
          "tools": [
            {"name": "tool1", "description": "First tool"}
          ]
        },
        "id": 5
      }
      ''';
      final response = JsonRpcResponse.fromJson(jsonDecode(json));
      expect(response.jsonrpc, '2.0');
      expect(response.id, 5);
      expect(response.result['tools'], isA<List>());
    });

    test('parses from JSON without id', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "result": {"status": "ok"}
      }
      ''';
      final response = JsonRpcResponse.fromJson(jsonDecode(json));
      expect(response.id, isNull);
      expect(response.result, {'status': 'ok'});
    });

    test('toJson round-trips through fromJson', () {
      final original = JsonRpcResponse(
        result: {
          'items': [1, 2, 3],
          'count': 3,
        },
        id: 'resp-123',
      );
      final json = original.toJson();
      final restored = JsonRpcResponse.fromJson(json);
      expect(restored, equals(original));
    });

    test('equality', () {
      final a = JsonRpcResponse(result: {'x': 1}, id: 1);
      final b = JsonRpcResponse(result: {'x': 1}, id: 1);
      final c = JsonRpcResponse(result: {'x': 2}, id: 1);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith overrides fields', () {
      final original = JsonRpcResponse(result: {'old': true}, id: 1);

      final updated = original.copyWith(result: {'new': false}, id: 2);

      expect(updated.result, {'new': false});
      expect(updated.id, 2);
    });

    test('copyWith removes id when removeId is true', () {
      final original = JsonRpcResponse(result: {'x': 1}, id: 99);

      final updated = original.copyWith(removeId: true);
      expect(updated.id, isNull);
    });
  });

  group('JsonRpcError', () {
    test('constructs with code, message, and id', () {
      final error = JsonRpcError(
        code: -32601,
        message: 'Method not found',
        id: 3,
      );
      expect(error.code, -32601);
      expect(error.message, 'Method not found');
      expect(error.id, 3);
      expect(error.jsonrpc, '2.0');
    });

    test('asserts on empty message', () {
      expect(
        () => JsonRpcError(code: -1, message: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructs with data payload', () {
      final error = JsonRpcError(
        code: -32000,
        message: 'Server error',
        data: {'detail': 'something went wrong'},
        id: 7,
      );
      expect(error.data, {'detail': 'something went wrong'});
    });

    test('parses from JSON with fromJson', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "code": -32602,
        "message": "Invalid params",
        "id": 100
      }
      ''';
      final error = JsonRpcError.fromJson(jsonDecode(json));
      expect(error.code, -32602);
      expect(error.message, 'Invalid params');
      expect(error.id, 100);
    });

    test('toJson round-trips through fromJson', () {
      final original = JsonRpcError(
        code: -32603,
        message: 'Internal error',
        data: {'stack': 'trace'},
        id: 'err-1',
      );
      final json = original.toJson();
      final restored = JsonRpcError.fromJson(json);
      expect(restored.code, original.code);
      expect(restored.message, original.message);
      expect(restored.data, original.data);
      expect(restored.id, original.id);
      expect(restored, equals(original));
    });

    test('equality and hashCode', () {
      final a = JsonRpcError(
        code: -32601,
        message: 'Method not found',
        data: null,
        id: 1,
      );
      final b = JsonRpcError(
        code: -32601,
        message: 'Method not found',
        data: null,
        id: 1,
      );
      final c = JsonRpcError(
        code: -32602,
        message: 'Invalid params',
        data: null,
        id: 1,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('copyWith overrides fields', () {
      final original = JsonRpcError(
        code: -1,
        message: 'old',
        data: 'old data',
        id: 1,
      );

      final updated = original.copyWith(code: -32600, message: 'new', id: 2);

      expect(updated.code, -32600);
      expect(updated.message, 'new');
      expect(updated.id, 2);
      expect(updated.data, 'old data');
    });

    test('copyWith removes data when removeData is true', () {
      final original = JsonRpcError(
        code: -1,
        message: 'msg',
        data: 'sensitive',
      );

      final updated = original.copyWith(removeData: true);
      expect(updated.data, isNull);
    });

    test('copyWith removes id when removeId is true', () {
      final original = JsonRpcError(code: -1, message: 'msg', id: 123);

      final updated = original.copyWith(removeId: true);
      expect(updated.id, isNull);
    });

    test('standard JSON-RPC error codes', () {
      const parseError = -32700;
      const invalidRequest = -32600;
      const methodNotFound = -32601;
      const invalidParams = -32602;
      const internalError = -32603;

      expect(
        JsonRpcError(code: parseError, message: 'Parse error').code,
        parseError,
      );
      expect(
        JsonRpcError(code: invalidRequest, message: 'Invalid Request').code,
        invalidRequest,
      );
      expect(
        JsonRpcError(code: methodNotFound, message: 'Method not found').code,
        methodNotFound,
      );
      expect(
        JsonRpcError(code: invalidParams, message: 'Invalid params').code,
        invalidParams,
      );
      expect(
        JsonRpcError(code: internalError, message: 'Internal error').code,
        internalError,
      );
    });
  });

  group('JsonRpcNotification', () {
    test('constructs with required method', () {
      final notification = JsonRpcNotification(method: 'notifications/ready');
      expect(notification.jsonrpc, '2.0');
      expect(notification.method, 'notifications/ready');
      expect(notification.params, {});
    });

    test('asserts on empty method', () {
      expect(
        () => JsonRpcNotification(method: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('parses a notification from JSON', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "method": "notifications/initialized"
      }
      ''';
      final notification = JsonRpcNotification.fromJson(jsonDecode(json));
      expect(notification.method, 'notifications/initialized');
      expect(notification.params, {});
    });

    test('parses notification with params', () {
      const json = r'''
      {
        "jsonrpc": "2.0",
        "method": "notifications/progress",
        "params": {
          "progressToken": "abc",
          "progress": 50
        }
      }
      ''';
      final notification = JsonRpcNotification.fromJson(jsonDecode(json));
      expect(notification.method, 'notifications/progress');
      expect(notification.params['progress'], 50);
      expect(notification.params['progressToken'], 'abc');
    });

    test('serializes to JSON with toJson', () {
      final notification = JsonRpcNotification(
        method: 'notifications/update',
        params: {'status': 'ok'},
      );
      final json = notification.toJson();
      expect(json['jsonrpc'], '2.0');
      expect(json['method'], 'notifications/update');
      expect(json['params'], {'status': 'ok'});
      expect(json.containsKey('id'), isFalse);
    });

    test('toJson round-trips through fromJson', () {
      final original = JsonRpcNotification(
        method: 'notifications/test',
        params: {
          'key': [1, 2, 3],
        },
      );
      final json = original.toJson();
      final restored = JsonRpcNotification.fromJson(json);
      expect(restored.method, original.method);
      expect(restored.params['key'], [1, 2, 3]);
      expect(restored, equals(original));
    });

    test('equality', () {
      final a = JsonRpcNotification(method: 'notify', params: {'id': 1});
      final b = JsonRpcNotification(method: 'notify', params: {'id': 1});
      final c = JsonRpcNotification(method: 'other', params: {'id': 1});

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith overrides fields', () {
      final original = JsonRpcNotification(method: 'old', params: {'a': 1});

      final updated = original.copyWith(method: 'new', params: {'b': 2});

      expect(updated.method, 'new');
      expect(updated.params, {'b': 2});
      expect(updated.jsonrpc, '2.0');
    });
  });

  group('cross-type equality', () {
    test('different types are never equal', () {
      final request = JsonRpcRequest(method: 'test', id: 1);
      final response = JsonRpcResponse(result: {'test': true}, id: 1);
      final error = JsonRpcError(code: -1, message: 'test', id: 1);
      final notification = JsonRpcNotification(method: 'test');

      expect(request, isNot(equals(response)));
      expect(request, isNot(equals(error)));
      expect(request, isNot(equals(notification)));
    });
  });
}
