import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcMultiSelect] — a flat dropdown with per-row checkboxes that
/// summarises a [Set] of selected values as either a count or chips.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcMultiSelect`. The builders return
/// the component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas. Selection is stateful, so the interactive cases live inside a
/// file-private [_MultiSelectDemo].

const _path = '[Components]/Inputs';

const List<CcSelectOption<String>> _skillOptions = [
  CcSelectOption(value: 'review', label: 'Review', icon: LucideIcons.eye),
  CcSelectOption(value: 'design', label: 'Design', icon: LucideIcons.pencilRuler),
  CcSelectOption(
    value: 'architecture',
    label: 'Architecture',
    icon: LucideIcons.layers,
  ),
  CcSelectOption(value: 'testing', label: 'Testing', icon: LucideIcons.flaskConical),
];

/// A self-contained selection harness so the panel can toggle values live.
class _MultiSelectDemo extends StatefulWidget {
  const _MultiSelectDemo({
    required this.options,
    this.initial = const {},
    this.hintText,
    this.enabled = true,
    this.showChips = false,
    this.countLabel,
  });

  final List<CcSelectOption<String>> options;
  final Set<String> initial;
  final String? hintText;
  final bool enabled;
  final bool showChips;
  final String Function(int count)? countLabel;

  @override
  State<_MultiSelectDemo> createState() => _MultiSelectDemoState();
}

class _MultiSelectDemoState extends State<_MultiSelectDemo> {
  late Set<String> _values = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: CcMultiSelect<String>(
        options: widget.options,
        values: _values,
        hintText: widget.hintText,
        enabled: widget.enabled,
        showChips: widget.showChips,
        countLabel: widget.countLabel,
        onChanged: (next) => setState(() => _values = next),
      ),
    );
  }
}

/// Empty (placeholder) versus a filled selection summarised as a count.
@widgetbook.UseCase(name: 'Count summary', type: CcMultiSelect, path: _path)
Widget ccMultiSelectCountUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _MultiSelectDemo(
          options: _skillOptions,
          hintText: 'Assign skills',
        ),
        _MultiSelectDemo(
          options: _skillOptions,
          hintText: 'Assign skills',
          initial: {'review', 'architecture'},
        ),
      ],
    ),
  );
}

/// The chip summary — selected option labels render as small chips in the
/// trigger instead of a count.
@widgetbook.UseCase(name: 'Chips summary', type: CcMultiSelect, path: _path)
Widget ccMultiSelectChipsUseCase(BuildContext context) {
  return const Center(
    child: _MultiSelectDemo(
      options: _skillOptions,
      hintText: 'Assign skills',
      showChips: true,
      initial: {'review', 'design', 'testing'},
    ),
  );
}

/// The disabled treatment — the trigger keeps its selection but reads as
/// non-interactive.
@widgetbook.UseCase(name: 'Disabled', type: CcMultiSelect, path: _path)
Widget ccMultiSelectDisabledUseCase(BuildContext context) {
  return const Center(
    child: _MultiSelectDemo(
      options: _skillOptions,
      hintText: 'Assign skills',
      enabled: false,
      initial: {'review', 'design'},
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcMultiSelect, path: _path)
Widget ccMultiSelectPlaygroundUseCase(BuildContext context) {
  final showChips = context.knobs.boolean(label: 'Show chips');
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final hintText = context.knobs.string(
    label: 'Hint text',
    initialValue: 'Pick reviewers',
  );
  return Center(
    child: _MultiSelectDemo(
      options: const [
        CcSelectOption(value: 'opus', label: 'Claude Opus', icon: LucideIcons.bot),
        CcSelectOption(value: 'sonnet', label: 'Claude Sonnet', icon: LucideIcons.bot),
        CcSelectOption(value: 'haiku', label: 'Claude Haiku', icon: LucideIcons.bot),
      ],
      hintText: hintText,
      enabled: enabled,
      showChips: showChips,
      initial: const {'sonnet'},
      countLabel: (count) => '$count agents',
    ),
  );
}
