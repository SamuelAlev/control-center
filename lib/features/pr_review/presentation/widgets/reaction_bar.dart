import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/domain/entities/reaction_group.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A bar of reaction chips with an add-reaction button.
class ReactionBar extends StatefulWidget {
  /// Creates a [ReactionBar].
  const ReactionBar({
    super.key,
    required this.reactions,
    required this.onToggle,
  });

  /// Current reaction groups.
  final List<ReactionGroup> reactions;

  /// Called to toggle a reaction on or off. Returns a future that completes when the server round-trip finishes.
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
          ..[idx] = g.copyWith(count: g.count + 1, userReacted: true);
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
        ..[idx] = g.copyWith(count: g.count - 1, userReacted: false);
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

class _ReactionPopoverChip extends StatefulWidget {
  const _ReactionPopoverChip({required this.onSelected});

  final void Function(String content) onSelected;

  @override
  State<_ReactionPopoverChip> createState() => _ReactionPopoverChipState();
}

class _ReactionPopoverChipState extends State<_ReactionPopoverChip> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcPopover(
      controller: _controller,
      overlayBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(6),
        child: _ReactionGrid(
          onSelected: (content) {
            widget.onSelected(content);
            _controller.hide();
          },
        ),
      ),
      target: _AddReactionChipBody(),
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
            return CcTappable(
              onPressed: () => onSelected(r.content),
              builder: (context, states) => CcTooltip(
                message: r.content,
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final accent = tokens.fgBrandPrimary;
    final bgColor = group.userReacted
        ? accent.withValues(alpha: 0.12)
        : tokens.borderSecondary.withValues(alpha: 0.5);
    final fgColor = group.userReacted ? accent : tokens.muted;

    String? tooltip;
    if (group.usernames.isNotEmpty) {
      tooltip = group.usernames.join(', ');
    }

    return CcTooltip(
      message: tooltip ?? '',
      child: CcTappable(
        onPressed: onTap,
        builder: (context, states) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
              border: group.userReacted
                  ? Border.all(color: accent.withValues(alpha: 0.4))
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: tokens.borderSecondary.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_emotions_outlined,
              size: 14,
              color: tokens.muted,
            ),
            const SizedBox(width: 3),
            Text(
              AppLocalizations.of(context).react,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.muted,
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
