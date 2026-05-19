import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';

/// Mark file viewed use case.
class MarkFileViewedUseCase {
  /// Creates a new [Mark file viewed use case].
  MarkFileViewedUseCase({required PrReviewRepository repository})
    : _repository = repository;

  final PrReviewRepository _repository;

  /// Execute.
  Future<void> execute({
    required int prNumber,
    required String externalId,
    required String path,
    required bool viewed,
  }) {
    return _repository.markFileAsViewed(
      prNumber: prNumber,
      externalId: externalId,
      path: path,
      viewed: viewed,
    );
  }
}
