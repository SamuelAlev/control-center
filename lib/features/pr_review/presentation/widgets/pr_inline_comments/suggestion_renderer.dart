import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_markdown/cc_markdown.dart' show CcSelectionRegion;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/features/pr_review/presentation/utils/word_diff.dart';
import 'package:control_center/features/pr_review/presentation/widgets/github_reference_link_builder.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/suggestion_diff_line.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/syntax/grammar_registry.dart';
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Suggestion aware markdown.
class SuggestionAwareMarkdown extends ConsumerWidget {
  /// SuggestionAwareMarkdown({.
  const SuggestionAwareMarkdown({
    super.key,
    required this.prRef,
    required this.body,
    required this.originalCode,
    this.filePath,
    this.originalStartLine,
  });

  /// The PR this suggestion belongs to: its repo resolves the owner/repo that
  /// bare `#N` references link against — never the UI-selected active repo.
  final PrRef prRef;

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
    final activeRepo = ref.watch(prRepoRowProvider(prRef));
    final owner = activeRepo?.remoteOwner ?? '';
    final repo = activeRepo?.remoteName ?? '';
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final workspaceRepos = workspaceId == null
        ? const <String>{}
        : (ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [])
              .map(
                (r) =>
                    '${r.remoteOwner.toLowerCase()}/${r.remoteName.toLowerCase()}',
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
      compact: true,
      codeFontFamily: codeFont,
      codeLigatures: ref.watch(codeFontLigaturesProvider),
      linkBuilder: owner.isNotEmpty && repo.isNotEmpty
          ? GitHubReferenceLinkBuilder(
              currentOwner: owner,
              currentRepo: repo,
              knownWorkspaceRepos: workspaceRepos,
              onSwitchToRepo: switchToRepo,
            )
          : null,
      onSwitchToRepo: switchToRepo,
    );
  }
}

class _SuggestionMiniDiff extends ConsumerStatefulWidget {
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
  ConsumerState<_SuggestionMiniDiff> createState() =>
      _SuggestionMiniDiffState();
}

class _SuggestionMiniDiffState extends ConsumerState<_SuggestionMiniDiff> {
  /// Languages this block has already asked the registry to fetch. Guards the
  /// warm below from re-entering on every rebuild.
  final Set<String> _warmed = <String>{};

  /// Tokenizing is synchronous and gives up when the grammar is not resident —
  /// which on web means a not-yet-fetched deferred pack. Without this the
  /// block renders plain and STAYS plain, because nothing ever rebuilds it:
  /// the fetch the tokenizer kicks off has no listener. Fetch it here instead
  /// and rebuild once it lands, so a suggestion is highlighted on every
  /// platform rather than only where the grammar happened to be resident.
  void _warmGrammar(String language) {
    if (!_warmed.add(language)) {
      return;
    }
    unawaited(
      ensureLanguageAvailable(language).then((available) {
        if (available && mounted) {
          setState(() {});
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final original = widget.original;
    final suggested = widget.suggested;
    final originalStartLine = widget.originalStartLine;
    final filePath = widget.filePath;
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final codeFont = ref.watch(codeFontFamilyProvider);
    final codeStyle =
        AppFonts.codeStyleDynamic(
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
    final path = filePath;
    final language = path == null ? null : shikiLangForPath(path);

    // Each side is tokenized as one block (grammar state carries across
    // lines), then indexed per row.
    final originalTokens = highlightDiffLines(
      originalLines.join('\n'),
      language,
      dark: isDark,
    );
    final suggestedTokens = highlightDiffLines(
      suggestedLines.join('\n'),
      language,
      dark: isDark,
    );
    if (language != null &&
        !_anyColored(originalTokens) &&
        !_anyColored(suggestedTokens)) {
      _warmGrammar(language);
    }

    final specs = <DiffLineSpec>[
      const DiffLineSpec(
        kind: DiffLineKind.hunkHeader,
        tokens: <DiffToken>[],
        hunkHeader: '',
      ),
      for (var i = 0; i < originalLines.length; i++)
        DiffLineSpec(
          kind: DiffLineKind.deletion,
          tokens: originalTokens[i],
          oldLine: originalStartLine + i,
        ),
      for (var i = 0; i < suggestedLines.length; i++)
        DiffLineSpec(
          kind: DiffLineKind.addition,
          tokens: suggestedTokens[i],
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
        borderRadius: AppRadii.brMd,
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
                  AppLocalizations.of(context).suggestedChange,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // ONE region over every line, not a `SelectableText` per line: each
          // of those owned its own selection, so a drag down the block only
          // ever highlighted the line it started on. The line-number gutter is
          // excluded below, so the copy is the code and not a column of
          // numbers interleaved with it.
          CcSelectionRegion(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final spec in specs)
                  if (spec.kind != DiffLineKind.hunkHeader)
                    SuggestionDiffLine(
                      spec: spec,
                      style: codeStyle,
                      gutterWidth: gutterWidth,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Whether any token in [lines] carries a syntax color — i.e. the grammar was
/// resident and tokenization actually ran.
bool _anyColored(List<List<DiffToken>> lines) =>
    lines.any((line) => line.any((t) => t.colorValue != null));
