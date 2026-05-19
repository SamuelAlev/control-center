import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';

/// Append-only orchestration revision history (PRD 17 §5).
abstract class OrchestrationRevisionRepository {
  /// Records one revision snapshot. Idempotent per
  /// (orchestrationId, revision) — recording the same revision twice keeps
  /// the first row.
  Future<void> record(OrchestrationRevision revision);

  /// Every revision of [orchestrationId], oldest first.
  Future<List<OrchestrationRevision>> forOrchestration(
    String workspaceId,
    String orchestrationId,
  );

  /// One revision snapshot, or null.
  Future<OrchestrationRevision?> byRevision(
    String workspaceId,
    String orchestrationId,
    int revision,
  );

  /// Live revision list, oldest first.
  Stream<List<OrchestrationRevision>> watchForOrchestration(
    String workspaceId,
    String orchestrationId,
  );
}

/// Single-agent plan-mode documents (PRD 17 §8).
abstract class PlanDocumentRepository {
  /// Inserts or replaces [doc] (keyed by id).
  Future<void> upsert(PlanDocument doc);

  /// One document, or null.
  Future<PlanDocument?> getById(String workspaceId, String id);

  /// The newest document authored in [conversationId], or null.
  Future<PlanDocument?> latestForConversation(
    String workspaceId,
    String conversationId,
  );

  /// Live documents for a workspace, newest first.
  Stream<List<PlanDocument>> watchForWorkspace(String workspaceId);

  /// Live single document.
  Stream<PlanDocument?> watchById(String workspaceId, String id);

  /// Deletes a document.
  Future<void> deleteById(String workspaceId, String id);
}

/// Parameterized, versioned playbooks (PRD 17 §10).
abstract class PlaybookRepository {
  /// Inserts or replaces [playbook] (keyed by id; name unique per workspace).
  Future<void> upsert(Playbook playbook);

  /// One playbook by id, or null.
  Future<Playbook?> getById(String workspaceId, String id);

  /// One playbook by display name, or null.
  Future<Playbook?> getByName(String workspaceId, String name);

  /// All playbooks in a workspace, by name.
  Future<List<Playbook>> forWorkspace(String workspaceId);

  /// Live playbook list, by name.
  Stream<List<Playbook>> watchForWorkspace(String workspaceId);

  /// Deletes a playbook.
  Future<void> deleteById(String workspaceId, String id);
}
