import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// Mic toggle.
///
/// Tap once to start dictation; tap again to stop. While recording we stream
/// 16 kHz mono PCM16 frames from [AudioRecorder.startStream] straight into
/// the transcriber. On stop, the transcriber finalizes the buffered audio
/// and emits the final transcript via [onTranscript].
///
/// If [transcriber] is null (model not installed) the button is disabled
/// with an explanatory tooltip.
class VoiceButton extends ConsumerStatefulWidget {
  /// Creates a new [VoiceButton].
  const VoiceButton({
    super.key,
    required this.transcriber,
    required this.onTranscript,
  });

  /// Optional speech transcriber. When null the button is disabled.
  final SpeechTranscriber? transcriber;

  /// Called when a transcription result is ready.
  final void Function(TranscriptionResult) onTranscript;

  @override
  ConsumerState<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends ConsumerState<VoiceButton>
    with SingleTickerProviderStateMixin {
  // NOTE: keep echoCancel/noiseSuppress disabled. On macOS, `record_macos`
  // wires those to AVAudioEngine.setVoiceProcessingEnabled(true), which often
  // produces near-silent / heavily processed audio that Whisper transcribes
  // as "(buzzing)". Whisper handles noise well on raw mic input.
  static const _baseConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
  );

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSub;
  StreamSubscription<TranscriptionResult>? _transcriptSub;
  StreamController<List<int>>? _audioToTranscriber;
  bool _recording = false;
  String? _statusMessage;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _teardown();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_recording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    final t = widget.transcriber;
    if (t == null) {
      return;
    }
    try {
      _recorder = AudioRecorder();
      if (!await _recorder!.hasPermission()) {
        setState(() => _statusMessage = 'Mic permission denied');
        await _teardown();
        return;
      }
      if (!t.isReady) {
        await t.initialize();
      }
      _audioToTranscriber = StreamController<List<int>>();
      _transcriptSub =
          t.transcribe(_audioToTranscriber!.stream).listen(widget.onTranscript);

      final config = await _resolveConfig();
      final audioStream = await _recorder!.startStream(config);
      _audioSub = audioStream.listen(
        (chunk) => _audioToTranscriber?.add(chunk),
        onError: (e) {
          _statusMessage = 'Recording error';
        },
      );
      setState(() => _recording = true);
    } catch (e) {
      setState(() => _statusMessage = 'Failed to start mic');
      await _teardown();
    }
  }

  Future<void> _stop() async {
    try {
      await _recorder?.stop();
    } catch (_) {
      // Best-effort; we still need to close downstream streams.
    }
    await _audioSub?.cancel();
    _audioSub = null;
    await _audioToTranscriber?.close();
    _audioToTranscriber = null;
    // Don't cancel _transcriptSub yet — the transcriber emits its final
    // result asynchronously after the audio stream closes.
    if (mounted) {
      setState(() => _recording = false);
    }
  }

  Future<RecordConfig> _resolveConfig() async {
    final wantedId = ref.read(audioInputDeviceProvider);
    if (wantedId == null || _recorder == null) {
      return _baseConfig;
    }
    // Verify the saved device is still attached; otherwise fall back to
    // the system default rather than failing the recording start.
    try {
      final devices = await _recorder!.listInputDevices();
      final match = devices.firstWhere(
        (d) => d.id == wantedId,
        orElse: () => const InputDevice(id: '', label: ''),
      );
      if (match.id.isEmpty) {
        return _baseConfig;
      }
      return RecordConfig(
        encoder: _baseConfig.encoder,
        sampleRate: _baseConfig.sampleRate,
        numChannels: _baseConfig.numChannels,
        autoGain: _baseConfig.autoGain,
        echoCancel: _baseConfig.echoCancel,
        noiseSuppress: _baseConfig.noiseSuppress,
        device: match,
      );
    } catch (_) {
      return _baseConfig;
    }
  }

  Future<void> _teardown() async {
    try {
      await _recorder?.stop();
    } catch (_) {}
    await _audioSub?.cancel();
    _audioSub = null;
    await _audioToTranscriber?.close();
    _audioToTranscriber = null;
    await _transcriptSub?.cancel();
    _transcriptSub = null;
    _recorder = null;
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final disabled = widget.transcriber == null;
    final color = disabled
        ? ds.textTertiary
        : (_recording ? ds.textErrorPrimary : ds.textTertiary);
    final tooltipMessage = disabled
        ? 'Voice unavailable — install the model from Settings'
        : (_statusMessage ??
            (_recording ? 'Stop dictation' : 'Start dictation'));
    return CcTooltip(
      message: tooltipMessage,
      child: CcTappable(
        onPressed: disabled ? null : _toggle,
        mouseCursor: disabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        builder: (context, states) => SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(AppIcons.mic, size: 16, color: color),
              if (_recording)
                Positioned(
                  top: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _pulse,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: ds.textErrorPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

