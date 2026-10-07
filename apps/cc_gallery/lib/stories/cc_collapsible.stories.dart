import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_collapsible.stories.g.dart';

/// Stories for [CcCollapsible] — the body of every accordion and disclosure:
/// it grows from the top edge to reveal its child and shrinks it away again.
///
/// The stories below are listed under `Primitives → CcCollapsible`. A toggle
/// from the keyboard snaps without animating; reduced motion snaps the size
/// and keeps only a short fade on reveal.

const _path = '[Primitives]';

const component = ComponentMeta(name: 'CcCollapsible', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcCollapsiblePlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    expanded: BoolArg(true, name: 'Expanded'),
    durationMs: IntArg(
      160,
      name: 'Expand duration (ms)',
      style: const SliderIntArgStyle(min: 80, max: 600, divisions: 26),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccCollapsiblePlaygroundStory(context, args),
  ),
);

final $Accordion = _Story(
  args: _Args.fixed(preview: ccCollapsibleAccordionStory),
);

final $GrowingContent = _Story(
  name: 'Growing content',
  args: _Args.fixed(preview: ccCollapsibleGrowingContentStory),
);

final $MaintainState = _Story(
  name: 'Maintain state',
  args: _Args.fixed(preview: ccCollapsibleMaintainStateStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcCollapsiblePlayground {
  CcCollapsiblePlayground({required this.expanded, required this.durationMs});

  final bool expanded;
  final int durationMs;
}

/// Three disclosure sections, each opening and closing on its own.
Widget ccCollapsibleAccordionStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            title: 'Repository',
            initiallyExpanded: true,
            child: _Lines([
              'control-center',
              'Default branch: main',
              'Linked to 2 workspaces',
            ]),
          ),
          _Section(
            title: 'Sandbox',
            child: _Lines([
              'Backend: rift copy-on-write',
              'Network: allowlist only',
            ]),
          ),
          _Section(
            title: 'Environment',
            child: _Lines([
              'FLUTTER_ROOT',
              'CC_BOOTSTRAP',
              'GIT_CONFIG_GLOBAL',
              'PUB_CACHE',
            ]),
          ),
        ],
      ),
    ),
  );
}

/// An open section whose content grows and shrinks. The height follows the
/// content directly; only opening and closing animate.
Widget ccCollapsibleGrowingContentStory(BuildContext context) {
  return const Center(child: SizedBox(width: 380, child: _GrowingSection()));
}

/// The same counter in two sections. Collapse both and reopen them: the one
/// with `maintainState` keeps its count, the other starts again at zero.
Widget ccCollapsibleMaintainStateStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            title: 'maintainState: true',
            initiallyExpanded: true,
            maintainState: true,
            child: _Counter(),
          ),
          _Section(
            title: 'maintainState: false',
            initiallyExpanded: true,
            child: _Counter(),
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — flip [CcCollapsible.expanded] and tune the
/// expand duration (the collapse runs on its paired exit token).
Widget ccCollapsiblePlaygroundStory(
  BuildContext context,
  CcCollapsiblePlaygroundArgs args,
) {
  final t = context.designSystem!;
  return Center(
    child: SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Content above',
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          CcCollapsible(
            expanded: args.expanded,
            duration: Duration(milliseconds: args.durationMs),
            child: const _Panel(
              child: _Lines([
                'The child stays mounted while it collapses, so it slides',
                'under the clip instead of leaving an empty gap.',
              ]),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Content below',
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
        ],
      ),
    ),
  );
}

/// A disclosure header over a [CcCollapsible] body.
class _Section extends StatefulWidget {
  const _Section({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.maintainState = false,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final bool maintainState;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _expanded,
          child: CcTappable(
            onPressed: () => setState(() => _expanded = !_expanded),
            borderRadius: AppRadii.brSm,
            semanticLabel: widget.title,
            builder: (context, states) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: states.contains(WidgetState.hovered) ? t.hover : null,
                borderRadius: AppRadii.brSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: CcTypography.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Collapsed, the chevron points along the reading direction.
                  AnimatedRotation(
                    duration: CcMotion.resolveToggle(
                      context,
                      CcMotion.moderate,
                    ),
                    curve: CcMotion.standard,
                    turns: _expanded ? 0 : (rtl ? 0.25 : -0.25),
                    child: Icon(
                      CcIcons.chevronDown,
                      size: 16,
                      color: t.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        CcCollapsible(
          expanded: _expanded,
          maintainState: widget.maintainState,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              end: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

/// An open section with buttons that add and remove lines.
class _GrowingSection extends StatefulWidget {
  const _GrowingSection();

  @override
  State<_GrowingSection> createState() => _GrowingSectionState();
}

class _GrowingSectionState extends State<_GrowingSection> {
  int _count = 2;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Build log',
      initiallyExpanded: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Lines([for (var i = 1; i <= _count; i++) 'Step $i finished']),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              CcButton(
                variant: CcButtonVariant.secondary,
                size: CcButtonSize.sm,
                icon: CcIcons.plus,
                onPressed: () => setState(() => _count++),
                child: const Text('Add line'),
              ),
              CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                icon: CcIcons.minus,
                onPressed: _count > 0 ? () => setState(() => _count--) : null,
                child: const Text('Remove line'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A tap counter, to show whether a section kept its state.
class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Row(
      children: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: () => setState(() => _taps++),
          child: const Text('Tap'),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          'Tapped $_taps times',
          style: CcTypography.bodySm.copyWith(color: t.textSecondary),
        ),
      ],
    );
  }
}

/// A bordered surface, so the clip edge is visible while it animates.
class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: t.borderSecondary),
      ),
      child: child,
    );
  }
}

/// Lines of secondary body text.
class _Lines extends StatelessWidget {
  const _Lines(this.lines);

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Text(
              line,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
      ],
    );
  }
}
