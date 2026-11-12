import 'package:cc_domain/core/domain/ports/import_hold_review.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/import_hold_wording.dart';
import 'package:control_center/features/settings/providers/backup_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One grant a restored copy carried: what it would grant to whom, and the
/// server owner's two answers, Accept (apply it) and Dismiss (drop it).
///
/// A kind this build cannot describe can only be dismissed: accepting
/// something nobody could read first is not a decision.
class ImportHoldEntry extends ConsumerStatefulWidget {
  /// Creates the row for [hold] of [workspaceId].
  const ImportHoldEntry({
    super.key,
    required this.workspaceId,
    required this.hold,
    required this.sentence,
  });

  /// The restored workspace the hold belongs to.
  final String workspaceId;

  /// The held grant.
  final ImportHoldView hold;

  /// What it grants, worded ([importHoldSentence]).
  final String sentence;

  @override
  ConsumerState<ImportHoldEntry> createState() => _ImportHoldEntryState();
}

class _ImportHoldEntryState extends ConsumerState<ImportHoldEntry> {
  bool? _resolving;

  Future<void> _resolve({required bool accept}) async {
    final l10n = AppLocalizations.of(context);
    if (accept && importHoldNeedsConfirmation(widget.hold)) {
      final confirmed = await showCcConfirmDialog(
        context: context,
        title: l10n.importHoldAcceptTitle,
        message: l10n.importHoldAcceptBody(widget.sentence),
        confirmLabel: l10n.importHoldAccept,
        cancelLabel: l10n.cancel,
      );
      if (!confirmed || !mounted) {
        return;
      }
    }
    setState(() => _resolving = accept);
    final toasts = CcToastScope.maybeOf(context);
    try {
      final applied = await ref
          .read(importHoldActionsProvider)
          .resolve(
            workspaceId: widget.workspaceId,
            hold: widget.hold,
            accept: accept,
          );
      if (accept) {
        toasts?.show(
          applied ? l10n.importHoldAccepted : l10n.importHoldNotApplied,
          variant: applied ? CcToastVariant.success : CcToastVariant.neutral,
        );
      }
    } on Object catch (e) {
      toasts?.show(failureMessage(l10n, e), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _resolving = null);
      }
    }
  }

  Widget _details(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final scope = importHoldScope(l10n, widget.hold);
    final importedAt = widget.hold.importedAt;
    final caption = CcTypography.caption.copyWith(color: tokens.textTertiary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.sentence,
          style: CcTypography.bodySm.copyWith(color: tokens.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            if (scope != null) Text(scope, style: caption),
            AppTimestamp(
              dateTime: importedAt,
              child: Text(
                l10n.importHoldRestoredAt(
                  formatRelativeTime(context, importedAt),
                ),
                style: caption,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = _resolving != null;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        if (widget.hold.kind != null)
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            loading: _resolving == true,
            onPressed: busy ? null : () => _resolve(accept: true),
            child: Text(l10n.importHoldAccept),
          ),
        CcButton(
          size: CcButtonSize.sm,
          variant: CcButtonVariant.ghost,
          loading: _resolving == false,
          onPressed: busy ? null : () => _resolve(accept: false),
          child: Text(l10n.importHoldDismiss),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(vertical: AppSpacing.sm),
    // The actions drop beneath the sentence where sharing a line would
    // squeeze it into a sliver.
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kSettingsFieldInlineBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _details(context)),
              const SizedBox(width: AppSpacing.md),
              _actions(context),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _details(context),
            const SizedBox(height: AppSpacing.sm),
            _actions(context),
          ],
        );
      },
    ),
  );
}
