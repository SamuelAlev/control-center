/// The one path that ends a person's provider credentials when they leave.
library;

import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/google_calendar_server.dart'
    show CalendarAccountService;
import 'package:cc_server_core/src/identity/user_credentials_store.dart';

/// Ends the provider credentials of a person who left a workspace or the
/// server, and of a deleted workspace: every sign-in lane revokes upstream
/// (best effort) and deletes what it keeps, then the credentials no lane
/// owns (GitLab and Bitbucket sign-ins, Jira and ClickUp tokens, which have
/// no revoke endpoint) are deleted.
///
/// * A member removed from a workspace (by an admin, by SCIM deactivation,
///   by leaving) loses everything kept in that workspace's own slots.
/// * A person who belongs to no workspace any more loses their global
///   sign-ins as well.
/// * A deleted workspace loses every member's slot credentials and its own
///   grants (the Linear app actor, the shared Slack install).
///
/// [reconcile] runs the same rules at boot for anything a crash (or an
/// earlier build) left behind.
final class CredentialOffboarding {
  /// Creates the offboarding over the registered sign-in lanes.
  CredentialOffboarding({
    required this._signIn,
    required this._users,
    required this._members,
    required this._workspaces,
    this._calendar,
  });

  final ProviderSignInService _signIn;
  final UserCredentialsStore _users;
  final WorkspaceMembershipRepository _members;
  final WorkspaceRepository _workspaces;
  final CalendarAccountService? _calendar;

  /// [userId] is no longer a member of [workspaceId].
  Future<void> memberLeft(String userId, String workspaceId) async {
    await _offboard(
      userId: userId,
      workspaceId: workspaceId,
      reason: 'member_removed',
    );
    if ((await _members.getForUser(userId)).isEmpty) {
      await _offboard(userId: userId, reason: 'no_workspace');
    }
  }

  /// [workspaceId] was deleted. Runs before its secrets are deleted, while
  /// the grants can still be presented upstream.
  Future<void> workspaceDeleted(String workspaceId) =>
      _offboard(workspaceId: workspaceId, reason: 'workspace_deleted');

  /// Applies the rules above to what is stored now: a slot credential of a
  /// person who is not a member of that workspace (or of a deleted one), and
  /// a global sign-in of a person who belongs to no workspace.
  Future<void> reconcile() async {
    final slots = <({String workspaceId, String userId})>{
      for (final forge in ForgeHost.values)
        for (final held in await _users.forgeTokens(forge))
          if (held.workspaceId case final workspaceId?)
            (workspaceId: workspaceId, userId: held.userId),
      for (final provider in TicketProvider.values)
        ...await _users.workspaceTicketSlots(provider),
    };
    final workspaceIds = {for (final slot in slots) slot.workspaceId};
    final calendar = _calendar;
    if (calendar != null) {
      slots.addAll(await calendar.holders(workspaceIds));
    }
    final gone = <String>{};
    for (final workspaceId in {for (final slot in slots) slot.workspaceId}) {
      final workspace = await _workspaces.getById(workspaceId);
      if (workspace == null || workspace.deletedAt != null) {
        gone.add(workspaceId);
        await workspaceDeleted(workspaceId);
      }
    }
    for (final (:workspaceId, :userId) in slots) {
      if (!gone.contains(workspaceId) &&
          await _members.getMember(workspaceId, userId) == null) {
        await _offboard(
          userId: userId,
          workspaceId: workspaceId,
          reason: 'not_a_member',
        );
      }
    }
    final globalHolders = <String>{
      for (final forge in ForgeHost.values)
        for (final held in await _users.forgeTokens(forge))
          if (held.workspaceId == null) held.userId,
      for (final provider in TicketProvider.values)
        ...await _users.ticketUsers(provider),
    };
    for (final userId in globalHolders) {
      if ((await _members.getForUser(userId)).isEmpty) {
        await _offboard(userId: userId, reason: 'no_workspace');
      }
    }
  }

  Future<void> _offboard({
    String? userId,
    String? workspaceId,
    required String reason,
  }) async {
    for (final binding in _signIn.bindings) {
      try {
        final count = await binding.offboard(
          userId: userId,
          workspaceId: workspaceId,
        );
        if (count > 0) {
          _cleared(binding.lane.wire, userId, workspaceId, reason, count);
        }
      } on Object catch (e) {
        forgeAudit(ForgeAuditEvent.grantResetFailed, {
          'lane': binding.lane.wire,
          'user_id': userId,
          'workspace_id': workspaceId,
          'reason': '$reason:${errorKindOf(e)}',
        });
      }
    }
    if (userId == null) {
      // A deleted workspace's remaining slot keys go with its secrets.
      return;
    }
    final forges = await _users.clearPersonForgeTokens(
      userId,
      workspaceId: workspaceId,
    );
    final tickets = await _users.clearPersonTicketTokens(
      userId,
      workspaceId: workspaceId,
    );
    for (final (:forge, workspaceId: _, :token) in forges) {
      _cleared(forge.wire, userId, workspaceId, reason, 1);
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': forge.wire,
        'user_id': userId,
        'reason': 'no_revoke_endpoint',
      }, token: token.accessToken);
    }
    for (final (:provider, :token) in tickets) {
      _cleared(provider.name, userId, workspaceId, reason, 1);
      forgeAudit(ForgeAuditEvent.grantRevokeSkipped, {
        'lane': provider.name,
        'user_id': userId,
        'reason': 'no_revoke_endpoint',
      }, token: token.accessToken);
    }
  }

  static void _cleared(
    String lane,
    String? userId,
    String? workspaceId,
    String reason,
    int count,
  ) => forgeAudit(ForgeAuditEvent.grantCleared, {
    'lane': lane,
    'user_id': userId,
    'workspace_id': workspaceId,
    'reason': reason,
    'count': count,
  });
}
