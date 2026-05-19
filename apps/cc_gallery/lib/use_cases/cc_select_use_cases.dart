import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcSelect] — the design system's flat single-select dropdown
/// (the cc_ui replacement for Material's `DropdownButton`).
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcSelect`. The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas. [CcSelect] is generic, so the bare class name is used as `type`.

const _path = '[Components]/Inputs';

const List<CcSelectOption<String>> _sortOptions = [
  CcSelectOption(value: 'recent', label: 'Most recent'),
  CcSelectOption(value: 'oldest', label: 'Oldest'),
  CcSelectOption(value: 'largest', label: 'Largest diff'),
];

const List<CcSelectOption<String>> _modelOptions = [
  CcSelectOption(value: 'opus', label: 'Claude Opus 4.8'),
  CcSelectOption(value: 'sonnet', label: 'Claude Sonnet 4.5'),
  CcSelectOption(value: 'haiku', label: 'Claude Haiku 4'),
];

/// Eight options — past the six-option scroll threshold, so the panel caps at
/// five and a half rows and the half-cut last row signals more below.
const List<CcSelectOption<String>> _memberOptions = [
  CcSelectOption(value: 'amara', label: 'Amara Diallo'),
  CcSelectOption(value: 'bjoern', label: 'Björn Larsen'),
  CcSelectOption(value: 'chen', label: 'Chen Wei'),
  CcSelectOption(value: 'duna', label: 'Duna Haddad'),
  CcSelectOption(value: 'eli', label: 'Eli Moreau'),
  CcSelectOption(value: 'farah', label: 'Farah Naz'),
  CcSelectOption(value: 'gus', label: 'Gus Papadopoulos'),
  CcSelectOption(value: 'hina', label: 'Hina Sato'),
];

/// The default control with a value selected — open it to see the row check
/// and keyboard highlight.
@widgetbook.UseCase(name: 'Default', type: CcSelect, path: _path)
Widget ccSelectDefaultUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: _SelectDemo(options: _sortOptions, initial: 'recent'),
    ),
  );
}

/// The model picker — three text-only options (dropdowns never carry icons).
@widgetbook.UseCase(name: 'Models', type: CcSelect, path: _path)
Widget ccSelectModelsUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: _SelectDemo(options: _modelOptions, initial: 'opus'),
    ),
  );
}

/// A long option list scrolls from the sixth option: the panel stops at five
/// and a half rows so the half-visible row advertises the overflow.
@widgetbook.UseCase(name: 'Long list', type: CcSelect, path: _path)
Widget ccSelectLongListUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: _SelectDemo(options: _memberOptions, initial: 'amara'),
    ),
  );
}

/// Empty (placeholder hint, no selection) next to the disabled treatment.
@widgetbook.UseCase(name: 'Empty & disabled', type: CcSelect, path: _path)
Widget ccSelectEmptyAndDisabledUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SelectDemo(
            options: _sortOptions,
            initial: null,
            hintText: 'Sort pull requests',
          ),
          SizedBox(height: 16),
          CcSelect<String>(
            options: _sortOptions,
            value: null,
            enabled: false,
            hintText: 'Sort pull requests',
            onChanged: _ignore,
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcSelect, path: _path)
Widget ccSelectPlaygroundUseCase(BuildContext context) {
  final preselected = context.knobs.boolean(
    label: 'Has selection',
    initialValue: true,
  );
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final hint = context.knobs.string(
    label: 'Hint text',
    initialValue: 'Pick a workspace',
  );

  const options = [
    CcSelectOption(value: 'control-center', label: 'control-center'),
    CcSelectOption(value: 'cc-ui', label: 'cc_ui'),
    CcSelectOption(value: 'rift', label: 'rift'),
  ];

  return Center(
    child: SizedBox(
      width: 260,
      child: _SelectDemo(
        key: ValueKey('$preselected-$enabled'),
        options: options,
        initial: preselected ? 'control-center' : null,
        hintText: hint,
        enabled: enabled,
      ),
    ),
  );
}

void _ignore(String _) {}

/// Stateful host that owns the selection, mirroring `_SelectDemo` in
/// `component_stories.dart`.
class _SelectDemo extends StatefulWidget {
  const _SelectDemo({
    required this.options,
    required this.initial,
    this.hintText,
    this.enabled = true,
    super.key,
  });

  final List<CcSelectOption<String>> options;
  final String? initial;
  final String? hintText;
  final bool enabled;

  @override
  State<_SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<_SelectDemo> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return CcSelect<String>(
      options: widget.options,
      value: _value,
      hintText: widget.hintText,
      enabled: widget.enabled,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
