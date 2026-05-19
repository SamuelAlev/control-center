import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';

/// Repository for the compose-PR draft → publish lifecycle.
///
/// PR generations are workspace-scoped, so every lookup names its workspace: a
/// generation id resolves only inside the workspace that owns it.
abstract class PrLifecycleRepository {
  /// Stream of PR generations for a workspace.
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId);

  /// The generation [id] within [workspaceId], or `null`.
  Future<PrGeneration?> getById(String workspaceId, String id);

  /// Create draft.
  Future<String> createDraft({
    required String workspaceId,
    required String title,
    required String body,
    String? diffSummary,
  });

  /// Updates the draft [prId] in [workspaceId].
  Future<void> updateDraft(
    String workspaceId,
    String prId, {
    String? title,
    String? body,
    String? status,
    int? prNumber,
    String? prUrl,
  });

  /// Publish a draft PR to GitHub. When [draft] is true the PR is opened as a
  /// GitHub draft. [assignees] (logins), [reviewerUsers] (logins) and
  /// [reviewerTeams] (slugs) are applied to the new PR after creation.
  Future<Map<String, dynamic>> publishToForge({
    required String workspaceId,
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

  /// Deletes the generation [id] from [workspaceId].
  Future<void> delete(String workspaceId, String id);
}
