part of 'transcript_flow.dart';

/// Chat-register markdown for prose that may be (or may have been) streaming.
///
/// While [streaming] it renders through [CcStreamingMarkdown] so per-delta
/// builds re-parse only the volatile tail. When a stream ends IN PLACE (the
/// same element, carried across the row's open → closed move by its key), it
/// stays on that renderer and finalizes it: the authoritative parse seeds the
/// parse cache and the sealed blocks it agrees with keep their widgets, so
/// the frame a turn finishes re-renders one block, not the whole answer.
/// Content that was never streamed here takes the cached [CcMarkdown] path.
///
/// The in-place path needs an ancestor-owned selection region (the feed's
/// [CcSelectionScope]): standalone, [CcMarkdown] owns its own selection region
/// and the streaming renderer has none, so the swap is the correct behaviour
/// there.
class _ChatProseMarkdown extends StatefulWidget {
  const _ChatProseMarkdown({
    required this.data,
    required this.style,
    required this.codeBuilder,
    required this.streaming,
  });

  final String data;
  final CcMarkdownStyle style;
  final CcCodeBuilder codeBuilder;
  final bool streaming;

  @override
  State<_ChatProseMarkdown> createState() => _ChatProseMarkdownState();
}

class _ChatProseMarkdownState extends State<_ChatProseMarkdown> {
  /// Whether this element has rendered a live stream.
  bool _streamed = false;

  @override
  Widget build(BuildContext context) {
    _streamed = _streamed || widget.streaming;
    if (_streamed && CcSelectionScope.of(context)) {
      return CcStreamingMarkdown.value(
        data: widget.data,
        complete: !widget.streaming,
        selectable: true,
        style: widget.style,
        plugins: chatMarkdownPlugins,
        options: chatMarkdownOptions,
        builders: chatMarkdownBuilders,
        imageBuilder: appMarkdownImageBuilder,
        codeBuilder: widget.codeBuilder,
      );
    }
    if (widget.streaming) {
      return CcStreamingMarkdown.value(
        data: widget.data,
        selectable: true,
        style: widget.style,
        plugins: chatMarkdownPlugins,
        options: chatMarkdownOptions,
        builders: chatMarkdownBuilders,
        imageBuilder: appMarkdownImageBuilder,
        codeBuilder: widget.codeBuilder,
      );
    }
    return CcMarkdown(
      data: widget.data,
      selectable: true,
      style: widget.style,
      plugins: chatMarkdownPlugins,
      options: chatMarkdownOptions,
      builders: chatMarkdownBuilders,
      imageBuilder: appMarkdownImageBuilder,
      codeBuilder: widget.codeBuilder,
    );
  }
}
