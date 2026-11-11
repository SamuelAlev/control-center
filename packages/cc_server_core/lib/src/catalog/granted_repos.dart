/// A workspace's repository list as one member may see it.
///
/// Repository names are not public to every member: a member who is not an
/// admin sees only the repositories they hold a Control Center grant on.
/// Whether their own forge sign-in can read a granted repository does not
/// matter here: a repository they hold the grant on but cannot reach on the
/// forge stays listed (it is where they ask for forge access), while its pull
/// requests stay hidden ([PrRepoVisibility]).
library;

import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart'
    show PrRepoVisibility;

/// The [repos] that [userId] may see in [workspaceId]: all of them
/// for an admin, those with a read grant otherwise, none for a non-member
/// or without membership wiring (fail closed).
Future<List<Repo>> grantedRepos({
  required WorkspaceMembershipRepository? members,
  required String workspaceId,
  required String userId,
  required List<Repo> repos,
}) async {
  if (members == null) {
    return const [];
  }
  final member = await members.getMember(workspaceId, userId);
  if (member == null) {
    return const [];
  }
  if (member.role.isAdmin) {
    return repos;
  }
  final grants = await members.getRepoGrants(workspaceId, userId);
  return [
    for (final r in repos)
      if ((grants[r.id] ?? RepoGrantLevel.none).allowsRead) r,
  ];
}

/// Live frames of [repos] narrowed by [grantedRepos], re-evaluated when the
/// repository list changes or [changes] ticks (the caller's role or grants
/// moved). Identical frames collapse.
Stream<Map<String, dynamic>> grantedRepoFrames({
  required WorkspaceMembershipRepository? members,
  required String workspaceId,
  required String userId,
  required Stream<List<Repo>> repos,
  required FutureOr<Map<String, dynamic>> Function(List<Repo> repos) render,
  Stream<void>? changes,
}) => Stream<Map<String, dynamic>>.multi((out) {
  List<Repo>? latest;
  String? last;
  var chain = Future<void>.value();

  void update() {
    final list = latest;
    if (list == null) {
      return;
    }
    // Serialized, so an older evaluation never lands after a newer one.
    chain = chain.then((_) async {
      try {
        final frame = await render(
          await grantedRepos(
            members: members,
            workspaceId: workspaceId,
            userId: userId,
            repos: list,
          ),
        );
        final encoded = jsonEncode(frame);
        if (!out.isClosed && encoded != last) {
          last = encoded;
          out.add(frame);
        }
      } on Object catch (e, st) {
        if (!out.isClosed) {
          out.addError(e, st);
        }
      }
    });
  }

  final repoSub = repos.listen(
    (list) {
      latest = list;
      update();
    },
    onError: out.addError,
    // A source that answers once and ends still re-filters on [changes].
    onDone: () => changes == null ? chain.whenComplete(out.close) : null,
  );
  final tickSub = changes?.listen((_) => update());
  out.onCancel = () async {
    await repoSub.cancel();
    await tickSub?.cancel();
  };
});

/// The ticks [grantedRepoFrames] re-evaluates on for [userId] in
/// [workspaceId]: [visibility]'s per-person changes (membership, role and
/// grant edits tick it), none without one.
Stream<void>? grantChanges(
  PrRepoVisibility? visibility,
  String workspaceId,
  String userId,
) => visibility?.changes(workspaceId, userId);
