import 'package:cc_domain/features/soundscape/domain/entities/soundscape_context.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/soundscape/presentation/widgets/soundscape_tune_pad.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The body of the soundscape control panel: play/pause + current scene, the
/// mood picker, the master volume slider, the auto-detected weather location,
/// and the focus-mode auto-start toggle. Drives [soundscapeProvider] and the
/// weather repository only — the server owns generation.
class SoundscapeControls extends ConsumerWidget {
  /// Creates a [SoundscapeControls] body.
  const SoundscapeControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Sleep is deliberately "homogenous and even" — no melody or drive to
    // tune, so the pad only shows for focus/relax.
    final showTunePad = ref.watch(
      soundscapeProvider.select((s) => s.mood != SoundscapeMood.sleep),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sceneRow(context, ref),
        const SizedBox(height: 20),
        _sectionLabel(context, l10n.soundscapeMoodLabel),
        const SizedBox(height: 8),
        _moodPicker(context, ref),
        if (showTunePad) ...[
          const SizedBox(height: 20),
          _sectionLabel(context, l10n.soundscapeTuneLabel),
          const SizedBox(height: 8),
          const Center(child: SoundscapeTunePad()),
          const SizedBox(height: 6),
          Center(child: _hint(context, l10n.soundscapeTuneResetHint)),
        ],
        const SizedBox(height: 20),
        _sectionLabel(context, l10n.soundscapeVolumeLabel),
        _volumeRow(context, ref),
        const SizedBox(height: 16),
        _sectionLabel(context, l10n.soundscapeLocationLabel),
        const SizedBox(height: 8),
        _locationRow(context, ref),
        const SizedBox(height: 20),
        _autoStartRow(context, ref),
      ],
    );
  }

  DesignSystemTokens _tokens(BuildContext c) =>
      c.designSystem ?? DesignSystemTokens.light();

  Widget _sectionLabel(BuildContext context, String text) => Text(
    text,
    style: CcTypography.caption.copyWith(
      color: _tokens(context).textTertiary,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _body(BuildContext context, String text, Color color) =>
      Text(text, style: CcTypography.caption.copyWith(color: color));

  Widget _hint(BuildContext context, String text) => Text(
    text,
    style: CcTypography.caption.copyWith(color: _tokens(context).textTertiary),
  );

  Widget _sceneRow(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = _tokens(context);
    final state = ref.watch(soundscapeProvider);
    final controller = ref.read(soundscapeProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: t.borderSecondary),
      ),
      child: Row(
        children: [
          Expanded(child: _sceneSummary(context, ref)),
          const SizedBox(width: AppSpacing.md),
          CcButton(
            icon: state.playing ? AppIcons.pause : AppIcons.play,
            variant: state.playing
                ? CcButtonVariant.secondary
                : CcButtonVariant.accent,
            onPressed: controller.toggle,
            child: Text(
              state.playing ? l10n.soundscapePause : l10n.soundscapePlay,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sceneSummary(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = _tokens(context);
    final data = ref.watch(soundscapeSceneProvider).value;
    final name = (data?['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      return _body(context, l10n.soundscapeSceneLoading, t.textTertiary);
    }
    final tempRaw = data?['temperature_celsius'];
    final tempC = tempRaw is num ? tempRaw.round() : null;
    final loc = (data?['location_label'] as String?)?.trim();
    final parts = <String>[
      if (tempC != null) l10n.soundscapeTemperature(tempC),
      if (loc != null && loc.isNotEmpty) loc,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _sectionLabel(context, l10n.soundscapeSceneLabel),
        const SizedBox(height: 2),
        Text(
          name,
          style: CcTypography.body.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (parts.isNotEmpty) ...[
          const SizedBox(height: 2),
          _body(context, parts.join(' · '), t.textSecondary),
        ],
      ],
    );
  }

  Widget _moodPicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(soundscapeProvider);
    final controller = ref.read(soundscapeProvider.notifier);
    const moods = SoundscapeMood.values;
    return Row(
      children: [
        for (var i = 0; i < moods.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: CcButton(
              variant: moods[i] == state.mood
                  ? CcButtonVariant.accent
                  : CcButtonVariant.secondary,
              fullWidth: true,
              onPressed: () async {
                await controller.setMood(moods[i]);
              },
              child: Text(_moodLabel(l10n, moods[i])),
            ),
          ),
        ],
      ],
    );
  }

  String _moodLabel(AppLocalizations l10n, SoundscapeMood mood) =>
      switch (mood) {
        SoundscapeMood.focus => l10n.soundscapeMoodFocus,
        SoundscapeMood.relax => l10n.soundscapeMoodRelax,
        SoundscapeMood.sleep => l10n.soundscapeMoodSleep,
      };

  Widget _volumeRow(BuildContext context, WidgetRef ref) {
    final t = _tokens(context);
    final state = ref.watch(soundscapeProvider);
    final controller = ref.read(soundscapeProvider.notifier);
    return Row(
      children: [
        Icon(
          state.volume <= 0 ? AppIcons.volumeOff : AppIcons.volume2,
          size: 16,
          color: t.textTertiary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          // CcSlider is widgets-only, so it needs no Material ancestor — the
          // transparent Material this used to carry (for the panel's root
          // overlay, which has none) is gone with it.
          child: CcSlider(
            value: state.volume,
            divisions: 20,
            onChanged: (v) async {
              await controller.setVolume(v);
            },
          ),
        ),
      ],
    );
  }

  Widget _locationRow(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = _tokens(context);
    final label = ref.watch(weatherProvider).value?.locationLabel;
    final display = (label != null && label.isNotEmpty)
        ? label
        : l10n.soundscapeLocationDetecting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.mapPin, size: 16, color: t.textTertiary),
            const SizedBox(width: 8),
            Expanded(child: _body(context, display, t.textPrimary)),
            const SizedBox(width: 8),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              icon: AppIcons.refreshCw,
              onPressed: () async {
                final ws = ref.read(activeWorkspaceIdProvider);
                if (ws == null) {
                  return;
                }
                try {
                  await ref.read(weatherRepositoryProvider).refreshNow(ws);
                } on Object {
                  // Host-only refresh may fail (offline / no host) — ignore;
                  // the watch keeps showing the last snapshot.
                }
              },
              child: Text(l10n.soundscapeRefreshWeather),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _hint(context, l10n.soundscapeLocationAutoNote),
      ],
    );
  }

  Widget _autoStartRow(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = _tokens(context);
    final state = ref.watch(soundscapeProvider);
    final controller = ref.read(soundscapeProvider.notifier);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _body(context, l10n.soundscapeAutoStartLabel, t.textPrimary),
              const SizedBox(height: 2),
              _hint(context, l10n.soundscapeAutoStartDescription),
            ],
          ),
        ),
        const SizedBox(width: 12),
        CcSwitch(
          value: state.autoStartWithFocus,
          onChanged: (v) async {
            await controller.setAutoStartWithFocus(value: v);
          },
        ),
      ],
    );
  }
}
