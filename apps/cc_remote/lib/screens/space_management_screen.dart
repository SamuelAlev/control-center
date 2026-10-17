import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/space_management_providers.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/space_management/space_form.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Creates or edits a server-owned collaborative space in the active workspace.
class SpaceManagementScreen extends ConsumerWidget {
  const SpaceManagementScreen({this.spaceId, super.key});

  final String? spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
    final client = ref.watch(rpcClientProvider).value;
    final roleAsync = ref.watch(workspaceRoleProvider);
    final spaces = ref.watch(spacesProvider);
    final agents = ref.watch(agentsProvider);
    final linkedRepos = ref.watch(workspaceReposProvider);
    final members = workspaceId == null || client == null
        ? const AsyncValue<List<WorkspaceMemberDto>>.loading()
        : ref.watch(remoteSpaceMembersProvider(workspaceId));
    final editing = spaceId != null;
    final space = editing && workspaceId != null
        ? (spaces.value ?? const <SpaceDto>[])
              .where(
                (item) => item.id == spaceId && item.workspaceId == workspaceId,
              )
              .firstOrNull
        : null;
    final key = space == null ? null : (workspaceId!, space.id);
    final participants = key == null
        ? const AsyncValue<List<SpaceParticipantDto>>.data([])
        : ref.watch(remoteSpaceParticipantsProvider(key));
    final selection = key == null
        ? const AsyncValue<List<String>?>.data(null)
        : ref.watch(remoteSpaceReposProvider(key));
    final baseBranches = key == null
        ? const AsyncValue<Map<String, String>>.data({})
        : ref.watch(remoteSpaceBranchesProvider(key));
    final autonomy = key == null
        ? const AsyncValue<Map<String, String>>.data({})
        : ref.watch(remoteSpaceAutonomyProvider(key));
    final loading =
        workspaceId == null ||
        client == null ||
        (editing && spaces.isLoading) ||
        agents.isLoading ||
        linkedRepos.isLoading ||
        members.isLoading ||
        participants.isLoading ||
        selection.isLoading ||
        baseBranches.isLoading ||
        autonomy.isLoading ||
        roleAsync.isLoading;
    final loadError =
        spaces.error ??
        agents.error ??
        linkedRepos.error ??
        members.error ??
        participants.error ??
        selection.error ??
        baseBranches.error ??
        autonomy.error ??
        roleAsync.error;
    return SafeArea(
      child: ColoredBox(
        color: tokens.canvas,
        child: Column(
          children: [
            DetailHeader(
              title: editing ? l10n.mobileSpacesManage : l10n.mobileSpacesNew,
            ),
            if (loading)
              const Expanded(child: Center(child: CcSpinner(size: 24)))
            else if (loadError != null ||
                roleAsync.value == null ||
                (editing && space == null))
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: CcEmptyState(
                        icon: AppIcons.triangleAlert,
                        message: loadError == null
                            ? l10n.mobileSpacesMissing
                            : l10n.spacesLoadFailed,
                        description: loadError?.toString(),
                      ),
                    ),
                    if (loadError != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: CcButton(
                          size: CcButtonSize.lg,
                          onPressed: () {
                            ref.invalidate(spacesProvider);
                            ref.invalidate(agentsProvider);
                            ref.invalidate(workspaceReposProvider);
                            ref.invalidate(workspaceRoleProvider);
                            ref.invalidate(
                              remoteSpaceMembersProvider(workspaceId),
                            );
                            if (key != null) {
                              ref.invalidate(
                                remoteSpaceParticipantsProvider(key),
                              );
                              ref.invalidate(remoteSpaceReposProvider(key));
                              ref.invalidate(remoteSpaceBranchesProvider(key));
                              ref.invalidate(remoteSpaceAutonomyProvider(key));
                            }
                          },
                          child: Text(l10n.mobileSpacesRetry),
                        ),
                      ),
                  ],
                ),
              )
            else
              Expanded(
                child: SpaceForm(
                  key: ValueKey((workspaceId, spaceId)),
                  workspaceId: workspaceId,
                  space: space,
                  role: roleAsync.value!,
                  selfId: ref.watch(remoteIdentityProvider).value?.userId,
                  agents: agents.value!,
                  members: members.value!,
                  repos: linkedRepos.value!,
                  participants: participants.value!,
                  selectedRepos: selection.value,
                  baseBranches: baseBranches.value!,
                  autonomy: autonomy.value!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
