import 'dart:typed_data';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// Exercises [RpcMeetingRecordingControl] — the thin-client recording adapter
/// that maps each port call onto the host's `meeting.*` ops with PCM16 audio
/// carried base64-encoded in the JSON-RPC envelope.
void main() {
  late _Host host;
  late RemoteRpcClient client;

  setUp(() {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _Host(server);
    client = RemoteRpcClient(clientChannel)..start();
  });

  tearDown(() async => client.close());

  group('RpcMeetingRecordingControl', () {
    test(
      'startRecording forwards title + mode and returns the meeting id',
      () async {
        final port = RpcMeetingRecordingControl(client);
        expect(
          await port.startRecording(title: 'Standup', mode: 'transcribe'),
          'm-1',
        );
        final call = host.lastCall('meeting.startRecording')!;
        expect(call.args['title'], 'Standup');
        expect(call.args['mode'], 'transcribe');
      },
    );

    test(
      'ingestAudio base64-encodes the PCM frame and forwards the seq',
      () async {
        final port = RpcMeetingRecordingControl(client);
        final pcm = Uint8List.fromList([0, 1, 2, 3]);
        await port.ingestAudio(
          meetingId: 'm-1',
          channel: 'speaker-0',
          seq: 7,
          pcm: pcm,
        );
        final call = host.lastCall('meeting.ingestAudio')!;
        expect(call.args['meeting_id'], 'm-1');
        expect(call.args['channel'], 'speaker-0');
        expect(call.args['seq'], 7);
        // base64Encode([0,1,2,3]) == 'AAECAw=='
        expect(call.args['pcm'], 'AAECAw==');
      },
    );

    test(
      'stopRecording forwards the meeting_id only when no instructions',
      () async {
        final port = RpcMeetingRecordingControl(client);
        await port.stopRecording(meetingId: 'm-1');
        final args = host.lastCall('meeting.stopRecording')!.args;
        expect(args['meeting_id'], 'm-1');
        expect(args.containsKey('summary_instructions'), isFalse);
      },
    );

    test(
      'stopRecording forwards summary_instructions when non-empty',
      () async {
        final port = RpcMeetingRecordingControl(client);
        await port.stopRecording(
          meetingId: 'm-1',
          summaryInstructions: 'Focus on action items',
        );
        expect(
          host.lastCall('meeting.stopRecording')!.args['summary_instructions'],
          'Focus on action items',
        );
      },
    );

    test('stopRecording drops an empty summary_instructions', () async {
      final port = RpcMeetingRecordingControl(client);
      await port.stopRecording(meetingId: 'm-1', summaryInstructions: '');
      expect(
        host
            .lastCall('meeting.stopRecording')!
            .args
            .containsKey('summary_instructions'),
        isFalse,
      );
    });
  });
}

/// Records a `repo/call` invocation.
class _Call {
  const _Call({required this.op, required this.args});
  final String op;
  final Map<String, dynamic> args;
}

class _Host {
  _Host(this.space) {
    space.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort space;
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
        final result =
            callResults[op] ??
            (op == 'meeting.startRecording'
                ? {'meeting_id': 'm-1'}
                : const <String, dynamic>{});
        _reply(id, {'op': op, 'data': result});
      default:
        _reply(id, const <String, dynamic>{});
    }
  }

  void _reply(dynamic id, Map<String, dynamic> result) =>
      space.send({'jsonrpc': '2.0', 'id': id, 'result': result});
}
