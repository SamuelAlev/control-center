import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One quick open result: `<basename>` prominent with `<folder>` dimmed beside
/// it (the Explorer's flat-list idiom). The selected row reveals its actions —
/// open to the side, and for a recent file the "Recently opened" tag plus a
/// button that forgets it.
class QuickOpenRow extends StatelessWidget {
  /// Creates a result row.
  const QuickOpenRow({
    super.key,
    required this.repoId,
    required this.path,
    required this.recent,
    required this.selected,
    required this.query,
    required this.onOpen,
    required this.onOpenToSide,
    required this.onHover,
    this.onRemove,
  });

  /// Fixed row extent; the picker sizes and scrolls its list by it.
  static const double height = 32;

  /// The file's repo (empty when unknown).
  final String repoId;

  /// The file's repo-relative path.
  final String path;

  /// Whether the row comes from the recently opened list.
  final bool recent;

  /// Whether the row is the keyboard/hover selection.
  final bool selected;

  /// The typed query, highlighted in the file name.
  final String query;

  /// Opens the file in a tab of the active pane.
  final VoidCallback onOpen;

  /// Opens the file in a new pane to the side.
  final VoidCallback onOpenToSide;

  /// Makes this row the selection.
  final VoidCallback onHover;

  /// Removes the file from the recent list; null for search hits.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final slash = path.lastIndexOf('/');
    final name = slash < 0 ? path : path.substring(slash + 1);
    final dir = slash < 0 ? '' : path.substring(0, slash);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHover(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onOpen,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.sm,
            end: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: selected ? ds.hoverStrong : const Color(0x00000000),
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            children: [
              Icon(AppIcons.fileCode, size: 14, color: ds.textTertiary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: _HighlightedName(
                  name: name,
                  query: query,
                  style: CcTypography.bodySm.copyWith(color: ds.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                // RTL carve-out: a path reads left-to-right in any locale.
                child: Text(
                  dir,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.start,
                  style: CcTypography.caption.copyWith(color: ds.textTertiary),
                ),
              ),
              if (selected) ...[
                if (recent) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.ideQuickOpenRecentlyOpened,
                    style: CcTypography.caption.copyWith(
                      color: ds.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.xs),
                CcIconButton(
                  icon: AppIcons.columns,
                  size: CcButtonSize.sm,
                  tooltip: l10n.ideQuickOpenOpenToSide,
                  onPressed: onOpenToSide,
                ),
                if (onRemove != null)
                  CcIconButton(
                    icon: AppIcons.x,
                    size: CcButtonSize.sm,
                    tooltip: l10n.ideQuickOpenRemoveRecent,
                    onPressed: onRemove,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The file name with the query's characters bolded where they match in order
/// (a case-insensitive subsequence, like the fuzzy ranker). Nothing is
/// highlighted when the query only matches through the folder path.
class _HighlightedName extends StatelessWidget {
  const _HighlightedName({
    required this.name,
    required this.query,
    required this.style,
  });

  final String name;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final hits = _matchIndices(name, query.replaceAll(' ', ''));
    final strong = style.copyWith(fontWeight: CcTypography.semiboldWeight);
    // Consecutive characters sharing a state become one span.
    final spans = <TextSpan>[];
    var start = 0;
    for (var i = 1; i <= name.length; i++) {
      if (i == name.length || hits.contains(i) != hits.contains(start)) {
        spans.add(
          TextSpan(
            text: name.substring(start, i),
            style: hits.contains(start) ? strong : null,
          ),
        );
        start = i;
      }
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  static Set<int> _matchIndices(String text, String query) {
    if (query.isEmpty) {
      return const {};
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final out = <int>{};
    var from = 0;
    for (final ch in lowerQuery.split('')) {
      final at = lowerText.indexOf(ch, from);
      if (at < 0) {
        return const {};
      }
      out.add(at);
      from = at + 1;
    }
    return out;
  }
}
