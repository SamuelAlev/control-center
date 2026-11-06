import 'package:control_center/features/environments/presentation/settings/environment_component_forms.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/settings/environment_lists_form.dart';
import 'package:control_center/features/environments/presentation/settings/environment_record_list.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// A fresh component of [kind]. Required keys are present so the first edit
/// doesn't start from a parse failure.
Map<String, dynamic> blankEnvironmentComponent(String kind, int index) => {
  'kind': kind,
  'id': '$kind-${index + 1}',
  if (kind == 'process' || kind == 'app') 'command': <String>['true'],
  if (kind == 'task') ...{
    'command': <String>['true'],
    'when': <String>['manual'],
  },
  if (kind == 'cli')
    'verbs': {
      'create': <String>['true'],
      'status': <String>['true'],
      'destroy': <String>['true'],
    },
};

/// The components, in the order they start.
class EnvironmentComponentList extends StatelessWidget {
  /// Creates an [EnvironmentComponentList].
  const EnvironmentComponentList({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  static const List<Object> _path = ['components'];

  void _move(int from, int to) {
    final items = form.list(_path);
    items.insert(to, items.removeAt(from));
    form.notifier.restructure(_path, items);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = form.list(_path);
    return EnvironmentRecordList(
      count: items.length,
      enabled: form.enabled,
      onMove: _move,
      onRemove: (index) => form.notifier.restructure(_path, [
        ...items.take(index),
        ...items.skip(index + 1),
      ]),
      adders: [
        for (final kind in const ['compose', 'process', 'task', 'cli', 'app'])
          (
            label: environmentKindLabel(l10n, kind),
            onAdd: () => form.notifier.restructure(_path, [
              ...items,
              blankEnvironmentComponent(kind, items.length),
            ]),
          ),
      ],
      entry: (index) {
        final path = <Object>[..._path, index];
        final kind = form.text([...path, 'kind']);
        final id = form.text([...path, 'id']);
        final label = form.text([...path, 'label']);
        return EnvironmentRecordEntry(
          icon: environmentKindIcon(kind),
          title: label.isEmpty ? id : label,
          summary: EnvironmentRecordSummary(
            parts: [
              (text: environmentKindLabel(l10n, kind), code: false),
              (
                text: environmentCommandSummary(
                  form.value([...path, 'command']),
                ),
                code: true,
              ),
            ],
          ),
          hasIssue: form.hasIssueUnder(path),
          detail: EnvironmentComponentForm(form: form, path: path, kind: kind),
        );
      },
    );
  }
}
