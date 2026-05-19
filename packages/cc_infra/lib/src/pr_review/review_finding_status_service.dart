// The one place a review finding's status changes.
//
// Before this existed there were two half-paths and a hole. An unregistered
// MCP tool could dismiss a finding with a reason and record a suppression
// fact — but it was never wired, so nothing could reach it. A chat bubble
// could dismiss by writing `status` into the raw metadata map, which skipped
// the reason, the system message and the suppression fact, and bypassed the
// typed payload entirely. And nothing anywhere could mark a finding RESOLVED,
// which meant the enum member, the UI that renders it and the `actionRate`
// metric computed from it were all wired to a value no code ever wrote.
//
// Routing every change through one service is what makes a status mean
// something: it is written through the typed payload rather than pasted into
// a map, it always leaves a trace in the room, and a dismissal always feeds
// the suppression memory that stops the same finding coming back.

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/pr_review/domain/ports/review_finding_status_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:uuid/uuid.dart';

/// Moves a review finding between [ReviewNodeStatus] values.
class ReviewFindingStatusService implements ReviewFindingStatusPort {
  /// Creates a [ReviewFindingStatusService].
  ///
  /// Every collaborator but [messaging] is optional, and each one lost costs
  /// something specific rather than the operation: without [reviewSpaces] and
  /// [runSnapshots] the decision never reaches the finalized pass's counters,
  /// and without [memoryFacts] + [resolveDomain] a dismissal still lands, it
  /// just teaches nothing.
  ReviewFindingStatusService({
    required MessagingRepository messaging,
    ReviewSpaceRepository? reviewSpaces,
    ReviewRunSnapshotRepository? runSnapshots,
    MemoryFactRepository? memoryFacts,
    ResolveOrCreateDomainUseCase? resolveDomain,
  }) : _messaging = messaging,
       _reviewSpaces = reviewSpaces,
       _runSnapshots = runSnapshots,
       _memoryFacts = memoryFacts,
       _resolveDomain = resolveDomain;

  final MessagingRepository _messaging;
  final ReviewSpaceRepository? _reviewSpaces;
  final ReviewRunSnapshotRepository? _runSnapshots;
  final MemoryFactRepository? _memoryFacts;
  final ResolveOrCreateDomainUseCase? _resolveDomain;

  /// Memory domain collecting dismissed-finding patterns. Reviewers consult it
  /// through `search_memory`, and the finalizer's suppression matcher reads
  /// the same dismissals back mechanically.
  static const String suppressionDomain = 'review-suppressions';

  /// Sets [nodeMessageId]'s status to [status].
  ///
  /// [actorLabel] is who did it, as it should read in the room — a person's
  /// name or an agent id. [reason] is required by convention for a dismissal
  /// (it is what the suppression fact is made of) and optional otherwise.
  @override
  Future<ReviewFindingStatusChange> setStatus({
    required String workspaceId,
    required String spaceId,
    required String nodeMessageId,
    required ReviewNodeStatus status,
    required String actorLabel,
    String? reason,
  }) async {
    // Space-wide: the finding lives in whichever reviewer's stream filed it,
    // not in the room's standing conversation.
    final messages = await _messaging.getSpaceMessages(workspaceId, spaceId);
    Message? target;
    for (final m in messages) {
      if (m.id == nodeMessageId && m.messageType == MessageType.reviewNode) {
        target = m;
        break;
      }
    }
    if (target == null) {
      throw ReviewFindingNotFound(nodeMessageId);
    }

    final payload = ReviewNodePayload.fromMetadata(target.metadata);
    final previous = payload?.status ?? ReviewNodeStatus.open;

    // Written through the typed payload, not by pasting a key into the raw
    // map: a blind merge is how a metadata write ends up carrying a status the
    // parser cannot read back.
    final next = payload != null
        ? payload.copyWith(status: status).toMetadata()
        : <String, dynamic>{...?target.metadata, 'status': status.wireName};

    await _messaging.updateMessage(workspaceId, nodeMessageId, metadata: next);

    if (previous != status) {
      await _messaging.sendMessage(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: target.conversationId,
        content: _trace(status, actorLabel, reason),
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
      );
    }

    final association = await _association(workspaceId, spaceId);

    // The decision has to reach the finalized pass, not just the bubble. A
    // pass freezes its findings' statuses at finalize time, and a person marks
    // a finding fixed AFTER reading the review — the only order this ever
    // happens in. Skip it and `actionRate` stays structurally zero and the
    // suppression memory never sees a dismissal, which is precisely the state
    // this whole surface exists to leave behind.
    if (association != null) {
      await _applyToRunSnapshots(
        workspaceId: workspaceId,
        prExternalId: association.prExternalId,
        nodeMessageId: nodeMessageId,
        status: status,
      );
    }

    final suppressionRecorded =
        status == ReviewNodeStatus.dismissed && association != null
        ? await _recordSuppression(
            workspaceId: workspaceId,
            node: target,
            reason: reason ?? '',
            actorLabel: actorLabel,
          )
        : false;

    return ReviewFindingStatusChange(
      nodeMessageId: nodeMessageId,
      status: status,
      previousStatus: previous,
      suppressionRecorded: suppressionRecorded,
    );
  }

  /// The line left in the room. A status change with no trace is one nobody
  /// can account for later.
  String _trace(ReviewNodeStatus status, String actor, String? reason) {
    final because = reason == null || reason.trim().isEmpty
        ? ''
        : ': ${reason.trim()}';
    return switch (status) {
      ReviewNodeStatus.resolved => '✅ $actor marked this finding fixed$because',
      ReviewNodeStatus.dismissed => '❌ $actor dismissed this finding$because',
      ReviewNodeStatus.open => '↩︎ $actor reopened this finding$because',
      ReviewNodeStatus.consensusReady =>
        '👥 $actor confirmed this finding$because',
    };
  }

  /// The review this space is attached to, or null when it is not one.
  ///
  /// Best-effort: a lookup that fails must not cost the caller their status
  /// change, which has already landed by the time this is asked.
  Future<ReviewSpaceAssociation?> _association(
    String workspaceId,
    String spaceId,
  ) async {
    final reviewSpaces = _reviewSpaces;
    if (reviewSpaces == null) {
      return null;
    }
    try {
      return await reviewSpaces.watchBySpace(workspaceId, spaceId).first;
    } on Object catch (e, st) {
      CcInfraLog.error('review finding status: space lookup failed', e, st);
      return null;
    }
  }

  /// Writes the decision back onto every finalized pass that reported it.
  Future<void> _applyToRunSnapshots({
    required String workspaceId,
    required String prExternalId,
    required String nodeMessageId,
    required ReviewNodeStatus status,
  }) async {
    final runSnapshots = _runSnapshots;
    if (runSnapshots == null) {
      return;
    }
    try {
      await runSnapshots.applyFindingStatus(
        workspaceId,
        prExternalId,
        nodeMessageId,
        status,
      );
    } on Object catch (e, st) {
      // Bookkeeping. Losing the counter update is bad; losing the status
      // change because the counter update failed is worse.
      CcInfraLog.error(
        'review finding status: failed to update the run snapshot',
        e,
        st,
      );
    }
  }

  /// Records the dismissal so reviewers stop re-flagging the pattern.
  ///
  /// Best-effort by design: losing the lesson is bad, losing the dismissal
  /// because the lesson failed to save is worse.
  Future<bool> _recordSuppression({
    required String workspaceId,
    required Message node,
    required String reason,
    required String actorLabel,
  }) async {
    final memoryFacts = _memoryFacts;
    final resolveDomain = _resolveDomain;
    if (memoryFacts == null || resolveDomain == null) {
      return false;
    }
    try {
      final meta = node.metadata ?? const {};
      final filePath = meta['filePath'] is String
          ? meta['filePath'] as String
          : null;
      final summary = node.content.trim().split('\n').first;
      final topic = filePath != null
          ? 'Dismissed finding in $filePath'
          : 'Dismissed finding: ${_truncate(summary, 48)}';
      final buf = StringBuffer()
        ..writeln(
          'A reviewer dismissed a finding — do not re-flag this pattern '
          'on future PRs.',
        )
        ..writeln()
        ..writeln('**Finding:** ${_truncate(summary, 280)}');
      if (filePath != null) {
        buf.writeln('**File:** `$filePath`');
      }
      buf.writeln(
        reason.trim().isEmpty
            ? '**Dismissed by:** $actorLabel'
            : '**Dismissal reason:** ${reason.trim()}',
      );
      final body = buf.toString().trim();

      final domain = await resolveDomain.execute(
        workspaceId: workspaceId,
        domainInput: suppressionDomain,
        domainLabel: 'Review suppressions',
        domainDescription:
            'Findings the team dismissed during review. Reviewers should '
            'consult these and avoid re-flagging the same patterns.',
        authorRole: AgentRole.reviewer,
      );

      // Light dedup: an identical suppression for this topic teaches nothing
      // new and would double-count in any similarity threshold.
      final existing = await memoryFacts.getActiveByTopic(workspaceId, topic);
      if (existing.any(
        (f) => f.domain == domain.name && f.content.trim() == body,
      )) {
        return true;
      }

      final now = DateTime.now();
      await memoryFacts.upsert(
        MemoryFact(
          id: const Uuid().v4(),
          workspaceId: workspaceId,
          domain: domain.name,
          topic: topic,
          content: body,
          // Soft: one dismissal is a preference, not a rule. Repetition is
          // what the matcher's minimum-match count reads.
          confidence: 0.7,
          authoredByAgentId: actorLabel,
          authoredByRole: AgentRole.reviewer,
          createdAt: now,
          updatedAt: now,
        ),
      );
      return true;
    } on Object catch (e, st) {
      CcInfraLog.error(
        'review finding status: failed to record suppression fact',
        e,
        st,
      );
      return false;
    }
  }

  static String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max).trimRight()}…';
}
