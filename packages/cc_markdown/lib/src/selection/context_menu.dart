// The ONLY file in cc_markdown that imports Material — for the default
// adaptive selection toolbar. Everything else builds on widgets.dart.
import 'package:cc_markdown/src/selection/copy_filter.dart';
import 'package:flutter/material.dart';

/// The default selection context menu: the platform-adaptive toolbar with the
/// copy button wrapped to run the overlay-line clipboard filter after the
/// default copy action.
Widget ccDefaultSelectionContextMenu(
  BuildContext context,
  SelectableRegionState state,
) {
  return AdaptiveTextSelectionToolbar.buttonItems(
    anchors: state.contextMenuAnchors,
    buttonItems: state.contextMenuButtonItems.map((item) {
      if (item.type == ContextMenuButtonType.copy) {
        final original = item.onPressed;
        return ContextMenuButtonItem(
          label: item.label,
          type: ContextMenuButtonType.copy,
          onPressed: () {
            original?.call();
            scheduleClipboardFilter();
          },
        );
      }
      return item;
    }).toList(),
  );
}
