import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/database/daos/review_dao.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/features/pr_review/data/repositories/cached_pr_review_repository.dart';
import 'package:control_center/features/pr_review/data/sources/github_api_pr_diff_source.dart';
import 'package:control_center/features/pr_review/data/sources/local_git_pr_diff_source.dart';
import 'package:control_center/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';

/// [VcsProviderFactory] for GitHub repositories.
class GitHubVcsProviderFactory implements VcsProviderFactory {
  const GitHubVcsProviderFactory({
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

  @override
  VcsHost get host => VcsHost.github;

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
