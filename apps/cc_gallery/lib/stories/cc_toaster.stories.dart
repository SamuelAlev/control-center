import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_toaster.stories.g.dart';

/// Stories for [CcToastScope] — the design system's transient toast host.
///
/// Toasts are surfaced imperatively: descendants call
/// `CcToastScope.of(context).show(message, variant: ...)`, which enqueues an
/// overlay-backed card that animates in, waits, then dismisses itself. Each
/// builder therefore wraps a [CcToastScope] and exposes [CcButton] triggers so
/// the toast can be observed in the canvas. The gallery's theme addon supplies
/// the [CcTheme] + canvas; builders add no background of their own.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcToastScope', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcToastScopePlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    variant: EnumArg<CcToastVariant>(
      CcToastVariant.values.first,
      name: 'Variant',
      values: CcToastVariant.values,
    ),
    alignment: SingleArg<Alignment>(
      Alignment.topLeft,
      name: 'Alignment',
      values: const [
        Alignment.topLeft,
        Alignment.topRight,
        Alignment.bottomLeft,
        Alignment.bottomRight,
      ],
      labelBuilder: _alignmentLabel,
    ),
    title: NullableStringArg(null, name: 'Title'),
    message: StringArg(
      'Agent deployed to the review workspace',
      name: 'Message',
    ),
    seconds: DoubleArg(
      5,
      name: 'Duration (s)',
      style: const SliderDoubleArgStyle(min: 1, max: 8, divisions: 7),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccToasterPlaygroundStory(context, args)),
);

final $Alignments = _Story(
  args: _Args.fixed(preview: ccToasterAlignmentsStory),
);

final $Variants = _Story(args: _Args.fixed(preview: ccToasterVariantsStory));

final $WithTitle = _Story(
  name: 'With title',
  args: _Args.fixed(preview: ccToasterWithTitleStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcToastScopePlayground {
  CcToastScopePlayground({
    required this.variant,
    required this.alignment,
    required this.title,
    required this.message,
    required this.seconds,
  });

  final CcToastVariant variant;
  final Alignment alignment;
  final String? title;
  final String message;
  final double seconds;
}

/// One trigger per severity, so every [CcToastVariant] accent + status shape
/// can be raised side by side. Raise several to see the stack: toasts share
/// one fixed width and the newest enters at the anchored edge, nudging the
/// older ones along. Hovering a toast pauses its auto-dismiss countdown.
Widget ccToasterVariantsStory(BuildContext context) {
  return const CcToastScope(child: _VariantTriggers());
}

/// The titled anatomy — a semibold headline over a secondary-tone message,
/// for toasts where the outcome and its detail read better apart.
Widget ccToasterWithTitleStory(BuildContext context) {
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
Widget ccToasterAlignmentsStory(BuildContext context) {
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
Widget ccToasterPlaygroundStory(
  BuildContext context,
  CcToastScopePlaygroundArgs args,
) {
  final variant = args.variant;
  final alignment = args.alignment;
  final title = args.title;
  final message = args.message;
  final seconds = args.seconds;
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
