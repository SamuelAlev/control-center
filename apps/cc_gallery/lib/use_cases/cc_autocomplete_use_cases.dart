import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcAutocomplete] — an input whose typed query filters a list of
/// [CcSelectOption]s in a floating panel anchored below the field.
///
/// The builders return the component directly — the gallery's theme addon
/// supplies the [CcTheme] + canvas. Type into the field to open the panel.

const _path = '[Components]/Inputs';

const List<CcSelectOption<String>> _repos = [
  CcSelectOption(value: 'control-center', label: 'control-center'),
  CcSelectOption(value: 'cc-ui', label: 'cc_ui'),
  CcSelectOption(value: 'rift', label: 'rift'),
  CcSelectOption(value: 'rtk', label: 'rtk'),
];

const List<CcSelectOption<String>> _models = [
  CcSelectOption(
    value: 'opus',
    label: 'Claude Opus 4.8',
    icon: LucideIcons.sparkles,
  ),
  CcSelectOption(
    value: 'sonnet',
    label: 'Claude Sonnet 4.5',
    icon: LucideIcons.zap,
  ),
  CcSelectOption(
    value: 'haiku',
    label: 'Claude Haiku 4',
    icon: LucideIcons.feather,
  ),
];

/// Default field — type to filter a flat list of repositories.
@widgetbook.UseCase(name: 'Default', type: CcAutocomplete, path: _path)
Widget ccAutocompleteDefaultUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 280,
      child: CcAutocomplete<String>(
        hintText: 'Search repos…',
        options: _repos,
        onSelected: _noop,
      ),
    ),
  );
}

/// Options carrying leading icons — pick the Claude model to dispatch an agent.
@widgetbook.UseCase(name: 'With icons', type: CcAutocomplete, path: _path)
Widget ccAutocompleteWithIconsUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 280,
      child: CcAutocomplete<String>(
        hintText: 'Choose a model…',
        options: _models,
        onSelected: _noop,
      ),
    ),
  );
}

/// Disabled — the field is non-interactive and never opens its panel.
@widgetbook.UseCase(name: 'Disabled', type: CcAutocomplete, path: _path)
Widget ccAutocompleteDisabledUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 280,
      child: CcAutocomplete<String>(
        hintText: 'Assign reviewer…',
        enabled: false,
        options: _repos,
        onSelected: _noop,
      ),
    ),
  );
}

/// Interactive playground — drive the field's props and watch the selection.
@widgetbook.UseCase(name: 'Playground', type: CcAutocomplete, path: _path)
Widget ccAutocompletePlaygroundUseCase(BuildContext context) {
  final hintText = context.knobs.string(
    label: 'Hint text',
    initialValue: 'Search workspaces…',
  );
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final withIcons = context.knobs.boolean(label: 'Option icons');
  return _AutocompletePlayground(
    hintText: hintText,
    enabled: enabled,
    options: withIcons ? _models : _repos,
  );
}

class _AutocompletePlayground extends StatefulWidget {
  const _AutocompletePlayground({
    required this.hintText,
    required this.enabled,
    required this.options,
  });

  final String hintText;
  final bool enabled;
  final List<CcSelectOption<String>> options;

  @override
  State<_AutocompletePlayground> createState() =>
      _AutocompletePlaygroundState();
}

class _AutocompletePlaygroundState extends State<_AutocompletePlayground> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcAutocomplete<String>(
              hintText: widget.hintText,
              enabled: widget.enabled,
              options: widget.options,
              onSelected: (value) => setState(() => _selected = value),
            ),
            const SizedBox(height: 12),
            Text(
              _selected == null ? 'No selection' : 'Selected: $_selected',
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

void _noop(String value) {}
