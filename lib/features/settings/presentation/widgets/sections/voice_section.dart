import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/model_section_shared.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/voice_section_extras.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section for voice model and audio input configuration.
///
/// Platform-neutral: it reads the seamed [voiceModelControlProvider] +
/// [voiceModelStatusSnapshotProvider]. On desktop these resolve to the
/// in-process model notifier; on web/thin clients they resolve to the connected
/// server's voice model over the `models.voice*` RPC ops. When the connected
/// server hosts no model (status is `null`), it renders an honest "managed on
/// the server host" placeholder.
///
/// The ASR model picker, the bundled-VAD row, and the audio-input device picker
/// + mic test are device-local (the host's hardware/filesystem), so they render
/// only on desktop via the [voiceModelPickerEnabled] / [VoiceSectionExtras]
/// seam — the web build never pulls `package:record` or the audio providers.
class VoiceSection extends ConsumerWidget {
  /// Creates a [VoiceSection].
  const VoiceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusAsync = ref.watch(voiceModelStatusSnapshotProvider);

    return ModelSectionCard(
      label: l10n.voiceTranscription,
      statusAsync: statusAsync,
      child: (status) => ModelSectionBody(
        icon: AppIcons.mic,
        title: ref.watch(voiceModelRowTitleProvider),
        status: status,
        control: ref.watch(voiceModelControlProvider),
        onChanged: () => ref.invalidate(voiceModelStatusSnapshotProvider),
        subtitle: _subtitle(l10n, status),
        redownloadTitle: l10n.redownloadVoiceModel,
        redownloadBody: l10n.voiceRedownloadBody,
        removeTitle: l10n.removeVoiceModel,
        removeBody: l10n.voiceRemoveBody,
        leading: voiceModelPickerEnabled
            ? VoiceModelPicker(enabled: !status.downloading)
            : null,
        trailing: const VoiceSectionExtras(),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n, ModelStatusSnapshot status) {
    final pct = (status.progress * 100).clamp(0, 100).round();
    return switch (status.status) {
      ModelLifecycleStatus.installed => l10n.voiceModelInstalled,
      ModelLifecycleStatus.downloading => status.phase == 'extracting'
          ? l10n.extractingModel(pct)
          : l10n.downloadingModel(pct),
      ModelLifecycleStatus.error =>
        l10n.voiceInstallFailed(status.error ?? 'unknown error'),
      ModelLifecycleStatus.notInstalled => l10n.voiceModelNotInstalled,
      ModelLifecycleStatus.unknown => l10n.checkingEllipsis,
    };
  }
}
