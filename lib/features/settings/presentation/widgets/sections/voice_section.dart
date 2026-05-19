import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/infrastructure/audio/audio_input_settings.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';

class VoiceSection extends ConsumerWidget {
  const VoiceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceModelStateProvider);
    final notifier = ref.read(voiceModelStateProvider.notifier);
    final colors = FTheme.of(context).colors;

    final isDownloading = state.status == VoiceModelStatus.downloading;
    final l10n = AppLocalizations.of(context);
    final isInstalled = state.status == VoiceModelStatus.installed;
    final hasError = state.status == VoiceModelStatus.error;

    final pct = (state.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final subtitle = switch (state.status) {
      VoiceModelStatus.installed =>
        l10n.whisperInstalled,
      VoiceModelStatus.downloading => state.phase == 'extracting'
          ? l10n.extractingModel(int.parse(pct))
          : l10n.downloadingModel(int.parse(pct)),
      VoiceModelStatus.error =>
        l10n.voiceInstallFailed(state.error ?? 'unknown error'),
      VoiceModelStatus.notInstalled =>
        l10n.voiceModelNotInstalled,
      VoiceModelStatus.unknown => l10n.checkingEllipsis,
    };

    return SectionCard(
      label: l10n.voiceTranscription,
      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.mic,
            title: l10n.whisperBaseEn,
            subtitle: subtitle,
            subtitleStyle: hasError
                ? TextStyle(fontSize: 12, color: colors.destructive)
                : null,
            trailing: _VoiceActions(
              isInstalled: isInstalled,
              isDownloading: isDownloading,
              onInstall: notifier.installIfNeeded,
              onCancel: notifier.cancel,
              onReinstall: () => _confirmReinstall(context, notifier),
              onRemove: () => _confirmRemove(context, notifier),
            ),
          ),
          if (isDownloading) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: state.progress > 0
                  ? FDeterminateProgress(value: state.progress)
                  : const FProgress(),
            ),
          ],
          const SizedBox(height: 8),
          const AudioInputRow(),
        ],
      ),
    );
  }

  Future<void> _confirmReinstall(
    BuildContext context,
    VoiceModelStateNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: AppLocalizations.of(context).redownloadVoiceModel,
      body:
          l10n.voiceRedownloadBody,
      confirmLabel: l10n.redownload,
    );
    if (ok) {
      await notifier.uninstall();
      await notifier.installIfNeeded();
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    VoiceModelStateNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: AppLocalizations.of(context).removeVoiceModel,
      body: l10n.voiceRemoveBody,
      confirmLabel: l10n.remove,
      destructive: true,
    );
    if (ok) {
      await notifier.uninstall();
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    final l10n = AppLocalizations.of(context);
    final result = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) {
        return FDialog(
          style: style,
          animation: animation,
          title: Text(title),
          body: Text(body),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    onPress: () => Navigator.of(dialogContext).pop(false),
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: () => Navigator.of(dialogContext).pop(true),
                    variant: destructive
                        ? FButtonVariant.destructive
                        : FButtonVariant.primary,
                    mainAxisSize: MainAxisSize.min,
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _VoiceActions extends StatelessWidget {
  const _VoiceActions({
    required this.isInstalled,
    required this.isDownloading,
    required this.onInstall,
    required this.onCancel,
    required this.onReinstall,
    required this.onRemove,
  });

  final bool isInstalled;
  final bool isDownloading;
  final VoidCallback onInstall;
  final VoidCallback onCancel;
  final VoidCallback onReinstall;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (isDownloading) {
      return FButton(
        onPress: onCancel,
        variant: FButtonVariant.outline,
        mainAxisSize: MainAxisSize.min,
        child: Text(l10n.cancel),
      );
    }
    if (isInstalled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FButton(
            onPress: onRemove,
            variant: FButtonVariant.ghost,
            mainAxisSize: MainAxisSize.min,
            child: Text(l10n.remove),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: onReinstall,
            variant: FButtonVariant.outline,
            mainAxisSize: MainAxisSize.min,
            prefix: const Icon(LucideIcons.refreshCw, size: 14),
            child: Text(l10n.redownload),
          ),
        ],
      );
    }
    return FButton(
      onPress: onInstall,
      mainAxisSize: MainAxisSize.min,
      prefix: const Icon(LucideIcons.download, size: 14),
      child: Text(l10n.install),
    );
  }
}

class AudioInputRow extends ConsumerStatefulWidget {
  const AudioInputRow({super.key});

  @override
  ConsumerState<AudioInputRow> createState() => _AudioInputRowState();
}

class _AudioInputRowState extends ConsumerState<AudioInputRow> {
  static const _testCeiling = Duration(seconds: 30);
  static const _testConfig = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    autoGain: false,
    echoCancel: false,
    noiseSuppress: false,
  );

  AudioRecorder? _recorder;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<Uint8List>? _audioSub;
  Timer? _autoStop;
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
        setState(() => _testError = AppLocalizations.of(context).microphonePermissionDenied);
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

      final audioStream = await recorder.startStream(config);
      _audioSub = audioStream.listen((_) {}, onError: (_) {});

      _amplitudeSub = recorder
          .onAmplitudeChanged(const Duration(milliseconds: 80))
          .listen((amp) {
        final db = amp.current;
        final normalized = ((db + 60) / 60).clamp(0.0, 1.0);
        if (mounted) {
          setState(() => _level = normalized);
        }
      });

      _autoStop = Timer(_testCeiling, _stopTest);
      setState(() => _testing = true);
    } catch (e) {
      setState(() => _testError = AppLocalizations.of(context).failedToStartMicTest);
      await _stopTest();
    }
  }

  Future<void> _stopTest() async {
    _autoStop?.cancel();
    _autoStop = null;
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
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
    final colors = FTheme.of(context).colors;
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
          icon: LucideIcons.audioLines,
          title: l10n.audioInput,
          subtitle: subtitle,
          subtitleStyle: _testError != null
              ? TextStyle(fontSize: 12, color: colors.destructive)
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
                      child: FCircularProgress(),
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: _testing
                      ? null
                      : () => ref.invalidate(audioInputDevicesProvider),
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  prefix: const Icon(LucideIcons.refreshCw, size: 14),
                  child: Text(l10n.refresh),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: _toggleTest,
                  variant: _testing
                      ? FButtonVariant.destructive
                      : FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  prefix: Icon(
                    _testing ? LucideIcons.square : LucideIcons.mic,
                    size: 14,
                  ),
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
    final colors = FTheme.of(context).colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 0, 0),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: FDeterminateProgress(
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
                color: colors.mutedForeground,
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
    final items = <String, String>{
      AppLocalizations.of(context).systemDefault: _systemDefaultId,
      for (final d in devices) d.label: d.id,
    };
    final validValues = items.values.toSet();
    final current = selectedId != null && validValues.contains(selectedId)
        ? selectedId!
        : _systemDefaultId;

    return FSelect<String>(
      items: items,
      control: FSelectControl<String>.lifted(
        value: current,
        onChange: (v) {
          if (v == null || v == _systemDefaultId) {
            onChange(null);
          } else {
            onChange(v);
          }
        },
      ),
    );
  }
}
