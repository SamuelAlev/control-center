import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';

/// Invalidate pr cache use case.
class InvalidatePrCacheUseCase {
  /// InvalidatePrCacheUseCase({required.
  const InvalidatePrCacheUseCase({required PrReviewRepository repository})
    : _repository = repository;

  final PrReviewRepository _repository;

  /// Execute.
  Future<void> execute(int prNumber) {
    return _repository.invalidatePullRequest(prNumber);
  }
}
