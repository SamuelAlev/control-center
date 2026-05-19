import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders markdown with the shared GitHub-style look: the
/// [githubMarkdownStyleSheet] typography, soft inline `code` chips
/// ([InlineCodeBuilder]), fenced code blocks with a copy button
/// ([CodeBlockBuilder]), and read-only task-list checkboxes
/// ([markdownCheckboxBuilder]).
///
/// This is the repo-agnostic counterpart to PR rendering: it deliberately omits
/// the GitHub reference-link resolution, cross-repo switching, and private
/// attachment plumbing that `PrBodyMarkdown` layers on top. Use it for surfaces
/// that aren't bound to a GitHub repo — e.g. ticket descriptions.
class StyledMarkdownBody extends ConsumerWidget {
  /// Creates a [StyledMarkdownBody].
  const StyledMarkdownBody({
    super.key,
    required this.data,
    this.compact = false,
  });

  /// The raw markdown to render.
  final String data;

  /// Whether to use the tighter, smaller-type variant of the stylesheet.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    final codeLigatures = ref.watch(codeFontLigaturesProvider);
    return GitHubMarkdownBody(
      data: data,
      styleSheet: githubMarkdownStyleSheet(
        context,
        compact: compact,
        codeFontFamily: codeFont,
        codeLigatures: codeLigatures,
      ),
      checkboxBuilder: markdownCheckboxBuilder(context),
      builders: {
        'code': InlineCodeBuilder(),
        'pre': CodeBlockBuilder(
          codeFontFamily: codeFont,
          codeLigatures: codeLigatures,
        ),
      },
    );
  }
}
