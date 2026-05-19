import 'package:cc_markdown/cc_markdown.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/material.dart';

/// Renders inline `code` as the app's soft chip (Container background — NOT
/// `TextStyle.backgroundColor`, which would paint over the selection
/// highlight). cc_markdown embeds it as a `WidgetSpan` inside the paragraph's
/// single `Text.rich`, so surrounding text wraps naturally.
class AppInlineCodeBuilder extends CcNodeBuilder {
  /// Creates an [AppInlineCodeBuilder].
  const AppInlineCodeBuilder();

  /// The chip carries text that reads as part of the sentence, so it must
  /// share the paragraph's baseline — middle-aligning the padded chip box
  /// leaves the code riding visibly high next to the surrounding words.
  @override
  PlaceholderAlignment get placeholderAlignment =>
      PlaceholderAlignment.baseline;

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) {
    final code = (node as CcInlineCode).code;
    return buildSharedInlineCodeChip(
      code,
      style.inlineCode ?? style.code ?? const TextStyle(),
    );
  }
}

/// Renders `<details>`/`<summary>` blocks with the app's disclosure chrome
/// (chevron + summary header, indented body), replacing the engine's neutral
/// default. Recursion goes through the engine's bound render callbacks.
class AppDetailsBuilder extends CcNodeBuilder {
  /// Creates an [AppDetailsBuilder].
  const AppDetailsBuilder();

  @override
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context) {
    final details = node as CcDetails;
    return _AppDetailsView(
      details: details,
      renderContext: context,
      style: style,
    );
  }
}

class _AppDetailsView extends StatefulWidget {
  const _AppDetailsView({
    required this.details,
    required this.renderContext,
    required this.style,
  });

  final CcDetails details;
  final CcRenderContext renderContext;
  final CcMarkdownStyle style;

  @override
  State<_AppDetailsView> createState() => _AppDetailsViewState();
}

class _AppDetailsViewState extends State<_AppDetailsView> {
  late bool _open = widget.details.open;

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final summary = widget.details.summary.isEmpty
        ? const [CcText('Details')]
        : widget.details.summary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _open ? AppIcons.chevronDown : AppIcons.chevronRight,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: widget.renderContext.renderInlines!(
                    summary,
                    (style.paragraph ?? const TextStyle()).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 6, bottom: 2),
            child: widget.renderContext.renderBlocks!(widget.details.children),
          ),
      ],
    );
  }
}
