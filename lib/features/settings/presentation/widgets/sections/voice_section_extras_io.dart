// Desktop (VM) voice-section extras: the ASR model picker + the bundled-VAD
// row. (The audio-input device picker + mic test is the shared [AudioInputRow],
// which works on every platform.)
//
// The model selection (persisted to disk) and the bundled Silero VAD are
// device-local sub-features that only make sense on the host that owns the
// hardware, so they render only on desktop via the `voice_section_extras.dart`
// seam. The web variant renders the shared audio-input row alone.
library;

import 'package:cc_infra/src/speech/voice_model_manager.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audio_input_row.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The title shown on the voice model's status row. On desktop this is the
/// selected ASR model's display name (the section also offers a picker above
/// the row to switch models).
final voiceModelRowTitleProvider = Provider<String>((ref) {
  return ref.watch(selectedVoiceModelInfoProvider).displayName;
});

/// Whether the platform offers an ASR model picker above the status row.
/// True on desktop (each model installs independently).
const bool voiceModelPickerEnabled = true;

/// The ASR model picker shown above the voice model's status row (desktop).
/// Disabled while a download is in flight.
class VoiceModelPicker extends ConsumerWidget {
  /// Creates a [VoiceModelPicker].
  const VoiceModelPicker({required this.enabled, super.key});

  /// Whether the picker accepts a new selection (false while downloading).
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedVoiceModelInfoProvider).id;
    return _ModelPicker(
      selectedId: selectedId,
      enabled: enabled,
      onChange: ref.read(selectedVoiceModelProvider.notifier).select,
    );
  }
}

/// The desktop voice-section extras rendered BELOW the model status row: the
/// bundled-VAD indicator and the (shared) audio-input device picker + mic test.
class VoiceSectionExtras extends StatelessWidget {
  /// Creates a [VoiceSectionExtras].
  const VoiceSectionExtras({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 8),
        _VadRow(),
        SizedBox(height: 8),
        AudioInputRow(),
      ],
    );
  }
}

/// Row for the Silero VAD model that gates transcription on learned speech
/// detection. The model is bundled with the app, so it is always included — no
/// install step. (If a broken build can't materialize it, the recorder falls
/// back to the RMS energy gate.)
class _VadRow extends StatelessWidget {
  const _VadRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsRow(
      icon: AppIcons.audioWaveform,
      title: l10n.meetingVad,
      subtitle: l10n.meetingVadDescription,
      trailing: const _IncludedBadge(),
    );
  }
}

/// A quiet "included" indicator for models that ship bundled with the app
/// (no download). Reports presence at a glance without offering an action.
class _IncludedBadge extends StatelessWidget {
  const _IncludedBadge();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppIcons.check, size: 14, color: tokens?.textTertiary),
        const SizedBox(width: 6),
        Text(
          l10n.meetingModelIncluded,
          style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
        ),
      ],
    );
  }
}

/// Dropdown that selects the active ASR model from [VoiceModelInfo.all]. The
/// selection is persisted and each model installs/uninstalls independently.
class _ModelPicker extends StatelessWidget {
  const _ModelPicker({
    required this.selectedId,
    required this.enabled,
    required this.onChange,
  });

  final String selectedId;
  final bool enabled;
  final ValueChanged<String> onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = [
      for (final m in VoiceModelInfo.all)
        CcSelectOption(value: m.id, label: m.displayName),
    ];
    return SettingsRow(
      icon: AppIcons.languages,
      title: l10n.speechModel,
      subtitle: l10n.speechModelHint,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: CcSelect<String>(
          options: options,
          value: selectedId,
          onChanged: enabled ? onChange : (_) {},
        ),
      ),
    );
  }
}
