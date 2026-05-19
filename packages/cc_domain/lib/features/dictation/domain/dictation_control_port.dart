import 'dart:typed_data';

/// One transcription update for an in-progress dictation (PRD 25 §2). The host
/// runs a rolling-window transcriber and pushes a window's text as it finalizes;
/// [isFinal] marks the last update after the session stops.
class DictationPartial {
  /// Creates a [DictationPartial].
  const DictationPartial({required this.text, this.isFinal = false});

  /// The transcribed text of this window (already trimmed/de-hallucinated).
  final String text;

  /// Whether this is the terminal update (the session stopped and drained).
  final bool isFinal;
}

/// Client-side control channel for a host-run dictation session (PRD 25 §2).
///
/// The client captures the mic (16 kHz mono PCM16) and streams frames to the
/// host, which runs the SAME windowed transcriber the meeting recorder uses and
/// pushes back finalized windows via [watchPartials]. The thin client owns no
/// ASR model — dictation runs over RPC exactly like meeting recording. The
/// owning workspace is injected by the host from the session binding, never a
/// parameter.
abstract interface class DictationControlPort {
  /// Starts a dictation session on the host; returns the server-minted id used
  /// for [ingestAudio] / [stop] / [watchPartials].
  Future<String> start();

  /// Streams one PCM16 (16 kHz mono) [pcm] frame into session [dictationId].
  /// [seq] is the per-session sequence number (gap diagnostics).
  Future<void> ingestAudio({
    required String dictationId,
    required int seq,
    required Uint8List pcm,
  });

  /// Stops the session, forcing a final flush of the trailing window.
  Future<void> stop({required String dictationId});

  /// The stream of transcription updates for [dictationId].
  Stream<DictationPartial> watchPartials(String dictationId);
}
