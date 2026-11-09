import 'package:cc_domain/cc_domain.dart'
    show
        AuthException,
        NotFoundException,
        RepoOpKind,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/ports/forge_credential_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show prCommitToWire, prFileToWire;
import 'package:cc_server_core/src/forge/forge_pr_client_resolver.dart';

/// The linked repos of a workspace (forge or not; the ops filter).
typedef WorkspaceReposLookup = Future<List<Repo>> Function(String workspaceId);

/// `forge.repoBranches`, `forge.defaultBranch`, `forge.prTemplates` and
/// `forge.compareBranches`: the compose-PR reads, on the repo's own forge.
///
/// Every read runs server-side on the caller's own credential for that forge;
/// the client holds no token. The `owner`/`repo` (and optional `forge`) args
/// must name a forge repo linked to the bound workspace, and the caller must
/// hold a read grant on it (membership is not code access), before any forge
/// call. Stating `forge` keeps two repos with the same `owner/name` on
/// different forges apart; without it a coordinate both forges share is
/// refused rather than guessed. Empty when no client resolver is wired.
List<RepoOp> buildForgeComposeOps({
  required WorkspaceReposLookup linkedRepos,
  required WorkspaceMembershipRepository? members,
  required ForgePrClientResolver? clientFor,
  ForgeConnectionView? connections,
}) {
  if (clientFor == null) {
    return const [];
  }

  Future<(Repo, ForgePrClient)> resolve(RepoOpContext ctx) async {
    final workspaceId = ctx.workspaceId!;
    final repo = await _requireLinkedForgeRepo(
      ctx,
      linkedRepos: linkedRepos,
      members: members,
    );
    return (
      repo,
      clientFor(repo, workspaceId: workspaceId, actingUserId: ctx.userId),
    );
  }

  return [
    RepoOp(
      name: 'forge.repoBranches',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final (repo, client) = await resolve(ctx);
        final branches = await client.listBranches();
        // The CALLER's own branches lead the picker — that is almost always
        // what they are about to open a PR from. Resolved per forge AND per
        // caller: the same human is a different account on each forge.
        final me =
            (await connections?.viewerLogin(
                      repo.forge,
                      userId: ctx.userId,
                      workspaceId: ctx.workspaceId,
                    ) ??
                    '')
                .toLowerCase();
        final mine = <String>[];
        final others = <String>[];
        for (final b in branches) {
          (me.isNotEmpty && b.lastCommitAuthor.toLowerCase() == me
                  ? mine
                  : others)
              .add(b.name);
        }
        return {
          'branches': [...mine, ...others],
        };
      },
    ),
    RepoOp(
      name: 'forge.defaultBranch',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final (_, client) = await resolve(ctx);
        return {'branch': await client.getDefaultBranch()};
      },
    ),
    RepoOp(
      name: 'forge.prTemplates',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo'],
      handler: (ctx) async {
        final (_, client) = await resolve(ctx);
        if (!client.capabilities.prTemplates) {
          return {'templates': <Map<String, dynamic>>[]};
        }
        final templates = await client.listPrTemplates();
        return {
          'templates': [
            for (final entry in templates.entries)
              {
                'name': entry.key,
                'body': entry.value,
                // The conventional single template is the default; with
                // several the composer lets the operator pick.
                'is_default': templates.length == 1,
              },
          ],
        };
      },
    ),
    RepoOp(
      name: 'forge.compareBranches',
      kind: RepoOpKind.read,
      requiredArgs: ['owner', 'repo', 'base', 'head'],
      handler: (ctx) async {
        final base = ctx.args['base'];
        final head = ctx.args['head'];
        if (base is! String || head is! String) {
          throw const NotFoundException(
            'Missing or invalid argument: base/head',
          );
        }
        final (_, client) = await resolve(ctx);
        final c = await client.compareBranches(base: base, head: head);
        if (c == null) {
          return {'comparison': null};
        }
        return {
          'comparison': {
            'files': [for (final f in c.files) prFileToWire(f)],
            'commits': [for (final cm in c.commits) prCommitToWire(cm)],
            'additions': c.additions,
            'deletions': c.deletions,
            'total_commits': c.totalCommits,
          },
        };
      },
    ),
  ];
}

/// The forge repo `owner`/`repo` (and `forge`, when stated) names among the
/// bound workspace's linked repos, after checking the caller's read grant.
Future<Repo> _requireLinkedForgeRepo(
  RepoOpContext ctx, {
  required WorkspaceReposLookup linkedRepos,
  required WorkspaceMembershipRepository? members,
}) async {
  final owner = ctx.args['owner'];
  final name = ctx.args['repo'];
  if (owner is! String || owner.isEmpty || name is! String || name.isEmpty) {
    throw const NotFoundException('Missing or invalid argument: owner/repo');
  }
  final forgeArg = ctx.args['forge'];
  final forge = forgeArg is String && forgeArg.isNotEmpty
      ? ForgeHost.fromWire(forgeArg)
      : null;
  final workspaceId = ctx.workspaceId!;
  final matches = [
    for (final r in await linkedRepos(workspaceId))
      if (r.hasForgeRemote &&
          (forge == null || r.forge == forge) &&
          r.remoteOwner.toLowerCase() == owner.toLowerCase() &&
          r.remoteName.toLowerCase() == name.toLowerCase())
        r,
  ];
  if (matches.isEmpty) {
    throw const WorkspaceMismatchException(
      'Repository is not linked to this workspace',
    );
  }
  if (matches.length > 1) {
    throw const NotFoundException(
      'Several linked repositories share this owner/name; pass forge',
    );
  }
  final repo = matches.single;
  // Fail closed: without membership wiring repo access cannot be authorized.
  if (members == null) {
    throw const AuthException(
      'This server has no membership wiring, so repo access cannot be '
      'authorized.',
    );
  }
  final member = await members.getMember(workspaceId, ctx.userId);
  if (member == null) {
    throw const AuthException('Not a member of this workspace');
  }
  if (!member.role.isAdmin) {
    final grants = await members.getRepoGrants(workspaceId, ctx.userId);
    if (!(grants[repo.id] ?? RepoGrantLevel.none).allowsRead) {
      throw const AuthException('No read access to this repo');
    }
  }
  return repo;
}
