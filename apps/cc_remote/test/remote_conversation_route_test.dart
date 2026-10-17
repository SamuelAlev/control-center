@TestOn('browser')
library;

import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/conversation_feed.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _workspace = 'workspace/one';
const _space = 'space with / and ?';

class _RouteHost {
  _RouteHost() {
    final (server, channel) = InProcessRpcChannel.pair();
    this.server = server;
    client = RemoteRpcClient(channel);
    server.incoming.listen(_answer);
    client.start();
  }

  late final RemoteRpcChannelPort server;
  late final RemoteRpcClient client;
  final conversations = <String, Map<String, dynamic>>{};
  final messages = <String, Map<String, dynamic>>{};
  final calls = <({String op, Map<String, dynamic> args})>[];

  void _answer(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (id == null) return;
    final method = frame['method'];
    if (method != RpcMethods.repoCall) {
      unawaited(
        server.send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'capabilities': <String, dynamic>{}},
        }),
      );
      return;
    }
    final params = (frame['params'] as Map).cast<String, dynamic>();
    final op = params['op'] as String;
    final args = (params['args'] as Map).cast<String, dynamic>();
    calls.add((op: op, args: args));
    final data = switch (op) {
      'conversation.getById' => {
        'conversation': conversations[args['conversation_id']],
      },
      'messaging.getMessageById' => {'message': messages[args['message_id']]},
      'conversation.list' => {'conversations': <Map<String, dynamic>>[]},
      _ => throw StateError('Unexpected route operation $op'),
    };
    unawaited(
      server.send({
        'jsonrpc': '2.0',
        'id': id,
        'result': {'op': op, 'data': data},
      }),
    );
  }

  Future<void> close() => server.close();
}

Map<String, dynamic> _conversation(
  String id, {
  String workspace = _workspace,
  String space = _space,
}) => {
  'id': id,
  'workspace_id': workspace,
  'space_id': space,
  'title': 'Real conversation',
  'status': 'active',
};

Map<String, dynamic> _message(
  String id, {
  String? conversation = 'thread-9',
  String space = _space,
}) => {
  'id': id,
  'space_id': space,
  'conversation_id': ?conversation,
  'sender_id': 'owner',
  'sender_type': 'user',
  'content': 'Read me',
};

void main() {
  late _RouteHost host;
  late ProviderContainer container;

  setUp(() async {
    host = _RouteHost();
    container = ProviderContainer(
      overrides: [
        rpcClientProvider.overrideWith((ref) => Stream.value(host.client)),
        activeWorkspaceIdProvider.overrideWith(
          (ref) => Stream.value(_workspace),
        ),
      ],
    );
    container.listen(rpcClientProvider, (_, _) {});
    container.listen(activeWorkspaceIdProvider, (_, _) {});
    await container.read(rpcClientProvider.future);
    await container.read(activeWorkspaceIdProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await host.close();
  });

  test('space URL encodes all three identities without losing any', () {
    const conversationId = 'thread/# 9?';
    const messageId = 'message?& #42';
    final location = remoteSpaceLocation(
      workspaceId: _workspace,
      spaceId: _space,
      conversationId: conversationId,
      messageId: messageId,
    );
    final uri = Uri.parse(location);
    expect(uri.pathSegments.last, _space);
    expect(uri.path, startsWith('/spaces/'));
    expect(uri.queryParameters, {
      'workspace_id': _workspace,
      'conversation_id': conversationId,
      'message_id': messageId,
    });
    expect(location, isNot(contains('#')));
    final switched = Uri.parse(
      remoteWorkspaceLocation(location, 'other workspace'),
    );
    expect(switched.queryParameters['workspace_id'], 'other workspace');
    expect(switched.queryParameters['conversation_id'], conversationId);
    expect(switched.queryParameters['message_id'], messageId);
  });

  test(
    'explicit conversation and linked message open exactly the matching pair',
    () async {
      host.conversations['thread-9'] = _conversation('thread-9');
      host.messages['msg-1'] = _message('msg-1');
      const route = (
        spaceId: _space,
        conversationId: 'thread-9',
        messageId: 'msg-1',
      );
      final found = await container.read(
        remoteConversationProvider(route).future,
      );
      expect(found?.id, 'thread-9');
      expect(found?.workspaceId, _workspace);
      expect(host.calls.map((call) => call.op), [
        'messaging.getMessageById',
        'conversation.getById',
      ]);
      for (final call in host.calls) {
        expect(call.args['workspace_id'], _workspace);
      }
      expect(host.calls.last.args['conversation_id'], 'thread-9');
    },
  );

  test(
    'message-only URL finds the owning conversation, not the standing one',
    () async {
      host.messages['msg-1'] = _message('msg-1');
      host.conversations['thread-9'] = _conversation('thread-9');
      final found = await container.read(
        remoteConversationProvider((
          spaceId: _space,
          conversationId: null,
          messageId: 'msg-1',
        )).future,
      );
      expect(found?.id, 'thread-9');
      expect(host.calls.map((call) => call.op), [
        'messaging.getMessageById',
        'conversation.getById',
      ]);
    },
  );

  test(
    'conflicting, missing or foreign message identities never fall back',
    () async {
      host.conversations['thread-9'] = _conversation('thread-9');
      host.messages['msg-1'] = _message('msg-1');
      host.messages['other-space'] = _message(
        'other-space',
        space: 'elsewhere',
      );
      host.messages['no-conversation'] = _message(
        'no-conversation',
        conversation: null,
      );
      final routes = [
        (spaceId: _space, conversationId: 'wrong-thread', messageId: 'msg-1'),
        (spaceId: _space, conversationId: 'thread-9', messageId: 'missing'),
        (spaceId: _space, conversationId: null, messageId: 'other-space'),
        (spaceId: _space, conversationId: null, messageId: 'no-conversation'),
      ];
      for (final route in routes) {
        await expectLater(
          container.read(remoteConversationProvider(route).future),
          throwsA(isA<StateError>()),
        );
      }
      expect(
        host.calls.where(
          (call) =>
              call.op == 'conversation.list' ||
              call.op == 'conversation.ensure',
        ),
        isEmpty,
      );
    },
  );

  test(
    'absent, wrong-space and wrong-workspace conversations are rejected',
    () async {
      host.conversations['wrong-space'] = _conversation(
        'wrong-space',
        space: 'elsewhere',
      );
      host.conversations['wrong-workspace'] = _conversation(
        'wrong-workspace',
        workspace: 'another',
      );
      for (final id in ['missing', 'wrong-space', 'wrong-workspace']) {
        await expectLater(
          container.read(
            remoteConversationProvider((
              spaceId: _space,
              conversationId: id,
              messageId: null,
            )).future,
          ),
          throwsA(isA<StateError>()),
        );
      }
      expect(
        host.calls.where(
          (call) =>
              call.op == 'conversation.list' ||
              call.op == 'conversation.ensure',
        ),
        isEmpty,
      );
    },
  );
}
