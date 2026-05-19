import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_control.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/model_section_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section that exposes the local speaker-diarization model lifecycle.
///
/// Platform-neutral: it reads the seamed [diarizationModelControlProvider] +
/// [diarizationModelStatusSnapshotProvider]. On desktop these resolve to the
/// in-process model notifier; on web/thin clients they resolve to the connected
/// server's diarization model over the `models.diarization*` RPC ops. When the
/// connected server hosts no model (status is `null`), it renders an honest
/// "managed on the server host" placeholder.
class DiarizationSection extends ConsumerWidget {
  /// Creates a [DiarizationSection].
  const DiarizationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusAsync = ref.watch(diarizationModelStatusSnapshotProvider);

    return ModelSectionCard(
      label: l10n.speakerDiarization,
      statusAsync: statusAsync,
      child: (status) => ModelSectionBody(
        icon: AppIcons.users,
        title: l10n.diarizationModel,
        status: status,
        control: ref.watch(diarizationModelControlProvider),
        onChanged: () => ref.invalidate(diarizationModelStatusSnapshotProvider),
        subtitle: _subtitle(l10n, status),
        redownloadTitle: l10n.redownloadDiarizationModel,
        redownloadBody: l10n.diarizationRedownloadBody,
        removeTitle: l10n.removeDiarizationModel,
        removeBody: l10n.diarizationRemoveBody,
      ),
    );
  }

  String _subtitle(AppLocalizations l10n, ModelStatusSnapshot status) {
    final pct = (status.progress * 100).clamp(0, 100).round();
    return switch (status.status) {
      ModelLifecycleStatus.installed => l10n.diarizationInstalled,
      ModelLifecycleStatus.downloading => l10n.downloadingModel(pct),
      ModelLifecycleStatus.error =>
        l10n.diarizationInstallFailed(status.error ?? 'unknown error'),
      ModelLifecycleStatus.notInstalled => l10n.diarizationNotInstalled,
      ModelLifecycleStatus.unknown => l10n.checkingEllipsis,
    };
  }
}
