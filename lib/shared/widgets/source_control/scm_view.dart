/// A VS Code-style Source Control surface, shared by the PR workbench and the
/// messaging IDE panel so both read identically: collapsible Staged changes
/// / Changes groups with per-group bulk actions and per-file rows that show
/// a two-line `basename` + dimmed `dir`, reveal their actions on hover and put
/// the single status letter (M/A/D/R) on the RIGHT — no checkboxes.
///
/// The building blocks ([ScmGroup] + [ScmFileRow]) are cc_ui-pure
/// (`flutter/widgets.dart` only) so they compose into either surface without
/// pulling in Material.
library;

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One hover/bulk action: an icon button with a tooltip. A null `onPressed`
/// renders it disabled (dimmed).
typedef ScmAction = ({IconData icon, String tooltip, VoidCallback? onPressed});

/// The (letter, color) status glyph for a changed file — the single source of
/// truth both source-control surfaces share.
(String, Color) scmStatusGlyph(PrFileStatus status, DesignSystemTokens t) {
  return switch (status) {
    PrFileStatus.added => ('A', t.success),
    PrFileStatus.modified => ('M', t.accent),
    PrFileStatus.removed => ('D', t.danger),
    PrFileStatus.renamed => ('R', t.textSecondary),
    PrFileStatus.unchanged => (' ', t.textTertiary),
  };
}

/// A collapsible source-control group ("Staged changes" / "Changes") with a
/// header (chevron + title + count + bulk [actions]) and its file rows.
class ScmGroup extends StatelessWidget {
  /// Creates an [ScmGroup].
  const ScmGroup({
    super.key,
    required this.title,
    required this.count,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.children,
    this.subtitle,
    this.subtitleWidget,
    this.syncLabel,
    this.headerTrailing,
    this.uppercaseTitle = true,
    this.actions = const [],
  });

  /// Group title, e.g. "Staged changes".
  final String title;

  /// An optional dimmed second line under the title — the checked-out branch
  /// when the group is a repository. Rendered verbatim (never upper-cased).
  /// Ignored when [subtitleWidget] is set.
  final String? subtitle;

  /// Replaces [subtitle] when the second line is itself a control, such as
  /// the branch picker. The header does not upper-case it.
  final Widget? subtitleWidget;

  /// Ahead/behind counts drawn after [subtitle] (`36↓ 0↑`). A git status
  /// glyph, so the header paints it left-to-right in every locale.
  final String? syncLabel;

  /// Controls on the title row, after the name and before the hover actions.
  /// The branch picker and the sync counts sit here.
  final Widget? headerTrailing;

  /// Section headers ("Changes") are small caps. A repository name is not —
  /// VS Code leaves that row in the repo's own casing.
  final bool uppercaseTitle;

  /// File count shown as a badge after the title.
  final int count;

  /// Whether the group body is collapsed.
  final bool collapsed;

  /// Toggles [collapsed].
  final VoidCallback onToggleCollapse;

  /// Bulk actions shown on the right of the header (stage all / unstage all /
  /// discard all). Rendered as hover-revealed icon buttons.
  final List<ScmAction> actions;

  /// The file rows (typically [ScmFileRow]s).
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScmGroupHeader(
          title: title,
          subtitle: subtitle,
          subtitleWidget: subtitleWidget,
          syncLabel: syncLabel,
          headerTrailing: headerTrailing,
          uppercaseTitle: uppercaseTitle,
          count: count,
          collapsed: collapsed,
          onToggleCollapse: onToggleCollapse,
          actions: actions,
          tokens: t,
        ),
        if (!collapsed) ...children,
      ],
    );
  }
}

class _ScmGroupHeader extends StatefulWidget {
  const _ScmGroupHeader({
    required this.title,
    required this.subtitle,
    required this.subtitleWidget,
    required this.syncLabel,
    required this.headerTrailing,
    required this.uppercaseTitle,
    required this.count,
    required this.collapsed,
    required this.onToggleCollapse,
    required this.actions,
    required this.tokens,
  });

  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final String? syncLabel;
  final Widget? headerTrailing;
  final bool uppercaseTitle;
  final int count;
  final bool collapsed;
  final VoidCallback onToggleCollapse;
  final List<ScmAction> actions;
  final DesignSystemTokens tokens;

  @override
  State<_ScmGroupHeader> createState() => _ScmGroupHeaderState();
}

class _ScmGroupHeaderState extends State<_ScmGroupHeader> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onToggleCollapse,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 5,
          ),
          child: Row(
            children: [
              Icon(
                widget.collapsed ? AppIcons.chevronRight : AppIcons.chevronDown,
                size: 16,
                color: t.textTertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.uppercaseTitle
                          ? widget.title.toUpperCase()
                          : widget.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: widget.uppercaseTitle ? 11 : 13,
                        fontWeight: widget.uppercaseTitle
                            ? FontWeight.w700
                            : FontWeight.w600,
                        letterSpacing: widget.uppercaseTitle ? 0.3 : 0,
                        color: widget.uppercaseTitle
                            ? t.textSecondary
                            : t.textPrimary,
                      ),
                    ),
                    if (widget.headerTrailing == null &&
                        (widget.subtitleWidget != null ||
                            (widget.subtitle != null &&
                                widget.subtitle!.isNotEmpty) ||
                            (widget.syncLabel != null &&
                                widget.syncLabel!.isNotEmpty)))
                      Row(
                        children: [
                          if (widget.subtitleWidget != null)
                            Flexible(child: widget.subtitleWidget!)
                          else if (widget.subtitle != null &&
                              widget.subtitle!.isNotEmpty)
                            Flexible(
                              child: Text(
                                widget.subtitle!,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: t.textTertiary,
                                ),
                              ),
                            ),
                          if (widget.syncLabel != null &&
                              widget.syncLabel!.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.sm),
                            // RTL carve-out: ahead/behind counts are a git
                            // status glyph (`36↓ 0↑`), not prose.
                            Text(
                              widget.syncLabel!,
                              textDirection: TextDirection.ltr,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: t.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
              if (widget.headerTrailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                widget.headerTrailing!,
              ],
              // Bulk actions appear on hover to keep the header quiet. Their
              // slot is always laid out (opacity, not presence) so revealing
              // them never shifts the title or the count badge.
              if (widget.actions.isNotEmpty)
                IgnorePointer(
                  ignoring: !_hovered,
                  child: Opacity(
                    opacity: _hovered ? 1 : 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final a in widget.actions)
                          ScmIconAction(action: a),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 4),
              _CountBadge(count: widget.count, tokens: t),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.tokens});

  final int count;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: tokens.hoverStrong,
        borderRadius: AppRadii.brSm,
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: tokens.textSecondary,
        ),
      ),
    );
  }
}

/// One changed-file row: two-line `basename` + dimmed `dir`, hover-revealed
/// [actions] and the single status letter on the RIGHT. Clicking the row runs
/// [onTap] (open the file / focus its diff).
class ScmFileRow extends StatefulWidget {
  /// Creates an [ScmFileRow].
  const ScmFileRow({
    super.key,
    required this.file,
    required this.selected,
    required this.onTap,
    this.actions = const [],
  });

  /// The changed file.
  final PrFile file;

  /// Whether this row is the focused/selected one (persistent highlight).
  final bool selected;

  /// Opens/focuses the file.
  final VoidCallback onTap;

  /// Hover-revealed row actions (stage / unstage / discard / open).
  final List<ScmAction> actions;

  @override
  State<ScmFileRow> createState() => _ScmFileRowState();
}

class _ScmFileRowState extends State<ScmFileRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final (letter, color) = scmStatusGlyph(widget.file.status, t);
    final name = widget.file.filename;
    final slash = name.lastIndexOf('/');
    final basename = slash >= 0 ? name.substring(slash + 1) : name;
    final dirname = slash >= 0 ? name.substring(0, slash) : '';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: widget.selected
              ? t.hover
              : (_hovered ? t.hoverStrong : const Color(0x00000000)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              4,
              AppSpacing.xs,
              4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        basename,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.selected
                              ? FontWeight.w600
                              : CcTypography.regularWeight,
                          color: t.textSecondary,
                        ),
                      ),
                      if (dirname.isNotEmpty)
                        Text(
                          dirname,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontSize: 10, color: t.textTertiary),
                        ),
                    ],
                  ),
                ),
                // Actions on hover; the status letter always trails on the right
                // (VS Code layout).
                if (_hovered)
                  for (final a in widget.actions) ScmIconAction(action: a),
                const SizedBox(width: 4),
                SizedBox(
                  width: 14,
                  child: Text(
                    letter,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
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

/// A compact text button for the repository header: branch name, sync counts.
///
/// When [onPressed] is null the chip is only a visual — the parent (a menu
/// trigger) owns the tap. A set callback is its own button and wins over the
/// header's collapse tap.
class ScmHeaderChip extends StatefulWidget {
  /// Creates an [ScmHeaderChip].
  const ScmHeaderChip({
    super.key,
    required this.semanticLabel,
    required this.child,
    this.onPressed,
    this.enabled = true,
  });

  /// Spoken name. Also the tooltip when this chip is itself a button.
  final String semanticLabel;

  /// The label, already direction-aware (a branch name or `19↓ 0↑`).
  final Widget child;

  /// Tap handler. Null when a parent control handles the press.
  final VoidCallback? onPressed;

  /// Dims the chip when a checkout or sync is already running.
  final bool enabled;

  @override
  State<ScmHeaderChip> createState() => _ScmHeaderChipState();
}

class _ScmHeaderChipState extends State<ScmHeaderChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final box = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.enabled && widget.onPressed != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _hovered && widget.enabled ? t.hover : const Color(0x00000000),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: t.borderSecondary),
        ),
        child: IconTheme(
          data: IconThemeData(
            size: 12,
            color: widget.enabled ? t.textTertiary : t.textDisabled,
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.enabled ? t.textSecondary : t.textTertiary,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
    if (widget.onPressed == null) {
      return box;
    }
    return CcTooltip(
      message: widget.semanticLabel,
      showDelay: const Duration(milliseconds: 400),
      child: CcTappable(
        onPressed: widget.enabled ? widget.onPressed : null,
        semanticLabel: widget.semanticLabel,
        borderRadius: BorderRadius.circular(4),
        builder: (context, _) => box,
      ),
    );
  }
}

/// A compact icon button for SCM row/header actions: a hover wash + rounded box,
/// a tooltip, dimmed when disabled. cc_ui-pure.
class ScmIconAction extends StatelessWidget {
  /// Creates an [ScmIconAction].
  const ScmIconAction({super.key, required this.action});

  /// The action to render.
  final ScmAction action;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final enabled = action.onPressed != null;
    return CcTooltip(
      message: action.tooltip,
      showDelay: const Duration(milliseconds: 400),
      child: CcTappable(
        onPressed: action.onPressed,
        semanticLabel: action.tooltip,
        borderRadius: BorderRadius.circular(4),
        builder: (context, states) => Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: states.contains(WidgetState.hovered)
                ? t.hover
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            action.icon,
            size: 14,
            color: enabled
                ? (states.contains(WidgetState.hovered)
                      ? t.fg
                      : t.textSecondary)
                : t.textTertiary,
          ),
        ),
      ),
    );
  }
}
