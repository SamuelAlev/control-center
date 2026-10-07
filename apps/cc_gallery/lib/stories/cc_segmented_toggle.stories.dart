import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_segmented_toggle.stories.g.dart';

/// Stories for [CcSegmentedToggle] — the design system's connected segmented
/// control, and the cc_ui replacement for Material's `SegmentedButton` /
/// `ToggleButtons`.
///
/// The selected segment takes the primary-button fill (dark ink, white label)
/// per DESIGN.md, so the choice reads at a glance and survives grayscale.
/// Keyboard: Tab lands on the selected segment, `←`/`→` move (and select).

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcSegmentedToggle', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcSegmentedTogglePlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    enabled: BoolArg(true, name: 'Enabled'),
    fullWidth: BoolArg(false, name: 'Full width'),
    large: BoolArg(false, name: 'Medium (40px)'),
    withIcons: BoolArg(false, name: 'Leading icons'),
    count: IntArg(
      3,
      name: 'Segments',
      style: const SliderIntArgStyle(min: 2, max: 5, divisions: 3),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccSegmentedTogglePlaygroundStory(context, args),
  ),
);

final $FullWidth = _Story(
  name: 'Full width',
  args: _Args.fixed(preview: ccSegmentedToggleFullWidthStory),
);

final $SizesAndDisabled = _Story(
  name: 'Sizes and disabled',
  args: _Args.fixed(preview: ccSegmentedToggleSizesStory),
);

final $WithIcons = _Story(
  name: 'With icons',
  args: _Args.fixed(preview: ccSegmentedToggleWithIconsStory),
);

final $WritePreview = _Story(
  name: 'Write / Preview',
  args: _Args.fixed(preview: ccSegmentedToggleStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcSegmentedTogglePlayground {
  CcSegmentedTogglePlayground({
    required this.enabled,
    required this.fullWidth,
    required this.large,
    required this.withIcons,
    required this.count,
  });

  final bool enabled;
  final bool fullWidth;
  final bool large;
  final bool withIcons;
  final int count;
}

/// The canonical binary toggle — the markdown editor's Write / Preview switch.
Widget ccSegmentedToggleStory(BuildContext context) {
  return const Center(
    child: _Demo(
      segments: [
        CcSegment(value: 'write', label: 'Write'),
        CcSegment(value: 'preview', label: 'Preview'),
      ],
      initial: 'write',
    ),
  );
}

/// Three segments with leading icons — the PR diff's view switcher.
Widget ccSegmentedToggleWithIconsStory(BuildContext context) {
  return const Center(
    child: _Demo(
      segments: [
        CcSegment(value: 'diff', label: 'Diff', icon: CcIcons.fileDiff),
        CcSegment(value: 'preview', label: 'Preview', icon: CcIcons.eye),
        CcSegment(value: 'blame', label: 'Blame', icon: CcIcons.gitBranch),
      ],
      initial: 'diff',
    ),
  );
}

/// The size ramp beside the disabled treatment: `sm` (32px, the dense toolbar
/// default) and `md` (40px, field height). A disabled control keeps its
/// selected segment filled — which option is on is still information.
Widget ccSegmentedToggleSizesStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  const segments = [
    CcSegment(value: 'all', label: 'All'),
    CcSegment(value: 'done', label: 'Done'),
    CcSegment(value: 'processing', label: 'Processing'),
  ];
  Widget labelled(String caption, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      child,
      const SizedBox(height: 8),
      Text(
        caption,
        style: CcTypography.caption.copyWith(color: t.textSecondary),
      ),
    ],
  );

  return Center(
    child: Wrap(
      spacing: 32,
      runSpacing: 24,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        labelled('sm · 32px', const _Demo(segments: segments, initial: 'all')),
        labelled(
          'md · 40px',
          const _Demo(
            segments: segments,
            initial: 'done',
            size: CcSegmentedToggleSize.md,
          ),
        ),
        labelled(
          'Disabled',
          const CcSegmentedToggle<String>(
            segments: segments,
            value: 'done',
            onChanged: null,
          ),
        ),
      ],
    ),
  );
}

/// `fullWidth` — equal-width segments filling the row, the shape a settings
/// panel or the phone remote wants.
Widget ccSegmentedToggleFullWidthStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 420,
      child: _Demo(
        segments: [
          CcSegment(value: 'propose', label: 'Propose only'),
          CcSegment(value: 'approve', label: 'Act with approval'),
          CcSegment(value: 'free', label: 'Act freely'),
        ],
        initial: 'approve',
        fullWidth: true,
        size: CcSegmentedToggleSize.md,
      ),
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccSegmentedTogglePlaygroundStory(
  BuildContext context,
  CcSegmentedTogglePlaygroundArgs args,
) {
  final enabled = args.enabled;
  final fullWidth = args.fullWidth;
  final large = args.large;
  final withIcons = args.withIcons;
  final count = args.count;
  const labels = ['All', 'Running', 'Blocked', 'Failed', 'Done'];
  const icons = [
    CcIcons.boxes,
    CcIcons.activity,
    CcIcons.clock,
    CcIcons.circleX,
    CcIcons.circleCheck,
  ];
  return Center(
    child: SizedBox(
      width: fullWidth ? 480 : null,
      child: _Demo(
        segments: [
          for (var i = 0; i < count; i++)
            CcSegment(
              value: labels[i],
              label: labels[i],
              icon: withIcons ? icons[i] : null,
            ),
        ],
        initial: labels.first,
        enabled: enabled,
        fullWidth: fullWidth,
        size: large ? CcSegmentedToggleSize.md : CcSegmentedToggleSize.sm,
      ),
    ),
  );
}

class _Demo extends StatefulWidget {
  const _Demo({
    required this.segments,
    required this.initial,
    this.size = CcSegmentedToggleSize.sm,
    this.fullWidth = false,
    this.enabled = true,
  });

  final List<CcSegment<String>> segments;
  final String initial;
  final CcSegmentedToggleSize size;
  final bool fullWidth;
  final bool enabled;

  @override
  State<_Demo> createState() => _DemoState();
}

class _DemoState extends State<_Demo> {
  late String _value = widget.initial;

  @override
  void didUpdateWidget(covariant _Demo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The playground args can drop the segment that was selected.
    if (!widget.segments.any((s) => s.value == _value)) {
      _value = widget.initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CcSegmentedToggle<String>(
      segments: widget.segments,
      value: _value,
      size: widget.size,
      fullWidth: widget.fullWidth,
      onChanged: widget.enabled ? (v) => setState(() => _value = v) : null,
    );
  }
}
