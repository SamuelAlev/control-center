import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_item_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/anchored_code_block.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inline chat rendering of a `reviewNode` channel message.
///
/// Mirrors the data treatment of `ReviewAccordionItem` from the PR-review
/// screen, but slots into the chat flow as a single agent-side bubble.
/// Collapsed by default; expanding reveals the full body, the anchored
/// source snippet (when available), and Fix / Comment / Dismiss actions.
class ReviewNodeBubble extends ConsumerStatefulWidget {
  /// Creates a [ReviewNodeBubble].
  const ReviewNodeBubble({
    super.key,
    required this.message,
    this.fetchFileContent,
    this.prNumber,
    this.onFix,
    this.onComment,
  });

  /// The reviewNode channel message.
  final ChannelMessage message;

  /// Resolves a repo-relative path to its full file contents for the anchor
  /// snippet. When null, the anchor renders as a path-only badge.
  final Future<String> Function(String path)? fetchFileContent;

  /// PR number the finding belongs to, when known. Used by `Comment` to post
  /// the finding back as an inline PR comment.
  final int? prNumber;

  /// Optional handler for the Fix action. When null, a snackbar is shown.
  final VoidCallback? onFix;

  /// Optional handler for the Comment action. When null, a snackbar is shown.
  final VoidCallback? onComment;

  @override
  ConsumerState<ReviewNodeBubble> createState() => _ReviewNodeBubbleState();
}

class _ReviewNodeBubbleState extends ConsumerState<ReviewNodeBubble> {
  bool _expanded = false;
  bool _dismissing = false;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final payload = ReviewNodePayload.fromMetadata(widget.message.metadata);
    if (payload == null) {
      return const SizedBox.shrink();
    }
    final isDismissed = payload.status == ReviewNodeStatus.dismissed;
    final isResolved = payload.status == ReviewNodeStatus.resolved;
    final dimOpacity = isDismissed ? 0.4 : (isResolved ? 0.65 : 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Opacity(
        opacity: dimOpacity,
        child: FocusableBubble(
          messageId: widget.message.id,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderRow(
                payload: payload,
                expanded: _expanded,
                onToggle: () =>
                    setState(() => _expanded = !_expanded),
              ),
              if (_expanded)
                _ExpandedBody(
                  message: widget.message,
                  payload: payload,
                  fetchFileContent: widget.fetchFileContent,
                  prNumber: widget.prNumber,
                  onFix: _handleFix,
                  onComment: _handleComment,
                  onDismiss: _dismissing ? null : _handleDismiss,
                  dismissing: _dismissing,
                  tokens: tokens,
                  theme: theme,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleFix() {
    if (widget.onFix != null) {
      widget.onFix!();
      return;
    }
    _snack(AppLocalizations.of(context).fix);
  }

  void _handleComment() {
    if (widget.onComment != null) {
      widget.onComment!();
      return;
    }
    _snack(AppLocalizations.of(context).comment);
  }

  Future<void> _handleDismiss() async {
    setState(() => _dismissing = true);
    try {
      final repo = ref.read(messagingRepositoryProvider);
      final next = Map<String, dynamic>.from(widget.message.metadata ?? const {});
      next['status'] = 'dismissed';
      await repo.updateMessage(widget.message.id, metadata: next);
    } finally {
      if (mounted) {
        setState(() => _dismissing = false);
      }
    }
  }

  void _snack(String action) {
    CcToastScope.of(context).show(
      '$action — no handler bound',
      variant: CcToastVariant.neutral,
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.payload,
    required this.expanded,
    required this.onToggle,
  });

  final ReviewNodePayload payload;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final decor = reviewItemDecor(context, payload.kind, payload.priority);
    final statusColor = reviewStatusRingColor(payload.status, context);
    final priorityColor = reviewPriorityColor(payload.priority, context);
    final statusLabel = switch (payload.status) {
      ReviewNodeStatus.open => AppLocalizations.of(context).openStatus,
      ReviewNodeStatus.consensusReady =>
          AppLocalizations.of(context).consensus,
      ReviewNodeStatus.resolved => AppLocalizations.of(context).resolved,
      ReviewNodeStatus.dismissed => AppLocalizations.of(context).dismissed,
    };
    final lineInfo = payload.anchor.filePath != null
        ? '${payload.anchor.filePath}'
            '${payload.anchor.lineNumber != null ? ':${payload.anchor.lineNumber}' : ''}'
        : null;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(decor.icon, size: 14, color: decor.accent),
            const SizedBox(width: 6),
            Text(
              decor.label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: decor.accent,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· ${payload.priority.name.toUpperCase()}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: priorityColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '· ${(payload.confidence * 100).round()}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: tokens.textTertiary,
                fontSize: 10,
              ),
            ),
            if (lineInfo != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  lineInfo,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.textTertiary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ] else
              const Spacer(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
              size: 14,
              color: tokens.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.message,
    required this.payload,
    required this.fetchFileContent,
    required this.prNumber,
    required this.onFix,
    required this.onComment,
    required this.onDismiss,
    required this.dismissing,
    required this.tokens,
    required this.theme,
  });

  final ChannelMessage message;
  final ReviewNodePayload payload;
  final Future<String> Function(String path)? fetchFileContent;
  final int? prNumber;
  final VoidCallback onFix;
  final VoidCallback onComment;
  final VoidCallback? onDismiss;
  final bool dismissing;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final canComment = payload.anchor.filePath != null &&
        payload.anchor.lineNumber != null;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.borderSecondary)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.content.isNotEmpty)
            GitHubMarkdownBody(
              data: message.content,
              styleSheet: githubMarkdownStyleSheet(context, compact: true),
              builders: {
                'code': InlineCodeBuilder(),
                'pre': CodeBlockBuilder(),
              },
            ),
          if (payload.anchor.hasAnchor &&
              fetchFileContent != null &&
              payload.anchor.filePath != null) ...[
            const SizedBox(height: 10),
            AnchoredCodeBlock(
              filePath: payload.anchor.filePath!,
              lineNumber: payload.anchor.lineNumber ?? 1,
              lineEnd: payload.anchor.lineEnd,
              fetchFileContent: fetchFileContent!,
              prNumber: prNumber,
            ),
          ],
          if (payload.confirmedBy.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l10n.confirmedBy,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final id in payload.confirmedBy)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.bgBrandPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '@$id',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.fgBrandPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.primary,
                onPressed: onFix,
                icon: AppIcons.wrench,
                child: Text(l10n.fix),
              ),
              const SizedBox(width: 8),
              if (!canComment)
                CcTooltip(
                  message: l10n.noFileAnchor,
                  child: CcButton(
                    size: CcButtonSize.sm,
                    variant: CcButtonVariant.secondary,
                    onPressed: null,
                    icon: AppIcons.messageSquarePlus,
                    child: Text(l10n.comment),
                  ),
                )
              else
                CcButton(
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.secondary,
                  onPressed: onComment,
                  icon: AppIcons.messageSquarePlus,
                  child: Text(l10n.comment),
                ),
              const SizedBox(width: 8),
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                onPressed: onDismiss,
                loading: dismissing,
                icon: AppIcons.x,
                child: Text(l10n.dismissed),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
