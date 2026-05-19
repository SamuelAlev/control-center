import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';

/// Load pull request details use case.
class LoadPullRequestDetailsUseCase {
  /// LoadPullRequestDetailsUseCase({required.
  const LoadPullRequestDetailsUseCase({required PrReviewRepository repository})
    : _repository = repository;

  final PrReviewRepository _repository;

  /// Execute.
  Stream<PullRequest?> execute(int prNumber) {
    return _repository.watchPullRequest(prNumber);
  }
}
