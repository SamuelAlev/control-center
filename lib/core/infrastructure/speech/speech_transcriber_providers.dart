import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Returns a ready-to-use [SpeechTranscriber] when the model is installed,
/// or null otherwise. Composer consumers should disable the mic button when
/// this is null.
///
/// The transcriber is kept alive across rebuilds via Riverpod (its native
/// recognizer holds onto loaded ONNX graphs — re-creating them per click
/// would re-decode the model on every utterance).
final speechTranscriberProvider = Provider<SpeechTranscriber?>((ref) {
  final modelState = ref.watch(voiceModelStateProvider);
  final paths = modelState.paths;
  if (paths == null) {
    return null;
  }
  final transcriber = SherpaOnnxTranscriber(paths: paths);
  ref.onDispose(transcriber.dispose);
  return transcriber;
});
