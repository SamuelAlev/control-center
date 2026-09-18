import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
part 'comment_inbox_chip.dart';

/// Toggle between unified and split diff views.
class ViewModeToggle extends StatelessWidget {
  /// Creates a [ViewModeToggle].
  const ViewModeToggle({
    super.key,
    required this.splitView,
    required this.onChanged,
  });

  /// Whether split view is currently active.
  final bool splitView;

  /// Called when the view mode changes.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ViewModeSegment(
            tooltip: AppLocalizations.of(context).unifiedDiff,
            icon: AppIcons.alignJustify,
            active: !splitView,
            onTap: () => onChanged(false),
          ),
          ViewModeSegment(
            tooltip: AppLocalizations.of(context).splitDiff,
            icon: AppIcons.columns,
            active: splitView,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

/// A single segment button within the view mode toggle.
class ViewModeSegment extends StatelessWidget {
  /// Creates a [ViewModeSegment].
  const ViewModeSegment({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  /// Tooltip text for this segment.
  final String tooltip;

  /// Icon for this segment.
  final IconData icon;

  /// Whether this segment is the active one.
  final bool active;

  /// Called when this segment is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return CcTooltip(
      message: tooltip,
      child: CcTappable(
        // The selected segment is not actionable, so it renders disabled —
        // the `active` styling below still carries the selection.
        onPressed: active ? null : onTap,
        semanticLabel: tooltip,
        builder: (context, states) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: active
              ? tokens.textPrimary
              : (states.contains(WidgetState.hovered)
                    ? tokens.hover
                    : const Color(0x00000000)),
          child: Icon(
            icon,
            size: 14,
            color: active
                ? tokens.bgPrimary
                : (states.contains(WidgetState.hovered)
                      ? tokens.textPrimary
                      : tokens.textTertiary),
          ),
        ),
      ),
    );
  }
}

/// A chip showing the inline comment count; tapping it opens the comment inbox.

class CommentCountChip extends StatelessWidget {
  /// Creates a [CommentCountChip].
  const CommentCountChip({super.key, required this.count});

  /// Number of comments to display.
  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.messageSquare, size: 13, color: tokens.textTertiary),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: CcTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: tokens.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// A chip indicating that new commits are available; tapping it refreshes the diff.
class DiffUpdateChip extends StatelessWidget {
  /// Creates a [DiffUpdateChip].
  const DiffUpdateChip({super.key, required this.onRefresh});

  /// Called when the chip is tapped to refresh the diff.
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveDesignTokens(context);
    return CcTooltip(
      message: AppLocalizations.of(context).newCommitsPushed,
      child: CcTappable(
        onPressed: onRefresh,
        borderRadius: BorderRadius.circular(999),
        builder: (context, states) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F75FE).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFF1F75FE).withValues(alpha: 0.3),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.refreshCw, size: 13, color: tokens.textPrimary),
              const SizedBox(width: 6),
              Text(
                'New changes — Refresh diff',
                style: CcTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
