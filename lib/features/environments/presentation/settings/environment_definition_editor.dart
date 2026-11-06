import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_checks_panel.dart';
import 'package:control_center/features/environments/presentation/settings/environment_definition_delete.dart';
import 'package:control_center/features/environments/presentation/settings/environment_definition_form.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/environments/presentation/settings/environment_json_view.dart';
import 'package:control_center/features/environments/presentation/settings/environment_overrides_form.dart';
import 'package:control_center/features/environments/presentation/settings/environment_running_panel.dart';
import 'package:control_center/features/environments/presentation/settings/environment_source_panel.dart';
import 'package:control_center/features/environments/presentation/settings/environment_test_panel.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_controls.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One definition: a form, its raw JSON, and the ways to prove it works.
class EnvironmentDefinitionEditor extends ConsumerStatefulWidget {
  /// Creates an [EnvironmentDefinitionEditor].
  const EnvironmentDefinitionEditor({super.key, required this.seed});

  /// What this session opened on.
  final EnvironmentEditorSeed seed;

  @override
  ConsumerState<EnvironmentDefinitionEditor> createState() =>
      _EnvironmentDefinitionEditorState();
}

class _EnvironmentDefinitionEditorState
    extends ConsumerState<EnvironmentDefinitionEditor> {
  int _tab = 0;

  void _close() => ref
      .read(navigationHistoryProvider.notifier)
      .backOr(settingsEnvironmentsRoute(widget.seed.workspaceId));

  /// Whether unsaved edits may go: asks only when there are some.
  Future<bool> _mayDiscard(AppLocalizations l10n) async {
    if (!ref.read(environmentEditorProvider(widget.seed)).dirty) {
      return true;
    }
    return confirmEnvironmentAction(
      context,
      title: l10n.discardChangesTitle,
      body: l10n.environmentsDiscardBody,
      confirmLabel: l10n.discard,
    );
  }

  Future<void> _back(AppLocalizations l10n) async {
    if (await _mayDiscard(l10n) && mounted) {
      _close();
    }
  }

  Future<void> _discard(AppLocalizations l10n) async {
    if (await _mayDiscard(l10n) && mounted) {
      ref.read(environmentEditorProvider(widget.seed).notifier).discard();
    }
  }

  Future<void> _save(AppLocalizations l10n) async {
    final toasts = CcToastScope.maybeOf(context);
    final saved = await ref
        .read(environmentEditorProvider(widget.seed).notifier)
        .save();
    if (saved) {
      toasts?.show(l10n.environmentsSaved, variant: CcToastVariant.success);
    }
  }

  Future<void> _delete(String id, String name) async {
    final deleted = await deleteEnvironmentDefinition(
      context,
      ref,
      workspaceId: widget.seed.workspaceId,
      id: id,
      name: name,
    );
    if (deleted && mounted) {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final seed = widget.seed;
    final state = ref.watch(environmentEditorProvider(seed));
    final notifier = ref.read(environmentEditorProvider(seed).notifier);
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(seed.workspaceId))?.isAdmin ?? false;
    final linkedRepoIds = ref
        .watch(reposForWorkspaceProvider(seed.workspaceId))
        .value
        ?.map((repo) => repo.id)
        .toSet();
    // A file-linked definition is read-only here: its text changes in its repo
    // and through approval, and only the overrides belong to this workspace.
    final form = EnvironmentForm(
      workspaceId: seed.workspaceId,
      state: state,
      notifier: notifier,
      enabled: isAdmin && !state.linked,
      linkedRepoIds: linkedRepoIds,
    );
    final record = state.record;
    final tabs = [
      CcTab(l10n.environmentDefinition),
      CcTab(l10n.environmentsTabJson),
      CcTab(l10n.testLabel),
      CcTab(l10n.checks),
      if (record != null) CcTab(l10n.running),
      if (record?.hasSource ?? false) CcTab(l10n.environmentsTabSource),
    ];
    final tab = _tab.clamp(0, tabs.length - 1);
    final name = form.text(const ['name']);
    final issues = _IssueSummary(form: form, notes: seed.notes);
    return PageWrapper(
      title: name.isEmpty ? l10n.environmentsTitle : name,
      subtitle: isAdmin ? null : l10n.environmentsAdminOnly,
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: AppIcons.arrowLeft,
          onPressed: () => unawaited(_back(l10n)),
          child: Text(l10n.back),
        ),
        if (record != null && isAdmin)
          CcButton(
            variant: CcButtonVariant.destructive,
            size: CcButtonSize.sm,
            icon: AppIcons.trash2,
            onPressed: () => unawaited(_delete(record.id, record.name)),
            child: Text(l10n.delete),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: CcTabs(
              tabs: tabs,
              selectedIndex: tab,
              onChanged: (index) => setState(() => _tab = index),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            // JSON scrolls inside its own editor and takes all the height; a
            // page scroll around it would leave it nothing to fill.
            child: tab == 1
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      issues,
                      Expanded(
                        child: EnvironmentJsonView(
                          // A discard bumps the revision and re-seeds the text.
                          key: ValueKey(state.revision),
                          form: form,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        issues,
                        switch (tab) {
                          0 => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state.linked)
                                EnvironmentOverridesForm(
                                  form: form,
                                  enabled: isAdmin,
                                ),
                              EnvironmentDefinitionForm(form: form),
                            ],
                          ),
                          2 => EnvironmentTestPanel(form: form),
                          3 => EnvironmentChecksPanel(form: form),
                          4 => EnvironmentRunningPanel(form: form),
                          _ => EnvironmentSourcePanel(form: form),
                        },
                      ],
                    ),
                  ),
          ),
          if (isAdmin)
            SettingsSaveBar(
              dirty: state.dirty,
              busy: state.saving,
              onSave: () => unawaited(_save(l10n)),
              onDiscard: () => unawaited(_discard(l10n)),
              saveEnabled: state.jsonError == null,
              error: state.jsonError == null
                  ? null
                  : l10n.environmentsJsonInvalid(state.jsonError!),
            ),
        ],
      ),
    );
  }
}

/// Problems no field can show, and what a repo scan noted.
class _IssueSummary extends StatelessWidget {
  const _IssueSummary({required this.form, required this.notes});

  final EnvironmentForm form;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issues = form.issues;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final note in notes)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CcAlert(title: note),
            ),
          if (issues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CcAlert(
                variant: CcAlertVariant.danger,
                title: l10n.environmentsIssues,
                description: Text(
                  issues
                      .map(
                        (issue) => issue.path.isEmpty
                            ? issue.message
                            : '${issue.path}: ${issue.message}',
                      )
                      .join('\n'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
