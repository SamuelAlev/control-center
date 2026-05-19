import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings section that exposes the local embedding model lifecycle.
class EmbeddingSection extends ConsumerWidget {
  /// Creates an [EmbeddingSection].
  const EmbeddingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(embeddingModelStateProvider);
    final notifier = ref.read(embeddingModelStateProvider.notifier);
    final colors = FTheme.of(context).colors;
    final l10n = AppLocalizations.of(context);


    final isDownloading = state.status == EmbeddingModelStatus.downloading;
    final isInstalled = state.status == EmbeddingModelStatus.installed;
    final hasError = state.status == EmbeddingModelStatus.error;

    final pct = (state.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final subtitle = switch (state.status) {
      EmbeddingModelStatus.installed =>
        l10n.embeddingInstalled,
      EmbeddingModelStatus.downloading => l10n.downloadingModel(int.parse(pct)),
      EmbeddingModelStatus.error =>
        l10n.embeddingInstallFailed(state.error ?? 'unknown error'),
      EmbeddingModelStatus.notInstalled =>
        l10n.embeddingNotInstalled,
      EmbeddingModelStatus.unknown => l10n.checkingEllipsis,
    };

    return SectionCard(
      label: l10n.semanticSearch,

      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.brain,
            title: l10n.embeddingModel,

            subtitle: subtitle,
            subtitleStyle: hasError
                ? TextStyle(fontSize: 12, color: colors.destructive)
                : null,
            trailing: _EmbeddingActions(
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
        ],
      ),
    );
  }

  Future<void> _confirmReinstall(
    BuildContext context,
    EmbeddingModelStateNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: AppLocalizations.of(context).redownloadEmbeddingModel,
      body:
          l10n.embeddingRedownloadBody,
      confirmLabel: l10n.redownload,
    );
    if (ok) {
      await notifier.uninstall();
      await notifier.installIfNeeded();
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    EmbeddingModelStateNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: AppLocalizations.of(context).removeEmbeddingModel,
      body:
          l10n.embeddingRemoveBody,
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
    final result = await showFDialog<bool>(
      context: context,
      builder: (dialogContext, style, animation) {
        final l10n = AppLocalizations.of(context);

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

class _EmbeddingActions extends StatelessWidget {
  const _EmbeddingActions({
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
