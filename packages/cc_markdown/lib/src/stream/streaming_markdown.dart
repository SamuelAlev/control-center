import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/cache/parse_cache.dart';
import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';
import 'package:cc_markdown/src/render/node_builder.dart';
import 'package:cc_markdown/src/render/render_context.dart';
import 'package:cc_markdown/src/render/renderer.dart';
import 'package:cc_markdown/src/selection/selection_scope.dart';
import 'package:cc_markdown/src/stream/stream_controller.dart';
import 'package:cc_markdown/src/style/style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Streaming-first markdown rendering for LLM output.
///
/// Sealed blocks (see [CcMarkdownStreamController]) render ONCE and are
/// reused as `identical()` widget instances across frames — `Element.update`
/// skips their whole subtree, so a delta costs one small tail rebuild, not a
/// document re-render. The volatile tail parses ephemerally per frame (one
/// block, typically small) with `cache: false` threaded to [codeBuilder] so
/// a still-streaming fence doesn't churn the app's highlight cache.
///
/// Three ways to drive it:
///  * [CcStreamingMarkdown.new] — bring your own controller (shared state,
///    `complete()` on finish seeds the global parse cache);
///  * [CcStreamingMarkdown.value] — data-in per rebuild; an internal
///    controller `setText`s the grown string (drop-in for parents that
///    already rebuild per delta);
///  * [CcStreamingMarkdown.listenable] — subscribes to a
///    `ValueListenable<String>` so the PARENT never rebuilds per delta.
class CcStreamingMarkdown extends StatefulWidget {
  /// Controller-driven streaming rendering.
  const CcStreamingMarkdown({
    required CcMarkdownStreamController this.controller,
    super.key,
    this.style,
    this.builders,
    this.onTapLink,
    this.onTapImage,
    this.imageBuilder,
    this.codeBuilder,
    this.selectable = false,
  }) : data = null,
       source = null,
       plugins = CcPluginSet.empty,
       options = const CcParseOptions();

  /// Data-driven: pass the (growing) accumulated text each rebuild.
  const CcStreamingMarkdown.value({
    required String this.data,
    super.key,
    this.plugins = CcPluginSet.empty,
    this.options = const CcParseOptions(),
    this.style,
    this.builders,
    this.onTapLink,
    this.onTapImage,
    this.imageBuilder,
    this.codeBuilder,
    this.selectable = false,
  }) : controller = null,
       source = null;

  /// Listenable-driven: subscribes to [source]; the parent widget never
  /// rebuilds per delta.
  const CcStreamingMarkdown.listenable({
    required ValueListenable<String> this.source,
    super.key,
    this.plugins = CcPluginSet.empty,
    this.options = const CcParseOptions(),
    this.style,
    this.builders,
    this.onTapLink,
    this.onTapImage,
    this.imageBuilder,
    this.codeBuilder,
    this.selectable = false,
  }) : controller = null,
       data = null;

  /// External controller (controller constructor only).
  final CcMarkdownStreamController? controller;

  /// Accumulated text (value constructor only).
  final String? data;

  /// Text source (listenable constructor only).
  final ValueListenable<String>? source;

  /// Plugins for the internal controller (value/listenable constructors).
  final CcPluginSet plugins;

  /// Parse options for the internal controller (value/listenable).
  final CcParseOptions options;

  /// Stylesheet (value-equal styles do not invalidate the block memo).
  final CcMarkdownStyle? style;

  /// Builder overrides (identity change invalidates the memo).
  final CcBuilderRegistry? builders;

  /// Link tap callback.
  final void Function(String url)? onTapLink;

  /// Image tap callback.
  final void Function(String url, String? alt, String? title)? onTapImage;

  /// Custom image renderer.
  final CcImageBuilder? imageBuilder;

  /// Custom fenced-code renderer (`cache: false` for the volatile tail).
  final CcCodeBuilder? codeBuilder;

  /// Whether rendered text participates in an ancestor selection region.
  final bool selectable;

  @override
  State<CcStreamingMarkdown> createState() => _CcStreamingMarkdownState();
}

class _CcStreamingMarkdownState extends State<CcStreamingMarkdown> {
  CcMarkdownStreamController? _ownedController;
  CcMarkdownStreamController get _controller =>
      widget.controller ?? _ownedController!;

  /// Sealed-block widget memo: index → (block identity, rendered widget).
  final Map<int, (CcSealedBlock, Widget)> _memo = {};
  CcMarkdownStyle? _memoStyle;
  CcBuilderRegistry? _memoBuilders;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = CcMarkdownStreamController(
        plugins: widget.plugins,
        options: widget.options,
      );
      if (widget.data != null) {
        _ownedController!.setText(widget.data!);
      }
      if (widget.source != null) {
        _ownedController!.setText(widget.source!.value);
        widget.source!.addListener(_onSource);
      }
    }
    _controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(covariant CcStreamingMarkdown old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
      _memo.clear();
    }
    if (old.source != widget.source && _ownedController != null) {
      old.source?.removeListener(_onSource);
      widget.source?.addListener(_onSource);
      if (widget.source != null) {
        _ownedController!.setText(widget.source!.value);
      }
    }
    if (widget.data != null &&
        widget.data != old.data &&
        _ownedController != null) {
      _ownedController!.setText(widget.data!);
    }
  }

  @override
  void dispose() {
    widget.source?.removeListener(_onSource);
    _controller.removeListener(_onController);
    _ownedController?.dispose();
    super.dispose();
  }

  void _onSource() => _ownedController?.setText(widget.source!.value);

  void _onController() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? const CcMarkdownStyle();
    final builders = widget.builders ?? CcBuilderRegistry.empty;

    // Environment change invalidates the memo. Style compares by VALUE (a
    // token-rebuilt-but-equal style is a non-event); builders by identity.
    if (_memoStyle != style || !identical(_memoBuilders, builders)) {
      _memo.clear();
      _memoStyle = style;
      _memoBuilders = builders;
    }

    final renderer = CcRenderer(style: style, builders: builders);
    final ancestorOwnsSelection = CcSelectionScope.of(context);
    final baseContext = CcRenderContext(
      style: style,
      onTapLink: widget.onTapLink,
      onTapImage: widget.onTapImage,
      imageBuilder: widget.imageBuilder,
      codeBuilder: widget.codeBuilder,
      selectable: widget.selectable && !ancestorOwnsSelection,
    );

    final sealed = _controller.sealedBlocks;
    _memo.removeWhere((i, _) => i >= sealed.length);
    final sealedWidgets = <Widget>[];
    for (var i = 0; i < sealed.length; i++) {
      final block = sealed[i];
      final memoed = _memo[i];
      Widget rendered;
      if (memoed != null && identical(memoed.$1, block)) {
        rendered = memoed.$2;
      } else {
        rendered = renderer.render(
          block.nodes,
          context: baseContext.copyWith(
            footnotes: [
              for (final node in block.nodes)
                if (node is CcFootnoteDef) node,
            ],
          ),
        );
        _memo[i] = (block, rendered);
      }
      if (sealedWidgets.isNotEmpty) {
        sealedWidgets.add(SizedBox(height: style.blockSpacing));
      }
      sealedWidgets.add(rendered);
    }

    // The volatile tail: ephemeral parse, cache:false code blocks. Skipped
    // once complete() collapsed everything into one sealed block.
    Widget? tail;
    final tailText = _controller.tailText;
    if (tailText.trim().isNotEmpty) {
      final tailNodes = CcMarkdownCache.parseEphemeral(
        tailText,
        _controller.plugins,
        options: _controller.options,
      );
      tail = renderer.render(
        tailNodes,
        context: baseContext.copyWith(codeCache: false),
      );
    }

    if (sealedWidgets.isEmpty && tail == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sealedWidgets.isNotEmpty)
          // One boundary around the whole sealed prefix: it repaints only
          // when a block seals; the tail repaints every delta anyway.
          RepaintBoundary(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: sealedWidgets,
            ),
          ),
        if (tail != null) ...[
          if (sealedWidgets.isNotEmpty)
            SizedBox(
              height: (widget.style ?? const CcMarkdownStyle()).blockSpacing,
            ),
          tail,
        ],
      ],
    );
  }
}
