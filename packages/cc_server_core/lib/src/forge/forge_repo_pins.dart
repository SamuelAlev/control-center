/// A linked repository is pinned by the forge's durable id, so a repository
/// renamed, transferred, or deleted and then re-registered at the old path by
/// someone else never receives this server's tokens, pushes or comments.
library;

import 'package:cc_domain/cc_domain.dart'
    show AuthException, ForgeAccessRefusedException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart' show ForgeCredentialUnavailable;
import 'package:cc_server_core/src/forge/forge_audit.dart';
import 'package:cc_server_core/src/forge/forge_automation_request_policy.dart'
    show forgeRequestRepo;
import 'package:cc_server_core/src/forge/forge_link_check.dart';
import 'package:cc_server_core/src/forge/repo_access_registry.dart';

/// A repository as the forge names it right now: its durable `id` (a GitHub
/// repository id, a GitLab project id, a Bitbucket repository uuid) and its
/// current path.
typedef ForgeRepoIdentity = ({String id, String owner, String name});

/// A link check's outcome: the forge's durable id for the repository as the
/// linker's own verified read saw it (empty when nothing authorized read
/// it), and what automation will meet there.
typedef RepoLinkVerdict = ({
  String forgeRepoId,
  List<RepoAccessIssue> warnings,
});

/// The `code` of the [AuthException] a replaced repository is refused with.
const String forgeRepoReplacedCode = 'repo_replaced';

/// Confirms that [owner]/[name] on [forge] in a workspace still names the
/// repository linked there, as [resolved] (read with an authorized token)
/// says; see [ForgeRepoPins.confirm].
typedef ConfirmForgeRepo =
    Future<void> Function(
      String workspaceId,
      ForgeHost forge,
      String owner,
      String name,
      ForgeRepoIdentity resolved,
    );

/// Confirms, before a person's own request on [forge] goes out with their
/// [token], that a linked repository the request names is still the one
/// linked; see [ForgeRepoPins.confirmPersonRequest].
typedef ConfirmPersonForgeRequest =
    Future<void> Function(
      String workspaceId,
      ForgeHost forge,
      String url,
      Object? jsonBody,
      String? token,
    );

/// The one place a linked repository's stored durable id is compared with
/// what the forge answers for its path, filled in, or moved.
///
/// Every chokepoint that turns a linked repository into a token or a forge
/// call asks here first: GitHub's repository read behind every mint
/// (`GitHubMinter.repoFacts`), and every GitLab and Bitbucket request a
/// repository's client sends ([confirmRequest]).
final class ForgeRepoPins {
  /// Creates the pins over the workspace repositories (unguarded: the pin
  /// belongs to the row, whatever path it serves) and the access record.
  ForgeRepoPins({
    required this._repos,
    required this._access,
    ForgeRepoRead? read,
    DateTime Function()? now,
  }) : _read = read ?? readForgeRepo,
       _now = now ?? DateTime.now;

  final RepoRepository _repos;
  final RepoAccessRegistry _access;
  final ForgeRepoRead _read;
  final DateTime Function() _now;

  /// How long a GitLab or Bitbucket path's resolved id is trusted, as long
  /// as GitHub's repository facts are.
  static const Duration resolvedTtl = Duration(minutes: 5);
  static const int _maxResolved = 2048;
  final Map<String, ({ForgeRepoIdentity identity, DateTime at})> _resolved = {};

  static bool _same(String a, String b) => a.toLowerCase() == b.toLowerCase();

  /// Compares every row of [workspaceId] linked as [owner]/[name] on [forge]
  /// with [resolved]:
  ///
  /// - no such row (not linked: a skill source, a link being made): nothing;
  /// - a row pinned to nothing yet: pinned to [resolved] (one write,
  ///   audited `forge.repo.pinned`);
  /// - the same id under another owner/name (renamed or transferred): the
  ///   stored owner/name follow it (audited `forge.repo.moved`), and the
  ///   caller carries on;
  /// - another id: recorded [RepoAccessState.repoReplaced] for an admin to
  ///   relink, audited `forge.repo.replaced`, and refused with a
  ///   [ForgeAccessRefusedException] whose code is
  ///   [forgeRepoReplacedCode].
  Future<void> confirm(
    String workspaceId,
    ForgeHost forge,
    String owner,
    String name,
    ForgeRepoIdentity resolved,
  ) async {
    if (resolved.id.isEmpty) {
      return;
    }
    final rows = [
      for (final r in await _repos.getAll(workspaceId))
        if (r.forge == forge &&
            r.hasForgeRemote &&
            _same(r.remoteOwner, owner) &&
            _same(r.remoteName, name))
          r,
    ];
    for (final row in rows) {
      if (row.forgeRepoId.isNotEmpty && row.forgeRepoId != resolved.id) {
        final message =
            '${row.fullName} now names a different repository on '
            '${forge.displayName} than the one linked here; relink it to use '
            'that one.';
        await _access.record(
          workspaceId,
          forge: forge,
          owner: row.remoteOwner,
          name: row.remoteName,
          state: RepoAccessState.repoReplaced,
          repoId: row.id,
          message: message,
        );
        forgeAudit(ForgeAuditEvent.forgeRepoReplaced, {
          'forge': forge.wire,
          'workspace_id': workspaceId,
          'repo_id': row.id,
          'repo': row.fullName,
          'pinned_id': row.forgeRepoId,
          'resolved_id': resolved.id,
        });
        throw ForgeAccessRefusedException(
          message,
          code: forgeRepoReplacedCode,
          forge: forge,
        );
      }
      final moved =
          resolved.owner.isNotEmpty &&
          resolved.name.isNotEmpty &&
          !(_same(row.remoteOwner, resolved.owner) &&
              _same(row.remoteName, resolved.name));
      if (row.forgeRepoId == resolved.id && !moved) {
        continue;
      }
      await _repos.upsert(
        workspaceId,
        row.copyWith(
          forgeRepoId: resolved.id,
          remoteOwner: moved ? resolved.owner : null,
          remoteName: moved ? resolved.name : null,
          // A display name that was the old path follows it.
          name: moved && row.name == row.fullName
              ? '${resolved.owner}/${resolved.name}'
              : null,
          updatedAt: _now(),
        ),
      );
      if (moved) {
        // The record was about the old path.
        await _access.forgetRepo(
          workspaceId,
          forge: forge,
          owner: row.remoteOwner,
          name: row.remoteName,
        );
      }
      forgeAudit(
        moved
            ? ForgeAuditEvent.forgeRepoMoved
            : ForgeAuditEvent.forgeRepoPinned,
        {
          'forge': forge.wire,
          'workspace_id': workspaceId,
          'repo_id': row.id,
          'repo': row.fullName,
          if (moved) 'moved_to': '${resolved.owner}/${resolved.name}',
          'forge_repo_id': resolved.id,
        },
      );
    }
  }

  /// The pin check one GitLab or Bitbucket request for [repo] makes before
  /// it is sent with [token]: what the forge names [repo]'s path (read with
  /// that same token, trusted for [resolvedTtl]) is compared ([confirm]).
  ///
  /// Refused locally, nothing sent: a replaced repository (409), and a
  /// pinned one whose id could not be read now (the forge's own status, or
  /// 503 when it was not reached). A row not pinned yet whose id cannot be
  /// read goes out as before: there is nothing to compare it with.
  Future<void> confirmRequest(
    String workspaceId,
    Repo repo,
    String token,
  ) async {
    if (!repo.hasForgeRemote) {
      return;
    }
    final key =
        '$workspaceId\u0000${repo.forge.wire}\u0000'
        '${repo.fullName.toLowerCase()}';
    final now = _now();
    var identity = _resolved[key];
    if (identity == null || now.difference(identity.at) >= resolvedTtl) {
      final answer = await _read(
        repo.forge,
        token,
        repo.remoteOwner,
        repo.remoteName,
      );
      final read = answer.repo;
      if (answer.status != 200 || read == null) {
        if (repo.forgeRepoId.isEmpty) {
          return;
        }
        final status = answer.status;
        throw ForgeCredentialUnavailable(
          status == 401 || status == 403 || status == 404 ? status! : 503,
          '${repo.forge.displayName} could not confirm that ${repo.fullName} '
          'is still the repository linked here.',
        );
      }
      _resolved
        ..removeWhere((_, v) => now.difference(v.at) >= resolvedTtl)
        ..remove(key);
      while (_resolved.length >= _maxResolved) {
        _resolved.remove(_resolved.keys.first);
      }
      identity = (identity: read, at: now);
      _resolved[key] = identity;
    }
    try {
      await confirm(
        workspaceId,
        repo.forge,
        repo.remoteOwner,
        repo.remoteName,
        identity.identity,
      );
    } on AuthException catch (e) {
      if (e.code != forgeRepoReplacedCode) {
        rethrow;
      }
      throw ForgeCredentialUnavailable.repoReplaced(repo.forge, e.message);
    }
  }

  /// The pin check a person's own request makes before it is sent with
  /// their [token]: when [url] (or a GitHub GraphQL request's variables)
  /// names a repository linked in [workspaceId] on [forge], that repository
  /// is confirmed as [confirmRequest] confirms an automation request, so a
  /// person never acts on another repository created at a linked path. A
  /// request naming no linked repository (who the token is, a search, a
  /// notification) goes out unchecked.
  Future<void> confirmPersonRequest(
    String workspaceId,
    ForgeHost forge,
    String url,
    Object? jsonBody,
    String? token,
  ) async {
    if (workspaceId.isEmpty || token == null || token.isEmpty) {
      return;
    }
    final named = forgeRequestRepo(forge, url, jsonBody);
    if (named == null) {
      return;
    }
    for (final row in await _repos.getAll(workspaceId)) {
      if (row.forge == forge &&
          row.hasForgeRemote &&
          _same(row.remoteOwner, named.owner) &&
          _same(row.remoteName, named.name)) {
        await confirmRequest(workspaceId, row, token);
        return;
      }
    }
  }
}
