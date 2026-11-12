import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/commit_signing_key_details.dart';
import 'package:control_center/features/settings/providers/commit_signing_key_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Commits → Verified commits: the person's commit signing
/// key. Off until they create one; then the public half, where each forge
/// takes it, and a way to delete it.
class CommitSigningKeySection extends ConsumerStatefulWidget {
  /// Creates a [CommitSigningKeySection].
  const CommitSigningKeySection({super.key});

  @override
  ConsumerState<CommitSigningKeySection> createState() =>
      _CommitSigningKeySectionState();
}

class _CommitSigningKeySectionState
    extends ConsumerState<CommitSigningKeySection> {
  bool _busy = false;

  String _reason(AppLocalizations l10n, Object error) =>
      failureMessage(l10n, error);

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(commitSigningKeyProvider.notifier).create();
      if (mounted) {
        CcToastScope.maybeOf(context)?.show(
          l10n.settingsCommitSigningCreated,
          variant: CcToastVariant.success,
        );
      }
    } on Object catch (error) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(_reason(l10n, error), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.settingsCommitSigningDeleteTitle,
      message: l10n.settingsCommitSigningDeleteBody,
      confirmLabel: l10n.settingsCommitSigningDelete,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(commitSigningKeyProvider.notifier).delete();
      if (mounted) {
        CcToastScope.maybeOf(context)?.show(l10n.settingsCommitSigningDeleted);
      }
    } on Object catch (error) {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(_reason(l10n, error), variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (ref.watch(isDemoServerProvider)) {
      return SectionCard(
        label: l10n.settingsCommitSigningSection,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: DemoUnavailable(
            capability: DemoCapability.forge,
            compact: true,
          ),
        ),
      );
    }
    final state = ref.watch(commitSigningKeyProvider);
    final key = state.value;
    return SectionCard(
      label: l10n.settingsCommitSigningSection,
      trailing: state.hasValue
          ? CcStatusTag(
              label: key == null
                  ? l10n.settingsCommitSigningStatusOff
                  : l10n.settingsCommitSigningStatusOn,
              tone: key == null ? CcStatusTone.neutral : CcStatusTone.positive,
            )
          : null,
      child: switch (state) {
        AsyncValue(hasValue: true) => _body(l10n, key),
        AsyncError(:final error) => _ErrorRow(
          message: failureMessage(l10n, error),
          onRetry: () => ref.invalidate(commitSigningKeyProvider),
        ),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(child: CcSpinner(size: 16)),
        ),
      },
    );
  }

  Widget _body(AppLocalizations l10n, CommitSigningKey? key) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (key == null)
          Text(
            l10n.settingsCommitSigningIntro,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          )
        else
          CommitSigningKeyDetails(signingKey: key),
        const SizedBox(height: AppSpacing.lg),
        const CommitSigningTrust(),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: key == null
              ? CcButton(
                  icon: AppIcons.keyRound,
                  loading: _busy,
                  onPressed: _busy ? null : _create,
                  child: Text(l10n.settingsCommitSigningCreate),
                )
              : CcButton(
                  variant: CcButtonVariant.destructive,
                  size: CcButtonSize.sm,
                  icon: AppIcons.trash2,
                  loading: _busy,
                  onPressed: _busy ? null : _delete,
                  child: Text(l10n.settingsCommitSigningDelete),
                ),
        ),
      ],
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Wrap(
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(AppIcons.triangleAlert, size: 14, color: t.fgErrorPrimary),
        Text(
          l10n.settingsCommitSigningLoadFailed(message),
          style: CcTypography.caption.copyWith(color: t.textErrorPrimary),
        ),
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: onRetry,
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}
