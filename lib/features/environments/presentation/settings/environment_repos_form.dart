import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/settings/environment_record_list.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The roles a definition binds to workspace repos.
class EnvironmentReposForm extends ConsumerWidget {
  /// Creates an [EnvironmentReposForm].
  const EnvironmentReposForm({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  Map<String, dynamic> get _roles {
    final repos = form.value(const ['repos']);
    return repos is Map ? Map<String, dynamic>.from(repos) : {};
  }

  /// Renames a role in place: the first role a space has is the default cwd,
  /// so order is meaning.
  void _rename(String from, String to) {
    if (to.isEmpty || _roles.containsKey(to)) {
      return;
    }
    form.notifier.set(
      const ['repos'],
      {
        for (final entry in _roles.entries)
          (entry.key == from ? to : entry.key): entry.value,
      },
    );
  }

  EnvironmentRecordEntry _entry(
    AppLocalizations l10n,
    List<Repo> repos,
    int index,
    String role,
    int roleCount,
  ) {
    final path = <Object>['repos', role];
    final repoId = form.text([...path, 'repoId']);
    final repo = repos.firstWhereOrNull((each) => each.id == repoId);
    return EnvironmentRecordEntry(
      icon: AppIcons.folderGit2,
      title: role,
      summary: EnvironmentRecordSummary(
        parts: [
          (text: repo?.name ?? repoId, code: true),
          if (form.value([...path, 'anchor']) == true)
            (text: l10n.environmentsAnchor, code: false),
          if (form.value([...path, 'required']) == true)
            (text: l10n.pipelineInputRequiredLabel, code: false),
        ],
      ),
      hasIssue: form.hasIssueUnder(path),
      canRemove: roleCount > 1,
      detail: _RoleForm(
        form: form,
        index: index,
        role: role,
        repos: repos,
        onRename: (name) => _rename(role, name),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final repos =
        ref.watch(reposForWorkspaceProvider(form.workspaceId)).value ??
        const <Repo>[];
    final roles = _roles;
    final names = roles.keys.toList();
    return EnvironmentRecordList(
      count: names.length,
      enabled: form.enabled,
      entry: (index) => _entry(l10n, repos, index, names[index], names.length),
      onRemove: (index) => form.notifier.restructure(
        const ['repos'],
        {
          for (final entry in roles.entries)
            if (entry.key != names[index]) entry.key: entry.value,
        },
      ),
      adders: [
        (
          label: l10n.environmentsAddRole,
          onAdd: () => form.notifier.restructure(
            const ['repos'],
            {
              ...roles,
              'role_${roles.length + 1}': {'repoId': ''},
            },
          ),
        ),
      ],
    );
  }
}

class _RoleForm extends StatelessWidget {
  const _RoleForm({
    required this.form,
    required this.index,
    required this.role,
    required this.repos,
    required this.onRename,
  });

  final EnvironmentForm form;
  final int index;
  final String role;
  final List<Repo> repos;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final path = <Object>['repos', role];
    final isSource = form.value([...path, 'whenMissing']) == 'useSource';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsField(
          label: l10n.roleLabel,
          // RTL carve-out: a role is an identifier.
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CcTextField(
              // By position: renaming changes the path, not the field.
              key: ValueKey('${form.state.revision}:role:$index'),
              enabled: form.enabled,
              initialValue: role,
              errorText: form.issue(path),
              textStyle: environmentCodeStyle(),
              onChanged: (value) => onRename(value.trim()),
            ),
          ),
        ),
        environmentFieldGap,
        EnvironmentSelectField(
          form: form,
          path: [...path, 'repoId'],
          label: l10n.prPropertyRepository,
          options: [
            for (final repo in repos)
              CcSelectOption(value: repo.id, label: repo.name),
          ],
        ),
        environmentFieldGap,
        EnvironmentCheckField(
          form: form,
          path: [...path, 'anchor'],
          label: l10n.environmentsAnchor,
          description: l10n.environmentsAnchorHelp,
        ),
        environmentFieldGap,
        EnvironmentCheckField(
          form: form,
          path: [...path, 'required'],
          label: l10n.pipelineInputRequiredLabel,
          description: l10n.environmentsRequiredHelp,
        ),
        environmentFieldGap,
        EnvironmentSelectField(
          form: form,
          path: [...path, 'whenMissing'],
          label: l10n.environmentsWhenMissing,
          fallback: form.value([...path, 'required']) == true
              ? 'addToSpace'
              : 'skip',
          options: [
            CcSelectOption(
              value: 'addToSpace',
              label: l10n.environmentsWhenMissingAdd,
            ),
            CcSelectOption(
              value: 'useSource',
              label: l10n.environmentsWhenMissingSource,
            ),
            CcSelectOption(
              value: 'skip',
              label: l10n.environmentsWhenMissingSkip,
            ),
          ],
        ),
        if (isSource) ...[
          environmentFieldGap,
          CcAlert(
            variant: CcAlertVariant.warning,
            title: l10n.environmentsUseSourceWarning,
          ),
        ],
      ],
    );
  }
}
