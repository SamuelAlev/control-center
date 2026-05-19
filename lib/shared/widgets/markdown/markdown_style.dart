import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Canonical code-block visual constants.
///
/// Shared by every markdown surface (cc_markdown via [buildSharedCodeBlock])
/// and the anchored file snippet (`AnchoredCodeBlock`) so every code surface
/// in the app — PR descriptions/summaries, chat messages, ticket
/// descriptions, meeting notes, anchored snippets — renders identically.
const EdgeInsets kCodeBlockContentPadding = EdgeInsets.symmetric(
  horizontal: 14,
  vertical: 12,
);

/// Padding for the fenced code-block header row (language label + copy button).
///
/// Only used when the fence names a language. Unlabeled fences (` ``` ` with
/// no info string) skip the header and overlay copy on the body instead.
const EdgeInsets kCodeBlockHeaderPadding = EdgeInsets.symmetric(
  horizontal: 12,
  vertical: 6,
);

/// Key on the language + copy header row. Absent when the fence has no
/// language, so tests can pin the GitHub-style unlabeled treatment.
const Key kCodeBlockHeaderKey = ValueKey<String>('codeBlockHeader');

/// Trailing inset reserved for the overlay copy control on unlabeled fences.
/// Matches [CcIconButton] `sm` (32) plus [AppSpacing.xs] from the edge, so
/// the first line of code is not painted under the button.
const double kCodeBlockOverlayCopyReserve = 32 + AppSpacing.xs;

/// Whether a fence info-string is a real language label (not empty / blank).
bool codeBlockHasLanguage(String? language) =>
    language != null && language.trim().isNotEmpty;

/// Padding inside an inline `code` chip.
const EdgeInsets kInlineCodeChipPadding = EdgeInsets.symmetric(
  horizontal: 4,
  vertical: 2,
);

/// Source-size ceiling above which [buildSharedCodeBlock] skips syntax
/// highlighting and truncates the rendered body (50KB).
const int kSharedCodeBlockMaxHighlightChars = 50 * 1024;

/// Number of leading lines an oversized code block renders (the copy button
/// still copies the full text).
const int kSharedCodeBlockMaxLines = 300;

/// Line count above which a code block collapses behind a "Show more" toggle.
///
/// Slightly higher than the collapsed height so a block is never collapsed to
/// hide only a line or two.
const int kSharedCodeBlockCollapseThreshold = 24;

/// Number of leading lines a collapsed code block shows.
const int kSharedCodeBlockCollapsedLines = 16;

/// Corner radius of an inline `code` chip.
const double kInlineCodeChipRadius = 4;

/// Background wash for an inline `code` chip — the single source of truth for
/// every surface that renders one (markdown bodies via
/// [buildSharedInlineCodeChip], titles via `buildInlineCodeSpans`).
///
/// A translucent ink wash (`hoverStrong`, fg @ 8% — DESIGN.md's documented
/// count-chip wash), deliberately NOT an opaque surface token. Inline code
/// lands on the white data panel, the canvas, hovered rows and chat bubbles;
/// only a wash steps relative to whatever it sits on. The opaque alternatives
/// each fail somewhere: `bgSecondary` IS the canvas colour (#fcfbf9), so it
/// vanished on a white panel at ~1.02:1 and `surface` (#f2f0e9) matches a
/// hovered row almost exactly.
Color inlineCodeChipColor(BuildContext context) =>
    (context.designSystem ?? DesignSystemTokens.light()).hoverStrong;

/// The mono text style for code (inline chips + fenced blocks), honoring the
/// user's selected code font and ligature preference.
TextStyle appCodeTextStyle(
  BuildContext context, {
  String? codeFontFamily,
  bool codeLigatures = true,
}) {
  final tokens = context.designSystem ?? DesignSystemTokens.light();
  return AppFonts.codeStyleDynamic(
    codeFontFamily ?? AppFonts.codeFamily,
    fontSize: 12,
    color: tokens.textPrimary,
  ).copyWith(
    letterSpacing: 0.2,
    fontFeatures: AppFonts.codeFontFeatures(ligatures: codeLigatures),
  );
}

/// THE unified markdown stylesheet — one [CcMarkdownStyle] for every surface
/// (chat bubbles, transcripts, PR descriptions, review comments, tickets,
/// meeting notes), built from design-system tokens + the app text theme.
///
/// Replaces the historically divergent chat/GitHub stylesheets: where they
/// disagreed (h1 size, blockquote italics, link color) the values below
/// resolve to the design tokens and the more recent chat treatment. Surfaces
/// with intentional local looks (PR peek flatten, meeting-notes mono
/// headings) derive via `copyWith`.
CcMarkdownStyle appMarkdownStyle(
  BuildContext context, {
  bool compact = false,
  String? codeFontFamily,
  bool codeLigatures = true,
}) {
  final tokens = context.designSystem ?? DesignSystemTokens.light();
  final uiFamilyKey = context.ccTheme?.fontFamily;
  // Memoized on everything it reads. Building this allocates ~30 TextStyles,
  // and `TurnProse.build` calls it on EVERY streaming delta — for a value
  // that only changes with the theme. `DesignSystemTokens` is built through
  // const factories, so instances are canonicalized and identity is a sound
  // (and cheap) key; the remaining inputs are the flags and the resolved
  // families.
  final cached = _appMarkdownStyleCache;
  if (cached != null &&
      identical(cached.tokens, tokens) &&
      cached.compact == compact &&
      cached.codeFontFamily == codeFontFamily &&
      cached.codeLigatures == codeLigatures &&
      cached.uiFamily == uiFamilyKey) {
    return cached.style;
  }

  final fg = tokens.textPrimary;
  final muted = tokens.textTertiary;
  final divider = tokens.borderSecondary;
  final codeBg = tokens.bgSecondary;

  final bodyFontSize = compact ? 13.5 : 14.0;
  // Manrope has no emoji glyphs; an explicit emoji fallback keeps emoji
  // advances correct (no phantom trailing space in centered table cells).
  final emojiFallback = AppFonts.emojiFallback;
  // CcTypography carries NO fontFamily by design (a `Text` merges it with the
  // ambient DefaultTextStyle). A markdown style is handed to RichText/TextSpan
  // trees instead, so it must name the family itself — and a null family
  // combined with `fontFamilyFallback` makes the FALLBACK the primary font,
  // which measured spaces in the emoji font and blew the word gaps open.
  final uiFamily = uiFamilyKey;
  TextStyle ui(TextStyle base) => CcFonts.ui(family: uiFamily, textStyle: base);
  final body = ui(CcTypography.body).copyWith(
    fontSize: bodyFontSize,
    fontFamilyFallback: emojiFallback,
    height: 1.6,
    // Split the line-height leading evenly above/below the glyphs. With the
    // default (proportional) distribution the baseline sits low in the tall
    // 1.6 line box, so an inline image `WidgetSpan` (aligned to the line-box
    // middle) floats above the text it sits beside — e.g. SonarQube's ✓ badges
    // reading high next to "0 New issues". Even leading recentres the glyphs in
    // the line box so inline badges line up with their text.
    leadingDistribution: TextLeadingDistribution.even,
    color: fg,
  );
  final code = appCodeTextStyle(
    context,
    codeFontFamily: codeFontFamily,
    codeLigatures: codeLigatures,
  );

  final built = CcMarkdownStyle(
    paragraph: body,
    h1: ui(CcTypography.title).copyWith(
      fontSize: compact ? 18 : 20,
      fontWeight: FontWeight.w700,
      color: fg,
      height: 1.25,
    ),
    h1Padding: EdgeInsets.only(top: compact ? 10 : 14),
    h2: ui(CcTypography.title).copyWith(
      fontSize: compact ? 16 : 18,
      fontWeight: FontWeight.w600,
      color: fg,
      height: 1.3,
    ),
    h2Padding: EdgeInsets.only(top: compact ? 8 : 12),
    h3: ui(CcTypography.title).copyWith(
      fontSize: compact ? 14 : 16,
      fontWeight: FontWeight.w600,
      color: fg,
      height: 1.35,
    ),
    h3Padding: EdgeInsets.only(top: compact ? 6 : 10),
    h4: ui(
      CcTypography.body,
    ).copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
    h5: ui(CcTypography.body).copyWith(fontWeight: FontWeight.w600, color: fg),
    h6: ui(
      CcTypography.caption,
    ).copyWith(fontWeight: FontWeight.w600, color: muted),
    code: code.copyWith(height: 1.5),
    inlineCode: code,
    link: body.copyWith(color: tokens.textBrandPrimary).withLinkUnderline(),
    blockquote: body.copyWith(color: muted),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: divider, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
    bold: TextStyle(fontWeight: FontWeight.w700, color: fg),
    italic: TextStyle(fontStyle: FontStyle.italic, color: fg),
    listBullet: body,
    tableHead: ui(CcTypography.body).copyWith(
      fontSize: bodyFontSize,
      fontFamilyFallback: emojiFallback,
      fontWeight: FontWeight.w600,
      color: fg,
    ),
    tableBody: ui(CcTypography.body).copyWith(
      fontSize: bodyFontSize,
      fontFamilyFallback: emojiFallback,
      color: fg,
    ),
    tableBorder: TableBorder.all(color: divider, width: 0.5),
    tableHeadDecoration: BoxDecoration(color: codeBg),
    tableCellPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    codeblockDecoration: BoxDecoration(
      color: codeBg,
      borderRadius: AppRadii.brLg,
      border: Border.all(color: divider),
    ),
    codeblockPadding: kCodeBlockContentPadding,
    inlineCodePadding: kInlineCodeChipPadding,
    inlineCodeRadius: kInlineCodeChipRadius,
    horizontalRuleColor: divider,
    blockSpacing: compact ? 6 : 10,
    listIndent: 28,
    mermaid: appMermaidStyle(
      context,
      compact: compact,
      codeFontFamily: codeFontFamily,
    ),
    // A stable top-level tear-off (not a fresh closure) so two builds of the
    // same style compare equal — the streaming widget's block memo keys on
    // style value-equality, so an inline closure here would invalidate it
    // every rebuild.
    checkbox: _appMarkdownCheckbox,
  );
  _appMarkdownStyleCache = _AppMarkdownStyleMemo(
    tokens: tokens,
    compact: compact,
    codeFontFamily: codeFontFamily,
    codeLigatures: codeLigatures,
    uiFamily: uiFamilyKey,
    style: built,
  );
  return built;
}

/// One-entry memo for [appMarkdownStyle].
///
/// One entry, not an LRU: a running app renders essentially every markdown
/// surface with the same tokens and flags, so the hit rate of a single slot is
/// already ~100% and a map would add hashing to a hot path for nothing.
class _AppMarkdownStyleMemo {
  const _AppMarkdownStyleMemo({
    required this.tokens,
    required this.compact,
    required this.codeFontFamily,
    required this.codeLigatures,
    required this.uiFamily,
    required this.style,
  });

  final DesignSystemTokens tokens;
  final bool compact;
  final String? codeFontFamily;
  final bool codeLigatures;
  final String? uiFamily;
  final CcMarkdownStyle style;
}

_AppMarkdownStyleMemo? _appMarkdownStyleCache;

/// THE mermaid diagram stylesheet, built from the same design tokens as the
/// markdown body so a diagram reads as part of the surface it sits on (and
/// follows light/dark without the author's `%%{init: theme}%%` fighting it).
///
/// Author-specified mermaid colors are intentionally NOT honored: an LLM's
/// hardcoded `#333` on a dark surface is unreadable and our accessibility floor
/// (AA, aiming AAA) is only enforceable if the palette is ours. The categorical
/// palette below is used for pie slices and timeline sections only, where hue
/// carries data — and every one of those is labeled in text as well.
CcMermaidStyle appMermaidStyle(
  BuildContext context, {
  bool compact = false,
  String? codeFontFamily,
}) {
  final tokens = context.designSystem ?? DesignSystemTokens.light();
  final label = AppFonts.ui(
    textStyle: TextStyle(
      fontSize: compact ? 11.5 : 12.5,
      color: tokens.textPrimary,
      fontFamilyFallback: AppFonts.emojiFallback,
      height: 1.25,
    ),
  );
  final mono = AppFonts.codeStyleDynamic(
    codeFontFamily ?? AppFonts.codeFamily,
    fontSize: compact ? 10.5 : 11.5,
    color: tokens.textSecondary,
  );

  return CcMermaidStyle(
    label: label,
    title: label.copyWith(
      fontSize: (compact ? 13.0 : 14.5),
      fontWeight: FontWeight.w600,
    ),
    clusterLabel: label.copyWith(
      fontSize: (compact ? 10.5 : 11.5),
      fontWeight: FontWeight.w600,
      color: tokens.textTertiary,
    ),
    edgeLabel: label.copyWith(
      fontSize: compact ? 10.5 : 11.5,
      color: tokens.textSecondary,
    ),
    compartment: mono,
    note: label.copyWith(fontSize: compact ? 10.5 : 11.5),
    legend: label.copyWith(
      fontSize: compact ? 10.5 : 11.5,
      color: tokens.textSecondary,
    ),
    nodeFill: tokens.surface,
    nodeBorder: tokens.borderPrimary,
    accent: tokens.textTertiary,
    clusterFill: tokens.bgTertiary,
    clusterBorder: tokens.borderSecondary,
    noteFill: tokens.bgTertiary,
    noteBorder: tokens.borderSecondary,
    edgeColor: tokens.textTertiary,
    // The label chip must hide the line it sits on, so it takes the diagram's
    // own background (the card surface), not a translucent wash.
    edgeLabelFill: tokens.bgSecondary,
    activationFill: tokens.bgQuaternary,
    frameFill: tokens.bgTertiary,
    frameBorder: tokens.borderSecondary,
    dividerColor: tokens.borderSecondary,
    mutedTextColor: tokens.textTertiary,
    background: tokens.bgSecondary,
    seriesPalette: const [
      Color(0xFF4E79A7),
      Color(0xFFE1893C),
      Color(0xFF52A15B),
      Color(0xFFD4595C),
      Color(0xFF9268C9),
      Color(0xFF3FA0A6),
    ],
    nodePadding: EdgeInsets.symmetric(
      horizontal: compact ? 11 : 13,
      vertical: compact ? 7 : 8,
    ),
    nodeSpacing: compact ? 20 : 24,
    rankSpacing: compact ? 34 : 40,
    canvasPadding: const EdgeInsets.all(6),
    // Rounding is reserved for the shapes whose roundness carries meaning
    // (`(text)`, `([text])`, notes); the rect family paints square, per the
    // design system's zero-radius geometry.
    cornerRadius: 5,
  );
}

/// Read-only task-list checkbox for markdown list items, wrapped in a
/// [FittedBox] so it fits the constrained bullet slot.
Widget _appMarkdownCheckbox(bool checked) => SizedBox(
  height: 22,
  child: FittedBox(
    fit: BoxFit.contain,
    child: CcCheckbox(value: checked, onChanged: null),
  ),
);

/// Renders an inline `code` chip using a [Container] background instead of
/// [TextStyle.backgroundColor].
///
/// `TextStyle.backgroundColor` is painted by the paragraph renderer *on top*
/// of the selection highlight, making selected inline code appear unselected.
/// Moving the background to a [Container] keeps the chip look while letting
/// the selection highlight shine through. cc_markdown embeds the returned
/// widget as a `WidgetSpan` inside the paragraph's single `Text.rich`, so the
/// surrounding text keeps wrapping character by character.
Widget buildSharedInlineCodeChip(String code, TextStyle codeStyle) {
  return _InlineCodeChip(code: code, codeStyle: codeStyle);
}

class _InlineCodeChip extends StatelessWidget {
  const _InlineCodeChip({required this.code, required this.codeStyle});

  final String code;
  final TextStyle codeStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kInlineCodeChipPadding,
      decoration: BoxDecoration(
        color: inlineCodeChipColor(context),
        borderRadius: BorderRadius.circular(kInlineCodeChipRadius),
      ),
      child: Text(code, style: codeStyle),
    );
  }
}

/// Builds the canonical fenced code-block widget.
///
/// A labeled fence (` ```dart `) keeps a slim header: language on the left,
/// copy on the right. An unlabeled fence (` ``` ` with no info string) skips
/// that row — an empty chrome band is wasted space — and parks copy in the
/// top-right of the body, the GitHub treatment.
///
/// The body is a horizontally-scrollable, syntax-highlighted code surface
/// (via shiki + the CC theme — see `shared/syntax/`).
///
/// This is the single code renderer for every markdown surface — passed to
/// cc_markdown as the `codeBuilder` callback.
///
/// Pass `cache: false` for volatile content (a still-streaming code block)
/// whose string changes on every build — see [highlightCodeSpans].
///
/// Giant blocks (> [kSharedCodeBlockMaxHighlightChars] source chars) skip
/// syntax highlighting entirely and render only the first
/// [kSharedCodeBlockMaxLines] lines with a truncation notice; the copy button
/// always copies the FULL text. Long-but-sane blocks (>
/// [kSharedCodeBlockCollapseThreshold] lines) collapse to their first
/// [kSharedCodeBlockCollapsedLines] lines behind a ghost "Show more"/"Show
/// less" toggle, so a wall of code never dominates the surrounding surface.
Widget buildSharedCodeBlock(
  BuildContext context,
  String code,
  String? language, {
  String? codeFontFamily,
  bool codeLigatures = true,
  bool cache = true,
}) {
  return _SharedCodeBlock(
    code: code,
    language: language,
    codeFontFamily: codeFontFamily,
    codeLigatures: codeLigatures,
    cache: cache,
  );
}

class _SharedCodeBlock extends StatefulWidget {
  const _SharedCodeBlock({
    required this.code,
    required this.language,
    required this.codeFontFamily,
    required this.codeLigatures,
    required this.cache,
  });

  final String code;
  final String? language;
  final String? codeFontFamily;
  final bool codeLigatures;
  final bool cache;

  @override
  State<_SharedCodeBlock> createState() => _SharedCodeBlockState();
}

class _SharedCodeBlockState extends State<_SharedCodeBlock> {
  bool _expanded = false;

  /// Number of lines in [code], counted without allocating them.
  static int _countLines(String code) {
    var lines = 1;
    for (var i = 0; i < code.length; i++) {
      if (code.codeUnitAt(i) == 0x0A) {
        lines++;
      }
    }
    return lines;
  }

  /// The index of the newline that ends line `[line] - 1`, i.e. the exclusive
  /// end of the first [line] lines — so `code.substring(0, _endOfLines(code,
  /// n))` equals `code.split('\n').take(n).join('\n')` without materializing
  /// every line. Returns `code.length` when the code has fewer lines.
  static int _endOfLines(String code, int line) {
    if (line <= 0) {
      return 0;
    }
    var seen = 0;
    for (var i = 0; i < code.length; i++) {
      if (code.codeUnitAt(i) != 0x0A) {
        continue;
      }
      seen++;
      if (seen == line) {
        return i;
      }
    }
    return code.length;
  }

  /// Async-highlight bookkeeping for blocks over the sync line budget: the
  /// spans land in the highlight LRU, this key just prevents re-scheduling
  /// the same tokenize on every rebuild while it is in flight.
  (String, String?, bool)? _pendingAsync;

  /// Resolves the spans for [displayCode], choosing sync, async-with-plain-
  /// first, or bounded streaming highlighting by the grammar's measured
  /// weight (see `syntax_languages.dart`).
  List<InlineSpan> _spansFor(
    String displayCode,
    String? languageId, {
    required bool dark,
  }) {
    final lineCount = _countLines(displayCode);
    if (!widget.cache) {
      // A still-streaming fence re-renders on every delta and is deliberately
      // uncached. Highlight a bounded head synchronously and leave the
      // growing tail plain: stable colors, bounded main-thread cost per
      // frame regardless of grammar weight. The sealed rebuild (cache: true)
      // re-highlights the whole block.
      final budget = syncLineBudget(syntaxWeightFor(languageId));
      if (lineCount <= budget) {
        return highlightCodeSpans(
          code: displayCode,
          languageId: languageId,
          dark: dark,
          cache: false,
        );
      }
      // Past the budget the HEAD is frozen — those first `budget` lines can
      // never change again for the rest of this stream — so it is cached like
      // any other stable block. It used to be re-tokenized under
      // `cache: false` on every single delta, up to 400 lines of dart/json
      // on the UI thread, for content that was already final. Caching it adds
      // exactly ONE LRU entry per streaming block, not one per delta: the
      // key is that same frozen head every time.
      final headEnd = _endOfLines(displayCode, budget);
      final head = displayCode.substring(0, headEnd);
      return [
        ...highlightCodeSpans(code: head, languageId: languageId, dark: dark),
        TextSpan(text: displayCode.substring(headEnd)),
      ];
    }
    if (shouldHighlightSynchronously(
      languageId: languageId,
      lineCount: lineCount,
    )) {
      return highlightCodeSpans(
        code: displayCode,
        languageId: languageId,
        dark: dark,
      );
    }
    final cached = peekHighlightedSpans(
      code: displayCode,
      languageId: languageId,
      dark: dark,
    );
    if (cached != null) {
      return cached;
    }
    final key = (displayCode, languageId, dark);
    if (_pendingAsync != key) {
      _pendingAsync = key;
      highlightCodeSpansAsync(
        code: displayCode,
        languageId: languageId,
        dark: dark,
      ).whenComplete(() {
        if (mounted && _pendingAsync == key) {
          setState(() => _pendingAsync = null);
        }
      });
    }
    return [TextSpan(text: displayCode)];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final code = widget.code;
    final language = widget.language;
    final codeStyle = appCodeTextStyle(
      context,
      codeFontFamily: widget.codeFontFamily,
      codeLigatures: widget.codeLigatures,
    );

    // Giant-content guard: highlighting a huge block would freeze the frame,
    // and rendering hundreds of thousands of glyphs is pointless. Render a
    // plain-text head only; the copy affordance below keeps the full text.
    final oversized = code.length > kSharedCodeBlockMaxHighlightChars;
    var displayCode = code;
    var truncatedLines = 0;
    var collapsedLines = 0;
    // Counted and sliced by index rather than `split('\n')`: this runs on
    // every build of every code block, and splitting allocates one string per
    // line of the block only to keep a prefix of them.
    final lineCount = _countLines(code);
    if (oversized) {
      if (lineCount > kSharedCodeBlockMaxLines) {
        truncatedLines = kSharedCodeBlockMaxLines;
        displayCode = code.substring(
          0,
          _endOfLines(code, kSharedCodeBlockMaxLines),
        );
      }
    } else if (lineCount > kSharedCodeBlockCollapseThreshold) {
      collapsedLines = lineCount - kSharedCodeBlockCollapsedLines;
      if (!_expanded) {
        displayCode = code.substring(
          0,
          _endOfLines(code, kSharedCodeBlockCollapsedLines),
        );
      }
    }

    final spans = oversized
        ? <InlineSpan>[TextSpan(text: displayCode)]
        : _spansFor(
            displayCode,
            shikiLangForFence(language),
            dark: Theme.of(context).brightness == Brightness.dark,
          );

    final l10n = AppLocalizations.of(context);
    final labeled = codeBlockHasLanguage(language);
    final copyButton = _CopyCodeButton(
      code: code,
      language: language,
      overlay: !labeled,
    );
    final body = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: labeled
          ? kCodeBlockContentPadding
          : kCodeBlockContentPadding.copyWith(
              right:
                  kCodeBlockContentPadding.right + kCodeBlockOverlayCopyReserve,
            ),
      child: Text.rich(TextSpan(style: codeStyle, children: spans)),
    );

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: tokens.borderSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (labeled)
            Container(
              key: kCodeBlockHeaderKey,
              padding: kCodeBlockHeaderPadding,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: tokens.borderSecondary),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    language!.trim(),
                    style: TextStyle(color: tokens.textTertiary, fontSize: 12),
                  ),
                  const Spacer(),
                  copyButton,
                ],
              ),
            ),
          if (labeled)
            body
          else
            Stack(
              children: [
                body,
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: copyButton,
                ),
              ],
            ),
          if (truncatedLines > 0)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
              child: Text(
                l10n.transcriptShowingFirstLines(truncatedLines),
                style: TextStyle(color: tokens.textQuaternary, fontSize: 11),
              ),
            ),
          if (collapsedLines > 0)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: tokens.borderSecondary)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  icon: _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? l10n.showLess : l10n.showMore),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CopyCodeButton extends StatefulWidget {
  const _CopyCodeButton({
    required this.code,
    this.language,
    this.overlay = false,
  });

  final String code;
  final String? language;

  /// When true the button sits on the code body (unlabeled fence) and uses
  /// a bordered fill so it stays readable over the tokens. Ghost in the
  /// labeled header row stays quiet against the chrome.
  final bool overlay;

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcIconButton(
      icon: _copied ? AppIcons.check : AppIcons.copy,
      size: CcButtonSize.sm,
      variant: widget.overlay
          ? CcButtonVariant.secondary
          : CcButtonVariant.ghost,
      color: t.textTertiary,
      tooltip: _copied
          ? AppLocalizations.of(context).copied
          : AppLocalizations.of(context).copy,
      onPressed: () {
        final lang = widget.language;
        final wrapped = codeBlockHasLanguage(lang)
            ? '```${lang!.trim()}\n${widget.code}\n```'
            : '```\n${widget.code}\n```';
        Clipboard.setData(ClipboardData(text: wrapped));
        setState(() => _copied = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _copied = false);
          }
        });
      },
    );
  }
}
