import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Always `null`: ad-hoc composer voice dictation has no on-device model to
/// fall back to (the client is a thin client — it owns no ASR model) and
/// `cc_server` exposes no RPC op for transcribing a short, one-off utterance
/// (only the meeting-recording stream: `meeting.startRecording`/
/// `ingestAudio`). Composer consumers disable the mic button when this is
/// null, identical to the web client.
final speechTranscriberProvider = Provider<SpeechTranscriber?>((ref) => null);
