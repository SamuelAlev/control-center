import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/reaction_group.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class ReactionBar extends StatefulWidget {
  const ReactionBar({
    super.key,
    required this.reactions,
    required this.onToggle,
  });

  final List<ReactionGroup> reactions;
  final Future<void> Function(String content, {required bool add}) onToggle;

  @override
  State<ReactionBar> createState() => _ReactionBarState();
}

class _ReactionBarState extends State<ReactionBar> {
  List<ReactionGroup>? _optimistic;
  bool _pending = false;

  List<ReactionGroup> get _current => _optimistic ?? widget.reactions;

  @override
  void didUpdateWidget(covariant ReactionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pending) {
      _optimistic = null;
    }
  }

  Future<void> _handleToggle(String content, bool add) async {
    final prev = _current;
    setState(() {
      _pending = true;
      _optimistic = _applyOptimistic(prev, content, add);
    });
    try {
      await widget.onToggle(content, add: add);
    } on Exception {
      if (mounted) {
        setState(() {
          _optimistic = prev;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
        });
      }
    }
  }

  static List<ReactionGroup> _applyOptimistic(
    List<ReactionGroup> reactions,
    String content,
    bool add,
  ) {
    final idx = reactions.indexWhere((g) => g.content == content);
    if (add) {
      if (idx >= 0) {
        final g = reactions[idx];
        return List.from(reactions)
          ..[idx] = g.copyWith(
            count: g.count + 1,
            userReacted: true,
          );
      }
      final emoji = ReactionGroup.emojiForContent(content);
      return [
        ...reactions,
        ReactionGroup(
          content: content,
          emoji: emoji,
          count: 1,
          userReacted: true,
        ),
      ];
    } else {
      if (idx < 0) {
        return reactions;
      }
      final g = reactions[idx];
      if (g.count <= 1) {
        return [...reactions]..removeAt(idx);
      }
      return List.from(reactions)
        ..[idx] = g.copyWith(
          count: g.count - 1,
          userReacted: false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reactions = _current;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final group in reactions)
          _ReactionChip(
            group: group,
            onTap: () => _handleToggle(group.content, !group.userReacted),
          ),
        _ReactionPopoverChip(
          onSelected: (content) => _handleToggle(content, true),
        ),
      ],
    );
  }
}

class _ReactionPopoverChip extends StatelessWidget {
  const _ReactionPopoverChip({required this.onSelected});

  final void Function(String content) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return FPopover(
      popoverAnchor: Alignment.topLeft,
      childAnchor: Alignment.bottomLeft,
      style: FPopoverStyle(
        popoverPadding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: theme.colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: theme.colors.border),
          boxShadow: AppShadows.golden,
        ),
      ),
      hideRegion: FPopoverHideRegion.excludeChild,
      popoverBuilder: (context, controller) => _ReactionGrid(
        onSelected: (content) {
          onSelected(content);
          controller.hide();
        },
      ),
      builder: (context, controller, child) => GestureDetector(
        onTap: controller.toggle,
        child: child,
      ),
      child: _AddReactionChipBody(),
    );
  }
}

class _ReactionGrid extends StatelessWidget {
  const _ReactionGrid({required this.onSelected});

  final void Function(String content) onSelected;

  @override
  Widget build(BuildContext context) {
    const reactions = ReactionGroup.supportedReactions;
    const columns = 4;
    final rows = (reactions.length / columns).ceil();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (row) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(columns, (col) {
            final idx = row * columns + col;
            if (idx >= reactions.length) {
              return const SizedBox(width: 36, height: 36);
            }
            final r = reactions[idx];
            return FTappable.static(
              onPress: () => onSelected(r.content),
              focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
              child: FTooltip(
                tipBuilder: (_, _) => Text(r.content),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Text(
                        r.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.group, required this.onTap});

  final ReactionGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final tokens = context.designSystem;
    final accent = tokens?.fgBrandPrimary ?? const Color(0xFFfa520f);
    final bgColor = group.userReacted
        ? accent.withValues(alpha: 0.12)
        : theme.colors.border.withValues(alpha: 0.5);
    final fgColor = group.userReacted ? accent : theme.colors.mutedForeground;

    String? tooltip;
    if (group.usernames.isNotEmpty) {
      tooltip = group.usernames.join(', ');
    }

    return FTooltip(
      tipBuilder: (_, _) => Text(tooltip ?? ''),
      child: FTappable.static(
        onPress: onTap,
        focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
              border: group.userReacted
                  ? Border.all(
                      color: accent.withValues(alpha: 0.4),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(group.emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 3),
                Text(
                  '${group.count}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddReactionChipBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: theme.colors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_emotions_outlined,
              size: 14,
              color: theme.colors.mutedForeground,
            ),
            const SizedBox(width: 3),
            Text(
              AppLocalizations.of(context).react,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: theme.colors.mutedForeground,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
