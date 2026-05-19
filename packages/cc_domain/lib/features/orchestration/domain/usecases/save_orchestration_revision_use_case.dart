import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/orchestration_events.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:uuid/uuid.dart';

/// Thrown when an edit was based on a stale revision (PRD 17 adversarial
/// review: "two editors, one plan" — optimistic concurrency, never a silent
/// clobber).
class StaleRevisionException implements Exception {
  /// Creates the exception.
  StaleRevisionException(this.baseRevision, this.currentRevision);

  /// The revision the edit was based on.
  final int baseRevision;

  /// The revision the orchestration is actually at.
  final int currentRevision;

  @override
  String toString() =>
      'The plan moved on: your edit was based on revision $baseRevision but '
      'the plan is at revision $currentRevision. Reload and re-apply.';
}

/// Saves an edited proposal as a new revision (PRD 17 §2/§5): validates,
/// bumps the monotonic revision, snapshots the append-only history row and
/// publishes [OrchestrationRevised]. Rewind is the same operation with a
/// prior revision's proposal as the input — history only ever grows.
class SaveOrchestrationRevisionUseCase {
  /// Creates the use case.
  SaveOrchestrationRevisionUseCase({
    required OrchestrationRepository orchestrations,
    required OrchestrationRevisionRepository revisions,
    required OrchestrationProposalValidator validator,
    required DomainEventBus eventBus,
  }) : _orchestrations = orchestrations,
       _revisions = revisions,
       _validator = validator,
       _eventBus = eventBus;

  final OrchestrationRepository _orchestrations;
  final OrchestrationRevisionRepository _revisions;
  final OrchestrationProposalValidator _validator;
  final DomainEventBus _eventBus;

  static const _uuid = Uuid();

  /// Saves [proposal] as the next revision of [orchestrationId].
  ///
  /// [baseRevision] is the revision the editor loaded; a mismatch with the
  /// live row throws [StaleRevisionException]. Invalid proposals throw
  /// [ArgumentError] with the validator's violations verbatim — an invalid
  /// edit is blocked, never silently accepted.
  Future<Orchestration> save({
    required String workspaceId,
    required String orchestrationId,
    required OrchestrationProposal proposal,
    required int baseRevision,
    required String authoredBy,
    String authorKind = 'user',
  }) async {
    final o = await _orchestrations.getById(workspaceId, orchestrationId);
    if (o == null) {
      throw StateError('Orchestration $orchestrationId not found');
    }
    if (o.status != OrchestrationStatus.proposed) {
      throw StateError(
        'Only a proposed orchestration can be edited (status: '
        '${o.status.name}). An executing plan changes via replan, which the '
        'diff gate reviews.',
      );
    }
    if (o.revision != baseRevision) {
      throw StaleRevisionException(baseRevision, o.revision);
    }
    final violations = _validator.validate(proposal);
    if (violations.isNotEmpty) {
      throw ArgumentError(violations.join('\n'));
    }

    // Backfill the baseline snapshot so the timeline always starts at the
    // revision the orchestrator originally proposed (record() is idempotent
    // per (orchestrationId, revision)).
    await _revisions.record(
      OrchestrationRevision(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        orchestrationId: orchestrationId,
        revision: o.revision,
        proposal: o.proposal,
        authoredBy: o.orchestratorAgentId ?? 'unknown',
        authorKind: 'agent',
        createdAt: o.updatedAt,
      ),
    );

    final newRevision = o.revision + 1;
    final updated = o.copyWith(
      proposal: proposal,
      revision: newRevision,
      updatedAt: DateTime.now(),
    );
    await _orchestrations.update(updated);
    await _revisions.record(
      OrchestrationRevision(
        id: _uuid.v4(),
        workspaceId: workspaceId,
        orchestrationId: orchestrationId,
        revision: newRevision,
        proposal: proposal,
        authoredBy: authoredBy,
        authorKind: authorKind,
        createdAt: DateTime.now(),
      ),
    );
    _eventBus.publish(
      OrchestrationRevised(
        orchestrationId: orchestrationId,
        workspaceId: workspaceId,
        revision: newRevision,
        occurredAt: DateTime.now(),
      ),
    );
    return updated;
  }
}
