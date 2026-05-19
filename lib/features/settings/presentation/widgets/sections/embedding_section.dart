import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_model_control.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/model_section_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings section that exposes the local embedding model lifecycle.
///
/// Platform-neutral: it reads the seamed [embeddingModelControlProvider] +
/// [embeddingModelStatusSnapshotProvider]. On desktop these resolve to the
/// in-process model controller; on web/thin clients they resolve to the
/// connected server's embedding model over the `models.embedding*` RPC ops.
/// When the connected server hosts no model (status is `null`), it renders an
/// honest "managed on the server host" placeholder.
class EmbeddingSection extends ConsumerWidget {
  /// Creates an [EmbeddingSection].
  const EmbeddingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statusAsync = ref.watch(embeddingModelStatusSnapshotProvider);

    return ModelSectionCard(
      label: l10n.semanticSearch,
      statusAsync: statusAsync,
      child: (status) => ModelSectionBody(
        icon: AppIcons.brain,
        title: l10n.embeddingModel,
        status: status,
        control: ref.watch(embeddingModelControlProvider),
        onChanged: () => ref.invalidate(embeddingModelStatusSnapshotProvider),
        subtitle: _subtitle(l10n, status),
        redownloadTitle: l10n.redownloadEmbeddingModel,
        redownloadBody: l10n.embeddingRedownloadBody,
        removeTitle: l10n.removeEmbeddingModel,
        removeBody: l10n.embeddingRemoveBody,
      ),
    );
  }

  String _subtitle(AppLocalizations l10n, ModelStatusSnapshot status) {
    final pct = (status.progress * 100).clamp(0, 100).round();
    return switch (status.status) {
      ModelLifecycleStatus.installed => l10n.embeddingInstalled,
      ModelLifecycleStatus.downloading => l10n.downloadingModel(pct),
      ModelLifecycleStatus.error =>
        l10n.embeddingInstallFailed(status.error ?? 'unknown error'),
      ModelLifecycleStatus.notInstalled => l10n.embeddingNotInstalled,
      ModelLifecycleStatus.unknown => l10n.checkingEllipsis,
    };
  }
}
