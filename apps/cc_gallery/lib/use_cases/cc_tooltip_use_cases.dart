import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTooltip] — a hover-driven, ink-dark helper panel.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Feedback → CcTooltip`. The builders return
/// the component directly — the gallery's theme addon supplies the [CcTheme]
/// and canvas. Hover the target to dwell the tooltip into view.

const _path = '[Components]/Feedback';

void _noop() {}

/// The default: a short plain-text message anchored beneath its target.
@widgetbook.UseCase(name: 'Default', type: CcTooltip, path: _path)
Widget ccTooltipDefaultUseCase(BuildContext context) {
  return const Center(
    child: CcTooltip(
      message: 'Re-run the failed checks',
      child: CcButton(onPressed: _noop, child: Text('Hover me')),
    ),
  );
}

/// A long message that wraps within [CcTooltip.maxWidth] versus a short one,
/// so the panel sizing across content lengths is visible side by side.
@widgetbook.UseCase(name: 'Long and short', type: CcTooltip, path: _path)
Widget ccTooltipLongAndShortUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 32,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcTooltip(
          message: 'Merge',
          child: CcButton(onPressed: _noop, child: Text('Short')),
        ),
        CcTooltip(
          message:
              'This pull request targets a protected branch. Squash and merge '
              'requires a passing review from a code owner on the workspace.',
          child: CcButton(onPressed: _noop, child: Text('Wraps to max width')),
        ),
      ],
    ),
  );
}

/// Rich [CcTooltip.tip] content instead of a plain message — an icon row plus
/// a label, the kind of detail a pipeline status chip surfaces on hover.
@widgetbook.UseCase(name: 'Rich content', type: CcTooltip, path: _path)
Widget ccTooltipRichContentUseCase(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: CcTooltip(
      tip: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.gitBranch, size: 14, color: t?.textWhite),
          const SizedBox(width: 6),
          Text(
            'agent/refactor-auth · 3 commits ahead',
            style: CcTypography.caption.copyWith(color: t?.textWhite),
          ),
        ],
      ),
      child: const CcButton(onPressed: _noop, child: Text('Workspace status')),
    ),
  );
}

/// Interactive playground — drive the message, dwell, width, and placement.
@widgetbook.UseCase(name: 'Playground', type: CcTooltip, path: _path)
Widget ccTooltipPlaygroundUseCase(BuildContext context) {
  final message = context.knobs.string(
    label: 'Message',
    initialValue: 'Deploy this agent to the workspace',
  );
  final maxWidth = context.knobs.double.slider(
    label: 'Max width',
    initialValue: 280,
    min: 120,
    max: 400,
  );
  final showDelayMs = context.knobs.double.slider(
    label: 'Show delay (ms)',
    initialValue: 500,
    min: 0,
    max: 1500,
  );
  final placement = context.knobs.object.dropdown(
    label: 'Placement',
    options: _TooltipPlacement.values,
    labelBuilder: (p) => p.label,
  );
  return Center(
    child: CcTooltip(
      message: message,
      maxWidth: maxWidth,
      showDelay: Duration(milliseconds: showDelayMs.round()),
      targetAnchor: placement.targetAnchor,
      followerAnchor: placement.followerAnchor,
      offset: placement.offset,
      child: const CcButton(onPressed: _noop, child: Text('Hover me')),
    ),
  );
}

/// Anchor presets exercising [CcTooltip]'s target/follower placement props.
enum _TooltipPlacement {
  below('Below', Alignment.bottomCenter, Alignment.topCenter, Offset(0, 8)),
  above('Above', Alignment.topCenter, Alignment.bottomCenter, Offset(0, -8)),
  right('Right', Alignment.centerRight, Alignment.centerLeft, Offset(8, 0)),
  left('Left', Alignment.centerLeft, Alignment.centerRight, Offset(-8, 0));

  const _TooltipPlacement(
    this.label,
    this.targetAnchor,
    this.followerAnchor,
    this.offset,
  );

  final String label;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;
}
