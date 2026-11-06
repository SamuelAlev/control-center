import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_component_list.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/settings/environment_lists_form.dart';
import 'package:control_center/features/environments/presentation/settings/environment_policy_form.dart';
import 'package:control_center/features/environments/presentation/settings/environment_repos_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';

/// The form view of a definition: every section an admin edits by hand. What
/// has no form field stays reachable through the JSON view.
class EnvironmentDefinitionForm extends StatelessWidget {
  /// Creates an [EnvironmentDefinitionForm].
  const EnvironmentDefinitionForm({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget card(
      String label,
      Widget child, {
      String? description,
      int? count,
      bool rows = false,
    }) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: SectionCard(
        label: label,
        count: count,
        subtitle: description == null ? null : Text(description),
        // Rows run to the card's edges so their rules and hover do too.
        padding: rows
            ? EdgeInsets.zero
            : const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                14,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
        headerPadding: rows
            ? const EdgeInsets.fromLTRB(AppSpacing.lg, 14, AppSpacing.lg, 0)
            : null,
        child: child,
      ),
    );
    final roles = form.value(const ['repos']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card(
          l10n.general,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EnvironmentTextField(
                form: form,
                path: const ['name'],
                label: l10n.name,
              ),
              environmentFieldGap,
              EnvironmentTextField(
                form: form,
                path: const ['naming', 'template'],
                label: l10n.environmentsNamingTemplate,
                hint: '{branch}',
                mono: true,
              ),
              environmentFieldGap,
              EnvironmentTextField(
                form: form,
                path: const ['naming', 'project'],
                label: l10n.environmentsNamingProject,
                mono: true,
              ),
            ],
          ),
        ),
        card(
          l10n.repositories,
          EnvironmentReposForm(form: form),
          description: l10n.environmentsReposHelp,
          count: roles is Map ? roles.length : 0,
          rows: true,
        ),
        card(
          l10n.environmentsSectionComponents,
          EnvironmentComponentList(form: form),
          description: l10n.environmentsComponentsHelp,
          count: form.list(const ['components']).length,
          rows: true,
        ),
        card(
          l10n.environmentsSectionOptions,
          EnvironmentOptionsForm(form: form),
          description: l10n.environmentsOptionsHelp,
          count: form.list(const ['options']).length,
          rows: true,
        ),
        card(
          l10n.environmentsSectionVariables,
          EnvironmentVariablesField(form: form, path: const ['env']),
          description: l10n.environmentsVariablesHelp,
        ),
        card(
          l10n.environmentsSectionSeedFiles,
          EnvironmentLinesField(form: form, path: const ['seedFiles']),
          description: l10n.environmentsSeedHelp,
        ),
        card(
          l10n.checks,
          EnvironmentChecksForm(form: form),
          description: l10n.environmentsChecksHelp,
          count: form.list(const ['checks']).length,
          rows: true,
        ),
        card(l10n.policy, EnvironmentPolicyForm(form: form)),
      ],
    );
  }
}
