import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/ide_sidebar_prefs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Width of one icon cell in the strip.
const double _cellWidth = 34;

/// Width of the trailing overflow caret, which is always present.
const double _caretWidth = 30;

/// Icon size inside a strip cell — matches the glyph size `CcTabs` uses, so the
/// sidebar rail and the editor tab strip on the other side of the divider read
/// as one family.
const double _glyphSize = 15;

/// Hover dwell before a cell names itself.
///
/// Shorter than the design system's 500ms default: on a labelled tab strip the
/// tooltip is supplemental, but here the glyph is the only visible name, so the
/// dwell is the cost of reading the rail. Assistive tech reads the same string
/// off the cell's accessible name and never waits.
const Duration _nameDwell = Duration(milliseconds: 250);

/// The icon rail that selects the messaging IDE sidebar's panel.
///
/// Replaces a labelled tab bar, which could not fit six panels into a 200px
/// sidebar. Each pinned view gets a square, icon-only cell (named by tooltip
/// and by its accessible label); the trailing caret opens a menu listing every
/// view, whatever fits or not, with a pin toggle per row.
///
/// Three rules keep the rail honest:
/// * The **active view always has a cell**, even when it is unpinned or would
///   fall past the fold, so the selection underline always has something to sit
///   on.
/// * **Order is canonical** ([IdeSidebarView]'s declaration order). Pinning
///   never reshuffles the rail, it only adds or removes a cell.
/// * **Overflow is width-driven**, not a fixed cap: pinned views that do not
///   fit the measured width move into the caret menu and come back when the
///   sidebar is widened.
class IdeSidebarViewStrip extends ConsumerStatefulWidget {
  /// Creates an [IdeSidebarViewStrip].
  const IdeSidebarViewStrip({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// The view whose panel is currently rendered below the strip.
  final IdeSidebarView selected;

  /// Called with the view a cell (or a menu row) selects.
  final ValueChanged<IdeSidebarView> onChanged;

  @override
  ConsumerState<IdeSidebarViewStrip> createState() =>
      _IdeSidebarViewStripState();
}

class _IdeSidebarViewStripState extends ConsumerState<IdeSidebarViewStrip> {
  final FocusScopeNode _scopeNode = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  late final Map<IdeSidebarView, FocusNode> _cellNodes = {
    for (final view in IdeSidebarView.values) view: FocusNode(),
  };
  final CcOverlayController _menu = CcOverlayController();

  /// The cells laid out by the last build, in render order. Arrow-key
  /// navigation walks this list, so it stays in step with what is on screen at
  /// the current sidebar width.
  List<IdeSidebarView> _visible = const [];

  @override
  void dispose() {
    for (final node in _cellNodes.values) {
      node.dispose();
    }
    _scopeNode.dispose();
    _menu.dispose();
    super.dispose();
  }

  void _select(IdeSidebarView view) {
    widget.onChanged(view);
    // Roving tabindex: move focus onto the newly-selected cell after the
    // rebuild that gives it one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cellNodes[view]?.requestFocus();
      }
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _visible.isEmpty) {
      return KeyEventResult.ignored;
    }
    // The active view is guaranteed a cell, so it is always in `_visible`.
    final current = _visible.indexOf(widget.selected);
    if (current < 0) {
      return KeyEventResult.ignored;
    }
    final count = _visible.length;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.arrowDown:
        _select(_visible[(current + 1) % count]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowUp:
        _select(_visible[(current - 1) % count]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _select(_visible.first);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _select(_visible.last);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Splits the rail into the cells that fit [width] and the ones that spill
  /// into the caret menu.
  ///
  /// [pinned] plus the active view (which is never dropped) form the rail; the
  /// first `width`-worth of them get cells. When the active view lands past the
  /// fold it evicts the last cell that fit, then the survivors are re-sorted so
  /// a cell never jumps position just because the selection moved.
  ({List<IdeSidebarView> cells, List<IdeSidebarView> hidden}) _split(
    Set<IdeSidebarView> pinned,
    double width,
  ) {
    final rail = [
      for (final view in IdeSidebarView.values)
        if (pinned.contains(view) || view == widget.selected) view,
    ];
    final fits = ((width - _caretWidth) / _cellWidth).floor().clamp(
      0,
      rail.length,
    );
    final cells = rail.take(fits).toList();
    if (!cells.contains(widget.selected)) {
      if (cells.isNotEmpty) {
        cells.removeLast();
      }
      cells
        ..add(widget.selected)
        ..sort((a, b) => a.index.compareTo(b.index));
    }
    return (
      cells: cells,
      hidden: [
        for (final view in rail)
          if (!cells.contains(view)) view,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final pinned = ref.watch(ideSidebarPinsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final split = _split(pinned, constraints.maxWidth);
        // Read during the next key event, not during layout — assigning here
        // keeps keyboard navigation in step with the rendered cells without a
        // second measure pass.
        _visible = split.cells;

        return Semantics(
          container: true,
          explicitChildNodes: true,
          child: FocusScope(
            node: _scopeNode,
            child: Focus(
              canRequestFocus: false,
              onKeyEvent: _onKey,
              child: Container(
                height: EditorTabBar.height,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.borderPrimary)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The cells take the width the caret leaves. `_split`
                    // already reserves the caret's width, so at any width the
                    // sidebar can actually be dragged to there is nothing to
                    // scroll; the scroll view is the safety net that turns an
                    // impossible width (below ~64px) into a scrollable rail
                    // instead of a flex-overflow assertion and it keeps the
                    // caret whole there because the caret is the only route to
                    // a view that has no cell.
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final view in split.cells)
                              _ViewCell(
                                view: view,
                                label: _viewLabel(l10n, view),
                                selected: view == widget.selected,
                                focusNode: _cellNodes[view],
                                tokens: t,
                                onPressed: () => _select(view),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _OverflowButton(
                      controller: _menu,
                      hiddenCount: split.hidden.length,
                      tokens: t,
                      selected: widget.selected,
                      pinned: pinned,
                      onSelectView: (view) {
                        _menu.hide();
                        _select(view);
                      },
                      onTogglePin: (view) => ref
                          .read(ideSidebarPinsProvider.notifier)
                          .toggle(view),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The human name of [view] — the cell tooltip, the accessible name and the
/// menu row label all read from here so they can never drift apart.
String _viewLabel(AppLocalizations l10n, IdeSidebarView view) => switch (view) {
  IdeSidebarView.general => l10n.ideTabGeneral,
  IdeSidebarView.explorer => l10n.ideTabExplorer,
  IdeSidebarView.sourceControl => l10n.ideTabSourceControl,
  IdeSidebarView.pullRequests => l10n.ideTabPullRequests,
  IdeSidebarView.notes => l10n.ideTabNotes,
  IdeSidebarView.artifacts => l10n.artifactsTabLabel,
};

/// The glyph of [view], shared by its rail cell and its menu row.
IconData viewIcon(IdeSidebarView view) => switch (view) {
  IdeSidebarView.general => AppIcons.layoutDashboard,
  IdeSidebarView.explorer => AppIcons.folderTree,
  IdeSidebarView.sourceControl => AppIcons.gitBranch,
  IdeSidebarView.pullRequests => AppIcons.gitPullRequest,
  IdeSidebarView.notes => AppIcons.notebookText,
  IdeSidebarView.artifacts => AppIcons.layoutTemplate,
};

/// One icon-only cell in the rail. Selection is carried by the 2px accent
/// underline, the ink-strong glyph and the `selected` semantic — never by
/// color alone.
class _ViewCell extends StatelessWidget {
  const _ViewCell({
    required this.view,
    required this.label,
    required this.selected,
    required this.focusNode,
    required this.tokens,
    required this.onPressed,
  });

  final IdeSidebarView view;
  final String label;
  final bool selected;
  final FocusNode? focusNode;
  final DesignSystemTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final duration = CcMotion.resolve(context, CcMotion.fast);
    return CcTooltip(
      message: label,
      showDelay: _nameDwell,
      child: Semantics(
        selected: selected,
        child: SizedBox(
          width: _cellWidth,
          child: CcTappable(
            onPressed: onPressed,
            focusNode: focusNode,
            // Roving tabindex: Tab lands on the selected cell, arrows move.
            canRequestFocus: selected,
            borderRadius: AppRadii.brSm,
            semanticLabel: label,
            builder: (context, states) {
              final hovered = states.contains(WidgetState.hovered);
              final pressed = states.contains(WidgetState.pressed);
              final Color background;
              if (pressed) {
                background = t.hoverStrong;
              } else if (hovered && !selected) {
                background = t.hover;
              } else {
                background = t.hover.withValues(alpha: 0);
              }
              final foreground = selected
                  ? t.fg
                  : (hovered ? t.fgSecondary : t.textTertiary);
              return AnimatedContainer(
                duration: duration,
                curve: CcMotion.standard,
                decoration: BoxDecoration(color: background),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        viewIcon(view),
                        size: _glyphSize,
                        color: foreground,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 2,
                      child: AnimatedOpacity(
                        duration: duration,
                        curve: CcMotion.standard,
                        opacity: selected ? 1 : 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: t.accent),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The trailing caret: opens the full view list and doubles as the pin manager.
///
/// Always present, not only when something overflows, because it is the only
/// way back to a view the operator has unpinned. How many views are currently
/// folded away is carried by the tooltip text, not by a color change.
class _OverflowButton extends StatelessWidget {
  const _OverflowButton({
    required this.controller,
    required this.hiddenCount,
    required this.tokens,
    required this.selected,
    required this.pinned,
    required this.onSelectView,
    required this.onTogglePin,
  });

  final CcOverlayController controller;
  final int hiddenCount;
  final DesignSystemTokens tokens;
  final IdeSidebarView selected;
  final Set<IdeSidebarView> pinned;
  final ValueChanged<IdeSidebarView> onSelectView;
  final ValueChanged<IdeSidebarView> onTogglePin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = tokens;
    final label = hiddenCount == 0
        ? l10n.ideSidebarAllViews
        : l10n.ideSidebarAllViewsHidden(hiddenCount);

    return CcPopover(
      controller: controller,
      // The trigger paints its own hover/open states, so it drives the
      // controller itself rather than being wrapped in the popover's tappable.
      toggleOnTargetTap: false,
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final view in IdeSidebarView.values)
                _ViewMenuRow(
                  view: view,
                  label: _viewLabel(l10n, view),
                  active: view == selected,
                  pinned: pinned.contains(view),
                  tokens: t,
                  onSelected: () => onSelectView(view),
                  onTogglePin: () => onTogglePin(view),
                ),
            ],
          ),
        ),
      ),
      target: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final open = controller.isOpen;
          return CcTooltip(
            message: label,
            showDelay: _nameDwell,
            child: SizedBox(
              width: _caretWidth,
              child: CcTappable(
                onPressed: controller.toggle,
                borderRadius: AppRadii.brSm,
                semanticLabel: label,
                builder: (context, states) {
                  final hovered = states.contains(WidgetState.hovered);
                  final pressed = states.contains(WidgetState.pressed);
                  final Color background;
                  if (pressed || open) {
                    background = t.hoverStrong;
                  } else if (hovered) {
                    background = t.hover;
                  } else {
                    background = t.hover.withValues(alpha: 0);
                  }
                  return AnimatedContainer(
                    duration: CcMotion.resolve(context, CcMotion.fast),
                    curve: CcMotion.standard,
                    decoration: BoxDecoration(color: background),
                    child: Center(
                      child: Icon(
                        open ? AppIcons.chevronUp : AppIcons.chevronDown,
                        size: _glyphSize,
                        color: hovered || open ? t.fgSecondary : t.textTertiary,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One row of the caret menu: pick the view, or pin/unpin it.
///
/// The label and the pin are **siblings**, not a button inside a button, so a
/// tap on the pin can never be swallowed by the row. The row's hover wash is
/// owned by an outer [MouseRegion] so hovering the label also reveals the pin.
class _ViewMenuRow extends StatefulWidget {
  const _ViewMenuRow({
    required this.view,
    required this.label,
    required this.active,
    required this.pinned,
    required this.tokens,
    required this.onSelected,
    required this.onTogglePin,
  });

  final IdeSidebarView view;
  final String label;
  final bool active;
  final bool pinned;
  final DesignSystemTokens tokens;
  final VoidCallback onSelected;
  final VoidCallback onTogglePin;

  @override
  State<_ViewMenuRow> createState() => _ViewMenuRowState();
}

class _ViewMenuRowState extends State<_ViewMenuRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final foreground = widget.active || _hovered ? t.fg : t.fgSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: CcMotion.resolve(context, CcMotion.fast),
        curve: CcMotion.standard,
        height: 32,
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.xs,
        ),
        color: widget.active
            ? t.hoverStrong
            : (_hovered ? t.hover : t.hover.withValues(alpha: 0)),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                selected: widget.active,
                child: CcTappable(
                  onPressed: widget.onSelected,
                  semanticLabel: widget.label,
                  borderRadius: AppRadii.brSm,
                  builder: (context, states) => Row(
                    children: [
                      Icon(viewIcon(widget.view), size: 16, color: foreground),
                      AppSpacing.hGapSm,
                      Expanded(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: CcTypography.regularWeight,
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _PinToggle(
              pinned: widget.pinned,
              rowHovered: _hovered,
              tokens: t,
              onPressed: widget.onTogglePin,
            ),
          ],
        ),
      ),
    );
  }
}

/// The per-row pin toggle.
///
/// Pinned reads as a pressed toolbar toggle: a filled square behind an
/// ink-strong pin, always visible, so pin state is carried by fill and
/// presence rather than by color alone. Unpinned is a bare, quiet glyph that
/// appears on row hover or when the toggle itself takes keyboard focus — the
/// focus case is what keeps it off the hover-only list.
class _PinToggle extends StatelessWidget {
  const _PinToggle({
    required this.pinned,
    required this.rowHovered,
    required this.tokens,
    required this.onPressed,
  });

  final bool pinned;
  final bool rowHovered;
  final DesignSystemTokens tokens;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = tokens;
    final label = pinned ? l10n.ideSidebarUnpinView : l10n.ideSidebarPinView;

    return CcTooltip(
      message: label,
      placement: CcTooltipPlacement.left,
      child: CcTappable(
        onPressed: onPressed,
        borderRadius: AppRadii.brSm,
        semanticLabel: label,
        builder: (context, states) {
          final visible =
              pinned || rowHovered || states.contains(WidgetState.focused);
          final hovered = states.contains(WidgetState.hovered);
          return AnimatedOpacity(
            duration: CcMotion.resolve(context, CcMotion.fast),
            curve: CcMotion.standard,
            opacity: visible ? 1 : 0,
            // An invisible glyph must not be a live click target; keyboard
            // focus still reaches it, which is what reveals it.
            child: IgnorePointer(
              ignoring: !visible,
              child: Semantics(
                toggled: pinned,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: pinned
                        ? (hovered ? t.hoverStrong : t.hover)
                        : (hovered ? t.hover : t.hover.withValues(alpha: 0)),
                  ),
                  child: Icon(
                    // At rest the glyph reports state (a pin means pinned); on
                    // hover it previews the consequence (a struck-through pin
                    // means this click unpins), so the toggle never relies on
                    // fill alone to say which way it will go.
                    pinned && hovered ? AppIcons.pinOff : AppIcons.pin,
                    size: 14,
                    color: pinned ? t.fg : t.textTertiary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
