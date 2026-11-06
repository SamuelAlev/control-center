import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_component.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/environments/presentation/environment_setup_prompt.dart';
import 'package:control_center/features/environments/presentation/settings/environment_definition_list.dart';
import 'package:control_center/features/environments/presentation/settings/environment_definition_route.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/features/environments/presentation/settings/environment_new_dialogs.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether [record] binds [repoId], and how strongly: 2 when it owns that
/// repo's provision or archive tasks (the repo's one place for them), 1 when it
/// only binds it, 0 when neither.
int _repoClaim(EnvironmentDefinitionRecord record, String repoId) {
  final definition = environmentDefinitionOf(record);
  if (definition == null) {
    return 0;
  }
  final roles = {
    for (final role in definition.repos)
      if (role.repoId == repoId) role.key,
  };
  if (roles.isEmpty) {
    return 0;
  }
  final present = {for (final role in definition.repos) role.key};
  final ownsTasks = definition.components
      .whereType<TaskEnvironmentComponent>()
      .any(
        (task) =>
            task.isWorktreeTask &&
            roles.contains(definition.roleFor(task, present)),
      );
  return ownsTasks ? 2 : 1;
}

/// The definition Settings → Repositories should open for [repoId].
EnvironmentDefinitionRecord? environmentDefinitionForRepo(
  List<EnvironmentDefinitionRecord> records,
  String repoId,
) => records
    .where((record) => _repoClaim(record, repoId) > 0)
    .sortedBy<num>((record) => -_repoClaim(record, repoId))
    .firstOrNull;

/// Settings → Environments: what each space can start.
class EnvironmentsSettingsView extends ConsumerStatefulWidget {
  /// Creates an [EnvironmentsSettingsView].
  const EnvironmentsSettingsView({super.key, this.definitionId});

  /// The definition the URL has open, [settingsNewEnvironmentId] for one not
  /// saved yet, or null for the list.
  final String? definitionId;

  @override
  ConsumerState<EnvironmentsSettingsView> createState() =>
      _EnvironmentsSettingsViewState();
}

class _EnvironmentsSettingsViewState
    extends ConsumerState<EnvironmentsSettingsView> {
  final _newMenu = CcOverlayController();

  @override
  void dispose() {
    _newMenu.dispose();
    super.dispose();
  }

  /// Opens the definition Settings → Repositories asked for, or a blank one
  /// bound to that repo.
  void _resolveRepoFocus(
    String workspaceId,
    String repoId,
    List<EnvironmentDefinitionRecord> records,
  ) {
    final l10n = AppLocalizations.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(environmentRepoFocusProvider.notifier).focus(null);
      final record = environmentDefinitionForRepo(records, repoId);
      openEnvironmentEditor(
        context,
        ref,
        record == null
            ? EnvironmentEditorSeed.blank(
                workspaceId,
                name: l10n.environmentsNewDefinitionName,
                repoId: repoId,
              )
            : EnvironmentEditorSeed.record(record),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (ref.watch(isDemoServerProvider)) {
      return PageWrapper(
        title: l10n.environmentsTitle,
        child: const DemoUnavailable(capability: DemoCapability.environments),
      );
    }
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final definitions = ref.watch(environmentDefinitionsProvider(workspaceId));
    final focus = ref.watch(environmentRepoFocusProvider);
    if (focus != null) {
      if (definitions.hasValue) {
        _resolveRepoFocus(workspaceId, focus, definitions.requireValue);
      }
      return const Center(child: CcSpinner());
    }
    final definitionId = widget.definitionId;
    // Nothing to open it from: the list below says why.
    final failed = definitions.hasError && !definitions.hasValue;
    if (definitionId != null && !failed) {
      // The active workspace follows the URL a beat behind, and an id looked up
      // in the workspace being left would read as a deleted definition.
      return context.currentWorkspaceId == workspaceId
          ? EnvironmentDefinitionRoute(
              workspaceId: workspaceId,
              definitionId: definitionId,
              definitions: definitions,
            )
          : const Center(child: CcSpinner());
    }
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
    final unsupported = definitions.error is EnvironmentsUnsupported;
    return PageWrapper(
      title: l10n.environmentsTitle,
      subtitle: l10n.environmentsDescription,
      actions: [
        if (isAdmin && !unsupported)
          CcMenu(
            controller: _newMenu,
            // The button drives the menu; left on, the menu's own tap would
            // lose the gesture to the button's.
            toggleOnTargetTap: false,
            semanticLabel: l10n.environmentsNew,
            targetAnchor: AlignmentDirectional.bottomEnd,
            followerAnchor: AlignmentDirectional.topEnd,
            items: [
              CcMenuItem(
                label: l10n.environmentsBlank,
                icon: AppIcons.filePlus,
                onSelected: () => openEnvironmentEditor(
                  context,
                  ref,
                  EnvironmentEditorSeed.blank(
                    workspaceId,
                    name: l10n.environmentsNewDefinitionName,
                  ),
                ),
              ),
              CcMenuItem(
                label: l10n.environmentsDraftFromRepo,
                icon: AppIcons.wand,
                onSelected: () => unawaited(
                  showEnvironmentDraftDialog(context, workspaceId: workspaceId),
                ),
              ),
              CcMenuItem(
                label: l10n.environmentsLinkFile,
                icon: AppIcons.link,
                onSelected: () => unawaited(
                  showEnvironmentLinkDialog(context, workspaceId: workspaceId),
                ),
              ),
            ],
            target: CcButton(
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
              onPressed: _newMenu.toggle,
              child: Text(l10n.environmentsNew),
            ),
          ),
      ],
      child: unsupported
          ? CcEmptyState(
              icon: AppIcons.boxes,
              message: l10n.environmentsUnsupported,
            )
          : EnvironmentDefinitionList(
              definitions: definitions,
              workspaceId: workspaceId,
            ),
    );
  }
}
