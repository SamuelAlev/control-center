import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcLinkText] — inline text that reads as a link.
///
/// The underline is drawn from a token rather than the text decoration so it
/// keeps its own contrast against the surface; a link is never signalled by
/// color alone.

const _path = '[Components]/Typography';

/// A link in running text, and one standing on its own.
@widgetbook.UseCase(name: 'In context', type: CcLinkText, path: _path)
Widget ccLinkTextInContextUseCase(BuildContext context) {
  final t = context.ds;
  return Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CcLinkText(
            'Open the pull request',
            style: CcTypography.body.copyWith(color: t.fgBrandPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          CcLinkText(
            'A longer link that wraps across more than one line so the '
            'underline can be seen following the text rather than the box',
            style: CcTypography.bodySm.copyWith(color: t.fgBrandPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          CcLinkText(
            'Truncated to a single line with an ellipsis when the row is tight',
            style: CcTypography.bodySm.copyWith(color: t.fgBrandPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcLinkText, path: _path)
Widget ccLinkTextPlaygroundUseCase(BuildContext context) {
  final t = context.ds;
  final text = context.knobs.string(
    label: 'Text',
    initialValue: 'github.com/anthropics/control-center',
  );
  final maxLines = context.knobs.int.slider(
    label: 'Max lines (0 = unbounded)',
    initialValue: 0,
    max: 4,
  );
  return Center(
    child: SizedBox(
      width: 320,
      child: CcLinkText(
        text,
        style: CcTypography.body.copyWith(color: t.fgBrandPrimary),
        maxLines: maxLines == 0 ? null : maxLines,
        overflow: maxLines == 0 ? null : TextOverflow.ellipsis,
      ),
    ),
  );
}
