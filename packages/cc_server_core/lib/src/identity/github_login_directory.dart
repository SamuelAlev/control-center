import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';

/// The GitHub credential [userId] has stored for [workspaceId] (the workspace
/// overlay, else their global sign-in where the workspace inherits), or null.
typedef GitHubCredentialLookup =
    Future<ProviderToken?> Function(String userId, String workspaceId);

/// Maps a GitHub account to the workspace member who signed in with it.
///
/// Matching is by GitHub's immutable numeric account id (`user.id`, stored on
/// the sign-in as [ProviderToken.accountId]), never by login: a login can be
/// renamed and then registered by someone else, who would otherwise inherit
/// the member's access. Unmapped accounts are external identities with no
/// workspace access.
class GitHubLoginDirectory {
  /// Creates a [GitHubLoginDirectory].
  GitHubLoginDirectory({
    required this._members,
    required this._credentials,
    this.ttl = const Duration(minutes: 5),
    DateTime Function()? now,
    DomainEventBus? eventBus,
    Stream<({String userId, String? workspaceId})>? githubSignInChanges,
  }) : _now = now ?? DateTime.now {
    eventBus?.on<WorkspaceMemberAdded>().listen(
      (event) => invalidate(event.workspaceId),
    );
    eventBus?.on<WorkspaceMemberRemoved>().listen(
      (event) => invalidate(event.workspaceId),
    );
    eventBus?.on<WorkspaceMemberRoleChanged>().listen(
      (event) => invalidate(event.workspaceId),
    );
    // A sign-in or disconnect must reach the PR bridge at once: a member's
    // first comment after signing in would otherwise be refused for up to
    // [ttl]. A global sign-in is seen by every workspace that inherits it.
    githubSignInChanges?.listen((change) {
      final workspaceId = change.workspaceId;
      if (workspaceId == null || workspaceId.isEmpty) {
        invalidateAll();
      } else {
        invalidate(workspaceId);
      }
    });
  }

  final WorkspaceMembershipRepository _members;
  final GitHubCredentialLookup _credentials;

  /// How long credential mappings are trusted. Membership events and GitHub
  /// sign-in changes invalidate the index immediately; the TTL only bounds
  /// what no event reports (a credential edited outside this process).
  final Duration ttl;

  final DateTime Function() _now;

  final Map<String, _WorkspaceIndex> _byWorkspace = {};

  /// Bumped per workspace by [invalidate] (and for all by [invalidateAll]),
  /// so an index built from reads taken before an invalidation is never
  /// cached over it.
  final Map<String, int> _generation = {};
  int _allGeneration = 0;

  /// The member of [workspaceId] who signed in to GitHub as account
  /// [accountId], or null.
  ///
  /// Null is the refusal answer: unknown id, not signed in, a sign-in that
  /// predates account ids, or a non-member.
  Future<WorkspaceMember?> memberForAccountId(
    String workspaceId,
    int accountId,
  ) async {
    if (workspaceId.isEmpty || accountId <= 0) {
      return null;
    }
    final index = await _indexFor(workspaceId);
    final userId = index.accounts['$accountId'];
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
    final generation = (_generation[workspaceId] ?? 0, _allGeneration);
    final members = await _members.getForWorkspace(workspaceId);
    final accounts = <String, String>{};
    for (final member in members) {
      final token = await _credentials(member.userId, workspaceId);
      final accountId = token?.accountId.trim() ?? '';
      if (accountId.isEmpty) {
        continue;
      }
      // putIfAbsent: the OLDEST member wins (the port returns members
      // oldest-first), so a duplicate claim is deterministic.
      accounts.putIfAbsent(accountId, () => member.userId);
    }
    final index = _WorkspaceIndex(
      members: members,
      accounts: accounts,
      builtAt: _now(),
    );
    if (generation == (_generation[workspaceId] ?? 0, _allGeneration)) {
      _byWorkspace[workspaceId] = index;
    }
    return index;
  }

  WorkspaceMember? _memberById(List<WorkspaceMember> members, String userId) =>
      members.where((m) => m.userId == userId).firstOrNull;

  /// Drops the cached index for [workspaceId] (e.g. after a membership or
  /// credential change the caller knows about).
  void invalidate(String workspaceId) {
    _byWorkspace.remove(workspaceId);
    _generation[workspaceId] = (_generation[workspaceId] ?? 0) + 1;
  }

  /// Drops every cached index (a global sign-in changed).
  void invalidateAll() {
    _byWorkspace.clear();
    _allGeneration++;
  }
}

class _WorkspaceIndex {
  _WorkspaceIndex({
    required this.members,
    required this.accounts,
    required this.builtAt,
  });

  final List<WorkspaceMember> members;

  /// GitHub account id (decimal) → user id.
  final Map<String, String> accounts;
  final DateTime builtAt;
}
