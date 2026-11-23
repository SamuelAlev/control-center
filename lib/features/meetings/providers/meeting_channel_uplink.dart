import 'package:cc_domain/features/meetings/domain/services/meeting_recording_control_port.dart';
import 'package:control_center/core/infrastructure/audio/pcm_uplink.dart';
import 'package:control_center/core/server/transient_rpc_failure.dart';
import 'package:control_center/core/utils/app_log.dart';

/// How long stopping a recording keeps retrying audio the host has not
/// acknowledged before finalizing without it. Long enough to ride out a
/// reconnect, short enough that a dead host does not leave the recorder stuck
/// in "stopping".
const Duration meetingStopFlushTimeout = Duration(minutes: 2);

/// The uplink that streams one recording [channel] (`me` = mic, `them` =
/// system audio) to the host session for [meetingId].
///
/// Capture chunks are coalesced into ~250 ms batches sent one at a time in
/// capture order, and a batch that fails in transit is resent under the same
/// seq (the host ignores a copy it already has) until it lands. One RPC per
/// chunk overran the session's request budget, so the "them" channel fell
/// minutes behind and audio was lost once the RPC client's own retries ran out.
/// Shared by the desktop and web recorders.
PcmUplink meetingChannelUplink(
  MeetingRecordingControlPort control,
  String meetingId, {
  required String channel,
}) {
  return PcmUplink(
    send: (seq, pcm) => control.ingestAudio(
      meetingId: meetingId,
      channel: channel,
      seq: seq,
      pcm: pcm,
    ),
    isRetryable: isTransientRpcFailure,
    onError: (e, {required willRetry}) => AppLog.w(
      'MeetingRecorder',
      '$channel ingest failed${willRetry ? ', retrying' : ''}: $e',
    ),
    onBacklog: (bytes) => AppLog.w(
      'MeetingRecorder',
      '$channel uplink is ${bytes ~/ 32000} s behind the host',
    ),
    onDrop: (bytes) => AppLog.e(
      'MeetingRecorder',
      '$channel: ${bytes ~/ 32} ms of audio never reached the host',
    ),
  );
}
