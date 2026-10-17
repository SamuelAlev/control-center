import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_activity.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Server mutations used by the space management form. The server remains the
/// authority for membership, repo selection, and autonomy policy.
class SpaceManagementCommands {
  SpaceManagementCommands(this.client);

  final RemoteRpcClient client;

  Future<String> create(
    String workspaceId,
    String name,
    List<String> agents, {
    required Mode mode,
    required List<String>? repoIds,
    required Map<String, String> repoBranches,
  }) async {
    final space = await RemoteMessagingDispatch(client).createSpace(
      workspaceId,
      name,
      agents,
      mode: mode,
      repoIds: repoIds,
      repoBranches: repoBranches,
    );
    return space.id;
  }

  Future<void> save(
    String workspaceId,
    SpaceDto space, {
    required String name,
    required Mode mode,
    required List<String>? repoIds,
    required List<String>? originalRepos,
    required bool Function() stillCurrent,
  }) async {
    final dispatch = RemoteMessagingDispatch(client);
    if (space.name != name) {
      await dispatch.updateSpaceName(workspaceId, space.id, name);
    }
    if (!stillCurrent()) return;
    if (Mode.fromDbValue(space.mode) != mode) {
      await RemoteMessagingRepository(
        client,
      ).setSpaceMode(workspaceId, space.id, mode.toDbValue());
    }
    if (!stillCurrent()) return;
    if (originalRepos == null
        ? repoIds != null
        : repoIds == null ||
              originalRepos.length != repoIds.length ||
              !originalRepos.toSet().containsAll(repoIds)) {
      await dispatch.setSpaceRepos(workspaceId, space.id, repoIds);
    }
  }

  Future<void> addHuman(String workspaceId, String spaceId, String id) async {
    await client.call('messaging.addUserParticipant', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'user_id': id,
    });
  }

  Future<void> changeParticipant(
    String workspaceId,
    String spaceId,
    String id, {
    required bool add,
    required bool human,
  }) async {
    if (add && human) {
      await addHuman(workspaceId, spaceId, id);
    } else if (add) {
      await RemoteMessagingRepository(
        client,
      ).addParticipant(workspaceId, spaceId, id);
    } else {
      await RemoteMessagingDispatch(
        client,
      ).removeParticipant(workspaceId, spaceId, id);
    }
  }

  Future<void> archive(String workspaceId, SpaceDto space) =>
      space.archivedAt == null
      ? RemoteMessagingDispatch(client).archiveSpace(workspaceId, space.id)
      : RemoteMessagingDispatch(client).unarchiveSpace(workspaceId, space.id);

  Future<void> autonomy(
    String workspaceId,
    String spaceId,
    String agentId,
    String? level,
  ) async {
    await client.call('autonomy.setForSpace', {
      'workspace_id': workspaceId,
      'space_id': spaceId,
      'agent_id': agentId,
      'level': level,
    });
  }
}

/// One server aggregate subscription per active workspace, never per list row.
final remoteSpaceActivityProvider = StreamProvider.autoDispose
    .family<List<SpaceActivity>, String>((ref, workspaceId) {
      final client = ref.watch(rpcClientProvider).value;
      if (ref.watch(activeWorkspaceIdProvider).value != workspaceId ||
          client == null) {
        return const Stream.empty();
      }
      return RemoteMessagingRepository(client)
          .watchSpaceActivity(workspaceId: workspaceId)
          .map(
            (rows) => [for (final row in rows) ?SpaceActivity.fromJson(row)],
          );
    });

/// Missing cursor means the user never opened this space, not an unread space.
final remoteSpaceReadProvider = StreamProvider.autoDispose
    .family<Map<String, DateTime>, String>((ref, workspaceId) {
      final client = ref.watch(rpcClientProvider).value;
      if (ref.watch(activeWorkspaceIdProvider).value != workspaceId ||
          client == null) {
        return const Stream.empty();
      }
      return RemoteSpaceReadRepository(client).watchUserSpaceReads(workspaceId);
    });

/// Single run subscription for the list, filtered before any UI receives rows.
final remoteRunningSpacesProvider = StreamProvider.autoDispose
    .family<Set<String>, String>((ref, workspaceId) {
      final client = ref.watch(rpcClientProvider).value;
      if (ref.watch(activeWorkspaceIdProvider).value != workspaceId ||
          client == null) {
        return const Stream.empty();
      }
      return RemoteAgentRunLogRepository(client).watchAll().map(
        (runs) => {
          for (final run in runs)
            if (run.workspaceId == workspaceId &&
                run.spaceId != null &&
                (run.status == 'running' || run.status == 'pending'))
              run.spaceId!,
        },
      );
    });

/// Scoped list of participant identities, watched only while managing a space.
final remoteSpaceParticipantsProvider = StreamProvider.autoDispose
    .family<List<SpaceParticipantDto>, (String, String)>((ref, key) {
      final client = ref.watch(rpcClientProvider).value;
      if (ref.watch(activeWorkspaceIdProvider).value != key.$1 ||
          client == null) {
        return const Stream.empty();
      }
      return RemoteMessagingRepository(
        client,
      ).watchParticipants(key.$1, key.$2);
    });

/// Repo selection is tri-state: null inherits all; [] explicitly selects none.
final remoteSpaceReposProvider = FutureProvider.autoDispose
    .family<List<String>?, (String, String)>((ref, key) async {
      final client = ref.watch(rpcClientProvider).value;
      if (ref.watch(activeWorkspaceIdProvider).value != key.$1 ||
          client == null) {
        return null;
      }
      return RemoteMessagingDispatch(client).getSpaceRepos(key.$1, key.$2);
    });

/// Read-only persisted base branches of an existing space's linked repos.
final remoteSpaceBranchesProvider = FutureProvider.autoDispose
    .family<Map<String, String>, (String, String)>((ref, key) async {
      final client = ref.watch(rpcClientProvider).value;
      if (ref.watch(activeWorkspaceIdProvider).value != key.$1 ||
          client == null) {
        return {};
      }
      final data = await client.call('messaging.getSpaceRepoBranches', {
        'workspace_id': key.$1,
        'space_id': key.$2,
      });
      return (data['branches'] as Map? ?? const {}).cast<String, String>();
    });

/// Explicit per-agent overrides only; absence inherits policy outside space.
final remoteSpaceAutonomyProvider = StreamProvider.autoDispose
    .family<Map<String, String>, (String, String)>((ref, key) {
      final client = ref.watch(rpcClientProvider).value;
      if (ref.watch(activeWorkspaceIdProvider).value != key.$1 ||
          client == null) {
        return const Stream.empty();
      }
      return client
          .subscribe('autonomy.watchForSpace', {
            'workspace_id': key.$1,
            'space_id': key.$2,
          })
          .map(
            (data) => {
              for (final entry in (data['autonomy'] as List? ?? const []))
                if (entry is Map &&
                    entry['agent_id'] is String &&
                    entry['level'] is String)
                  entry['agent_id'] as String: entry['level'] as String,
            },
          );
    });

/// Github branch suggestions for linked repositories in the active workspace.
final remoteRepoBranchesProvider = FutureProvider.autoDispose
    .family<List<String>, (String, String, String)>((ref, key) async {
      final client = ref.watch(rpcClientProvider).value;
      if (client == null ||
          ref.watch(activeWorkspaceIdProvider).value != key.$1) {
        return [];
      }
      final data = await client.call('github.repoBranches', {
        'workspace_id': key.$1,
        'owner': key.$2,
        'repo': key.$3,
      });
      return (data['branches'] as List? ?? const [])
          .whereType<String>()
          .toList();
    });

/// Members eligible to be invited to a space in the active workspace.
final remoteSpaceMembersProvider = StreamProvider.autoDispose
    .family<List<WorkspaceMemberDto>, String>((ref, workspaceId) {
      final client = ref.watch(rpcClientProvider).value;
      if (client == null ||
          ref.watch(activeWorkspaceIdProvider).value != workspaceId) {
        return const Stream.empty();
      }
      return RemoteIdentityRepository(client).watchMembers(workspaceId);
    });
