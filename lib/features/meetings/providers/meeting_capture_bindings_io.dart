// Desktop-only meeting CAPTURE bindings (device I/O, not business logic).
//
// The meeting recorder is a native-capture thin client over RPC (see
// `meeting_recorder_controller_io.dart`): transcription, persistence and the
// summary pipeline all run on the connected `cc_server`. The only genuinely
// local work is microphone + system-audio capture and the signal-level echo
// canceller that cleans the mic feed before it is streamed to the host. This
// file holds exactly that — cc_infra/cc_natives only, never cc_server_core/
// cc_persistence/cc_host/cc_mcp — so it stays on the client side of the
// thin-client boundary.
library;

import 'package:cc_domain/core/domain/ports/system_audio_capture_port.dart';
import 'package:cc_domain/features/meetings/domain/services/mic_echo_canceller.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/features/meetings/data/adapters/plugin_system_audio_capture.dart';
import 'package:control_center/features/meetings/data/services/aec_mic_filter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Captures system (loopback) audio for the "them" channel during recording.
final systemAudioCapturePortProvider = Provider<SystemAudioCapturePort>((ref) {
  return PluginSystemAudioCapture();
});

/// Factory for a fresh native AEC processor. WebRTC AEC3's handle is stateful,
/// so one is created per recording and disposed at stop.
///
/// The native library is REQUIRED for remote-mode recording: [AecProcessor.create]
/// throws [AecUnavailable] (failing the recording start loudly, with the build
/// script named) instead of silently taping an echo-laden track.
final aecProcessorFactoryProvider = Provider<AecProcessor Function()>((ref) {
  return () => AecProcessor.create(explicitPaths: aecFfiDylibCandidatePaths());
});

/// Builds the meeting recorder's signal-level mic echo canceller, returning the
/// domain [MicEchoCanceller] port so the recorder controller never names the
/// data-layer implementation. A null [processor] means IN-PERSON mode (no
/// loopback, so no far-end reference — AEC is not applicable) and yields an
/// identity passthrough; the cross-platform text echo filter remains the
/// backstop for that mode.
MicEchoCanceller makeMicEchoCanceller({
  AecEngine? processor,
  int Function()? clockNow,
  void Function(String message)? log,
}) {
  return AecMicFilter(processor: processor, clockNow: clockNow, log: log);
}
