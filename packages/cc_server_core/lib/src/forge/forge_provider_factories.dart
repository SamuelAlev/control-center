import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/cached_pr_review_repository.dart';
import 'package:cc_server_core/src/pr_review/forge_client_pr_diff_source.dart';
import 'package:dio/dio.dart';

/// Builds the [ForgePrClient] for one repository on one forge.
typedef ForgePrClientBuilder =
    ForgePrClient Function({required String owner, required String repo});

/// Server-side [ForgeProviderFactory] for any forge.
///
/// Every forge's factory is this same class with a different
/// [ForgePrClientBuilder]: the caching, drafts, diff sources and event
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
    required ForgePrClientBuilder buildClient,
    required PrDiffSource localGitSource,
    required PrDiffSource Function() buildApiDiffSource,
    DomainEventBus? eventBus,
    PrChangeSignals? changeSignals,
  }) : _dbs = workspaceDbs,
       _buildClient = buildClient,
       _localGitSource = localGitSource,
       _buildApiDiffSource = buildApiDiffSource,
       _eventBus = eventBus,
       _changeSignals = changeSignals;

  @override
  final ForgeHost forge;

  final WorkspaceDatabaseManager _dbs;
  final ForgePrClientBuilder _buildClient;
  final PrDiffSource _localGitSource;
  final PrDiffSource Function() _buildApiDiffSource;
  final DomainEventBus? _eventBus;
  final PrChangeSignals? _changeSignals;

  @override
  PrReviewRepository create(ForgeProviderContext ctx) {
    return CachedPrReviewRepository(
      db: _dbs.of(ctx.workspaceId),
      forgeClient: _buildClient(
        owner: ctx.repo.remoteOwner,
        repo: ctx.repo.remoteName,
      ),
      owner: ctx.repo.remoteOwner,
      repo: ctx.repo.remoteName,
      apiDiffSource: _buildApiDiffSource(),
      localDiffSource: _localGitSource,
      localCheckoutPath: ctx.repo.path,
      eventBus: _eventBus,
      changeSignals: _changeSignals,
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
  required ForgeDioFactory dioFactory,
  required PrDiffSource localGitSource,
  DomainEventBus? eventBus,
  PrChangeSignals? changeSignals,
}) {
  final factories = <ForgeProviderFactory>[];

  for (final forge in ForgeHost.supported) {
    final dio = dioFactory.of(forge);
    factories.add(
      ForgeRepositoryFactory(
        forge: forge,
        workspaceDbs: workspaceDbs,
        buildClient: forgePrClientBuilder(forge, dio),
        localGitSource: localGitSource,
        buildApiDiffSource: () => forgeApiDiffSource(forge, dio),
        eventBus: eventBus,
        changeSignals: changeSignals,
      ),
    );
  }

  return ForgeProviderRegistry(factories);
}

/// The client builder for [forge] over [dio].
ForgePrClientBuilder forgePrClientBuilder(
  ForgeHost forge,
  Dio dio,
) => switch (forge) {
  ForgeHost.github => ({required owner, required repo}) => GitHubForgePrClient(
    client: GitHubApiClient(dio),
    owner: owner,
    repo: repo,
  ),
  ForgeHost.gitlab => ({required owner, required repo}) => GitLabForgePrClient(
    client: GitLabApiClient(dio),
    owner: owner,
    repo: repo,
  ),
  ForgeHost.bitbucket =>
    ({required owner, required repo}) => BitbucketForgePrClient(
      client: BitbucketApiClient(dio),
      owner: owner,
      repo: repo,
    ),
  ForgeHost.local => throw ArgumentError.value(
    forge,
    'forge',
    'A local repo has no forge API client',
  ),
};

/// The API-backed diff source for [forge] over [dio].
///
/// Only GitHub ships a dedicated API diff source today; the others serve their
/// diff through the client and reuse the generic path.
PrDiffSource forgeApiDiffSource(ForgeHost forge, Dio dio) => switch (forge) {
  ForgeHost.github => GitHubApiPrDiffSource(GitHubApiClient(dio)),
  _ => ForgeClientPrDiffSource(forgePrClientBuilder(forge, dio)),
};
