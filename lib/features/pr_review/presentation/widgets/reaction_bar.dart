import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Shared pill geometry: reaction chips and the add-reaction pill must render
/// at exactly the same height, so both containers fix it here instead of
/// deriving it from their (differently sized) contents.
const double _kChipHeight = 22;
const EdgeInsets _kChipPadding = EdgeInsets.symmetric(horizontal: 7);

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
      crossAxisAlignment: WrapCrossAlignment.center,
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
      // We own the trigger tap (toggleOnTargetTap: false) because CcPopover's
      // built-in trigger swallows the interaction states; our own CcTappable
      // hands them to the pill so it can paint its hover/pressed treatment.
      toggleOnTargetTap: false,
      overlayBuilder: (context, _) => Padding(
        padding: const EdgeInsets.all(6),
        child: _ReactionGrid(
          onSelected: (content) {
            widget.onSelected(content);
            _controller.hide();
          },
        ),
      ),
      target: CcTappable(
        onPressed: _controller.toggle,
        borderRadius: BorderRadius.circular(999),
        semanticLabel: AppLocalizations.of(context).reactionAddTooltip,
        builder: (context, states) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) =>
              _AddReactionChipBody(states: states, open: _controller.isOpen),
        ),
      ),
    );
  }
}

class _ReactionGrid extends StatelessWidget {
  const _ReactionGrid({required this.onSelected});

  final void Function(String content) onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
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
              builder: (context, states) {
                final hovered = states.contains(WidgetState.hovered);
                return CcTooltip(
                  message: r.content,
                  child: AnimatedContainer(
                    duration: CcMotion.resolve(context, CcMotion.fast),
                    curve: CcMotion.standard,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      // Alpha-0 (not transparent-black) so the wash lerps in.
                      color: hovered ? tokens.hover : const Color(0x00000000),
                    ),
                    child: Center(
                      child: Text(
                        r.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                );
              },
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

    String? tooltip;
    if (group.usernames.isNotEmpty) {
      tooltip = group.usernames.join(', ');
    }

    return CcTooltip(
      message: tooltip ?? '',
      child: CcTappable(
        onPressed: onTap,
        borderRadius: BorderRadius.circular(999),
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final pressed = states.contains(WidgetState.pressed);

          final Color bg;
          final Color fg;
          final Color border;
          if (group.userReacted) {
            bg = accent.withValues(
              alpha: pressed
                  ? 0.24
                  : hovered
                  ? 0.18
                  : 0.12,
            );
            fg = accent;
            border = accent.withValues(alpha: hovered || pressed ? 0.6 : 0.4);
          } else {
            bg = pressed
                ? tokens.hoverStrong
                : hovered
                ? tokens.hover
                : tokens.borderSecondary.withValues(alpha: 0.5);
            fg = hovered || pressed ? tokens.fg : tokens.muted;
            // Alpha-0 border (not null) so the AnimatedContainer lerps.
            border = const Color(0x00000000);
          }

          Widget child = AnimatedContainer(
            duration: CcMotion.resolve(context, CcMotion.fast),
            curve: CcMotion.standard,
            height: _kChipHeight,
            padding: _kChipPadding,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 12px emoji ≈ the optical size of the 14px outline icon in
                // the add-reaction pill (emoji glyphs overshoot their point
                // size); height 1 keeps the line box from inflating the pill.
                Text(
                  group.emoji,
                  style: const TextStyle(fontSize: 12, height: 1),
                ),
                const SizedBox(width: 3),
                Text(
                  '${group.count}',
                  style: CcTypography.caption.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
              ],
            ),
          );

          if (pressed) {
            child = Transform.translate(
              offset: const Offset(0, 1),
              child: child,
            );
          }

          return child;
        },
      ),
    );
  }
}

class _AddReactionChipBody extends StatelessWidget {
  const _AddReactionChipBody({required this.states, required this.open});

  /// Live interaction states from the trigger's [CcTappable].
  final Set<WidgetState> states;

  /// Whether the reaction popover is open; keeps the pill lit while it is.
  final bool open;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final hovered = states.contains(WidgetState.hovered);
    final pressed = states.contains(WidgetState.pressed);
    final active = hovered || open;

    // State-Token Rule: hover is an ink wash, pressed the stronger wash and
    // the border strengthens to line-strong, like a secondary button.
    final Color bg = pressed
        ? tokens.hoverStrong
        : active
        ? tokens.hover
        // Alpha-0 (not transparent-black) so the AnimatedContainer lerps.
        : const Color(0x00000000);
    final Color border = active
        ? tokens.lineStrong
        : tokens.borderSecondary.withValues(alpha: 0.5);
    final Color fg = active ? tokens.fg : tokens.muted;

    Widget child = AnimatedContainer(
      duration: CcMotion.resolve(context, CcMotion.fast),
      curve: CcMotion.standard,
      height: _kChipHeight,
      padding: _kChipPadding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_emotions_outlined, size: 14, color: fg),
          const SizedBox(width: 3),
          Text(
            AppLocalizations.of(context).react,
            style: CcTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1,
            ),
          ),
        ],
      ),
    );

    // Flat 1px press nudge, same vocabulary as CcButton.
    if (pressed) {
      child = Transform.translate(offset: const Offset(0, 1), child: child);
    }

    return child;
  }
}
