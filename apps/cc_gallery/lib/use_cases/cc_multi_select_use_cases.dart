import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
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
  CcSelectOption(value: 'architecture', label: 'Architecture'),
  CcSelectOption(value: 'design', label: 'Design'),
  CcSelectOption(value: 'review', label: 'Review'),
  CcSelectOption(value: 'testing', label: 'Testing'),
];

/// Eight roles — enough to demo both filtering and the six-option scroll cap.
const List<CcSelectOption<String>> _roleOptions = [
  CcSelectOption(value: 'admin', label: 'Admin'),
  CcSelectOption(value: 'billing', label: 'Billing'),
  CcSelectOption(value: 'editor', label: 'Editor'),
  CcSelectOption(value: 'moderator', label: 'Moderator'),
  CcSelectOption(value: 'owner', label: 'Owner'),
  CcSelectOption(value: 'support', label: 'Support'),
  CcSelectOption(value: 'uploader', label: 'Uploader'),
  CcSelectOption(value: 'viewer', label: 'Viewer'),
];

/// A self-contained selection harness so the panel can toggle values live.
class _MultiSelectDemo extends StatefulWidget {
  const _MultiSelectDemo({
    required this.options,
    this.initial = const {},
    this.hintText,
    this.enabled = true,
    this.showChips = false,
    this.filterable = false,
    this.countLabel,
    this.selectAllLabel,
  });

  final List<CcSelectOption<String>> options;
  final Set<String> initial;
  final String? hintText;
  final bool enabled;
  final bool showChips;
  final bool filterable;
  final String Function(int count)? countLabel;
  final String? selectAllLabel;

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
        filterable: widget.filterable,
        countLabel: widget.countLabel,
        selectAllLabel: widget.selectAllLabel,
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
        _MultiSelectDemo(options: _skillOptions, hintText: 'Assign skills'),
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

/// A parent select-all checkbox pinned at the top of the panel — unchecked
/// selects everything, checked or indeterminate clears the selection. The
/// label names the set ("All skills"), never an action.
@widgetbook.UseCase(name: 'Select all', type: CcMultiSelect, path: _path)
Widget ccMultiSelectSelectAllUseCase(BuildContext context) {
  return const Center(
    child: _MultiSelectDemo(
      options: _skillOptions,
      hintText: 'Assign skills',
      selectAllLabel: 'All skills',
      initial: {'review'},
    ),
  );
}

/// Filterable: hovering the field shows a text cursor, the open field takes
/// typed input that narrows the list, and a ✕ clears just the filter. Eight
/// options also cross the six-option scroll threshold, so the panel caps at
/// five and a half rows.
@widgetbook.UseCase(name: 'Filterable', type: CcMultiSelect, path: _path)
Widget ccMultiSelectFilterableUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 280,
      child: _MultiSelectDemo(
        options: _roleOptions,
        hintText: 'Choose options',
        filterable: true,
        initial: {'editor'},
      ),
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
        CcSelectOption(value: 'opus', label: 'Claude Opus'),
        CcSelectOption(value: 'sonnet', label: 'Claude Sonnet'),
        CcSelectOption(value: 'haiku', label: 'Claude Haiku'),
      ],
      hintText: hintText,
      enabled: enabled,
      showChips: showChips,
      initial: const {'sonnet'},
      countLabel: (count) => '$count agents',
    ),
  );
}
