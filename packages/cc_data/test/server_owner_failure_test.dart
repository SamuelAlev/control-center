import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/server_owner_required.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Pins the one mapping from the server's owner-only refusal (`unauthorized`
/// with `data.kind: server_owner_required`) to [ServerOwnerRequiredException],
/// and that `workspace.create` goes through it.
void main() {
  group('serverOwnerRequiredOf', () {
    test('types an unauthorized refusal of kind server_owner_required', () {
      final typed = serverOwnerRequiredOf(
        RemoteRpcException(
          RpcErrorCodes.unauthorized,
          'Only the server owner can create workspaces.',
          {'kind': serverOwnerRequiredKind},
        ),
      );
      expect(typed, isA<ServerOwnerRequiredException>());
      expect(typed!.message, 'Only the server owner can create workspaces.');
      expect(typed.code, serverOwnerRequiredKind);
    });

    test('leaves every other refusal alone', () {
      expect(
        serverOwnerRequiredOf(
          RemoteRpcException(RpcErrorCodes.unauthorized, 'Not a member.'),
        ),
        isNull,
      );
      expect(
        serverOwnerRequiredOf(
          RemoteRpcException(RpcErrorCodes.unauthorized, 'x', {
            'kind': 'upstream_auth',
          }),
        ),
        isNull,
      );
      // The kind only counts on an unauthorized refusal.
      expect(
        serverOwnerRequiredOf(
          RemoteRpcException(RpcErrorCodes.internalError, 'x', {
            'kind': serverOwnerRequiredKind,
          }),
        ),
        isNull,
      );
      expect(serverOwnerRequiredOf(StateError('x')), isNull);
    });
  });

  test('saving a host-placed environment raises the typed failure', () async {
    final host = _Host();
    addTearDown(host.close);
    host.onCall = (op, args) => throw const _RpcError(
      RpcErrorCodes.unauthorized,
      'Only the server owner can save this.',
      {'kind': serverOwnerRequiredKind},
    );
    final repo = RpcEnvironmentRepository(host.client);
    await expectLater(
      repo.setDefinition('ws-1', const {'name': 'Shop'}),
      throwsA(isA<ServerOwnerRequiredException>()),
    );
    await expectLater(
      repo.approveSource('ws-1', repoId: 'r-1', path: '.cc/env.json'),
      throwsA(isA<ServerOwnerRequiredException>()),
    );
    expect(host.calls.map((c) => c.$1), [
      'environments.setDefinition',
      'environments.approveSource',
    ]);
  });

  group('RemoteWorkspaceRepository.create', () {
    late _Host host;

    setUp(() => host = _Host());
    tearDown(() => host.close());

    test('sends only the name and decodes the workspace', () async {
      host.onCall = (op, args) => {
        'workspace': {'id': 'ws-new', 'name': args['name']},
      };
      final created = await RemoteWorkspaceRepository(
        host.client,
      ).create(name: 'Platform');
      expect(created.id, 'ws-new');
      final (op, args) = host.calls.single;
      expect(op, 'workspace.create');
      expect(args, {'name': 'Platform'});
    });

    test('raises the typed failure when only the owner may create', () async {
      host.onCall = (op, args) => throw const _RpcError(
        RpcErrorCodes.unauthorized,
        'Only the server owner can create workspaces.',
        {'kind': serverOwnerRequiredKind},
      );
      await expectLater(
        RemoteWorkspaceRepository(host.client).create(name: 'Platform'),
        throwsA(isA<ServerOwnerRequiredException>()),
      );
    });

    test('passes any other refusal through untouched', () async {
      host.onCall = (op, args) =>
          throw const _RpcError(RpcErrorCodes.unauthorized, 'Nope.', {});
      await expectLater(
        RemoteWorkspaceRepository(host.client).create(name: 'Platform'),
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.unauthorized,
          ),
        ),
      );
    });
  });
}

/// An in-process host whose `repo/call` answers come from [onCall]; a thrown
/// [_RpcError] goes back as a JSON-RPC error with its code and `data`.
class _Host {
  _Host() {
    final (server, channel) = InProcessRpcChannel.pair();
    _server = server;
    _server.incoming.listen(_handle);
    client = RemoteRpcClient(channel)..start();
  }

  late final RemoteRpcChannelPort _server;
  late final RemoteRpcClient client;
  final List<(String, Map<String, dynamic>)> calls = [];
  Map<String, dynamic> Function(String, Map<String, dynamic>) onCall =
      (op, _) => throw StateError('Unexpected RPC: $op');

  void _handle(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (id == null) {
      return;
    }
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    if (frame['method'] != RpcMethods.repoCall) {
      unawaited(
        _server.send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'capabilities': <String, dynamic>{}},
        }),
      );
      return;
    }
    final op = params['op'] as String;
    final args = (params['args'] as Map).cast<String, dynamic>();
    calls.add((op, args));
    try {
      final data = onCall(op, args);
      unawaited(
        _server.send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'op': op, 'data': data},
        }),
      );
    } on _RpcError catch (error) {
      unawaited(
        _server.send({
          'jsonrpc': '2.0',
          'id': id,
          'error': {
            'code': error.code,
            'message': error.message,
            'data': error.data,
          },
        }),
      );
    }
  }

  Future<void> close() async {
    await client.close();
    await _server.close();
  }
}

class _RpcError {
  const _RpcError(this.code, this.message, this.data);

  final int code;
  final String message;
  final Map<String, dynamic> data;
}
