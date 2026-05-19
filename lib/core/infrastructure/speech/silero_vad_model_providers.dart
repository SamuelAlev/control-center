import 'package:control_center/core/infrastructure/speech/silero_vad_model_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing the [SileroVadModelManager]. The Silero VAD model ships as
/// a bundled app asset and is materialized to disk on first use, so it is always
/// available — there is no download lifecycle to track.
final sileroVadModelManagerProvider =
    Provider<SileroVadModelManager>((ref) => SileroVadModelManager());
