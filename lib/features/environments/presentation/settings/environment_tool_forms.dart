import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

const SizedBox _gap = environmentFieldGap;

/// The verbs a tool must map, then the ones it may.
const List<String> _requiredVerbs = ['create', 'status', 'destroy'];
const List<String> _optionalVerbs = ['start', 'stop', 'reset', 'logs', 'exec'];

/// A tool's mapped verbs.
class EnvironmentCliForm extends StatelessWidget {
  /// Creates an [EnvironmentCliForm].
  const EnvironmentCliForm({super.key, required this.form, required this.path});

  /// The draft.
  final EnvironmentForm form;

  /// Where this component lives.
  final List<Object> path;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget verb(String name) => EnvironmentCommandField(
      form: form,
      path: [...path, 'verbs', name],
      // The verbs are the tool's vocabulary, so they keep their names.
      label: name,
      showHelp: false,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final name in _requiredVerbs) ...[verb(name), _gap],
        SettingsDisclosure(
          title: l10n.advanced,
          dense: true,
          // A verb in use can't hide behind a closed section.
          initiallyExpanded: _optionalVerbs.any(
            (name) => form.value([...path, 'verbs', name]) != null,
          ),
          childPadding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, name) in _optionalVerbs.indexed) ...[
                if (index > 0) _gap,
                verb(name),
              ],
            ],
          ),
        ),
        _gap,
        EnvironmentCheckField(
          form: form,
          path: [...path, 'keepsDataOnStop'],
          label: l10n.environmentsKeepsData,
          fallback: true,
        ),
      ],
    );
  }
}

/// A desktop app.
class EnvironmentAppForm extends StatelessWidget {
  /// Creates an [EnvironmentAppForm].
  const EnvironmentAppForm({super.key, required this.form, required this.path});

  /// The draft.
  final EnvironmentForm form;

  /// Where this component lives.
  final List<Object> path;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasks = [
      for (final component in form.list(const ['components']))
        if (component is Map && component['kind'] == 'task')
          '${component['id']}',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnvironmentCommandField(
          form: form,
          path: [...path, 'command'],
          label: l10n.shellCommand,
        ),
        _gap,
        EnvironmentSelectField(
          form: form,
          path: [...path, 'prepare'],
          label: l10n.environmentsPrepareTask,
          options: [
            for (final task in tasks) CcSelectOption(value: task, label: task),
          ],
        ),
        _gap,
        EnvironmentSwitchRow(
          label: l10n.environmentsIsolateHome,
          value: form.value([...path, 'isolate']) == 'home',
          onChanged: form.enabled
              ? (value) => form.notifier.set([
                  ...path,
                  'isolate',
                ], value ? 'home' : null)
              : null,
        ),
      ],
    );
  }
}
