import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/teams/domain/repositories/team_repository.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [TeamRepository] the UI reads through — flipped to the cc_data
/// RpcX adapter over the desktop's in-process RPC server (the composition
/// flip). Server-side EXECUTION that touches teams (the pipeline team-dispatch
/// body, orchestration materialization) uses the Dao-backed
/// `daoTeamRepositoryProvider` in `di/providers.dart` instead, to stay direct on
/// the DB and avoid cycling through `rpcClientProvider`.
final teamRepositoryProvider = Provider<TeamRepository>((ref) {
  return RpcTeamRepository(ref.watch(rpcClientProvider));
});

/// Streams the teams in `workspaceId`, emitting on every change. The teams
/// management screen reads through this.
final teamsForWorkspaceProvider = StreamProvider.family<List<Team>, String>((
  ref,
  workspaceId,
) {
  return ref.watch(teamRepositoryProvider).watchTeamsForWorkspace(workspaceId);
});

/// Streams the members of `teamId`, emitting on every membership change.
final teamMembersProvider = StreamProvider.family<List<TeamMember>, String>((
  ref,
  teamId,
) {
  return ref
      .watch(teamRepositoryProvider)
      .watchMembersOf(ref.requireWorkspaceId(), teamId);
});
