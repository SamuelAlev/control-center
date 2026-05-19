import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MeetingRecordingControlPort] backed by the RPC client — the thin-client
/// recording path. Maps each call onto the host's `meeting.startRecording` /
/// `meeting.ingestAudio` / `meeting.stopRecording` ops.
///
/// PCM16 frames travel base64-encoded in the JSON-RPC envelope: the transport
/// has no raw-binary frame, so audio is carried the same way terminal PTY output
/// is. At 16 kHz mono PCM16 a ~256 ms frame is ~8 KB raw (~11 KB base64) — well
/// within the WebSocket's headroom.
class RpcMeetingRecordingControl implements MeetingRecordingControlPort {
  /// Creates an [RpcMeetingRecordingControl] over [client].
  RpcMeetingRecordingControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<String> startRecording({
    required String title,
    required String mode,
  }) async {
    final res = await _client.call('meeting.startRecording', {
      'title': title,
      'mode': mode,
    });
    return res['meeting_id'] as String;
  }

  @override
  Future<void> ingestAudio({
    required String meetingId,
    required String channel,
    required int seq,
    required Uint8List pcm,
  }) async {
    await _client.call('meeting.ingestAudio', {
      'meeting_id': meetingId,
      'channel': channel,
      'seq': seq,
      'pcm': base64Encode(pcm),
    });
  }

  @override
  Future<void> stopRecording({
    required String meetingId,
    String? summaryInstructions,
  }) async {
    await _client.call('meeting.stopRecording', {
      'meeting_id': meetingId,
      if (summaryInstructions != null && summaryInstructions.isNotEmpty)
        'summary_instructions': summaryInstructions,
    });
  }
}
