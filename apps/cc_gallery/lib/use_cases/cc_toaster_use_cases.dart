import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcToastScope] — the design system's transient toast host.
///
/// Toasts are surfaced imperatively: descendants call
/// `CcToastScope.of(context).show(message, variant: ...)`, which enqueues an
/// overlay-backed card that animates in, waits, then dismisses itself. Each
/// builder therefore wraps a [CcToastScope] and exposes [CcButton] triggers so
/// the toast can be observed in the canvas. The gallery's theme addon supplies
/// the [CcTheme] + canvas; builders add no background of their own.

const _path = '[Components]/Feedback';

/// One trigger per severity, so every [CcToastVariant] accent + status shape
/// can be raised side by side. Raise several to see the stack: toasts share
/// one fixed width and the newest enters at the anchored edge, nudging the
/// older ones along. Hovering a toast pauses its auto-dismiss countdown.
@widgetbook.UseCase(name: 'Variants', type: CcToastScope, path: _path)
Widget ccToasterVariantsUseCase(BuildContext context) {
  return const CcToastScope(child: _VariantTriggers());
}

/// The titled anatomy — a semibold headline over a secondary-tone message,
/// for toasts where the outcome and its detail read better apart.
@widgetbook.UseCase(name: 'With title', type: CcToastScope, path: _path)
Widget ccToasterWithTitleUseCase(BuildContext context) {
  return CcToastScope(
    child: Builder(
      builder: (ctx) => Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => CcToastScope.of(ctx).show(
                'main is now 3 commits ahead of origin',
                title: 'Branch pushed',
                variant: CcToastVariant.success,
              ),
              child: const Text('Success with title'),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => CcToastScope.of(ctx).show(
                'The build step exited with code 1',
                title: 'Pipeline failed',
                variant: CcToastVariant.danger,
              ),
              child: const Text('Danger with title'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// The same toasts, parked in each corner so the [CcToastScope.alignment] and
/// inset behaviour is legible. One scope per alignment keeps them independent.
@widgetbook.UseCase(name: 'Alignments', type: CcToastScope, path: _path)
Widget ccToasterAlignmentsUseCase(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final alignment in const [
          Alignment.topLeft,
          Alignment.topRight,
          Alignment.bottomLeft,
          Alignment.bottomRight,
        ])
          SizedBox(
            width: 220,
            height: 140,
            child: CcToastScope(
              alignment: alignment,
              child: _AlignmentTrigger(label: _alignmentLabel(alignment)),
            ),
          ),
      ],
    ),
  );
}

/// Interactive playground — drive the message, variant and dwell time, then
/// raise a toast to watch it animate in and auto-dismiss.
@widgetbook.UseCase(name: 'Playground', type: CcToastScope, path: _path)
Widget ccToasterPlaygroundUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: CcToastVariant.values,
    labelBuilder: (v) => v.name,
  );
  final alignment = context.knobs.object.dropdown(
    label: 'Alignment',
    options: const [
      Alignment.topLeft,
      Alignment.topRight,
      Alignment.bottomLeft,
      Alignment.bottomRight,
    ],
    labelBuilder: _alignmentLabel,
  );
  final title = context.knobs.stringOrNull(label: 'Title', initialValue: null);
  final message = context.knobs.string(
    label: 'Message',
    initialValue: 'Agent deployed to the review workspace',
  );
  final seconds = context.knobs.double.slider(
    label: 'Duration (s)',
    initialValue: 5,
    min: 1,
    max: 8,
    divisions: 7,
  );
  return CcToastScope(
    alignment: alignment,
    duration: Duration(milliseconds: (seconds * 1000).round()),
    child: Builder(
      builder: (ctx) => Center(
        child: CcButton(
          onPressed: () => CcToastScope.of(
            ctx,
          ).show(message, variant: variant, title: title),
          child: const Text('Raise toast'),
        ),
      ),
    ),
  );
}

String _alignmentLabel(Alignment alignment) {
  switch (alignment) {
    case Alignment.topLeft:
      return 'Top left';
    case Alignment.topRight:
      return 'Top right';
    case Alignment.bottomLeft:
      return 'Bottom left';
    case Alignment.bottomRight:
      return 'Bottom right';
  }
  return 'Bottom right';
}

/// A trigger per severity, mirroring the known-correct demo in
/// `component_stories.dart` with Control Center domain copy.
class _VariantTriggers extends StatelessWidget {
  const _VariantTriggers();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => CcToastScope.of(ctx).show('Draft review saved'),
              child: const Text('Neutral'),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => CcToastScope.of(ctx).show(
                'Pull request merged into main',
                variant: CcToastVariant.success,
              ),
              child: const Text('Success'),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => CcToastScope.of(ctx).show(
                'Workspace is over its token budget',
                variant: CcToastVariant.warning,
              ),
              child: const Text('Warning'),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              onPressed: () => CcToastScope.of(ctx).show(
                'Pipeline run failed on the build step',
                variant: CcToastVariant.danger,
              ),
              child: const Text('Danger'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single trigger used inside each corner-aligned scope.
class _AlignmentTrigger extends StatelessWidget {
  const _AlignmentTrigger({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => Center(
        child: CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => CcToastScope.of(ctx).show(
            'Claude Opus finished the task',
            variant: CcToastVariant.success,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
