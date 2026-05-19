import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/diarization_model_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings section that exposes the local speaker-diarization model lifecycle.
class DiarizationSection extends ConsumerWidget {
  /// Creates a [DiarizationSection].
  const DiarizationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(diarizationModelStateProvider);
    final notifier = ref.read(diarizationModelStateProvider.notifier);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);


    final isDownloading = state.status == DiarizationModelStatus.downloading;
    final isInstalled = state.status == DiarizationModelStatus.installed;
    final hasError = state.status == DiarizationModelStatus.error;

    final pct = (state.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final subtitle = switch (state.status) {
      DiarizationModelStatus.installed =>
        l10n.diarizationInstalled,
      DiarizationModelStatus.downloading => l10n.downloadingModel(int.parse(pct)),
      DiarizationModelStatus.error =>
        l10n.diarizationInstallFailed(state.error ?? 'unknown error'),
      DiarizationModelStatus.notInstalled =>
        l10n.diarizationNotInstalled,
      DiarizationModelStatus.unknown => l10n.checkingEllipsis,
    };

    return SectionCard(
      label: l10n.speakerDiarization,

      child: Column(
        children: [
          SettingsRow(
            icon: LucideIcons.users,
            title: l10n.diarizationModel,

            subtitle: subtitle,
            subtitleStyle: hasError
                ? TextStyle(fontSize: 12, color: tokens?.textErrorPrimary)
                : null,
            trailing: _DiarizationActions(
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
                  ? CcProgressBar(value: state.progress)
                  : const CcProgressBar(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReinstall(
    BuildContext context,
    DiarizationModelStateNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: AppLocalizations.of(context).redownloadDiarizationModel,
      body:
          l10n.diarizationRedownloadBody,
      confirmLabel: l10n.redownload,
    );
    if (ok) {
      await notifier.uninstall();
      await notifier.installIfNeeded();
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    DiarizationModelStateNotifier notifier,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: AppLocalizations.of(context).removeDiarizationModel,
      body:
          l10n.diarizationRemoveBody,
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
    final result = await showCcDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(context);

        return CcDialog(
          title: title,
          content: Text(body),
          actions: [
            CcButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              variant: CcButtonVariant.secondary,
              child: Text(l10n.cancel),
            ),
            CcButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              variant: destructive
                  ? CcButtonVariant.destructive
                  : CcButtonVariant.primary,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

class _DiarizationActions extends StatelessWidget {
  const _DiarizationActions({
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
      return CcButton(
        onPressed: onCancel,
        variant: CcButtonVariant.secondary,
        child: Text(l10n.cancel),
      );
    }
    if (isInstalled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcButton(
            onPressed: onRemove,
            variant: CcButtonVariant.ghost,
            child: Text(l10n.remove),
          ),
          const SizedBox(width: 8),
          CcButton(
            onPressed: onReinstall,
            variant: CcButtonVariant.secondary,
            icon: LucideIcons.refreshCw,
            child: Text(l10n.redownload),
          ),
        ],
      );
    }
    return CcButton(
      onPressed: onInstall,
      icon: LucideIcons.download,
      child: Text(l10n.install),
    );
  }
}
