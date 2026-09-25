import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/identity/user_credentials_store.dart';

/// Maps a GitHub login to the workspace member who connected that account.
///
/// Unmapped logins are external identities — no workspace write access until linked.
class GitHubLoginDirectory {
  /// Creates a [GitHubLoginDirectory].
  GitHubLoginDirectory({
    required this._members,
    required this._credentials,
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? now,
    DomainEventBus? eventBus,
  }) : _now = now ?? DateTime.now {
    eventBus?.on<WorkspaceMemberRemoved>().listen(
      (event) => invalidate(event.workspaceId),
    );
    eventBus?.on<WorkspaceMemberRoleChanged>().listen(
      (event) => invalidate(event.workspaceId),
    );
  }

  final WorkspaceMembershipRepository _members;
  final UserCredentialsStore _credentials;

  /// How long credential mappings are trusted. Membership removals and role
  /// changes invalidate the index immediately through membership events; TTL
  /// bounds credential changes without re-reading every token per comment.
  final Duration ttl;

  final DateTime Function() _now;

  final Map<String, _WorkspaceIndex> _byWorkspace = {};

  /// The member of [workspaceId] whose GitHub connection is [login], or null.
  ///
  /// Null is the refusal answer: not connected, or connected by a non-member.
  Future<WorkspaceMember?> memberForLogin(
    String workspaceId,
    String login,
  ) async {
    final key = login.trim().toLowerCase();
    if (workspaceId.isEmpty || key.isEmpty) {
      return null;
    }
    final index = await _indexFor(workspaceId);
    final userId = index.logins[key];
    if (userId == null) {
      return null;
    }
    return _memberById(index.members, userId);
  }

  Future<_WorkspaceIndex> _indexFor(String workspaceId) async {
    final cached = _byWorkspace[workspaceId];
    if (cached != null && _now().difference(cached.builtAt) < ttl) {
      return cached;
    }
    final members = await _members.getForWorkspace(workspaceId);
    final logins = <String, String>{};
    for (final member in members) {
      var token = await _credentials.forgeToken(
        member.userId,
        ForgeHost.github,
        workspaceId: workspaceId,
      );
      token ??= await _credentials.forgeToken(member.userId, ForgeHost.github);
      final login = token?.accountLogin ?? '';
      if (login.isEmpty) {
        continue;
      }
      // putIfAbsent: the OLDEST member wins (the port returns members
      // oldest-first), so a duplicate claim is deterministic.
      logins.putIfAbsent(login.toLowerCase(), () => member.userId);
    }
    return _byWorkspace[workspaceId] = _WorkspaceIndex(
      members: members,
      logins: logins,
      builtAt: _now(),
    );
  }

  WorkspaceMember? _memberById(List<WorkspaceMember> members, String userId) =>
      members.where((m) => m.userId == userId).firstOrNull;

  /// Drops the cached index for [workspaceId] (e.g. after a membership or
  /// credential change the caller knows about).
  void invalidate(String workspaceId) => _byWorkspace.remove(workspaceId);
}

class _WorkspaceIndex {
  _WorkspaceIndex({
    required this.members,
    required this.logins,
    required this.builtAt,
  });

  final List<WorkspaceMember> members;
  final Map<String, String> logins;
  final DateTime builtAt;
}
