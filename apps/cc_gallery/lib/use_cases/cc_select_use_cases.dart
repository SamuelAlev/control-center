import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
  CcSelectOption(value: 'opus', label: 'Claude Opus 4.8', icon: LucideIcons.sparkles),
  CcSelectOption(value: 'sonnet', label: 'Claude Sonnet 4.5', icon: LucideIcons.zap),
  CcSelectOption(value: 'haiku', label: 'Claude Haiku 4', icon: LucideIcons.feather),
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

/// Options carry leading icons in both the trigger and the panel rows — used
/// for the Claude model picker.
@widgetbook.UseCase(name: 'With icons', type: CcSelect, path: _path)
Widget ccSelectWithIconsUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: _SelectDemo(options: _modelOptions, initial: 'opus'),
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
  final withIcons = context.knobs.boolean(label: 'Option icons', initialValue: true);
  final preselected = context.knobs.boolean(label: 'Has selection', initialValue: true);
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final hint = context.knobs.string(label: 'Hint text', initialValue: 'Pick a workspace');

  final options = withIcons
      ? const [
          CcSelectOption(value: 'control-center', label: 'control-center', icon: LucideIcons.layoutDashboard),
          CcSelectOption(value: 'cc-ui', label: 'cc_ui', icon: LucideIcons.palette),
          CcSelectOption(value: 'rift', label: 'rift', icon: LucideIcons.gitBranch),
        ]
      : const [
          CcSelectOption(value: 'control-center', label: 'control-center'),
          CcSelectOption(value: 'cc-ui', label: 'cc_ui'),
          CcSelectOption(value: 'rift', label: 'rift'),
        ];

  return Center(
    child: SizedBox(
      width: 260,
      child: _SelectDemo(
        key: ValueKey('$withIcons-$preselected-$enabled'),
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
