import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/model_actions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shared scaffolding for the three on-device-model settings sections
/// (embedding / diarization / voice).
///
/// Each section reads a seamed [ModelControl] + a status provider
/// (`FutureProvider<ModelStatusSnapshot?>`) and renders the SAME UI on desktop
/// and web. The desktop control adapts the in-process model controller; the web
/// control drives the SERVER's model over the `models.*` RPC ops. When the
/// connected server hosts no such model, the status snapshot is `null` and the
/// card renders an honest "managed on the server host" placeholder — these
/// widgets centralise that null/loading/error handling + the install / cancel /
/// remove / redownload actions so the three sections stay in lockstep.

/// Wraps a model section in a [SectionCard] and resolves the
/// `AsyncValue<ModelStatusSnapshot?>` to loading / error / placeholder / body.
///
/// When the status data is `null` (the connected server hosts no such model)
/// the card shows the "managed on the server host" placeholder; otherwise it
/// delegates to [child] with the resolved non-null snapshot.
class ModelSectionCard extends StatelessWidget {
  /// Creates a [ModelSectionCard].
  const ModelSectionCard({
    required this.label,
    required this.statusAsync,
    required this.child,
    super.key,
  });

  /// The section's heading (e.g. "Semantic search").
  final String label;

  /// The model status snapshot (`null` ⇒ unavailable on this server).
  final AsyncValue<ModelStatusSnapshot?> statusAsync;

  /// Builds the body for a resolved, non-null snapshot.
  final Widget Function(ModelStatusSnapshot status) child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: label,
      child: statusAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => InlineLoadError(
          e,
          padding: const EdgeInsets.all(16),
          center: false,
        ),
        data: (status) {
          if (status == null) {
            return CcAlert(
              title: l10n.modelManagedOnServer,
              variant: CcAlertVariant.info,
            );
          }
          return child(status);
        },
      ),
    );
  }
}

/// The body of a model section: the status row (icon + title + subtitle +
/// install/cancel/remove/redownload actions) and the download progress bar.
///
/// Identical across the three sections; the per-model copy (title, subtitle,
/// dialog strings) is threaded in. [leading]/[trailing] let a section inject
/// extra device-local rows (the voice section's model picker / VAD / audio
/// input) above and below the status row.
class ModelSectionBody extends StatelessWidget {
  /// Creates a [ModelSectionBody].
  const ModelSectionBody({
    required this.icon,
    required this.title,
    required this.status,
    required this.control,
    required this.onChanged,
    required this.subtitle,
    required this.redownloadTitle,
    required this.redownloadBody,
    required this.removeTitle,
    required this.removeBody,
    this.leading,
    this.trailing,
    super.key,
  });

  /// The status row's leading icon.
  final IconData icon;

  /// The status row's title.
  final String title;

  /// The current model snapshot.
  final ModelStatusSnapshot status;

  /// The control the actions drive.
  final ModelControl control;

  /// Invoked after every action so the section refreshes its status snapshot.
  final VoidCallback onChanged;

  /// The status-row subtitle for the current [status].
  final String subtitle;

  /// Title for the "redownload?" confirmation dialog.
  final String redownloadTitle;

  /// Body for the "redownload?" confirmation dialog.
  final String redownloadBody;

  /// Title for the "remove?" confirmation dialog.
  final String removeTitle;

  /// Body for the "remove?" confirmation dialog.
  final String removeBody;

  /// Optional rows rendered ABOVE the status row (e.g. the ASR model picker).
  final Widget? leading;

  /// Optional rows rendered BELOW the progress bar (e.g. VAD / audio input).
  final Widget? trailing;

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final hasError = status.status == ModelLifecycleStatus.error;
    // Lifecycle → a tone and a word. The old row carried the state only in an
    // uncoloured subtitle sentence, so "installed" and "the last attempt
    // failed" looked identical until you read them.
    final (statusLabel, tone) = switch (status.status) {
      ModelLifecycleStatus.installed => (
        l10n.installedLabel,
        CcStatusTone.positive,
      ),
      ModelLifecycleStatus.downloading => (
        l10n.downloadingLabel,
        CcStatusTone.info,
      ),
      ModelLifecycleStatus.error => (
        l10n.settingsStateFailed,
        CcStatusTone.negative,
      ),
      ModelLifecycleStatus.notInstalled || ModelLifecycleStatus.unknown => (
        l10n.notInstalledLabel,
        CcStatusTone.neutral,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(height: AppSpacing.md),
        ],
        SettingsEntityRow(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          icon: icon,
          title: title,
          tone: tone,
          statusLabel: statusLabel,
          subtitleWidget: Text(
            subtitle,
            style: CcTypography.caption.copyWith(
              color: hasError ? tokens.textErrorPrimary : tokens.textTertiary,
              height: 1.4,
            ),
          ),
          trailing: ModelActions(
            isInstalled: status.installed,
            isDownloading: status.downloading,
            onInstall: () => _run(context, control.install),
            onCancel: () => _run(context, control.cancel),
            onReinstall: () => _confirmReinstall(context),
            onRemove: () => _confirmRemove(context),
          ),
        ),
        if (status.downloading) ...[
          const SizedBox(height: AppSpacing.sm),
          status.progress > 0
              ? CcProgressBar(value: status.progress)
              : const CcProgressBar(),
        ],
        ?trailing,
      ],
    );
  }

  Future<void> _confirmReinstall(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: redownloadTitle,
      body: redownloadBody,
      confirmLabel: l10n.redownload,
    );
    if (ok && context.mounted) {
      await _run(context, () async {
        await control.uninstall();
        await control.install();
      });
    }
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final ok = await _confirm(
      context,
      title: removeTitle,
      body: removeBody,
      confirmLabel: l10n.remove,
      destructive: true,
    );
    if (ok && context.mounted) {
      await _run(context, control.uninstall);
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
        final l10n = AppLocalizations.of(dialogContext);
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
