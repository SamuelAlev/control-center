import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';

/// Repository for board approvals and their comment history. Every method is
/// workspace-scoped — `workspaceId` is required and never optional.
abstract interface class ApprovalRepository {
  /// Watches all approvals for [workspaceId].
  Stream<List<Approval>> watchByWorkspace(String workspaceId);

  /// Watches approvals for [workspaceId] in a given [status] storage key.
  Stream<List<Approval>> watchByStatus(String workspaceId, String status);

  /// Returns a single approval by [id] within [workspaceId], or null.
  Future<Approval?> getById(String workspaceId, String id);

  /// Inserts or updates an approval.
  Future<void> upsert(Approval approval);

  /// Deletes an approval by [id] within [workspaceId].
  Future<void> delete(String workspaceId, String id);

  /// Watches the comment thread for [approvalId] within [workspaceId].
  Stream<List<ApprovalComment>> watchComments(
    String workspaceId,
    String approvalId,
  );

  /// Returns the comment thread for [approvalId] within [workspaceId].
  Future<List<ApprovalComment>> getComments(
    String workspaceId,
    String approvalId,
  );

  /// Adds a comment to an approval.
  Future<void> addComment(ApprovalComment comment);
}
