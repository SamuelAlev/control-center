import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_argv_text.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/settings/environment_record_list.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A command as one line, however it is stored.
String environmentCommandSummary(Object? command) => switch (command) {
  final String text => text,
  final Map<dynamic, dynamic> map when map['shell'] is String =>
    map['shell'] as String,
  final List<dynamic> argv when argv.every((item) => item is String) =>
    environmentArgvToText([for (final item in argv) '$item']),
  _ => '',
};

/// Removes the item at [index] from the list at [path].
void _removeAt(EnvironmentForm form, List<Object> path, int index) {
  final next = form.list(path)..removeAt(index);
  form.notifier.restructure(path, next.isEmpty ? null : next);
}

/// The options on the Start form.
class EnvironmentOptionsForm extends StatelessWidget {
  /// Creates an [EnvironmentOptionsForm].
  const EnvironmentOptionsForm({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  static const List<Object> _path = ['options'];

  String _typeLabel(AppLocalizations l10n, String type) => switch (type) {
    'bool' => l10n.environmentsOptionBool,
    'enum' => l10n.environmentsOptionEnum,
    'multi' => l10n.environmentsOptionMulti,
    _ => l10n.pipelineInputTypeText,
  };

  Widget _detail(AppLocalizations l10n, List<Object> path, String type) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          EnvironmentTextField(
            form: form,
            path: [...path, 'key'],
            label: l10n.variableKey,
            mono: true,
          ),
          environmentFieldGap,
          EnvironmentTextField(
            form: form,
            path: [...path, 'label'],
            label: l10n.nodeConfigLabel,
          ),
          environmentFieldGap,
          EnvironmentSelectField(
            form: form,
            path: [...path, 'type'],
            label: l10n.pipelineInputTypeLabel,
            fallback: 'string',
            options: [
              for (final value in const ['bool', 'enum', 'multi', 'string'])
                CcSelectOption(value: value, label: _typeLabel(l10n, value)),
            ],
          ),
          if (type == 'enum' || type == 'multi') ...[
            environmentFieldGap,
            EnvironmentLinesField(
              form: form,
              path: [...path, 'values'],
              label: l10n.environmentsOptionValues,
            ),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = form.list(_path);
    return EnvironmentRecordList(
      count: items.length,
      enabled: form.enabled,
      onRemove: (index) => _removeAt(form, _path, index),
      adders: [
        (
          label: l10n.environmentsAddOption,
          onAdd: () => form.notifier.restructure(_path, [
            ...items,
            {'key': 'option_${items.length + 1}', 'type': 'bool'},
          ]),
        ),
      ],
      entry: (index) {
        final path = <Object>[..._path, index];
        final key = form.text([...path, 'key']);
        final label = form.text([...path, 'label']);
        final type = form.text([...path, 'type']);
        return EnvironmentRecordEntry(
          icon: AppIcons.slidersHorizontal,
          title: label.isEmpty ? key : label,
          summary: EnvironmentRecordSummary(
            parts: [
              (text: key, code: true),
              (text: _typeLabel(l10n, type), code: false),
              (text: form.strings([...path, 'values']).join(', '), code: true),
            ],
          ),
          hasIssue: form.hasIssueUnder(path),
          detail: _detail(l10n, path, type),
        );
      },
    );
  }
}

/// The definition's host-readiness rows.
class EnvironmentChecksForm extends StatelessWidget {
  /// Creates an [EnvironmentChecksForm].
  const EnvironmentChecksForm({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  static const List<Object> _path = ['checks'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = form.list(_path);
    return EnvironmentRecordList(
      count: items.length,
      enabled: form.enabled,
      onRemove: (index) => _removeAt(form, _path, index),
      adders: [
        (
          label: l10n.environmentsAddCheck,
          onAdd: () => form.notifier.restructure(_path, [
            ...items,
            {
              'id': 'check_${items.length + 1}',
              'label': 'check_${items.length + 1}',
              'command': <String>['true'],
            },
          ]),
        ),
      ],
      entry: (index) {
        final path = <Object>[..._path, index];
        final label = form.text([...path, 'label']);
        final file = form.text([...path, 'file']);
        return EnvironmentRecordEntry(
          icon: AppIcons.listChecks,
          title: label.isEmpty ? form.text([...path, 'id']) : label,
          summary: EnvironmentRecordSummary(
            parts: [
              (
                text: file.isNotEmpty
                    ? file
                    : environmentCommandSummary(
                        form.value([...path, 'command']),
                      ),
                code: true,
              ),
            ],
          ),
          hasIssue: form.hasIssueUnder(path),
          detail: _CheckForm(key: form.key(path), form: form, path: path),
        );
      },
    );
  }
}

class _CheckForm extends StatefulWidget {
  const _CheckForm({super.key, required this.form, required this.path});

  final EnvironmentForm form;
  final List<Object> path;

  @override
  State<_CheckForm> createState() => _CheckFormState();
}

class _CheckFormState extends State<_CheckForm> {
  /// A check probes a file or runs a command, never both. Settled on opening:
  /// clearing the path to retype it must not swap the field underfoot.
  late final bool _probesFile =
      widget.form.value([...widget.path, 'file']) != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = widget.form;
    final path = widget.path;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        EnvironmentTextField(
          form: form,
          path: [...path, 'label'],
          label: l10n.nodeConfigLabel,
        ),
        environmentFieldGap,
        if (_probesFile)
          EnvironmentTextField(
            form: form,
            path: [...path, 'file'],
            label: l10n.environmentsCheckFile,
            mono: true,
          )
        else
          EnvironmentCommandField(
            form: form,
            path: [...path, 'command'],
            label: l10n.shellCommand,
          ),
        environmentFieldGap,
        EnvironmentTextField(
          form: form,
          path: [...path, 'hint'],
          label: l10n.environmentsCheckHint,
        ),
        environmentFieldGap,
        EnvironmentTextField(
          form: form,
          path: [...path, 'fix'],
          label: l10n.environmentsCheckFix,
          mono: true,
        ),
      ],
    );
  }
}
