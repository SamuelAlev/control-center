import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/system_audio_capture_port.dart';
import 'package:system_audio_capture/system_audio_capture.dart' as plugin;

/// [SystemAudioCapturePort] backed by the `system_audio_capture` plugin
/// (Core Audio taps on macOS, WASAPI loopback on Windows, a PipeWire/PulseAudio
/// monitor on Linux).
class PluginSystemAudioCapture implements SystemAudioCapturePort {
  /// Creates a [PluginSystemAudioCapture].
  PluginSystemAudioCapture([plugin.SystemAudioCapture? capture])
      : _capture = capture ?? plugin.SystemAudioCapture();

  final plugin.SystemAudioCapture _capture;

  @override
  Future<bool> isSupported() => _capture.isSupported();

  @override
  Future<bool> requestPermission() => _capture.requestPermission();

  @override
  Future<List<SystemAudioSource>> listSources() async {
    final sources = await _capture.listSources();
    return sources
        .map(
          (s) => SystemAudioSource(
            id: s.id,
            name: s.name,
            kind: _mapKind(s.kind),
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<Uint8List> capture({String? sourceId}) =>
      _capture.capture(sourceId: sourceId);

  @override
  Future<void> stop() => _capture.stop();

  SystemAudioSourceKind _mapKind(plugin.AudioCaptureSourceKind kind) {
    return switch (kind) {
      plugin.AudioCaptureSourceKind.system => SystemAudioSourceKind.system,
      plugin.AudioCaptureSourceKind.process => SystemAudioSourceKind.process,
      plugin.AudioCaptureSourceKind.monitor => SystemAudioSourceKind.monitor,
      plugin.AudioCaptureSourceKind.unknown => SystemAudioSourceKind.unknown,
    };
  }
}
