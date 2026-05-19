import 'dart:typed_data';

/// Client-side control channel for a host-run meeting recording.
///
/// A thin client (the web app) captures mic + system audio in the browser,
/// downsamples to 16 kHz mono PCM16, and drives the host's recording session
/// through these three calls — the host (a headless `cc_server` with an ASR
/// model installed) transcribes, dedups, and persists segments the client then
/// watches via `meeting.watchSegments`. The concrete implementation wraps the
/// RPC client and so lives in the data layer; the recorder controller depends
/// only on this abstraction.
///
/// The owning workspace is NOT a parameter: the host injects it authoritatively
/// from the session's binding (the RPC dispatcher overwrites `workspace_id`), so
/// a client physically cannot record into a workspace it is not bound to.
abstract interface class MeetingRecordingControlPort {
  /// Starts a recording on the host and returns the server-minted meeting id
  /// (used for [ingestAudio] / [stopRecording] and the `meeting.watchSegments`
  /// subscription). [mode] is a `MeetingMode` name (`remote` / `inPerson`).
  Future<String> startRecording({
    required String title,
    required String mode,
  });

  /// Streams one PCM16 (16 kHz mono) [pcm] frame on [channel] (`me` = mic,
  /// `them` = system/screenshare audio) into the host session for [meetingId].
  /// [seq] is the per-channel sequence number (gap diagnostics).
  Future<void> ingestAudio({
    required String meetingId,
    required String channel,
    required int seq,
    required Uint8List pcm,
  });

  /// Stops the recording: the host drains transcription and fires the summary
  /// pipeline. [summaryInstructions] optionally pins the meeting-note template.
  Future<void> stopRecording({
    required String meetingId,
    String? summaryInstructions,
  });
}
