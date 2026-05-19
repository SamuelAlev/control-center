import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/inbox/presentation/models/inbox_attention_item.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/pr_title_text.dart';
import 'package:flutter/material.dart';

/// The pinned attention strip above the PR sections: everything non-PR that
/// blocks the operator or explicitly requests them (blocked agents, failed
/// syncs), each row carrying its single most-likely next action.
class InboxAttentionCard extends StatelessWidget {
  /// Creates an [InboxAttentionCard].
  const InboxAttentionCard({super.key, required this.items});

  /// The sorted attention items (never empty — the caller hides the card).
  final List<InboxAttentionItem> items;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                Icon(AppIcons.alertCircle, size: 16, color: tokens.warn),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.inboxNeedsYourAttention,
                  style: CcTypography.body.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CcStatusTag(
                  label: '${items.length}',
                  tone: CcStatusTone.caution,
                  dot: false,
                ),
              ],
            ),
          ),
          CcDivider(color: tokens.borderSecondary),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) CcDivider(color: tokens.borderSoft),
            _AttentionRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _AttentionRow extends StatelessWidget {
  const _AttentionRow({required this.item});

  final InboxAttentionItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 9,
      ),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: tokens.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: PrTitleText(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.body.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    CcStatusTag(
                      label: _severityLabel(l10n, item.severity),
                      tone: _severityTone(item.severity),
                    ),
                  ],
                ),
                if (item.subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          CcButton(
            onPressed: item.onAction,
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            child: Text(item.actionLabel),
          ),
        ],
      ),
    );
  }
}

String _severityLabel(AppLocalizations l10n, InboxAttentionSeverity s) =>
    switch (s) {
      InboxAttentionSeverity.blocking => l10n.inboxSeverityBlocking,
      InboxAttentionSeverity.warning => l10n.inboxSeverityWaiting,
      InboxAttentionSeverity.info => l10n.inboxSeverityInfo,
    };

CcStatusTone _severityTone(InboxAttentionSeverity s) => switch (s) {
  InboxAttentionSeverity.blocking => CcStatusTone.caution,
  InboxAttentionSeverity.warning => CcStatusTone.info,
  InboxAttentionSeverity.info => CcStatusTone.neutral,
};
