import 'package:control_center/features/pr_review/domain/entities/pr_generation.dart';

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

  /// Publish a draft PR to GitHub.
  Future<Map<String, dynamic>> createOnGitHub({
    required String prId,
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
  });

  /// Delete.
  Future<void> delete(String id);
}

