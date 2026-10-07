import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_status_tag.stories.g.dart';

/// Stories for [CcStatusTag] — a live-state pill that maps a domain state to a
/// tone, a dot and a label, so connection / health / lifecycle state never
/// rests on color alone.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcStatusTag', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcStatusTagPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    label: StringArg('Connected', name: 'Label'),
    dot: BoolArg(true, name: 'Show dot'),
    tone: EnumArg<CcStatusTone>(
      CcStatusTone.values.first,
      name: 'Tone',
      values: CcStatusTone.values,
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccStatusTagPlaygroundStory(context, args),
  ),
);

final $Dots = _Story(args: _Args.fixed(preview: ccStatusTagDotsStory));

final $Tones = _Story(args: _Args.fixed(preview: ccStatusTagTonesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcStatusTagPlayground {
  CcStatusTagPlayground({
    required this.label,
    required this.dot,
    required this.tone,
  });

  final String label;
  final bool dot;
  final CcStatusTone tone;
}

/// The tones a caller maps live states onto: connected, failed, degraded,
/// stopped, informational.
Widget ccStatusTagTonesStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcStatusTag(label: 'Connected', tone: CcStatusTone.positive),
        CcStatusTag(label: 'Failed', tone: CcStatusTone.negative),
        CcStatusTag(label: 'Degraded', tone: CcStatusTone.caution),
        CcStatusTag(label: 'Stopped', tone: CcStatusTone.neutral),
        CcStatusTag(label: 'Running', tone: CcStatusTone.info),
      ],
    ),
  );
}

/// Bare status dots, the same vocabulary without the capsule — for dense rows
/// where the label lives elsewhere.
Widget ccStatusTagDotsStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        CcStatusDot(tone: CcStatusTone.positive),
        CcStatusDot(tone: CcStatusTone.negative),
        CcStatusDot(tone: CcStatusTone.caution),
        CcStatusDot(tone: CcStatusTone.neutral),
        CcStatusDot(tone: CcStatusTone.info),
      ],
    ),
  );
}

/// Interactive playground.
Widget ccStatusTagPlaygroundStory(
  BuildContext context,
  CcStatusTagPlaygroundArgs args,
) {
  final label = args.label;
  final dot = args.dot;
  final tone = args.tone;
  return Center(
    child: CcStatusTag(label: label, tone: tone, dot: dot),
  );
}
