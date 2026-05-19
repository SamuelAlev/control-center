import 'package:control_center/features/pr_review/domain/entities/issue_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({super.key, required this.splitView, required this.onChanged});
  final bool splitView;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.colors.secondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.theme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ViewModeSegment(
            tooltip: AppLocalizations.of(context).unifiedDiff,
            icon: LucideIcons.alignJustify,
            active: !splitView,
            onTap: () => onChanged(false),
          ),
          ViewModeSegment(
            tooltip: AppLocalizations.of(context).splitDiff,
            icon: LucideIcons.columns,
            active: splitView,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class ViewModeSegment extends StatelessWidget {
  const ViewModeSegment({super.key, 
    required this.tooltip,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: active ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: active ? theme.colors.foreground : Colors.transparent,
            child: Icon(
              icon,
              size: 14,
              color: active
                  ? theme.colors.background
                  : theme.colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class CommentInboxChip extends StatefulWidget {
  const CommentInboxChip({super.key, 
    required this.count,
    required this.controller,
    this.issueComments = const [],
    this.reviewComments = const [],
  });
  final int count;
  final PrInlineCommentsController controller;
  final List<IssueComment> issueComments;
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

class CommentCountChip extends StatelessWidget {
  const CommentCountChip({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.secondary.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: 13,
            color: theme.colors.mutedForeground,
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colors.foreground,
             ),
           ),
         ],
       ),
     );
   }
}

class DiffUpdateChip extends StatelessWidget {
  const DiffUpdateChip({super.key, required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return FTooltip(
      tipBuilder: (_, _) =>
          Text(AppLocalizations.of(context).newCommitsPushed),
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
                LucideIcons.refreshCw,
                size: 13,
                color: theme.colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'New changes — Refresh diff',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
