import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/features/dictation/domain/dictation_control_port.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/meetings/meeting_transcription_service.dart';

/// Server-side dictation transcription (PRD 25 §2). Reuses the meeting
/// recorder's rolling-window transcriber VERBATIM (min 1500 / max 5000 /
/// silenceFlush 650 ms — no new tuning surface) so a long dictation never hits
/// the 30-second single-decode cliff and pushes each finalized window back to
/// the client as a [DictationPartial].
///
/// One PCM16 (16 kHz mono) space per session, keyed by a server-minted id. The
/// heavy decode already runs on the transcriber's worker isolate, off the
/// server's main loop.
class DictationService {
  /// Creates a [DictationService] over [transcriber] (the installed ASR model).
  DictationService({
    required SpeechTranscriber transcriber,
    MeetingTranscriptionService? transcription,
  }) : _transcription =
           transcription ?? MeetingTranscriptionService(transcriber);

  final MeetingTranscriptionService _transcription;

  final Map<String, _DictationSession> _sessions = {};
  int _counter = 0;

  /// Starts a session for [workspaceId] and returns its id. The workspace is
  /// carried for isolation/audit even though a single dictation writes nothing
  /// to the DB — it exists only in memory until the client inserts the text.
  String start(String workspaceId) {
    final id = 'dictation-$workspaceId-${_counter++}';
    final session = _DictationSession();
    _sessions[id] = session;

    session.sub = _transcription
        .transcribe(session.input.stream)
        .listen(
          (window) {
            final text = window.text.trim();
            if (text.isNotEmpty && !session.output.isClosed) {
              session.output.add(DictationPartial(text: text));
            }
          },
          onError: (Object e) =>
              CcInfraLog.warning('dictation $id transcription error: $e'),
          onDone: () {
            if (!session.output.isClosed) {
              session.output
                ..add(const DictationPartial(text: '', isFinal: true))
                ..close();
            }
            if (!session._drained.isCompleted) {
              session._drained.complete();
            }
          },
        );
    return id;
  }

  /// Feeds one PCM16 frame into session [dictationId] (no-op if unknown/closed).
  void ingest(String dictationId, Uint8List pcm) {
    final session = _sessions[dictationId];
    if (session != null && !session.input.isClosed) {
      session.input.add(pcm);
    }
  }

  /// Stops session [dictationId]: closes the input so the transcriber drains
  /// its final window, then cancels the subscription and closes the output
  /// (which emits the terminal partial).
  Future<void> stop(String dictationId) async {
    final session = _sessions.remove(dictationId);
    if (session == null) {
      return;
    }
    await session.dispose();
  }

  /// The finalized-window stream for [dictationId] (empty when unknown).
  Stream<DictationPartial> watch(String dictationId) =>
      _sessions[dictationId]?.output.stream ??
      const Stream<DictationPartial>.empty();

  /// Tears down every live session (server shutdown).
  Future<void> dispose() async {
    final ids = _sessions.keys.toList();
    for (final id in ids) {
      await stop(id);
    }
  }
}

class _DictationSession {
  final StreamController<Uint8List> input = StreamController<Uint8List>();
  final StreamController<DictationPartial> output =
      StreamController<DictationPartial>.broadcast();
  StreamSubscription<Object?>? sub;

  /// Completes when the transcription subscription has finished (its done event
  /// has fired), so [dispose] can close the input and AWAIT the final window's
  /// decode before tearing down — cancelling the subscription outright would
  /// race the flush and drop the last partial.
  final Completer<void> _drained = Completer<void>();

  /// Closes the input so the transcriber drains its final window (the input's
  /// done event runs the last flush while the stream is still live), awaits
  /// that flush, then cancels the (now-done) subscription and closes the
  /// output.
  Future<void> dispose() async {
    await input.close();
    await _drained.future;
    await sub?.cancel();
    await output.close();
  }
}
