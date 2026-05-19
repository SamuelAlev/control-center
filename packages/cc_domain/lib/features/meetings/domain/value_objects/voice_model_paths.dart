/// The sherpa-onnx model family a voice model belongs to. It selects how the
/// recognizer is configured: a Whisper encoder/decoder pair vs. a transducer
/// encoder/decoder/joiner triple (NeMo Parakeet / Zipformer).
enum VoiceModelType {
  /// OpenAI Whisper (CoreML-free ONNX export). Encoder + decoder + tokens.
  whisper,

  /// Transducer (NeMo Parakeet TDT / Zipformer): encoder + decoder + joiner +
  /// tokens. Streaming-friendly and much faster to decode than Whisper.
  transducer,
}

/// Resolved on-disk model paths after a successful install.
///
/// Pure value object: the on-disk resolution / download lifecycle lives in the
/// app's `VoiceModelManager`; the on-device recognizer (in `cc_natives`) only
/// consumes these resolved paths. Kept in `cc_domain` so both the app
/// (resolution) and `cc_natives` (inference) can name the same type without
/// either depending on the other.
class VoiceModelPaths {
  /// Creates resolved paths to the model files.
  const VoiceModelPaths({
    required this.type,
    required this.encoder,
    required this.decoder,
    required this.tokens,
    this.joiner,
    this.language,
  });

  /// Model family — selects the recognizer config.
  final VoiceModelType type;

  /// Absolute path to the encoder ONNX file.
  final String encoder;

  /// Absolute path to the decoder ONNX file.
  final String decoder;

  /// Absolute path to the tokens text file.
  final String tokens;

  /// Absolute path to the joiner ONNX file (transducer models only).
  final String? joiner;

  /// Whisper decode language (`'en'`, or null for auto-detect / transducer).
  final String? language;
}
