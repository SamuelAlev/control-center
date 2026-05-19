import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_infra/src/git/github_api_pr_diff_source.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:cc_infra/src/pr_review/local_git_pr_diff_source.dart';
import 'package:cc_persistence/database/daos/cache_dao.dart';
import 'package:cc_persistence/database/daos/review_dao.dart';
import 'package:cc_server_core/src/cached_pr_review_repository.dart';

/// Server-side [VcsProviderFactory] for GitHub repositories.
///
/// Builds a [CachedPrReviewRepository] — the stateful, SWR-disk-cached
/// repository that owns GitHub auth, the diff sources, and draft persistence —
/// for a given `(workspace, owner, repo)`. This is the HOST side of the
/// PR-review RPC vertical: the desktop's in-process catalog (and any future
/// headless server with a token) wires this with the cache/review DAOs + the
/// GitHub client. Thin clients reach it over RPC via `RpcVcsProviderFactory`,
/// never holding a token themselves.
///
/// Moved out of the Flutter app (`lib/`) so that feature cluster no longer
/// constructs cc_persistence-backed repositories directly — the UI now resolves
/// PR-review repositories over the RPC client.
class GitHubVcsProviderFactory implements VcsProviderFactory {
  /// Creates a [GitHubVcsProviderFactory] with the required dependencies.
  GitHubVcsProviderFactory({
    required CacheDao cacheDao,
    required ReviewDao draftDao,
    required GitHubApiClient gitHubClient,
    required LocalGitPrDiffSource localGitSource,
    DomainEventBus? eventBus,
  }) : _cacheDao = cacheDao,
       _draftDao = draftDao,
       _gitHubClient = gitHubClient,
       _localGitSource = localGitSource,
       _eventBus = eventBus;

  final CacheDao _cacheDao;
  final ReviewDao _draftDao;
  final GitHubApiClient _gitHubClient;
  final LocalGitPrDiffSource _localGitSource;
  final DomainEventBus? _eventBus;

  /// The [VcsHost] this factory serves.
  @override
  VcsHost get host => VcsHost.github;

  /// Creates a [CachedPrReviewRepository] for the given [VcsProviderContext].
  @override
  PrReviewRepository create(VcsProviderContext ctx) {
    return CachedPrReviewRepository(
      cacheDao: _cacheDao,
      draftDao: _draftDao,
      gitHubClient: _gitHubClient,
      workspaceId: ctx.workspaceId,
      owner: ctx.repo.githubOwner,
      repo: ctx.repo.githubRepoName,
      apiDiffSource: GitHubApiPrDiffSource(_gitHubClient),
      localDiffSource: _localGitSource,
      localCheckoutPath: ctx.repo.path,
      eventBus: _eventBus,
    );
  }
}
