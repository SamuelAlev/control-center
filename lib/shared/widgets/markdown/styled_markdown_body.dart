import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/shared/widgets/github_markdown_body.dart'
    show GitHubMarkdownBody;
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_parse_pool.dart';
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
class StyledMarkdownBody extends ConsumerStatefulWidget {
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
  ConsumerState<StyledMarkdownBody> createState() => _StyledMarkdownBodyState();
}

class _StyledMarkdownBodyState extends ConsumerState<StyledMarkdownBody> {
  @override
  void initState() {
    super.initState();
    _prefetch();
  }

  @override
  void didUpdateWidget(StyledMarkdownBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _prefetch();
    }
  }

  // Parse a large document off the main thread and warm CcMarkdownCache so
  // rebuilds/re-mounts (theme changes, scroll virtualization) of this body
  // render without a synchronous parse on the UI thread — the real win on the
  // web, where there are no isolates. Best-effort and gated to large docs; the
  // build() below always parses synchronously on a cache miss, so rendering is
  // never blocked on the worker. `data` is parsed verbatim here (no GitHub
  // preprocessing), so the prefetched cache key matches what build() looks up.
  void _prefetch() {
    MarkdownParsePool.instance.prefetch(widget.data, githubMarkdownPlugins);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final compact = widget.compact;
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
      plugins: githubMarkdownPlugins,
      options: githubMarkdownOptions,
      builders: githubMarkdownBuilders,
      imageBuilder: appMarkdownImageBuilder,
      codeBuilder: (code, language, {required bool cache}) =>
          buildSharedCodeBlock(
            context,
            code,
            language,
            codeFontFamily: codeFont,
            codeLigatures: codeLigatures,
            cache: cache,
          ),
    );
  }
}
