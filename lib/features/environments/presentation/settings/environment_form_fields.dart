import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:flutter/widgets.dart';

export 'package:control_center/features/environments/presentation/settings/environment_command_field.dart';
export 'package:control_center/features/environments/presentation/settings/environment_form.dart';

/// How wide a select gets: past this it reads as a mistake.
const double _selectWidth = 320;

/// How wide a number gets.
const double _numberWidth = 120;

/// A text value bound to [path].
class EnvironmentTextField extends StatelessWidget {
  /// Creates an [EnvironmentTextField].
  const EnvironmentTextField({
    super.key,
    required this.form,
    required this.path,
    required this.label,
    this.hint,
    this.help,
    this.mono = false,
    this.controlWidth,
  });

  /// The form.
  final EnvironmentForm form;

  /// Where the value lives.
  final List<Object> path;

  /// The field's name.
  final String label;

  /// Placeholder text.
  final String? hint;

  /// A note beneath it.
  final String? help;

  /// Holds a machine value, which reads left to right in every locale.
  final bool mono;

  /// Caps the control for a value that is always short.
  final double? controlWidth;

  @override
  Widget build(BuildContext context) {
    final field = CcTextField(
      key: form.key(path),
      hintText: hint,
      helperText: help,
      enabled: form.enabled,
      initialValue: form.text(path),
      errorText: form.issue(path),
      textStyle: mono ? environmentCodeStyle() : null,
      onChanged: (value) => form.notifier.set(path, value),
    );
    return SettingsField(
      label: label,
      controlWidth: controlWidth,
      child: mono
          // RTL carve-out: paths, ids and commands read left to right.
          ? Directionality(textDirection: TextDirection.ltr, child: field)
          : field,
    );
  }
}

/// A whole number bound to [path].
class EnvironmentNumberField extends StatelessWidget {
  /// Creates an [EnvironmentNumberField].
  const EnvironmentNumberField({
    super.key,
    required this.form,
    required this.path,
    required this.label,
    this.description,
    this.fallback,
  });

  /// The form.
  final EnvironmentForm form;

  /// Where the value lives.
  final List<Object> path;

  /// The field's name.
  final String label;

  /// One sentence on what the value does.
  final String? description;

  /// What an empty field means, shown as its placeholder.
  final int? fallback;

  @override
  Widget build(BuildContext context) => SettingsField(
    label: label,
    description: description,
    controlWidth: _numberWidth,
    child: CcTextField(
      key: form.key(path),
      hintText: fallback?.toString(),
      enabled: form.enabled,
      initialValue: form.text(path),
      errorText: form.issue(path),
      keyboardType: TextInputType.number,
      textStyle: environmentCodeStyle(),
      onChanged: (value) => form.notifier.set(path, int.tryParse(value.trim())),
    ),
  );
}

/// A list of strings bound to [path], one per line.
class EnvironmentLinesField extends StatelessWidget {
  /// Creates an [EnvironmentLinesField].
  const EnvironmentLinesField({
    super.key,
    required this.form,
    required this.path,
    this.label,
    this.help,
  });

  /// The form.
  final EnvironmentForm form;

  /// Where the list lives.
  final List<Object> path;

  /// The field's name. Null when the section around it already says it.
  final String? label;

  /// A note beneath it.
  final String? help;

  @override
  Widget build(BuildContext context) {
    final field = Directionality(
      // RTL carve-out: repo paths and globs read left to right.
      textDirection: TextDirection.ltr,
      child: CcTextField(
        key: form.key(path),
        helperText: help,
        enabled: form.enabled,
        minLines: 2,
        maxLines: 6,
        initialValue: form.strings(path).join('\n'),
        textStyle: environmentCodeStyle(),
        onChanged: (value) {
          final lines = [
            for (final line in value.split('\n'))
              if (line.trim().isNotEmpty) line.trim(),
          ];
          form.notifier.set(path, lines.isEmpty ? null : lines);
        },
      ),
    );
    final name = label;
    return name == null ? field : SettingsField(label: name, child: field);
  }
}

/// A choice bound to [path].
class EnvironmentSelectField extends StatelessWidget {
  /// Creates an [EnvironmentSelectField].
  const EnvironmentSelectField({
    super.key,
    required this.form,
    required this.path,
    required this.label,
    required this.options,
    this.fallback,
  });

  /// The form.
  final EnvironmentForm form;

  /// Where the value lives.
  final List<Object> path;

  /// The field's name.
  final String label;

  /// The choices.
  final List<CcSelectOption<String>> options;

  /// What an absent value means.
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final current = form.value(path) as String? ?? fallback;
    return SettingsField(
      label: label,
      controlWidth: _selectWidth,
      child: CcSelect<String>(
        key: form.key(path),
        semanticLabel: label,
        enabled: form.enabled,
        value: current,
        options: options,
        errorText: form.issue(path),
        onChanged: (value) => form.notifier.set(path, value),
      ),
    );
  }
}

/// A boolean bound to [path].
class EnvironmentCheckField extends StatelessWidget {
  /// Creates an [EnvironmentCheckField].
  const EnvironmentCheckField({
    super.key,
    required this.form,
    required this.path,
    required this.label,
    this.description,
    this.fallback = false,
  });

  /// The form.
  final EnvironmentForm form;

  /// Where the value lives.
  final List<Object> path;

  /// The field's name.
  final String label;

  /// One sentence on what turning it on does.
  final String? description;

  /// What an absent value means.
  final bool fallback;

  @override
  Widget build(BuildContext context) => EnvironmentSwitchRow(
    label: label,
    description: description,
    value: form.value(path) as bool? ?? fallback,
    onChanged: form.enabled ? (value) => form.notifier.set(path, value) : null,
  );
}

/// A switch on the same line as every other control in the form.
class EnvironmentSwitchRow extends StatelessWidget {
  /// Creates an [EnvironmentSwitchRow].
  const EnvironmentSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  /// The field's name.
  final String label;

  /// One sentence on what turning it on does.
  final String? description;

  /// Whether it is on.
  final bool value;

  /// Null disables it.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SettingsField(
    label: label,
    description: description,
    centerControl: true,
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: CcSwitch(value: value, semanticLabel: label, onChanged: onChanged),
    ),
  );
}
