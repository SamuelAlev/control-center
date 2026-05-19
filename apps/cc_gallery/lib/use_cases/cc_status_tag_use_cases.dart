import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcStatusTag] — a live-state pill that maps a domain state to a
/// tone, a dot and a label, so connection / health / lifecycle state never
/// rests on color alone.

const _path = '[Components]/Feedback';

/// The tones a caller maps live states onto: connected, failed, degraded,
/// stopped, informational.
@widgetbook.UseCase(name: 'Tones', type: CcStatusTag, path: _path)
Widget ccStatusTagTonesUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'Dots', type: CcStatusTag, path: _path)
Widget ccStatusTagDotsUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'Playground', type: CcStatusTag, path: _path)
Widget ccStatusTagPlaygroundUseCase(BuildContext context) {
  final label = context.knobs.string(label: 'Label', initialValue: 'Connected');
  final dot = context.knobs.boolean(label: 'Show dot', initialValue: true);
  final tone = context.knobs.object.dropdown<CcStatusTone>(
    label: 'Tone',
    options: CcStatusTone.values,
    labelBuilder: (t) => t.name,
  );
  return Center(
    child: CcStatusTag(label: label, tone: tone, dot: dot),
  );
}
