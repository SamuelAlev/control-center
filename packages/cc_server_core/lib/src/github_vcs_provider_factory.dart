import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/services/pr_change_signals.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_server_core/src/cached_pr_review_repository.dart';

/// Server-side [VcsProviderFactory] for GitHub repositories.
///
/// Builds a [CachedPrReviewRepository] — the stateful, SWR-disk-cached
/// repository that owns GitHub auth, the diff sources, and draft persistence —
/// for a given `(workspace, owner, repo)`. This is the HOST side of the
/// PR-review RPC vertical: the desktop's in-process catalog (and any future
/// headless server with a token) wires this with the per-workspace databases +
/// the GitHub client. Thin clients reach it over RPC via `RpcVcsProviderFactory`,
/// never holding a token themselves.
///
/// The context's workspace id resolves the database file once, at creation, so
/// each repository instance is pinned to the workspace it was asked for.
///
/// Moved out of the Flutter app (`lib/`) so that feature cluster no longer
/// constructs cc_persistence-backed repositories directly — the UI now resolves
/// PR-review repositories over the RPC client.
class GitHubVcsProviderFactory implements VcsProviderFactory {
  /// Creates a [GitHubVcsProviderFactory] with the required dependencies.
  GitHubVcsProviderFactory({
    required WorkspaceDatabaseManager workspaceDbs,
    required GitHubApiClient gitHubClient,
    required LocalGitPrDiffSource localGitSource,
    DomainEventBus? eventBus,
    PrChangeSignals? changeSignals,
  }) : _dbs = workspaceDbs,
       _gitHubClient = gitHubClient,
       _localGitSource = localGitSource,
       _eventBus = eventBus,
       _changeSignals = changeSignals;

  final WorkspaceDatabaseManager _dbs;
  final GitHubApiClient _gitHubClient;
  final LocalGitPrDiffSource _localGitSource;
  final DomainEventBus? _eventBus;
  final PrChangeSignals? _changeSignals;

  /// The [VcsHost] this factory serves.
  @override
  VcsHost get host => VcsHost.github;

  /// Creates a [CachedPrReviewRepository] for the given [VcsProviderContext].
  @override
  PrReviewRepository create(VcsProviderContext ctx) {
    return CachedPrReviewRepository(
      db: _dbs.of(ctx.workspaceId),
      gitHubClient: _gitHubClient,
      owner: ctx.repo.githubOwner,
      repo: ctx.repo.githubRepoName,
      apiDiffSource: GitHubApiPrDiffSource(_gitHubClient),
      localDiffSource: _localGitSource,
      localCheckoutPath: ctx.repo.path,
      eventBus: _eventBus,
      changeSignals: _changeSignals,
    );
  }
}
