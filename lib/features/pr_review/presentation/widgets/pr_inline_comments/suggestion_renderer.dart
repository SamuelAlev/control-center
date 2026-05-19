import 'dart:convert';
import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/features/pr_review/presentation/utils/word_diff.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Suggestion aware markdown.
class SuggestionAwareMarkdown extends ConsumerWidget {
  /// SuggestionAwareMarkdown({.
  const SuggestionAwareMarkdown({
    super.key,
    required this.body,
    required this.originalCode,
    this.filePath,
    this.originalStartLine,
  });

  /// Raw markdown body (may contain suggestion fences).
  final String body;

  /// Original code the suggestion replaces.
  final String originalCode;

  /// String?.
  final String? filePath;

  /// int?.
  final int? originalStartLine;

  static final RegExp _suggestionFence = RegExp(
    r'```suggestion\s*\n([\s\S]*?)\n?```',
    multiLine: true,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = _suggestionFence.firstMatch(body);
    if (match == null) {
      return _markdown(context, ref, body);
    }

    final suggested = match.group(1) ?? '';
    final before = body.substring(0, match.start).trim();
    final after = body.substring(match.end).trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (before.isNotEmpty) _markdown(context, ref, before),
        if (before.isNotEmpty) const SizedBox(height: 6),
        _SuggestionMiniDiff(
          original: originalCode,
          suggested: suggested,
          filePath: filePath,
          originalStartLine: originalStartLine ?? 1,
        ),
        if (after.isNotEmpty) const SizedBox(height: 6),
        if (after.isNotEmpty) _markdown(context, ref, after),
      ],
    );
  }

  Widget _markdown(BuildContext context, WidgetRef ref, String data) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    final activeRepo = ref.watch(currentPrRepoProvider);
    final owner = activeRepo?.githubOwner ?? '';
    final repo = activeRepo?.githubRepoName ?? '';
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final workspaceRepos = workspaceId == null
        ? const <String>{}
        : (ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [])
              .map(
                (r) =>
                    '${r.githubOwner.toLowerCase()}/${r.githubRepoName.toLowerCase()}',
              )
              .toSet();

    Future<void> switchToRepo(String wsId, String repoId) async {
      await ref.read(activeWorkspaceIdProvider.notifier).setActive(wsId);
      await ref.read(activeRepoIdProvider.notifier).setActive(repoId);
    }

    return GitHubMarkdownBody(
      data: data,
      repoOwner: owner.isEmpty ? null : owner,
      repoName: repo.isEmpty ? null : repo,
      styleSheet: githubMarkdownStyleSheet(
        context,
        compact: true,
        codeFontFamily: codeFont,
        codeLigatures: ref.watch(codeFontLigaturesProvider),
      ),
      checkboxBuilder: markdownCheckboxBuilder(context),
      builders: {
        'code': InlineCodeBuilder(),
        'pre': CodeBlockBuilder(
          codeFontFamily: codeFont,
          codeLigatures: ref.watch(codeFontLigaturesProvider),
        ),
        if (owner.isNotEmpty && repo.isNotEmpty)
          'a': GitHubReferenceLinkBuilder(
            currentOwner: owner,
            currentRepo: repo,
            knownWorkspaceRepos: workspaceRepos,
            onSwitchToRepo: switchToRepo,
          ),
      },
      onSwitchToRepo: switchToRepo,
    );
  }
}

class _SuggestionMiniDiff extends ConsumerWidget {
  const _SuggestionMiniDiff({
    required this.original,
    required this.suggested,
    required this.originalStartLine,
    this.filePath,
  });
  final String original;
  final String suggested;
  final int originalStartLine;
  final String? filePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final codeFont = ref.watch(codeFontFamilyProvider);
    final codeStyle = AppFonts.codeStyleDynamic(
      codeFont,
      fontSize: 12,
      height: 1.55,
      color: tokens.textPrimary,
    ).copyWith(
      fontFeatures: AppFonts.codeFontFeatures(
        ligatures: ref.watch(codeFontLigaturesProvider),
      ),
    );
    final originalLines = const LineSplitter().convert(original);
    final suggestedLines = const LineSplitter().convert(suggested);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = diffSyntaxPalette(isDark: isDark);
    final language = _languageFor(filePath);

    final specs = <DiffLineSpec>[
      const DiffLineSpec(
        kind: DiffLineKind.hunkHeader,
        tokens: <DiffToken>[],
        hunkHeader: '',
      ),
      for (var i = 0; i < originalLines.length; i++)
        DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: highlightLineTokens(originalLines[i], language, palette),
          oldLine: originalStartLine + i,
        ),
      for (var i = 0; i < suggestedLines.length; i++)
        DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: highlightLineTokens(suggestedLines[i], language, palette),
          newLine: originalStartLine + i,
        ),
    ];
    applyInlineWordDiff(specs, palette);

    final maxLineNumber =
        originalStartLine +
        math.max(originalLines.length, suggestedLines.length);
    final gutterWidth = math.max(
      24.0,
      8.0 * maxLineNumber.toString().length + 12.0,
    );

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSecondary),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: tokens.bgSecondary.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(color: tokens.borderSecondary, width: 0.5),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Icon(AppIcons.diff, size: 12, color: tokens.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'Suggested change',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          for (final spec in specs)
            if (spec.kind != DiffLineKind.hunkHeader)
              _SuggestionDiffLine(
                spec: spec,
                style: codeStyle,
                gutterWidth: gutterWidth,
              ),
        ],
      ),
    );
  }

  static String? _languageFor(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return null;
    }

    final dot = filePath.lastIndexOf('.');
    if (dot == -1 || dot == filePath.length - 1) {
      return null;
    }

    return languageForExtension(filePath.substring(dot + 1).toLowerCase());
  }
}

class _SuggestionDiffLine extends StatelessWidget {
  const _SuggestionDiffLine({
    required this.spec,
    required this.style,
    required this.gutterWidth,
  });
  final DiffLineSpec spec;
  final TextStyle style;
  final double gutterWidth;

  @override
  Widget build(BuildContext context) {
    final isAdd = spec.kind == DiffLineKind.addition;
    final bgColor = (isAdd ? const Color(0xFF2DA44E) : const Color(0xFFCF222E))
        .withValues(alpha: 0.10);
    final gutterColor =
        (isAdd ? const Color(0xFF1A7F37) : const Color(0xFFCF222E)).withValues(
          alpha: 0.85,
        );
    final lineNumber = isAdd ? spec.newLine : spec.oldLine;
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: gutterWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                lineNumber?.toString() ?? '',
                textAlign: TextAlign.right,
                style: style.copyWith(
                  color: gutterColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TokenizedText(tokens: spec.tokens, baseStyle: style),
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenizedText extends StatelessWidget {
  const _TokenizedText({required this.tokens, required this.baseStyle});
  final List<DiffToken> tokens;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Text(' ', style: baseStyle);
    }

    return SelectableText.rich(
      TextSpan(
        children: [
          for (final t in tokens)
            TextSpan(
              text: t.text,
              style: baseStyle.copyWith(
                color: t.colorValue != null ? Color(t.colorValue!) : null,
                backgroundColor: t.backgroundColorValue != null
                    ? Color(t.backgroundColorValue!)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
