import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcProgressBar] — the design system's flat horizontal
/// progress indicator.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Feedback → CcProgressBar`. The builders
/// return the component directly — the gallery's theme addon supplies the
/// [CcTheme] + canvas. A bare progress bar fills its parent's width, so the
/// builders constrain it with a [SizedBox] for a readable preview.

const _path = '[Components]/Feedback';

/// The determinate fill at a few fractions, from empty to complete.
@widgetbook.UseCase(name: 'Determinate', type: CcProgressBar, path: _path)
Widget ccProgressBarDeterminateUseCase(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final step in const <(String, double)>[
            ('Cloning repo', 0.0),
            ('Indexing code graph', 0.25),
            ('Running checks', 0.6),
            ('Merging worktree', 0.9),
            ('Pipeline complete', 1.0),
          ]) ...[
            Text(
              '${step.$1} · ${(step.$2 * 100).round()}%',
              style: CcTypography.bodySm.copyWith(color: t?.textSecondary),
            ),
            const SizedBox(height: 6),
            CcProgressBar(value: step.$2),
            const SizedBox(height: 18),
          ],
        ],
      ),
    ),
  );
}

/// The indeterminate state — a short segment slides back and forth when motion
/// is allowed, and collapses to a static 30% bar under reduced motion.
@widgetbook.UseCase(name: 'Indeterminate', type: CcProgressBar, path: _path)
Widget ccProgressBarIndeterminateUseCase(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent is thinking…',
            style: CcTypography.bodySm.copyWith(color: t?.textSecondary),
          ),
          const SizedBox(height: 6),
          const CcProgressBar(semanticLabel: 'Claude is working'),
        ],
      ),
    ),
  );
}

/// The height scale — thin trackers for inline rows up to chunky deck bars.
@widgetbook.UseCase(name: 'Heights', type: CcProgressBar, path: _path)
Widget ccProgressBarHeightsUseCase(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final height in const <double>[2, 4, 8, 12]) ...[
            Text(
              '${height.toInt()} px',
              style: CcTypography.bodySm.copyWith(color: t?.textSecondary),
            ),
            const SizedBox(height: 6),
            CcProgressBar(value: 0.65, height: height),
            const SizedBox(height: 18),
          ],
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcProgressBar, path: _path)
Widget ccProgressBarPlaygroundUseCase(BuildContext context) {
  final indeterminate = context.knobs.boolean(label: 'Indeterminate');
  final value = context.knobs.double.slider(
    label: 'Value',
    initialValue: 0.6,
    min: 0,
    max: 1,
  );
  final height = context.knobs.double.slider(
    label: 'Height',
    initialValue: 4,
    min: 2,
    max: 16,
  );
  return Center(
    child: SizedBox(
      width: 320,
      child: CcProgressBar(
        value: indeterminate ? null : value,
        height: height,
        semanticLabel: 'Workspace sync progress',
      ),
    ),
  );
}
