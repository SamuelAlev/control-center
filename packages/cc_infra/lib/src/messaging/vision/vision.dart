/// Barrel export for the pure-Dart vision compaction core.
///
/// Serializes discarded conversation history into deterministic monochrome PNG
/// "bitmap frames" that vision models read back directly — fully local, no LLM
/// call. A Dart port of oh-my-pi's `snapcompact`. Start at `VisionCompactor`.
library;

export 'bitmap_font.dart';
export 'png_encoder.dart';
export 'vision_compactor.dart';
export 'vision_normalize.dart';
export 'vision_plan.dart';
export 'vision_serialize.dart';
export 'vision_shapes.dart';
