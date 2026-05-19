import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcSegmentedToggle] — the design system's connected segmented
/// control, and the cc_ui replacement for Material's `SegmentedButton` /
/// `ToggleButtons`.
///
/// The selected segment takes the primary-button fill (dark ink, white label)
/// per DESIGN.md, so the choice reads at a glance and survives grayscale.
/// Keyboard: Tab lands on the selected segment, `←`/`→` move (and select).

const _path = '[Components]/Inputs';

/// The canonical binary toggle — the markdown editor's Write / Preview switch.
@widgetbook.UseCase(
  name: 'Write / Preview',
  type: CcSegmentedToggle,
  path: _path,
)
Widget ccSegmentedToggleUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'With icons', type: CcSegmentedToggle, path: _path)
Widget ccSegmentedToggleWithIconsUseCase(BuildContext context) {
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
@widgetbook.UseCase(
  name: 'Sizes and disabled',
  type: CcSegmentedToggle,
  path: _path,
)
Widget ccSegmentedToggleSizesUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'Full width', type: CcSegmentedToggle, path: _path)
Widget ccSegmentedToggleFullWidthUseCase(BuildContext context) {
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

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcSegmentedToggle, path: _path)
Widget ccSegmentedTogglePlaygroundUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final fullWidth = context.knobs.boolean(label: 'Full width');
  final large = context.knobs.boolean(label: 'Medium (40px)');
  final withIcons = context.knobs.boolean(label: 'Leading icons');
  final count = context.knobs.int.slider(
    label: 'Segments',
    initialValue: 3,
    min: 2,
    max: 5,
  );
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
    // The playground knobs can drop the segment that was selected.
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
