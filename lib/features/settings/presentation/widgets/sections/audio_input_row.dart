// Audio-input device picker + mic test, shared by the voice section on every
// platform.
//
// `package:record` is cross-platform (it ships `record_web`), so this row works
// in the browser too: it enumerates input devices, persists the chosen one, and
// runs a live mic test. The level meter is derived from the PCM stream itself
// (RMS per frame) rather than `onAmplitudeChanged`, which `record_web` does not
// implement — so the meter animates identically on desktop and web.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

/// Row for configuring and testing audio input devices.
class AudioInputRow extends ConsumerStatefulWidget {
  /// Creates an [AudioInputRow].
  const AudioInputRow({super.key});

  @override
  ConsumerState<AudioInputRow> createState() => _AudioInputRowState();
}

class _AudioInputRowState extends ConsumerState<AudioInputRow> {
  static const _testCeiling = Duration(seconds: 30);
  static const _levelPushIntervalMs = 80;
  static const _testConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
  );

  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSub;
  Timer? _autoStop;
  final Stopwatch _levelClock = Stopwatch();
  int _lastLevelPushMs = 0;
  bool _testing = false;
  double _level = 0;
  String? _testError;

  @override
  void dispose() {
    unawaited(_stopTest());
    super.dispose();
  }

  Future<void> _toggleTest() async {
    if (_testing) {
      await _stopTest();
    } else {
      await _startTest();
    }
  }

  Future<void> _startTest() async {
    setState(() {
      _testError = null;
      _level = 0;
    });
    try {
      final recorder = AudioRecorder();
      _recorder = recorder;
      if (!await recorder.hasPermission()) {
        setState(
          () => _testError = AppLocalizations.of(context).microphonePermissionDenied,
        );
        await _stopTest();
        return;
      }

      final selectedId = ref.read(audioInputDeviceProvider);
      InputDevice? device;
      if (selectedId != null) {
        final devices = await recorder.listInputDevices();
        for (final d in devices) {
          if (d.id == selectedId) {
            device = d;
            break;
          }
        }
      }
      final config = device == null
          ? _testConfig
          : RecordConfig(
              encoder: _testConfig.encoder,
              sampleRate: _testConfig.sampleRate,
              numChannels: _testConfig.numChannels,
              autoGain: _testConfig.autoGain,
              echoCancel: _testConfig.echoCancel,
              noiseSuppress: _testConfig.noiseSuppress,
              device: device,
            );

      // Derive the level meter from the PCM stream (RMS per frame) instead of
      // `onAmplitudeChanged` — the latter is unimplemented on web, so this keeps
      // the meter working identically across platforms.
      _levelClock
        ..reset()
        ..start();
      _lastLevelPushMs = 0;
      final audioStream = await recorder.startStream(config);
      _audioSub = audioStream.listen(_onPcm, onError: (_) {});

      _autoStop = Timer(_testCeiling, _stopTest);
      setState(() => _testing = true);
    } catch (e) {
      setState(
        () => _testError = AppLocalizations.of(context).failedToStartMicTest,
      );
      await _stopTest();
    }
  }

  /// Computes a normalized [0,1] level from a PCM16 mono frame and pushes it to
  /// the meter at most every [_levelPushIntervalMs] so the UI stays smooth.
  void _onPcm(Uint8List bytes) {
    final elapsed = _levelClock.elapsedMilliseconds;
    if (elapsed - _lastLevelPushMs < _levelPushIntervalMs) {
      return;
    }
    _lastLevelPushMs = elapsed;
    final level = _rms(bytes);
    if (mounted) {
      setState(() => _level = level);
    }
  }

  static double _rms(Uint8List bytes) {
    final sampleCount = bytes.lengthInBytes ~/ 2;
    if (sampleCount == 0) {
      return 0;
    }
    final view = ByteData.sublistView(bytes);
    var sumSq = 0.0;
    for (var i = 0; i < sampleCount; i++) {
      final sample = view.getInt16(i * 2, Endian.little) / 32768.0;
      sumSq += sample * sample;
    }
    final rms = math.sqrt(sumSq / sampleCount);
    // Speech RMS sits around 0.05–0.25; a ×3.5 gain fills the meter without
    // pinning it, then clamp.
    return (rms * 3.5).clamp(0.0, 1.0);
  }

  Future<void> _stopTest() async {
    _autoStop?.cancel();
    _autoStop = null;
    _levelClock.stop();
    await _audioSub?.cancel();
    _audioSub = null;
    try {
      await _recorder?.stop();
    } catch (_) {}
    try {
      await _recorder?.dispose();
    } catch (_) {}
    _recorder = null;
    if (mounted) {
      setState(() {
        _testing = false;
        _level = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final devicesAsync = ref.watch(audioInputDevicesProvider);
    final selectedId = ref.watch(audioInputDeviceProvider);
    final notifier = ref.read(audioInputDeviceProvider.notifier);

    final subtitle = _testError != null
        ? _testError!
        : devicesAsync.when(
            data: (devices) {
              if (devices.isEmpty) {
                return l10n.noInputDevicesDetected;
              }
              final match = devices
                  .where((d) => d.id == selectedId)
                  .cast<InputDevice?>()
                  .firstWhere((_) => true, orElse: () => null);
              return match != null
                  ? l10n.recordingFromDevice(match.label)
                  : l10n.usingSystemDefaultMicrophone;
            },
            loading: () => l10n.detectingInputDevices,
            error: (e, _) => l10n.couldNotListDevices('$e'),
          );

    return Column(
      children: [
        SettingsRow(
          icon: AppIcons.audioLines,
          title: l10n.audioInput,
          subtitle: subtitle,
          subtitleStyle: _testError != null
              ? TextStyle(fontSize: 12, color: tokens?.textErrorPrimary)
              : null,
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: devicesAsync.when(
                    data: (devices) => _DeviceSelect(
                      devices: devices,
                      selectedId: selectedId,
                      onChange: notifier.setDeviceId,
                    ),
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CcSpinner(),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
                CcButton(
                  onPressed: _testing
                      ? null
                      : () => ref.invalidate(audioInputDevicesProvider),
                  variant: CcButtonVariant.secondary,
                  icon: AppIcons.refreshCw,
                  child: Text(l10n.refresh),
                ),
                const SizedBox(width: 8),
                CcButton(
                  onPressed: _toggleTest,
                  variant: _testing
                      ? CcButtonVariant.destructive
                      : CcButtonVariant.secondary,
                  icon: _testing ? AppIcons.square : AppIcons.mic,
                  child: Text(_testing ? l10n.stop : l10n.testLabel),
                ),
              ],
            ),
          ),
        ),
        if (_testing) ...[
          const SizedBox(height: 8),
          _LevelMeter(level: _level),
        ],
      ],
    );
  }
}

class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CcProgressBar(
                value: level.clamp(0.0, 1.0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${(level * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                height: 1.3,
                color: tokens?.textTertiary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSelect extends StatelessWidget {
  const _DeviceSelect({
    required this.devices,
    required this.selectedId,
    required this.onChange,
  });

  final List<InputDevice> devices;
  final String? selectedId;
  final ValueChanged<String?> onChange;

  static const _systemDefaultId = '__system_default__';

  @override
  Widget build(BuildContext context) {
    final options = <CcSelectOption<String>>[
      CcSelectOption(
        value: _systemDefaultId,
        label: AppLocalizations.of(context).systemDefault,
      ),
      for (final d in devices) CcSelectOption(value: d.id, label: d.label),
    ];
    final validValues = options.map((o) => o.value).toSet();
    final current = selectedId != null && validValues.contains(selectedId)
        ? selectedId!
        : _systemDefaultId;

    return CcSelect<String>(
      options: options,
      value: current,
      onChanged: (v) {
        if (v == _systemDefaultId) {
          onChange(null);
        } else {
          onChange(v);
        }
      },
    );
  }
}
