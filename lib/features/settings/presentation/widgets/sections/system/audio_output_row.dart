// Audio-output device picker + test chime, shared by the settings section and
// the onboarding voice step. The choice is APP-WIDE — notification sounds, the
// soundscape, meeting playback and a rig's audio lane all route through it.
//
// Desktop-only by construction: the web player cannot choose an output device
// (the browser routes audio), so [AudioOutputRow.isSupported] is false there and
// every host hides the row rather than showing a picker that silently does
// nothing.
library;

import 'dart:async';

import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/audio/audio_output_settings.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

/// Row for choosing and testing the output device app audio plays through.
class AudioOutputRow extends ConsumerStatefulWidget {
  /// Creates an [AudioOutputRow].
  const AudioOutputRow({super.key, this.title});

  /// Overrides the row title. Defaults to "Output device", which reads right
  /// inside the settings card that already names the surface; standalone hosts
  /// (onboarding) pass "Audio output" so it pairs with the input row above it.
  final String? title;

  /// Whether this platform can route audio to a chosen device at all.
  static bool get isSupported => !kIsWeb;

  @override
  ConsumerState<AudioOutputRow> createState() => _AudioOutputRowState();
}

class _AudioOutputRowState extends ConsumerState<AudioOutputRow> {
  /// Sentinel for "use the system default" — the select needs a real value,
  /// while the stored preference uses null for the default (same trick as the
  /// input-device picker).
  static const _systemDefaultId = '__system_default__';

  /// The test-sound player, created lazily on the first Test press so that
  /// merely rendering the row (in the app or in tests) never requires a native
  /// audio backend.
  Player? _testPlayer;

  /// Plays a short chime through the CURRENTLY selected output device — the
  /// point of the button is to verify the choice, so the device is applied to
  /// the test player, not inherited from anything else. Re-pressing restarts
  /// the chime (`open` stops whatever it was playing).
  Future<void> _playTest() async {
    try {
      final player = _testPlayer ??= Player();
      await applyAppAudioOutput(player, ref.read(audioOutputDeviceProvider));
      await player.open(
        Media('asset:///assets/${NotificationSound.chime.assetPath!}'),
      );
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    }
  }

  @override
  void dispose() {
    final player = _testPlayer;
    if (player != null) {
      // `dispose()` cannot await; release the native player detached.
      unawaited(() async {
        try {
          await player.dispose();
        } on Object {
          // Already disposed — nothing to do.
        }
      }());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AudioOutputRow.isSupported) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final devicesAsync = ref.watch(audioOutputDevicesProvider);
    final selected = ref.watch(audioOutputDeviceProvider);

    final devices = devicesAsync.asData?.value ?? const <AudioDevice>[];
    final selectable = devices
        .where((d) => d.name.isNotEmpty && d.name != 'auto')
        .toList();
    final selectedKnown =
        selectable.any((d) => d.name == selected) || selected == null;

    final String subtitle;
    if (devicesAsync.isLoading) {
      subtitle = l10n.checkingEllipsis;
    } else if (!selectedKnown) {
      // The stored device is gone (unplugged): say so, and that the default is
      // playing until a new choice is made — never silently pretend it applied.
      subtitle = l10n.audioOutputGone;
    } else if (selected == null) {
      subtitle = l10n.audioOutputDefaultHint;
    } else {
      subtitle = selectable.firstWhere((d) => d.name == selected).description;
    }

    return SettingsRow(
      icon: AppIcons.volume2,
      title: widget.title ?? l10n.audioOutputDeviceTitle,
      subtitle: subtitle,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: CcSelect<String>(
                value: selectedKnown && selected != null
                    ? selected
                    : _systemDefaultId,
                options: [
                  CcSelectOption(
                    value: _systemDefaultId,
                    label: l10n.systemDefault,
                  ),
                  for (final d in selectable)
                    CcSelectOption(value: d.name, label: d.description),
                ],
                enabled: !devicesAsync.isLoading,
                onChanged: (v) => ref
                    .read(audioOutputDeviceProvider.notifier)
                    .setDeviceName(v == _systemDefaultId ? null : v),
              ),
            ),
            const SizedBox(width: 8),
            CcButton(
              onPressed: devicesAsync.isLoading
                  ? null
                  : () => ref.invalidate(audioOutputDevicesProvider),
              variant: CcButtonVariant.secondary,
              icon: AppIcons.refreshCw,
              child: Text(l10n.refresh),
            ),
            const SizedBox(width: 8),
            CcButton(
              onPressed: _playTest,
              variant: CcButtonVariant.secondary,
              icon: AppIcons.play,
              child: Text(l10n.testLabel),
            ),
          ],
        ),
      ),
    );
  }
}
