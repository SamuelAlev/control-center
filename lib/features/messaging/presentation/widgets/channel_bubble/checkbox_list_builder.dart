import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;

/// Builder that renders markdown checkbox lists with [CcCheckbox].
class CcCheckboxListBuilder extends sm.MarkdownWidgetBuilder {
  /// Creates a [CcCheckboxListBuilder].
  const CcCheckboxListBuilder();

  @override
  bool canBuild(sm.MarkdownNode node) => node is sm.ListNode;

  @override
  Widget build(
    sm.MarkdownNode node,
    sm.MarkdownStyleSheet styleSheet,
    sm.MarkdownRenderContext context,
  ) {
    final listNode = node as sm.ListNode;
    final indent = styleSheet.listIndent ?? 24.0;

    final listItems = <Widget>[];
    for (var i = 0; i < listNode.items.length; i++) {
      final item = listNode.items[i];
      final index = listNode.ordered ? listNode.startIndex + i : null;

      listItems.add(
        _buildListItem(item, index, indent, styleSheet, context),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: listItems,
    );
  }

  Widget _buildListItem(
    sm.ListItemNode item,
    int? index,
    double indent,
    sm.MarkdownStyleSheet styleSheet,
    sm.MarkdownRenderContext context,
  ) {
    Widget marker;
    if (item.checked != null) {
      marker = SizedBox(
        height: 22,
        child: FittedBox(
          fit: BoxFit.contain,
          child: CcCheckbox(value: item.checked!, onChanged: null),
        ),
      );
    } else if (index != null) {
      marker = Text('$index. ', style: styleSheet.listBulletStyle);
    } else {
      marker = Text('• ', style: styleSheet.listBulletStyle);
    }

    final inlineRenderer = context.inlineRenderer;
    Widget content;
    if (inlineRenderer != null) {
      content = inlineRenderer(item.children, styleSheet.textStyle);
    } else {
      final buffer = StringBuffer();
      for (final child in item.children) {
        if (child is sm.TextNode) {
          buffer.write(child.content);
        }
      }
      content = Text(buffer.toString(), style: styleSheet.textStyle);
    }

    return Padding(
      padding: EdgeInsets.only(left: context.listLevel * indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          marker,
          const SizedBox(width: 4),
          Expanded(child: content),
        ],
      ),
    );
  }
}
