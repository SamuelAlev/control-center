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
            child: SingleChildScrollView(
              // The overlay scrollbar hugs the viewport's right edge; this
              // inset keeps the per-file match count from touching it.
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in result.groups)
                    _FileGroup(
                      group: group,
                      baseStyle: baseStyle,
                      tokens: tokens,
                      pattern: pattern,
                      dark: dark,
                    ),
                ],
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

class _FileGroup extends StatelessWidget {
  const _FileGroup({
    required this.group,
    required this.baseStyle,
    required this.tokens,
    required this.pattern,
    required this.dark,
  });

  final ({String path, List<GrepMatch> matches}) group;
  final TextStyle baseStyle;
  final DesignSystemTokens tokens;
  final String? pattern;
  final bool dark;

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
            child: CcSelectionRegion(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, match) in group.matches.indexed)
                    _MatchRow(
                      match: match,
                      gutterWidth: gutterWidth,
                      gutterStyle: gutterStyle,
                      baseStyle: baseStyle,
                      tokens: tokens,
                      languageId: i < highlightBudget ? languageId : null,
                      dark: dark,
                      emphasis: rx,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
