import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';

/// Pr lifecycle repository.
abstract class PrLifecycleRepository {
  /// Stream of PR generations for a workspace.
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId);

  /// Get by id.
  Future<PrGeneration?> getById(String id);

  /// Create draft.
  Future<String> createDraft({
    required String workspaceId,
    required String title,
    required String body,
    String? diffSummary,
  });

  /// Update draft.
  Future<void> updateDraft(
    String prId, {
    String? title,
    String? body,
    String? status,
    int? githubPrNumber,
    String? githubPrUrl,
  });

  /// Publish a draft PR to GitHub. When [draft] is true the PR is opened as a
  /// GitHub draft. [assignees] (logins), [reviewerUsers] (logins) and
  /// [reviewerTeams] (slugs) are applied to the new PR after creation.
  Future<Map<String, dynamic>> createOnGitHub({
    required String prId,
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
    List<String> assignees = const [],
    List<String> reviewerUsers = const [],
    List<String> reviewerTeams = const [],
  });

  /// Delete.
  Future<void> delete(String id);
}
