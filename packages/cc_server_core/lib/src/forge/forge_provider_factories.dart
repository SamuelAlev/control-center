import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/cached_pr_review_repository.dart';
import 'package:cc_server_core/src/forge/forge_pr_client_resolver.dart';
import 'package:cc_server_core/src/pr_review/forge_client_pr_diff_source.dart';
import 'package:rhttp/rhttp.dart';

/// Server-side [ForgeProviderFactory] for any forge.
///
/// Every forge's factory is this same class with a different
/// [ForgePrClientResolver]: the caching, drafts, diff sources and event
/// plumbing above the client are identical, so the only thing that varies is
/// which vendor API the client speaks. That is the whole point of the
/// abstraction — adding a forge means adding an adapter, not a repository.
///
/// The context's workspace id resolves the database file once, at creation, so
/// each repository instance is pinned to the workspace it was asked for. Thin
/// clients reach this over RPC via `RpcForgeProviderFactory` and never hold a
/// token themselves.
class ForgeRepositoryFactory implements ForgeProviderFactory {
  /// Creates a [ForgeRepositoryFactory] for [forge].
  ForgeRepositoryFactory({
    required this.forge,
    required WorkspaceDatabaseManager workspaceDbs,
    required this._clientFor,
    required this._localGitSource,
    required this._buildApiDiffSource,
    this._eventBus,
    this._changeSignals,
    this._blobStore,
  }) : _dbs = workspaceDbs;

  @override
  final ForgeHost forge;

  final WorkspaceDatabaseManager _dbs;
  final ForgePrClientResolver _clientFor;
  final PrDiffSource _localGitSource;
  final PrDiffSource Function(ForgePrClient client) _buildApiDiffSource;
  final DomainEventBus? _eventBus;
  final PrChangeSignals? _changeSignals;
  final BlobStore? _blobStore;

  /// Throws [StateError] for a repo not linked to the workspace without a
  /// member to key its cache rows by: those rows are never shared.
  @override
  PrReviewRepository create(ForgeProviderContext ctx) {
    final userId = ctx.userId;
    if (!ctx.linkedToWorkspace && (userId == null || userId.isEmpty)) {
      throw StateError(
        'A PR repository for a repo not linked to the workspace needs the '
        'member it acts for: its cache rows are that member\'s alone.',
      );
    }
    final client = _clientFor(
      ctx.repo,
      workspaceId: ctx.workspaceId,
      actingUserId: userId,
    );
    return CachedPrReviewRepository(
      db: _dbs.of(ctx.workspaceId),
      cacheMemberId: ctx.linkedToWorkspace ? null : userId,
      forgeClient: client,
      owner: ctx.repo.remoteOwner,
      repo: ctx.repo.remoteName,
      apiDiffSource: _buildApiDiffSource(client),
      localDiffSource: _localGitSource,
      localCheckoutPath: ctx.repo.path,
      eventBus: _eventBus,
      changeSignals: _changeSignals,
      blobStore: _blobStore,
    );
  }
}

/// Builds the registry of every forge the server can serve.
///
/// **Every supported forge is registered, connected or not.** Routing is a
/// static property of the repo, so making registry membership depend on a
/// credential would freeze it at boot: an operator who pastes a GitLab token
/// into Settings would keep getting the empty repository until the process
/// restarted, which is exactly the "no restart" promise the per-call credential
/// lookup exists to keep.
///
/// An unconnected forge therefore fails at the request, not at resolution — and
/// only for repos that actually live on it, so a workspace with no GitLab repos
/// never calls GitLab at all. The per-forge failure isolation upstream turns
/// that failure into "this forge contributed nothing" rather than an empty
/// inbox.
ForgeProviderRegistry buildForgeProviderRegistry({
  required WorkspaceDatabaseManager workspaceDbs,
  required ForgeHttpClientFactory httpClientFactory,
  required RhttpClient githubHttp,
  required PrDiffSource localGitSource,
  required ForgeApprovalGuardResolver approvalGuard,
  DomainEventBus? eventBus,
  PrChangeSignals? changeSignals,
  BlobStore? blobStore,
}) {
  final factories = <ForgeProviderFactory>[];

  for (final forge in ForgeHost.supported) {
    final httpClient = forge == ForgeHost.github
        ? githubHttp
        : httpClientFactory.of(forge);
    factories.add(
      ForgeRepositoryFactory(
        forge: forge,
        workspaceDbs: workspaceDbs,
        // The registry is per actor: [httpClient] already carries whose
        // credential every call rides.
        clientFor: forgePrClientBuilder(
          forge,
          httpClient,
          approvalGuard: approvalGuard,
        ),
        localGitSource: localGitSource,
        buildApiDiffSource: (client) =>
            forgeApiDiffSource(forge, httpClient, client),
        eventBus: eventBus,
        changeSignals: changeSignals,
        blobStore: blobStore,
      ),
    );
  }

  return ForgeProviderRegistry(factories);
}

/// The client resolver for [forge] over [httpClient], whose transport already
/// carries the credential (so the workspace and actor only choose the repo).
///
/// Every client it builds passes its approvals through [approvalGuard] for
/// the same repo, workspace and actor: this is where every server forge
/// client that can approve is made.
ForgePrClientResolver forgePrClientBuilder(
  ForgeHost forge,
  RhttpClient httpClient, {
  required ForgeApprovalGuardResolver approvalGuard,
}) => switch (forge) {
  ForgeHost.github =>
    (repo, {required workspaceId, actingUserId}) => GitHubForgePrClient(
      client: GitHubApiClient(httpClient),
      owner: repo.remoteOwner,
      repo: repo.remoteName,
      approvalGuard: approvalGuard(
        repo,
        workspaceId: workspaceId,
        actingUserId: actingUserId,
      ),
    ),
  ForgeHost.gitlab =>
    (repo, {required workspaceId, actingUserId}) => GitLabForgePrClient(
      client: GitLabApiClient(httpClient),
      owner: repo.remoteOwner,
      repo: repo.remoteName,
      approvalGuard: approvalGuard(
        repo,
        workspaceId: workspaceId,
        actingUserId: actingUserId,
      ),
    ),
  ForgeHost.bitbucket =>
    (repo, {required workspaceId, actingUserId}) => BitbucketForgePrClient(
      client: BitbucketApiClient(httpClient),
      owner: repo.remoteOwner,
      repo: repo.remoteName,
      approvalGuard: approvalGuard(
        repo,
        workspaceId: workspaceId,
        actingUserId: actingUserId,
      ),
    ),
  ForgeHost.local => throw ArgumentError.value(
    forge,
    'forge',
    'A local repo has no forge API client',
  ),
};

/// The API-backed diff source for [forge] over [httpClient], for the
/// repository [client] is pinned to.
///
/// Only GitHub ships a dedicated API diff source today; the others serve their
/// diff through the client and reuse the generic path.
PrDiffSource forgeApiDiffSource(
  ForgeHost forge,
  RhttpClient httpClient,
  ForgePrClient client,
) => switch (forge) {
  ForgeHost.github => GitHubApiPrDiffSource(GitHubApiClient(httpClient)),
  _ => ForgeClientPrDiffSource(client),
};
