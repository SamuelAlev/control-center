import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
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
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    return CcTooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: active ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: active ? tokens.textPrimary : Colors.transparent,
            child: Icon(
              icon,
              size: 14,
              color: active ? tokens.bgPrimary : tokens.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A chip showing the inline comment count; tapping it opens the comment inbox.
class CommentInboxChip extends StatefulWidget {
  /// Creates a [CommentInboxChip].
  const CommentInboxChip({
    super.key,
    required this.count,
    required this.controller,
    this.issueComments = const [],
    this.reviewComments = const [],
  });

  /// Number of inline comments.
  final int count;

  /// Controller for inline comment state.
  final PrInlineCommentsController controller;

  /// Issue-level comments to display in the inbox.
  final List<IssueComment> issueComments;

  /// Review-level comments to display in the inbox.
  final List<PrCodeReviewComment> reviewComments;
  @override
  State<CommentInboxChip> createState() => _CommentInboxChipState();
}

class _CommentInboxChipState extends State<CommentInboxChip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _toggle() {
    if (_overlay != null) {
      _close();
    } else {
      _open();
    }
  }

  void _open() {
    _overlay = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggle,
        borderRadius: BorderRadius.circular(999),
        child: CommentCountChip(count: widget.count),
      ),
    );
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 8),
          child: Consumer(
            builder: (context, ref, _) {
              final ctl = widget.controller;
              final cs = ref.watch(
                prInlineCommentsControllerProvider(ctl.prNumber),
              );
              return PrCommentsInbox(
                threads: cs.threads,
                onToggleResolved: ctl.toggleResolved,
                onClose: _close,
                issueComments: widget.issueComments,
                reviewComments: widget.reviewComments,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A non-interactive chip displaying the comment count.
class CommentCountChip extends StatelessWidget {
  /// Creates a [CommentCountChip].
  const CommentCountChip({super.key, required this.count});

  /// Number of comments to display.
  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.messageSquare,
            size: 13,
            color: tokens.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    return CcTooltip(
      message: AppLocalizations.of(context).newCommitsPushed,
      child: InkWell(
        onTap: onRefresh,
        borderRadius: BorderRadius.circular(999),
        child: Container(
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
              Icon(
                AppIcons.refreshCw,
                size: 13,
                color: tokens.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'New changes — Refresh diff',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
