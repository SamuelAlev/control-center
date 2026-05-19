import 'dart:math' as math;
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/features/pr_review/presentation/utils/word_diff.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Server review comments for a single file, split into those still anchored to
/// a live diff row and those the current diff can no longer place.
@immutable
class PartitionedServerComments {
  /// Creates a [PartitionedServerComments].
  const PartitionedServerComments({
    required this.anchored,
    required this.outdated,
  });

  /// Comments keyed by `"<side>-<anchorLine>"`, ready to be synthesised into
  /// inline threads on the matching diff row.
  final Map<String, List<PrCodeReviewComment>> anchored;

  /// Comments whose [PrCodeReviewComment.anchorLine] is null — the diff line
  /// they referenced no longer exists (the code changed after the comment was
  /// left), so they cannot be pinned to a real row. GitHub surfaces these under
  /// a collapsed "outdated" group rather than dropping them.
  final List<PrCodeReviewComment> outdated;
}

/// Partitions the server review [comments] for [filename] into anchored and
/// outdated buckets.
///
/// A comment is *outdated* when it has no [PrCodeReviewComment.anchorLine]: the
/// diff row it referenced is gone, so it can't be anchored to a live line.
/// Previously such comments were silently dropped from the review; keeping them
/// in [PartitionedServerComments.outdated] lets the viewer surface them in a
/// collapsed group (GitHub parity). Anchored comments keep the
/// `"<side>-<anchorLine>"` grouping the inline renderer expects.
///
/// Pure and side-effect free so it can be unit-tested without a widget tree.
PartitionedServerComments partitionServerCommentsForFile(
  Iterable<PrCodeReviewComment> comments,
  String filename,
) {
  final anchored = <String, List<PrCodeReviewComment>>{};
  final outdated = <PrCodeReviewComment>[];
  for (final c in comments) {
    if (c.path != filename) {
      continue;
    }
    final anchor = c.anchorLine;
    if (anchor == null) {
      outdated.add(c);
      continue;
    }
    anchored
        .putIfAbsent('${c.side}-$anchor', () => <PrCodeReviewComment>[])
        .add(c);
  }
  return PartitionedServerComments(anchored: anchored, outdated: outdated);
}

/// A file-header affordance that surfaces a file's *outdated* review comments —
/// those whose diff line no longer exists — in a collapsed group.
///
/// Rendered as a small "outdated" badge that toggles a floating panel; the
/// panel is hidden by default, so outdated comments never compete with the live
/// diff, yet are no longer dropped. Each entry shows the comment body and the
/// original diff-hunk snippet the author saw, so the reviewer keeps the context
/// even though the line is gone. Never anchored to a real diff row.
class OutdatedCommentsGroup extends StatelessWidget {
  /// Creates an [OutdatedCommentsGroup]. [comments] must be non-empty (callers
  /// omit the group when a file has no outdated comments).
  const OutdatedCommentsGroup({super.key, required this.comments});

  /// The file's outdated comments.
  final List<PrCodeReviewComment> comments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcPopover(
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      semanticLabel: l10n.outdatedComments,
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 420),
        child: _OutdatedPanel(comments: comments),
      ),
      target: CcBadge(
        label: l10n.outdatedCountLabel(comments.length),
        variant: CcBadgeVariant.warning,
        icon: AppIcons.clock,
      ),
    );
  }
}

/// The floating panel body listing every outdated comment for a file.
class _OutdatedPanel extends StatelessWidget {
  const _OutdatedPanel({required this.comments});

  final List<PrCodeReviewComment> comments;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    // The panel floats in the root overlay, above every route's Material, so it
    // inherits no usable DefaultTextStyle — supply one (concrete size + token
    // colour + no decoration) or WidgetsApp's yellow error style leaks through.
    return DefaultTextStyle(
      style: TextStyle(
        fontSize: 13,
        height: 1.4,
        color: tokens.textPrimary,
        fontFamily: CcFonts.uiFamily,
        decoration: TextDecoration.none,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(AppIcons.clock, size: 14, color: tokens.textTertiary),
                  const SizedBox(width: 6),
                  Text(
                    l10n.outdatedComments,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                itemCount: comments.length,
                separatorBuilder: (_, _) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: CcDivider(),
                ),
                itemBuilder: (context, i) =>
                    _OutdatedCommentTile(comment: comments[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single outdated comment: author, an "outdated" badge, the original
/// diff-hunk snippet and the comment body.
class _OutdatedCommentTile extends ConsumerWidget {
  const _OutdatedCommentTile({required this.comment});

  final PrCodeReviewComment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final login = comment.user?.login ?? l10n.unknownAuthor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GitHubUserAvatar(
              login: login,
              avatarUrl: comment.user?.avatarUrl,
              size: 18,
              showHoverCard: false,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                login,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.textPrimary,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            CcBadge(
              label: l10n.outdated,
              variant: CcBadgeVariant.warning,
              icon: AppIcons.clock,
            ),
          ],
        ),
        if (comment.diffHunk.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          ReviewDiffHunkSnippet(hunk: comment.diffHunk, path: comment.path),
        ],
        const SizedBox(height: 6),
        GitHubMarkdownBody(
          data: comment.body,
          compact: true,
          codeFontFamily: ref.watch(codeFontFamilyProvider),
        ),
      ],
    );
  }
}

/// The diff hunk a comment was left against, rendered like the real diff:
/// parsed rows, old/new line numbers, the diff palette and shiki syntax
/// highlighting — not the raw `+`/`-` text.
///
/// Public because it is the ONLY way to show what an OUTDATED conversation was
/// about — the line it referenced is gone from the diff — and both the file
/// header's outdated group and the conversation timeline need it.
///
/// Read-only ON PURPOSE. It carries none of the diff's review affordances: no
/// gutter "+" pill, no per-row comment tap, no floating selection toolbar.
/// This is a picture of code a conversation already exists about; offering to
/// start a second conversation on a frozen snapshot of it — whose lines may no
/// longer exist — would anchor a comment to nothing.
class ReviewDiffHunkSnippet extends ConsumerWidget {
  /// Creates a [ReviewDiffHunkSnippet] for [hunk].
  const ReviewDiffHunkSnippet({
    super.key,
    required this.hunk,
    this.path,
    this.maxRows = 24,
  });

  /// The forge's `diff_hunk` for the comment (a unified-diff fragment).
  final String hunk;

  /// The commented file's path, used to resolve the syntax grammar. Null
  /// renders plain (uncoloured) text rather than guessing a language.
  final String? path;

  /// How many rows to render before truncating.
  ///
  /// A forge hunk is usually a handful of lines, but it can run to the whole
  /// changed region — and this snippet sits inside a comment card, not a
  /// virtualised canvas, so every row is a real widget. The LAST rows are
  /// kept: a hunk's payload is its end, where the commented line is.
  final int maxRows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = DiffPalette.forBrightness(
      isDark ? Brightness.dark : Brightness.light,
    );

    // Hunk headers and the synthetic leading gap carry nothing a reader needs
    // here: the line-number gutter says the same thing, and there is nothing
    // to expand into.
    final parsed = [
      for (final line in parseUnifiedDiff(hunk))
        if (line.kind == DiffLineKind.context ||
            line.kind == DiffLineKind.addition ||
            line.kind == DiffLineKind.deletion)
          line,
    ];
    if (parsed.isEmpty) {
      return const SizedBox.shrink();
    }
    final rows = parsed.length > maxRows
        ? parsed.sublist(parsed.length - maxRows)
        : parsed;

    // One tokenize for the whole snippet, as the diff does per hunk: grammar
    // state carries across lines, so a multi-line string or comment colours
    // correctly instead of restarting on every row.
    final language = path == null ? null : shikiLangForPath(path!);
    final tokenLines = highlightDiffLines(
      [for (final r in rows) r.content].join('\n'),
      language,
      dark: isDark,
    );

    final specs = <DiffLineSpec>[
      for (var i = 0; i < rows.length; i++)
        DiffLineSpec(
          kind: rows[i].kind,
          tokens: i < tokenLines.length
              ? tokenLines[i]
              : [DiffToken(rows[i].content, null)],
          oldLine: rows[i].oldLine,
          newLine: rows[i].newLine,
        ),
    ];
    applyInlineWordDiff(specs, diffSyntaxPalette(isDark: isDark));

    final codeStyle =
        AppFonts.codeStyleDynamic(
          ref.watch(codeFontFamilyProvider),
          fontSize: 11.5,
          height: 1.55,
          color: tokens.textPrimary,
        ).copyWith(
          fontFeatures: AppFonts.codeFontFeatures(
            ligatures: ref.watch(codeFontLigaturesProvider),
          ),
        );
    final widest = specs.fold<int>(
      0,
      (w, r) => math.max(w, math.max(r.oldLine ?? 0, r.newLine ?? 0)),
    );
    final gutterWidth = math.max(22.0, 7.0 * '$widest'.length + 10.0);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: AppRadii.brSm,
      ),
      clipBehavior: Clip.hardEdge,
      // A horizontal scroll view hands its child UNBOUNDED width, so a row
      // asking for `double.infinity` inside one is an infinite constraint, not
      // a full-width row. Size the rows to the widest line instead
      // ([IntrinsicWidth] + stretch), floored at the viewport width so a
      // short line's tint still reaches the right edge.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : 0,
            ),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final spec in specs)
                    _SnippetRow(
                      spec: spec,
                      style: codeStyle,
                      palette: palette,
                      gutterWidth: gutterWidth,
                      gutterBorder: tokens.borderSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One rendered snippet row: the old and new line numbers, then the code.
class _SnippetRow extends StatelessWidget {
  const _SnippetRow({
    required this.spec,
    required this.style,
    required this.palette,
    required this.gutterWidth,
    required this.gutterBorder,
  });

  final DiffLineSpec spec;
  final TextStyle style;
  final DiffPalette palette;
  final double gutterWidth;
  final Color gutterBorder;

  @override
  Widget build(BuildContext context) {
    final isAdd = spec.kind == DiffLineKind.addition;
    final isDel = spec.kind == DiffLineKind.deletion;
    final rowBg = isAdd
        ? palette.additionBg
        : isDel
        ? palette.deletionBg
        : null;
    final gutterBg = isAdd
        ? palette.additionGutterBg
        : isDel
        ? palette.deletionGutterBg
        : null;
    final gutterFg = isAdd
        ? palette.additionGutterFg
        : isDel
        ? palette.deletionGutterFg
        : (context.designSystem ?? DesignSystemTokens.light()).textTertiary;
    final numberStyle = style.copyWith(
      color: gutterFg,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // Every row is one code line tall and the gutter tint has to be exactly as
    // tall as the code beside it, or it leaves a pale band across the hunk.
    //
    // A BLANK diff line tokenizes to a single EMPTY token, so its paragraph has
    // no glyph run to measure and falls back to the paragraph style — which,
    // with no `style` on the `Text.rich`, is the ambient one of whatever card
    // the snippet sits in (comment body text, ~21px), not the code style
    // (~18px). The row grew past its top-aligned gutter and every empty line in
    // the hunk punched a gap into the tint. Naming the code style fixes the
    // fallback; the forced strut pins both columns to one height whatever the
    // run turns out to be (an empty paragraph still measures a pixel short of a
    // glyph one, and a fallback font for an exotic glyph can measure long).
    final strut = StrutStyle.fromTextStyle(style, forceStrutHeight: true);

    Widget number(int? value) => SizedBox(
      width: gutterWidth,
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          value?.toString() ?? '',
          textAlign: TextAlign.right,
          style: numberStyle,
          strutStyle: strut,
        ),
      ),
    );

    return ColoredBox(
      color: rowBg ?? const Color(0x00000000),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: gutterBg,
              border: Border(
                right: BorderSide(color: gutterBorder, width: 0.5),
              ),
            ),
            child: Row(children: [number(spec.oldLine), number(spec.newLine)]),
          ),
          const SizedBox(width: 8),
          // Plain text, not selectable: a selection started here would be the
          // one thing that could surface a review toolbar over a snapshot that
          // cannot be commented on. Copy still works through any ancestor
          // SelectionArea.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text.rich(
                TextSpan(
                  children: [
                    if (spec.tokens.isEmpty)
                      TextSpan(text: ' ', style: style)
                    else
                      for (final t in spec.tokens)
                        TextSpan(
                          text: t.text,
                          style: style.copyWith(
                            color: t.colorValue != null
                                ? Color(t.colorValue!)
                                : null,
                            backgroundColor: t.backgroundColorValue != null
                                ? Color(t.backgroundColorValue!)
                                : null,
                          ),
                        ),
                  ],
                ),
                style: style,
                strutStyle: strut,
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
