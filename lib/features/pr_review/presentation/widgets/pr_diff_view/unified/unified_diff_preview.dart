import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:flutter/widgets.dart';

/// GitHub renders a Markdown file's leading YAML front matter as a metadata
/// table; a raw render collapses those `key: value` lines into one run-on
/// paragraph. Detect a front-matter block (`---` on the first line, closed by a
/// later `---`) and re-wrap it as a fenced YAML block so it reads as structured
/// metadata. Anything else is returned unchanged.
String withRenderableFrontmatter(String content) {
  final lines = content.split('\n');
  if (lines.isEmpty || lines.first.trim() != '---') {
    return content;
  }
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].trim() == '---') {
      final frontMatter = lines.sublist(1, i).join('\n').trim();
      final rest = lines.sublist(i + 1).join('\n').trimLeft();
      if (frontMatter.isEmpty) {
        return rest;
      }
      return '```yaml\n$frontMatter\n```\n\n$rest';
    }
  }
  return content;
}

/// Renders a Markdown file's HEAD content as a rich preview inside the diff, in
/// place of its source diff (the per-file "rich diff" toggle).
///
/// Content is fetched lazily but seeded from [cachedContent] (the view's
/// per-file cache) when available, so a recycled preview re-renders
/// synchronously — no loader frame, no re-fetch — which keeps the
/// `HeightReporter`-measured height stable as you scroll near it. On a refresh
/// that invalidates the cache, the previously-rendered content stays visible
/// until the new fetch resolves, so the body never collapses to the loader and
/// the diff doesn't jump.
class MarkdownPreviewBody extends StatefulWidget {
  /// Creates a [MarkdownPreviewBody].
  const MarkdownPreviewBody({
    super.key,
    required this.path,
    required this.fetch,
    required this.cachedContent,
    required this.onLoaded,
  });

  /// File path to render (the new/HEAD side).
  final String path;

  /// Fetches the file's full HEAD content.
  final Future<String> Function(String path) fetch;

  /// Already-resolved content from the view's cache, or null to fetch.
  final String? cachedContent;

  /// Called with freshly-fetched content so the view can cache it.
  final ValueChanged<String> onLoaded;

  @override
  State<MarkdownPreviewBody> createState() => _MarkdownPreviewBodyState();
}

class _MarkdownPreviewBodyState extends State<MarkdownPreviewBody> {
  String? _content;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _content = widget.cachedContent;
    if (_content == null) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant MarkdownPreviewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _content = widget.cachedContent;
      _error = null;
      if (_content == null) {
        _load();
      }
    } else if (widget.cachedContent == null && _content != null) {
      _load();
    } else if (widget.cachedContent != null && _content == null) {
      _content = widget.cachedContent;
    }
  }

  Future<void> _load() async {
    try {
      final content = await widget.fetch(widget.path);
      if (!mounted) {
        return;
      }
      widget.onLoaded(content);
      setState(() {
        _content = content;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    final surface = tokens.bgPrimary;
    final content = _content;
    final Widget child;
    if (content != null) {
      child = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: StyledMarkdownBody(data: withRenderableFrontmatter(content)),
          ),
        ),
      );
    } else if (_error != null) {
      child = Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            AppLocalizations.of(context).failedToLoad,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
        ),
      );
    } else {
      child = const SizedBox(
        height: 120,
        child: Center(child: CcSpinner(size: 20)),
      );
    }
    return Container(width: double.infinity, color: surface, child: child);
  }
}
