import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart'
    show GitHubMarkdownBody;
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders markdown with the shared unified look ([appMarkdownStyle]): soft
/// inline `code` chips, fenced code blocks with a copy button, read-only
/// task-list checkboxes, footnotes and `<details>`.
///
/// This is the repo-agnostic counterpart to PR rendering: it deliberately omits
/// the GitHub reference-link resolution, cross-repo switching and private
/// attachment plumbing that [GitHubMarkdownBody] layers on top. Use it for
/// surfaces that aren't bound to a GitHub repo — e.g. ticket descriptions,
/// meeting notes, diff review comments.
class StyledMarkdownBody extends ConsumerWidget {
  /// Creates a [StyledMarkdownBody].
  const StyledMarkdownBody({
    super.key,
    required this.data,
    this.compact = false,
    this.plugins,
    this.builders,
  });

  /// The raw markdown to render.
  final String data;

  /// Whether to use the tighter, smaller-type variant of the stylesheet.
  final bool compact;

  /// Parser plugins. Defaults to the GitHub register (plugin-free GFM).
  final CcPluginSet? plugins;

  /// Builder overrides. Defaults to the GitHub register.
  final CcBuilderRegistry? builders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    final codeLigatures = ref.watch(codeFontLigaturesProvider);
    return CcMarkdown(
      data: data,
      selectable: true,
      style: appMarkdownStyle(
        context,
        compact: compact,
        codeFontFamily: codeFont,
        codeLigatures: codeLigatures,
      ),
      plugins: plugins ?? githubMarkdownPlugins,
      options: githubMarkdownOptions,
      builders: builders ?? githubMarkdownBuilders,
      imageBuilder: appMarkdownImageBuilder,
      codeBuilder: sharedCodeBuilder(
        codeFontFamily: codeFont,
        codeLigatures: codeLigatures,
      ),
    );
  }
}
