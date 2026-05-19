import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// The workspace that owns every channel these tests address. A workspace id
/// selects the database file server-side, so a channel-addressed op is only
/// resolvable when it names its workspace — the assertions pin that arg.
const _ws = 'ws-1';

/// Exercises the full [RemoteMessagingDispatch] and [RpcMessagingPort] surface
/// (channel lifecycle + agent dispatch + steering) over an in-process JSON-RPC
/// host. Each method is a thin `_client.call(...)` delegate; these tests pin
/// the op name, the args shape and (where the method decodes a reply) the
/// return-value mapping — so a renamed op or a dropped arg is caught.
///
/// The in-memory run controls (`pauseRun`/`resumeRun`/`steerRun`) act on a run
/// the server already holds registered and touch no stored state, so they carry
/// only the run id — the steering tests assert the absence of `workspace_id`.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RemoteMessagingDispatch channel lifecycle', () {
    test(
      'sendUserMessage sends dispatch.sendUserMessage with the payload',
      () async {
        final dispatch = RemoteMessagingDispatch(client);
        await dispatch.sendUserMessage(
          _ws,
          'c-1',
          'hello',
          conversationId: 'conv-1',
          metadata: {'k': 'v'},
        );
        final call = host.lastCall('dispatch.sendUserMessage')!;
        expect(call.args['workspace_id'], _ws);
        expect(call.args['channel_id'], 'c-1');
        expect(call.args['content'], 'hello');
        // `conversation_id` replaced the old `parent_message_id`: Slack-style
        // threading was removed outright and every message now belongs to a
        // conversation (see the channel_messages rebuild in app_database.dart).
        expect(call.args['conversation_id'], 'conv-1');
        expect(call.args['metadata'], {'k': 'v'});
      },
    );

    test('sendUserMessage omits null optional fields', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.sendUserMessage(_ws, 'c-1', 'hello');
      final call = host.lastCall('dispatch.sendUserMessage')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args.containsKey('conversation_id'), isFalse);
      expect(call.args.containsKey('metadata'), isFalse);
    });

    test('addAgentToChannel sends dispatch.addAgentToChannel', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.addAgentToChannel(_ws, 'c-1', 'a-1');
      final call = host.lastCall('dispatch.addAgentToChannel')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['channel_id'], 'c-1');
      expect(call.args['agent_id'], 'a-1');
      expect(call.args['rename_for_group'], true);
    });

    test('removeParticipant sends messaging.removeParticipant', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.removeParticipant(_ws, 'c-1', 'a-1');
      final call = host.lastCall('messaging.removeParticipant')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['channel_id'], 'c-1');
      expect(call.args['agent_id'], 'a-1');
    });

    test('deleteChannel sends messaging.deleteChannel', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.deleteChannel(_ws, 'c-1');
      final call = host.lastCall('messaging.deleteChannel')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['channel_id'], 'c-1');
    });

    test('clearChannelMessages sends messaging.clearChannelMessages', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.clearChannelMessages(_ws, 'c-1');
      final call = host.lastCall('messaging.clearChannelMessages')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['channel_id'], 'c-1');
    });

    test('createChannel decodes the returned ChannelDto', () async {
      host.callResults['messaging.createChannel'] = {
        'channel': {
          'id': 'c-9',
          'name': 'Team',
          'workspace_id': _ws,
          'mode': 'chat',
          'provisioning_status': 'ready',
          'origin': 'user',
        },
      };
      final dispatch = RemoteMessagingDispatch(client);
      final dto = await dispatch.createChannel(_ws, 'Team', ['a-1']);
      expect(dto.id, 'c-9');
      expect(dto.name, 'Team');
      expect(dto.workspaceId, _ws);
      expect(dto.mode, 'chat');
      expect(dto.provisioningStatus, 'ready');
      final call = host.lastCall('messaging.createChannel')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['name'], 'Team');
      expect(call.args['agent_ids'], ['a-1']);
      expect(call.args['mode'], 'chat');
      expect(call.args.containsKey('pipeline_run_id'), isFalse);
      // No repo selection means every workspace repo; the arg stays off the wire.
      expect(call.args.containsKey('repo_ids'), isFalse);
    });

    test('createChannel forwards the pipelineRunId when given', () async {
      host.callResults['messaging.createChannel'] = {
        'channel': {'id': 'c-9', 'name': 'P', 'workspace_id': ''},
      };
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.createChannel(
        _ws,
        'P',
        ['a-1'],
        mode: Mode.orchestrate,
        pipelineRunId: 'pr-1',
      );
      final call = host.lastCall('messaging.createChannel')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['mode'], 'orchestrate');
      expect(call.args['pipeline_run_id'], 'pr-1');
    });
  });

  group('RemoteMessagingDispatch agent dispatch', () {
    test('sendAndDispatch sends the mentions and entity refs', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.sendAndDispatch(
        _ws,
        'c-1',
        'do it',
        structuredMentions: [
          const StructuredMention(agentId: 'a-1', raw: '@architect'),
        ],
        entityRefs: [const EntityRef(type: EntityRefType.ticket, id: 't-1')],
        conversationId: 'conv-1',
      );
      final call = host.lastCall('dispatch.sendAndDispatch')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['channel_id'], 'c-1');
      expect(call.args['content'], 'do it');
      expect(call.args['conversation_id'], 'conv-1');
      final mentions = call.args['structured_mentions'] as List;
      final firstMention = (mentions.first as Map).cast<String, dynamic>();
      expect(firstMention['agent_id'], 'a-1');
      expect(firstMention['raw'], '@architect');
      final refs = call.args['entity_refs'] as List;
      expect((refs.first as Map)['id'], 't-1');
    });

    test('sendAndDispatch omits null optional fields', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.sendAndDispatch(_ws, 'c-1', 'plain');
      final call = host.lastCall('dispatch.sendAndDispatch')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args.containsKey('structured_mentions'), isFalse);
      expect(call.args.containsKey('entity_refs'), isFalse);
      expect(call.args.containsKey('conversation_id'), isFalse);
    });

    test(
      'dispatchAgent returns the run_id and sends the full arg set',
      () async {
        host.callResults['dispatch.dispatchAgent'] = {'run_id': 'run-9'};
        final dispatch = RemoteMessagingDispatch(client);
        final runId = await dispatch.dispatchAgent(
          workspaceId: _ws,
          channelId: 'c-1',
          agentId: 'a-1',
          prompt: 'do work',
          ticketId: 't-1',
          pipelineRunId: 'pr-1',
          pipelineStepId: 'ps-1',
          inReplyToAgentId: 'a-0',
          conversationId: 'conv-1',
          wakeContext: const WakeContext(
            runId: 'run-x',
            agentId: 'a-1',
            workspaceId: _ws,
            wakeReason: WakeReason.userMessage,
            ticketId: 't-1',
            channelId: 'c-1',
            messageId: 'm-1',
            pipelineRunId: 'pr-1',
          ),
          expectedOutputSchema: {'type': 'object'},
          outputContractMode: OutputContractMode.permissive,
        );
        expect(runId, 'run-9');
        final call = host.lastCall('dispatch.dispatchAgent')!;
        expect(call.args['workspace_id'], _ws);
        expect(call.args['channel_id'], 'c-1');
        expect(call.args['agent_id'], 'a-1');
        expect(call.args['prompt'], 'do work');
        expect(call.args['ticket_id'], 't-1');
        expect(call.args['pipeline_run_id'], 'pr-1');
        expect(call.args['pipeline_step_id'], 'ps-1');
        expect(call.args['in_reply_to_agent_id'], 'a-0');
        expect(call.args['conversation_id'], 'conv-1');
        expect(call.args['expected_output_schema'], {'type': 'object'});
        expect(call.args['output_contract_mode'], 'permissive');
        // requestedByUserId is deliberately NOT sent over the wire.
        expect(call.args.containsKey('requested_by_user_id'), isFalse);
        // The wake context is mapped to its wire shape.
        final wake = call.args['wake_context'] as Map<String, dynamic>;
        expect(wake['run_id'], 'run-x');
        expect(wake['agent_id'], 'a-1');
        expect(wake['workspace_id'], _ws);
        expect(wake['wake_reason'], 'userMessage');
        expect(wake['ticket_id'], 't-1');
        expect(wake['channel_id'], 'c-1');
        expect(wake['message_id'], 'm-1');
        expect(wake['pipeline_run_id'], 'pr-1');
      },
    );

    test('dispatchAgent omits a null wake context', () async {
      host.callResults['dispatch.dispatchAgent'] = const {};
      final dispatch = RemoteMessagingDispatch(client);
      final runId = await dispatch.dispatchAgent(
        workspaceId: _ws,
        channelId: 'c-1',
        agentId: 'a-1',
        prompt: 'p',
      );
      expect(runId, isNull);
      final call = host.lastCall('dispatch.dispatchAgent')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args.containsKey('wake_context'), isFalse);
    });

    test('refinePlan sends dispatch.refinePlan', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.refinePlan(
        workspaceId: _ws,
        channelId: 'c-1',
        feedback: 'tighter',
      );
      final call = host.lastCall('dispatch.refinePlan')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['channel_id'], 'c-1');
      expect(call.args['feedback'], 'tighter');
    });

    test('retryAgentTurn sends dispatch.retryAgentTurn', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.retryAgentTurn(
        workspaceId: _ws,
        channelId: 'c-1',
        failedMessageId: 'm-1',
      );
      final call = host.lastCall('dispatch.retryAgentTurn')!;
      expect(call.args['workspace_id'], _ws);
      expect(call.args['channel_id'], 'c-1');
      expect(call.args['failed_message_id'], 'm-1');
    });

    test('stopRun sends dispatch.stopRun', () async {
      final dispatch = RemoteMessagingDispatch(client);
      await dispatch.stopRun(_ws, 'run-1');
      final call = host.lastCall('dispatch.stopRun')!;
      // stopRun finalizes a persisted run log, so it names its workspace.
      expect(call.args['workspace_id'], _ws);
      expect(call.args['run_id'], 'run-1');
    });

    test('steerRun returns true when delivered=true', () async {
      host.callResults['dispatch.steer'] = {'delivered': true};
      final dispatch = RemoteMessagingDispatch(client);
      expect(await dispatch.steerRun('run-1', 'nudge'), isTrue);
      final call = host.lastCall('dispatch.steer')!;
      expect(call.args['run_id'], 'run-1');
      expect(call.args['message'], 'nudge');
      expect(call.args['follow_up'], false);
      // A live in-process run needs no workspace: nothing stored is addressed.
      expect(call.args.containsKey('workspace_id'), isFalse);
    });

    test(
      'steerRun forwards followUp and returns false when not delivered',
      () async {
        host.callResults['dispatch.steer'] = {'delivered': false};
        final dispatch = RemoteMessagingDispatch(client);
        expect(
          await dispatch.steerRun('run-1', 'later', followUp: true),
          isFalse,
        );
        expect(host.lastCall('dispatch.steer')!.args['follow_up'], true);
      },
    );

    test(
      'compactConversation sends dispatch.compact and decodes the outcome',
      () async {
        host.callResults['dispatch.compact'] = {
          'status': 'compacted',
          'compacted_count': 12,
        };
        final dispatch = RemoteMessagingDispatch(client);
        final result = await dispatch.compactConversation(
          workspaceId: _ws,
          channelId: 'c-1',
          conversationId: 'thread-1',
        );
        final call = host.lastCall('dispatch.compact')!;
        expect(call.args['workspace_id'], _ws);
        expect(call.args['channel_id'], 'c-1');
        expect(call.args['conversation_id'], 'thread-1');
        expect(result.status, ConversationCompactionStatus.compacted);
        expect(result.compactedMessageCount, 12);
      },
    );

    test(
      'compactConversation omits a null conversation and maps busy',
      () async {
        host.callResults['dispatch.compact'] = {
          'status': 'agentBusy',
          'compacted_count': 0,
        };
        final dispatch = RemoteMessagingDispatch(client);
        final result = await dispatch.compactConversation(
          workspaceId: _ws,
          channelId: 'c-1',
        );
        final call = host.lastCall('dispatch.compact')!;
        expect(call.args['workspace_id'], _ws);
        expect(call.args.containsKey('conversation_id'), isFalse);
        expect(result.status, ConversationCompactionStatus.agentBusy);
        expect(result.compactedMessageCount, 0);
      },
    );
  });

  group('RpcMessagingPort full delegation', () {
    test('createChannel returns a Channel decoded from the dto', () async {
      host.callResults['messaging.createChannel'] = {
        'channel': {
          'id': 'c-9',
          'name': 'Team',
          'workspace_id': _ws,
          'mode': 'chat',
          'origin': 'user',
        },
      };
      final port = RpcMessagingPort(client);
      final channel = await port.createChannel(_ws, 'Team', ['a-1']);
      expect(channel.id, 'c-9');
      expect(channel.name, 'Team');
      expect(channel.workspaceId, _ws);
      expect(channel.mode, Mode.chat);
      expect(
        host.lastCall('messaging.createChannel')!.args['workspace_id'],
        _ws,
      );
    });

    test(
      'sendUserMessage / addAgent / remove / delete / clear all delegate',
      () async {
        final port = RpcMessagingPort(client);
        await port.sendUserMessage(_ws, 'c-1', 'hi');
        await port.addAgentToChannel(_ws, 'c-1', 'a-1');
        await port.removeParticipant(_ws, 'c-1', 'a-1');
        await port.deleteChannel(_ws, 'c-1');
        await port.clearChannelMessages(_ws, 'c-1');
        final send = host.lastCall('dispatch.sendUserMessage')!;
        expect(send.args['content'], 'hi');
        expect(send.args['workspace_id'], _ws);
        expect(
          host.lastCall('dispatch.addAgentToChannel')!.args['agent_id'],
          'a-1',
        );
        expect(
          host.lastCall('messaging.removeParticipant')!.args['agent_id'],
          'a-1',
        );
        expect(
          host.lastCall('messaging.deleteChannel')!.args['channel_id'],
          'c-1',
        );
        final clear = host.lastCall('messaging.clearChannelMessages')!;
        expect(clear.args['channel_id'], 'c-1');
        expect(clear.args['workspace_id'], _ws);
      },
    );

    test(
      'sendAndDispatch / dispatchAgent / refine / retry / stop delegate',
      () async {
        host.callResults['dispatch.dispatchAgent'] = {'run_id': 'run-9'};
        final port = RpcMessagingPort(client);
        await port.sendAndDispatch(_ws, 'c-1', 'go');
        expect(
          host.lastCall('dispatch.sendAndDispatch')!.args['content'],
          'go',
        );

        final runId = await port.dispatchAgent(
          workspaceId: _ws,
          channelId: 'c-1',
          agentId: 'a-1',
          prompt: 'p',
        );
        expect(runId, 'run-9');
        expect(
          host.lastCall('dispatch.dispatchAgent')!.args['agent_id'],
          'a-1',
        );

        await port.refinePlan(
          workspaceId: _ws,
          channelId: 'c-1',
          feedback: 'f',
        );
        expect(host.lastCall('dispatch.refinePlan')!.args['feedback'], 'f');

        await port.retryAgentTurn(
          workspaceId: _ws,
          channelId: 'c-1',
          failedMessageId: 'm-1',
        );
        expect(
          host.lastCall('dispatch.retryAgentTurn')!.args['failed_message_id'],
          'm-1',
        );

        await port.stopRun(_ws, 'run-1');
        final stop = host.lastCall('dispatch.stopRun')!;
        expect(stop.args['run_id'], 'run-1');
        expect(stop.args['workspace_id'], _ws);
      },
    );

    test('steerRun delegates with followUp', () async {
      host.callResults['dispatch.steer'] = {'delivered': true};
      final port = RpcMessagingPort(client);
      expect(await port.steerRun('run-1', 'nudge', followUp: true), isTrue);
      expect(host.lastCall('dispatch.steer')!.args['follow_up'], true);
    });

    test('compactConversation delegates', () async {
      host.callResults['dispatch.compact'] = {
        'status': 'nothingToCompact',
        'compacted_count': 0,
      };
      final port = RpcMessagingPort(client);
      final result = await port.compactConversation(
        workspaceId: _ws,
        channelId: 'c-1',
      );
      expect(result.status, ConversationCompactionStatus.nothingToCompact);
      final call = host.lastCall('dispatch.compact')!;
      expect(call.args['channel_id'], 'c-1');
      expect(call.args['workspace_id'], _ws);
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

/// In-process host that scripts `repo/call` results. Every op replies with its
/// scripted `data` (or `{}`), so the delegation + arg shape is testable without
/// a real server.
class _Host {
  _Host(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<_Call> calls = [];
  final Map<String, Map<String, dynamic>> callResults = {};

  _Call? lastCall(String op) => calls.lastWhere(
    (c) => c.op == op,
    orElse: () => const _Call(op: '', args: {}),
  );

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.subscribe:
        _reply(id, {'subscriptionId': 's1', 'rev': 0});
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      case RpcMethods.repoCall:
        final op = params['op'] as String;
        final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
        calls.add(_Call(op: op, args: args));
        _reply(id, {
          'op': op,
          'data': callResults[op] ?? const <String, dynamic>{},
        });
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
