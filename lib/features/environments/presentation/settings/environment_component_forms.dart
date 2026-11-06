import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_compose_form.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/settings/environment_tool_forms.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_labels.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

const SizedBox _gap = environmentFieldGap;

/// The form for one component.
class EnvironmentComponentForm extends StatelessWidget {
  /// Creates an [EnvironmentComponentForm].
  const EnvironmentComponentForm({
    super.key,
    required this.form,
    required this.path,
    required this.kind,
  });

  /// The draft.
  final EnvironmentForm form;

  /// Where this component lives.
  final List<Object> path;

  /// `compose`, `cli`, `process`, `task` or `app`.
  final String kind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnvironmentTextField(
          form: form,
          path: [...path, 'id'],
          label: l10n.environmentsComponentId,
          mono: true,
        ),
        _gap,
        EnvironmentTextField(
          form: form,
          path: [...path, 'label'],
          label: l10n.nodeConfigLabel,
        ),
        _gap,
        switch (kind) {
          'compose' => EnvironmentComposeForm(form: form, path: path),
          'process' => _ProcessForm(form: form, path: path),
          'task' => _TaskForm(form: form, path: path),
          'cli' => EnvironmentCliForm(form: form, path: path),
          'app' => EnvironmentAppForm(form: form, path: path),
          _ => const SizedBox.shrink(),
        },
        _gap,
        SettingsDisclosure(
          title: l10n.advanced,
          dense: true,
          childPadding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnvironmentTextField(
                form: form,
                path: [...path, 'enabledWhen'],
                label: l10n.environmentsEnabledWhen,
                hint: 'opt.seed',
                mono: true,
              ),
              _gap,
              EnvironmentLinesField(
                form: form,
                path: [...path, 'after'],
                label: l10n.environmentsAfter,
              ),
              _gap,
              EnvironmentTextField(
                form: form,
                path: [...path, 'cwd', 'role'],
                label: l10n.environmentsCwdRole,
                mono: true,
              ),
              _gap,
              EnvironmentTextField(
                form: form,
                path: [...path, 'cwd', 'path'],
                label: l10n.environmentsCwdPath,
                mono: true,
              ),
              _gap,
              EnvironmentVariablesField(form: form, path: [...path, 'env']),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProcessForm extends StatelessWidget {
  const _ProcessForm({required this.form, required this.path});

  final EnvironmentForm form;
  final List<Object> path;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnvironmentCommandField(
          form: form,
          path: [...path, 'command'],
          label: l10n.shellCommand,
        ),
        _gap,
        EnvironmentTextField(
          form: form,
          path: [...path, 'port'],
          label: l10n.port,
          mono: true,
          controlWidth: 120,
        ),
        _gap,
        EnvironmentTextField(
          form: form,
          path: [...path, 'endpoint', 'role'],
          label: l10n.environmentsEndpointRole,
          mono: true,
        ),
        _gap,
        EnvironmentCheckField(
          form: form,
          path: [...path, 'endpoint', 'primary'],
          label: l10n.environmentsPrimaryEndpoint,
        ),
        _gap,
        EnvironmentTextField(
          form: form,
          path: [...path, 'ready', 'http'],
          label: l10n.environmentsReadyHttp,
          hint: 'http://127.0.0.1:{port.web}/',
          mono: true,
        ),
        _gap,
        EnvironmentSelectField(
          form: form,
          path: [...path, 'restart'],
          label: l10n.environmentsRestartPolicy,
          fallback: EnvironmentRestartPolicy.onFailure.wire,
          options: [
            CcSelectOption(
              value: EnvironmentRestartPolicy.onFailure.wire,
              label: l10n.environmentsRestartOnFailure,
            ),
            CcSelectOption(
              value: EnvironmentRestartPolicy.always.wire,
              label: l10n.environmentsRestartAlways,
            ),
            CcSelectOption(
              value: EnvironmentRestartPolicy.never.wire,
              label: l10n.environmentsRestartNever,
            ),
          ],
        ),
        _gap,
        EnvironmentLinesField(
          form: form,
          path: [...path, 'restartOn'],
          label: l10n.environmentsRestartOn,
        ),
      ],
    );
  }
}

class _TaskForm extends StatelessWidget {
  const _TaskForm({required this.form, required this.path});

  final EnvironmentForm form;
  final List<Object> path;

  String _label(AppLocalizations l10n, EnvironmentTaskTrigger trigger) =>
      environmentTriggerLabel(l10n, trigger);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final when = form.strings([...path, 'when']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnvironmentCommandField(
          form: form,
          path: [...path, 'command'],
          label: l10n.shellCommand,
        ),
        _gap,
        SettingsField(
          label: l10n.environmentsTriggers,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final trigger in EnvironmentTaskTrigger.values)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: CcCheckbox(
                    value: when.contains(trigger.name),
                    label: Text(_label(l10n, trigger)),
                    onChanged: form.enabled
                        ? (selected) => form.notifier.set(
                            [...path, 'when'],
                            [
                              for (final each in EnvironmentTaskTrigger.values)
                                if (each == trigger
                                    ? selected == true
                                    : when.contains(each.name))
                                  each.name,
                            ],
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
        if (when.contains(EnvironmentTaskTrigger.change.name)) ...[
          _gap,
          EnvironmentLinesField(
            form: form,
            path: [...path, 'onChange'],
            label: l10n.environmentsOnChange,
          ),
        ],
        _gap,
        EnvironmentNumberField(
          form: form,
          path: [...path, 'timeout'],
          label: l10n.environmentsTimeoutSeconds,
        ),
      ],
    );
  }
}
