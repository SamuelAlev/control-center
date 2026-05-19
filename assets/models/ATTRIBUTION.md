# Bundled model attribution

These ONNX model weights ship inside the Control Center app bundle and are
materialized to the app-support models directory on first use. Both are
redistributed here under permissive (MIT) licenses; this notice preserves the
required attribution.

## silero-vad/silero_vad.onnx

- **Model:** Silero VAD (voice-activity detection).
- **Upstream:** https://github.com/snakers4/silero-vad (MIT License).
- **Distributed via:** k2-fsa/sherpa-onnx release asset
  `https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx`.
- **Use:** gates meeting transcription on detected speech.
