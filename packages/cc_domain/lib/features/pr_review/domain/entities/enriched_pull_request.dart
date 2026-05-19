import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// Sealed supertype for categorized pull requests with their source [Repo].
sealed class EnrichedPullRequest {
  const EnrichedPullRequest({required this.pr, required this.repo});

  /// pr.
  final PullRequest pr;

  /// repo.
  final Repo repo;

  /// Repo full name.
  String get repoFullName => repo.fullName;

  /// Repo owner.
  String get repoOwner => repo.githubOwner;

  /// Repo name.
  String get repoName => repo.githubRepoName;
}

/// Priority review.
class PriorityReview extends EnrichedPullRequest {
  /// PriorityReview.
  const PriorityReview({required super.pr, required super.repo});

  /// Age.
  Duration get age =>
      DateTime.now().difference(pr.updatedAt ?? pr.createdAt ?? DateTime.now());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityReview &&
          runtimeType == other.runtimeType &&
          pr.id == other.pr.id;

  @override
  int get hashCode => pr.id.hashCode;
}

/// Stale pr.
class StalePr extends EnrichedPullRequest {
  /// StalePr.
  const StalePr({required super.pr, required super.repo});

  /// Staleness age.
  Duration get stalenessAge =>
      DateTime.now().difference(pr.updatedAt ?? pr.createdAt ?? DateTime.now());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StalePr &&
          runtimeType == other.runtimeType &&
          pr.id == other.pr.id;

  @override
  int get hashCode => pr.id.hashCode;
}

/// Normal pr.
class NormalPr extends EnrichedPullRequest {
  /// NormalPr.
  const NormalPr({required super.pr, required super.repo});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NormalPr &&
          runtimeType == other.runtimeType &&
          pr.id == other.pr.id;

  @override
  int get hashCode => pr.id.hashCode;
}

/// Repo pull requests.
class RepoPullRequests {
  /// RepoPullRequests.
  const RepoPullRequests({required this.repo, required this.prs});

  /// repo.
  final Repo repo;

  /// prs.
  final List<PullRequest> prs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoPullRequests &&
          runtimeType == other.runtimeType &&
          repo == other.repo;

  @override
  int get hashCode => repo.hashCode;
}
