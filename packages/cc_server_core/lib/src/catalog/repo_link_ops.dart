import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/features/repos/domain/usecases/add_repo_from_path.dart';
import 'package:cc_host/cc_host.dart' show RepoOp;
import 'package:cc_server_core/src/catalog/catalog_wire.dart'
    show repoFromWire, repoToWire;
import 'package:cc_server_core/src/catalog/granted_repos.dart';
import 'package:cc_server_core/src/catalog/repo_link_guard.dart';
import 'package:cc_server_core/src/forge/forge_repo_pins.dart'
    show RepoLinkVerdict;
import 'package:cc_server_core/src/forge/repo_access_registry.dart'
    show RepoAccessIssue;
import 'package:cc_server_core/src/repo_path_guard.dart';

/// Checks the caller's own forge sign-in can see [repo] before it is linked,
/// and answers what automation will meet there and the forge's durable id
/// for the repository as that read saw it.
typedef VerifyRepoLink =
    Future<RepoLinkVerdict> Function({
      required String workspaceId,
      required String userId,
      required Repo repo,
    });

/// [repos] on the wire for a client listing them, each with `path_issue`:
/// null when its stored path is served, else the [RepoPathRefusal] code
/// (`repo_path.host_path`, `repo_path.missing`, `repo_path.data_dir`,
/// `repo_path.workspace_root`) that keeps it from being served, so a person
/// can see why and relink it. The code only, never the path or a message.
/// Without a [guard] (a bare test catalog) nothing is known: null.
Future<List<Map<String, dynamic>>> reposToListingWire(
  RepoPathGuard? guard,
  String workspaceId,
  List<Repo> repos,
) async => [
  for (final repo in repos)
    {
      ...repoToWire(repo),
      'path_issue': guard == null
          ? null
          : (await guard.refusalOf(workspaceId, repo))?.wire,
    },
];

/// Refuses [userId] reading [repoId] in [workspaceId] unless they hold a read
/// grant (or are an admin) and their own forge sign-in can read it.
typedef RepoReadCheck =
    Future<void> Function({
      required String workspaceId,
      required String userId,
      required String repoId,
    });

/// The `repos.*` ops that read, link, unlink and order a workspace's
/// repositories.
///
/// Linking is an admin decision: a new repository, a changed local path, a
/// changed forge remote, re-saving a row whose stored path is no longer
/// served, or `relink` (a repository whose path now names another one on
/// the forge, `repo_replaced`). A link is pinned to the forge's durable id
/// for the repository as the linker's verified read saw it
/// (`Repo.forgeRepoId`), and a rename keeps the pin. The path must pass [pathGuard] for the person linking it (a
/// checkout outside the workspace's storage only from the server owner), a
/// forge repository's checkout must have the stored repository as its
/// `origin`, and the linker's own forge sign-in must see it
/// ([verifyRepoLink]). Unlinking is an admin decision too, and forgets the
/// forge credentials held for the repository ([onRepoUnlinked]).
///
/// Without [pathGuard] every link is refused.
List<RepoOp> buildRepoLinkOps({
  required RepoRepository repos,
  required RepoReadCheck requireRepoRead,
  required WorkspaceMembershipRepository? members,
  required RepoPathGuard? pathGuard,
  GitRepoInspectorPort? inspector,
  DomainEventBus? eventBus,
  VerifyRepoLink? verifyRepoLink,
  Future<void> Function(String workspaceId, Repo repo)? onRepoUnlinked,
}) {
  RepoPathGuard guard() =>
      pathGuard ??
      (throw const ValidationException(
        'This server cannot check repository paths, so it links none.',
      ));

  Future<bool> served(String workspaceId, Repo repo) async {
    try {
      await guard().admit(workspaceId, repo);
      return true;
    } on RepoPathRefused {
      return false;
    }
  }

  return [
    RepoOp(
      name: 'repos.get',
      kind: RepoOpKind.read,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        final repo = await repos.getById(
          ctx.workspaceId!,
          ctx.args['repo_id'] as String,
        );
        if (repo == null) {
          throw const NotFoundException('Repo not found');
        }
        await requireRepoRead(
          workspaceId: ctx.workspaceId!,
          userId: ctx.userId,
          repoId: repo.id,
        );
        return {
          'repo': (await reposToListingWire(pathGuard, ctx.workspaceId!, [
            repo,
          ])).single,
        };
      },
    ),
    // Repo identity ACROSS workspaces is by path, not id (each workspace mints
    // its own id for a checkout), so this is how a caller asks "is this
    // checkout already here?".
    RepoOp(
      name: 'repos.findByPath',
      kind: RepoOpKind.read,
      requiredArgs: ['path'],
      handler: (ctx) async {
        final repo = await repos.findByPath(
          ctx.workspaceId!,
          ctx.args['path'] as String,
        );
        final granted = await grantedRepos(
          members: members,
          workspaceId: ctx.workspaceId!,
          userId: ctx.userId,
          repos: [?repo],
        );
        return {'repo': granted.isEmpty ? null : repoToWire(granted.single)};
      },
    ),
    RepoOp(
      name: 'repos.exists',
      kind: RepoOpKind.read,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        final exists = await repos.exists(
          ctx.workspaceId!,
          ctx.args['repo_id'] as String,
        );
        return {'exists': exists};
      },
    ),
    RepoOp(
      name: 'repos.upsert',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo'],
      handler: (ctx) async {
        final workspaceId = ctx.workspaceId!;
        final incoming = repoFromWire(
          (ctx.args['repo'] as Map).cast<String, dynamic>(),
        );
        final existing = await repos.getById(workspaceId, incoming.id);
        // A forge repository stays one: there is no local-only mode, so
        // nothing re-saves a linked forge repository without its remote
        // (which would take it out of every forge check).
        if (existing != null &&
            existing.hasForgeRemote &&
            !incoming.hasForgeRemote) {
          throw const ValidationException(
            'A linked forge repository keeps its forge remote.',
            code: 'repo_link.forge_remote_required',
          );
        }
        final link =
            existing == null ||
            ctx.args['relink'] == true ||
            existing.path != incoming.path ||
            changesForgeIdentity(existing, incoming) ||
            !await served(workspaceId, existing);
        if (existing != null && !link) {
          // A rename of a link already made: only the name shown changes.
          // Forge, remote, path, linker and pin stay the stored row's.
          final id = await repos.upsert(
            workspaceId,
            existing.copyWith(name: incoming.name, updatedAt: DateTime.now()),
          );
          return {'repo_id': id, 'access_warnings': accessWarningsWire([])};
        }
        requireRepoLinkAdmin(ctx);
        final path = await guard().check(
          workspaceId,
          incoming.path,
          linkedBy: ctx.userId,
        );
        var repo = incoming.copyWith(
          path: path,
          linkedBy: ctx.userId,
          forgeRepoId: '',
        );
        var warnings = const <RepoAccessIssue>[];
        if (repo.hasForgeRemote) {
          final checkout =
              inspector ??
              (throw const ValidationException(
                'This server cannot inspect checkouts, so it links no forge '
                'repository.',
              ));
          await RepoPathGuard.requireOrigin(checkout, path, repo);
          final verdict = await verifyRepoLink?.call(
            workspaceId: workspaceId,
            userId: ctx.userId,
            repo: repo,
          );
          if (verdict != null) {
            warnings = verdict.warnings;
            repo = repo.copyWith(forgeRepoId: verdict.forgeRepoId);
          }
        }
        final id = await repos.upsert(workspaceId, repo);
        return {'repo_id': id, 'access_warnings': accessWarningsWire(warnings)};
      },
    ),
    RepoOp(
      name: 'repos.delete',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo_id'],
      handler: (ctx) async {
        // Unlinking is the admin decision linking is.
        requireRepoLinkAdmin(ctx);
        final workspaceId = ctx.workspaceId!;
        final repoId = ctx.args['repo_id'] as String;
        final repo = await repos.getById(workspaceId, repoId);
        await repos.delete(workspaceId, repoId);
        if (repo != null) {
          await onRepoUnlinked?.call(workspaceId, repo);
        }
        return {'ok': true};
      },
    ),
    // Drag-to-reorder: persists the manual order every repo list reads back.
    RepoOp(
      name: 'repos.reorder',
      kind: RepoOpKind.mutate,
      requiredArgs: ['repo_ids'],
      handler: (ctx) async {
        await repos.reorder(
          ctx.workspaceId!,
          (ctx.args['repo_ids'] as List).map((e) => e.toString()).toList(),
        );
        return {'ok': true};
      },
    ),
    // Register a repo by pointing at a git checkout on the SERVER's filesystem.
    // Workspace-scoped: the inspected repo is linked into the session's bound
    // workspace via the `RepoAdded` event (server-side indexing keys off it).
    // The path is checked before it is inspected.
    if (inspector != null)
      RepoOp(
        name: 'repos.addFromPath',
        kind: RepoOpKind.mutate,
        requiredArgs: ['path'],
        handler: (ctx) async {
          final workspaceId = ctx.workspaceId!;
          final path = await guard().check(
            workspaceId,
            ctx.args['path'] as String,
            linkedBy: ctx.userId,
          );
          final useCase = AddRepoFromPathUseCase(
            repository: repos,
            inspector: inspector,
            eventBus: eventBus,
          );
          var warnings = const <RepoAccessIssue>[];
          final repo = await useCase.execute(
            path,
            workspaceId: workspaceId,
            linkedBy: ctx.userId,
            // The row already at this path is linked again when its stored
            // link is no longer served (adding the folder again is how a
            // person fixes it), through the same checks as a new link.
            relink: (existing) async => !await served(workspaceId, existing),
            // A new link: admin only, as in `repos.upsert`.
            verify: (repo) async {
              requireRepoLinkAdmin(ctx);
              final verdict = await verifyRepoLink?.call(
                workspaceId: workspaceId,
                userId: ctx.userId,
                repo: repo,
              );
              if (verdict == null) {
                return repo;
              }
              warnings = verdict.warnings;
              return repo.copyWith(forgeRepoId: verdict.forgeRepoId);
            },
          );
          return {
            'repo': repoToWire(repo),
            'access_warnings': accessWarningsWire(warnings),
          };
        },
      ),
  ];
}
