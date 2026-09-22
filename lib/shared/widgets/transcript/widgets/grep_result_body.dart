import 'package:cc_markdown/cc_markdown.dart' show CcSelectionRegion;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/diff_colors.dart'
    show diffBrightnessOf;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:control_center/shared/widgets/transcript/util/grep_output_parser.dart';
import 'package:control_center/shared/widgets/transcript/widgets/split_diff_view.dart';
import 'package:flutter/widgets.dart';

/// Longest rendered line — a grep hit on a minified bundle must not blow the
/// layout out sideways.
const int _maxLineChars = 500;

/// Past this many hits, or this many files, rows mount through a builder.
/// Grep opens expanded inside one chat list item, and a repo search is
/// hundreds of gutter rows the viewport cannot show.
const int _virtualizeRows = 64;

/// The body of a Grep / Search tool cell: the hits grouped by file, each with
/// a line-number gutter and the matched substring emphasized over the file's
/// syntax highlighting, under a compact "N matches · M files" stats line.
///
/// The transcript auto-expands these rows (see `toolBodyOpensByDefault`) — like
/// an edit's diff, the matches ARE the information; "Grep foo" alone says
/// nothing.
class GrepResultBody extends StatelessWidget {
  /// Creates a [GrepResultBody].
  const GrepResultBody({
    super.key,
    required this.outputs,
    required this.codeFont,
    required this.tokens,
    this.pattern,
    this.maxHeight = 320,
  });

  /// Raw tool output (`path:line: text` or bare-path lines).
  final String outputs;

  /// Mono font family.
  final String codeFont;

  /// Design tokens for colors.
  final DesignSystemTokens tokens;

  /// The searched pattern, used to emphasize the matched substring. Compiled
  /// as a regex when possible, treated literally otherwise.
  final String? pattern;

  /// Maximum height before the block scrolls internally.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = diffBrightnessOf(context) == Brightness.dark;
    final result = parseGrepOutput(outputs);

    if (result.matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          l10n.transcriptGrepNoMatches,
          style: CcTypography.caption.copyWith(color: tokens.textQuaternary),
        ),
      );
    }

    final baseStyle = AppFonts.codeDynamic(
      codeFont,
      textStyle: CcTypography.caption.copyWith(
        color: tokens.textTertiary,
        height: 1.45,
        fontSize: 12,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.transcriptGrepStats(result.matches.length, result.fileCount),
            style: CcTypography.caption.copyWith(color: tokens.textQuaternary),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            // Pinned per the carve-out below: paths, gutters and matched code
            // lines lay out LTR whatever the app locale. The stats line and
            // note above/below stay on the ambient direction.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _GrepHits(
                groups: result.groups,
                baseStyle: baseStyle,
                tokens: tokens,
                pattern: pattern,
                dark: dark,
                maxHeight: maxHeight,
              ),
            ),
          ),
          if (result.note != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                result.note!,
                style: CcTypography.caption.copyWith(
                  color: tokens.textQuaternary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GrepHits extends StatelessWidget {
  const _GrepHits({
    required this.groups,
    required this.baseStyle,
    required this.tokens,
    required this.pattern,
    required this.dark,
    required this.maxHeight,
  });

  final List<({String path, List<GrepMatch> matches})> groups;
  final TextStyle baseStyle;
  final DesignSystemTokens tokens;
  final String? pattern;
  final bool dark;
  final double maxHeight;

  Widget _group(({String path, List<GrepMatch> matches}) group) {
    return _FileGroup(
      group: group,
      baseStyle: baseStyle,
      tokens: tokens,
      pattern: pattern,
      dark: dark,
      maxHeight: maxHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The overlay scrollbar hugs the viewport's end edge; this inset keeps
    // the per-file match count from touching it.
    const inset = EdgeInsetsDirectional.only(end: 12);
    if (groups.length > _virtualizeRows && maxHeight.isFinite) {
      return SizedBox(
        height: maxHeight,
        child: ListView.builder(
          primary: false,
          padding: inset,
          itemCount: groups.length,
          itemBuilder: (context, index) => _group(groups[index]),
        ),
      );
    }
    return SingleChildScrollView(
      padding: inset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final group in groups) _group(group)],
      ),
    );
  }
}

class _FileGroup extends StatelessWidget {
  const _FileGroup({
    required this.group,
    required this.baseStyle,
    required this.tokens,
    required this.pattern,
    required this.dark,
    required this.maxHeight,
  });

  final ({String path, List<GrepMatch> matches}) group;
  final TextStyle baseStyle;
  final DesignSystemTokens tokens;
  final String? pattern;
  final bool dark;

  /// Outer block cap. A file past [_virtualizeRows] hits scrolls in a
  /// viewport short of this so the file header still fits above the hits.
  final double maxHeight;

  /// The pattern compiled for substring emphasis: regex first, literal
  /// fallback when it doesn't compile (a pattern the tool itself rejected
  /// would have failed the call, so this mostly covers glob-style inputs).
  RegExp? get _emphasis {
    final p = pattern;
    if (p == null || p.isEmpty) {
      return null;
    }
    try {
      return RegExp(p);
    } on Object {
      return RegExp(RegExp.escape(p));
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageId = shikiLangForPath(group.path);
    // Per-row tokenizes are one line each, so the grammar's sync line budget
    // doubles as the highlighted-row budget: rows past it render plain (an
    // extreme grammar like sql costs ~4ms per row — 200 rows would jank).
    final highlightBudget = syncLineBudget(syntaxWeightFor(languageId));
    final gutterWidth = group.matches
        .map((m) => m.line ?? 0)
        .fold(
          1,
          (w, line) => line.toString().length > w ? line.toString().length : w,
        );
    final gutterStyle = baseStyle.copyWith(color: tokens.textQuaternary);
    final rx = _emphasis;
    final matches = group.matches;
    final hits = matches.length > _virtualizeRows && maxHeight.isFinite
        ? SizedBox(
            height: maxHeight > 48 ? maxHeight - 48 : maxHeight,
            child: ListView.builder(
              primary: false,
              itemCount: matches.length,
              itemBuilder: (context, i) => _row(
                i,
                gutterWidth: gutterWidth,
                gutterStyle: gutterStyle,
                languageId: languageId,
                highlightBudget: highlightBudget,
                emphasis: rx,
              ),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < matches.length; i++)
                _row(
                  i,
                  gutterWidth: gutterWidth,
                  gutterStyle: gutterStyle,
                  languageId: languageId,
                  highlightBudget: highlightBudget,
                  emphasis: rx,
                ),
            ],
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Icon(AppIcons.fileCode, size: 12, color: tokens.fgQuaternary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    group.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${group.matches.length}',
                  style: CcTypography.caption.copyWith(
                    color: tokens.textQuaternary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: tokens.bgPrimary,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: tokens.borderSecondary),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: CcSelectionRegion(child: hits),
          ),
        ],
      ),
    );
  }

  Widget _row(
    int index, {
    required int gutterWidth,
    required TextStyle gutterStyle,
    required String? languageId,
    required int highlightBudget,
    required RegExp? emphasis,
  }) {
    return _MatchRow(
      match: group.matches[index],
      gutterWidth: gutterWidth,
      gutterStyle: gutterStyle,
      baseStyle: baseStyle,
      tokens: tokens,
      languageId: index < highlightBudget ? languageId : null,
      dark: dark,
      emphasis: emphasis,
    );
  }
}

// RTL carve-out: match rows render source code, which stays LTR by policy.
class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.match,
    required this.gutterWidth,
    required this.gutterStyle,
    required this.baseStyle,
    required this.tokens,
    required this.languageId,
    required this.dark,
    required this.emphasis,
  });

  final GrepMatch match;
  final int gutterWidth;
  final TextStyle gutterStyle;
  final TextStyle baseStyle;
  final DesignSystemTokens tokens;
  final String? languageId;
  final bool dark;
  final RegExp? emphasis;

  @override
  Widget build(BuildContext context) {
    final content = match.content.length > _maxLineChars
        ? '${match.content.substring(0, _maxLineChars)}…'
        : match.content;

    // Files-with-matches rows carry no line text — the gutter shows a bullet.
    if (match.line == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Text(
          match.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: baseStyle,
        ),
      );
    }

    final syntaxSpans = highlightCodeSpans(
      code: content,
      languageId: languageId,
      dark: dark,
    );
    final spans = applyIntralineBackground(
      syntaxSpans,
      _matchRanges(content),
      tokens.accentSoft.withValues(alpha: 0.5),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Text(
              '${match.line}'.padLeft(gutterWidth),
              style: gutterStyle,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text.rich(
                TextSpan(style: baseStyle, children: spans),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The (start, end) char ranges of every non-empty emphasis hit in [line].
  List<(int, int)> _matchRanges(String line) {
    final rx = emphasis;
    if (rx == null || line.isEmpty) {
      return const [];
    }
    return [
      for (final m in rx.allMatches(line))
        if (m.end > m.start) (m.start, m.end),
    ];
  }
}
