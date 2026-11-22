import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/json_safe.dart';

/// What shows the problem and the fix an improvement proposal names: the
/// runs, the messages and the check results (`improvement_proposals
/// .evidence`, a JSON object with these keys).
class ImprovementEvidence {
  /// Creates evidence. Throws [ArgumentError] past the limits.
  ImprovementEvidence({
    List<String> runIds = const [],
    List<String> messageIds = const [],
    List<GoalCheckResult> checkResults = const [],
  }) : runIds = List.unmodifiable(runIds),
       messageIds = List.unmodifiable(messageIds),
       checkResults = List.unmodifiable(checkResults) {
    if (runIds.length > maxIds || messageIds.length > maxIds) {
      throw ArgumentError('at most $maxIds run ids and $maxIds message ids');
    }
    if (checkResults.length > maxCheckResults) {
      throw ArgumentError.value(
        checkResults.length,
        'checkResults',
        'at most $maxCheckResults',
      );
    }
  }

  /// No evidence.
  static final ImprovementEvidence empty = ImprovementEvidence();

  /// The most run ids and message ids each.
  static const int maxIds = 50;

  /// The most check results.
  static const int maxCheckResults = 10;

  /// Runs that show the problem or the fix.
  final List<String> runIds;

  /// Messages that show it.
  final List<String> messageIds;

  /// Check results that show it.
  final List<GoalCheckResult> checkResults;

  /// The stored JSON object.
  Map<String, Object?> toJson() => {
    'runIds': runIds,
    'messageIds': messageIds,
    'checkResults': [for (final r in checkResults) r.toJson()],
  };

  /// [toJson] encoded.
  String encode() => jsonEncode(toJson());

  /// Decodes the stored column; malformed values read as [empty] and bad
  /// entries are dropped. Never throws.
  static ImprovementEvidence tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return empty;
    }
    Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return empty;
    }
    if (json is! Map) {
      return empty;
    }
    final results = json['checkResults'];
    return ImprovementEvidence(
      runIds: JsonSafe.strings(json['runIds']).take(maxIds).toList(),
      messageIds: JsonSafe.strings(json['messageIds']).take(maxIds).toList(),
      checkResults: [
        if (results is List)
          for (final r in results.take(maxCheckResults))
            ?GoalCheckResult.tryFromJson(r),
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementEvidence &&
          JsonSafe.equals(runIds, other.runIds) &&
          JsonSafe.equals(messageIds, other.messageIds) &&
          JsonSafe.equals(checkResults, other.checkResults);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(runIds),
    Object.hashAll(messageIds),
    Object.hashAll(checkResults),
  );
}

/// One change the learning review proposes after a goal passed verification
/// (`improvement_proposals`). Nothing changes until a person accepts it; a
/// skill change must first pass an evaluation campaign.
class ImprovementProposal {
  /// Creates a proposal. Throws [ArgumentError] for an empty id, workspace or
  /// agent, an empty or over-long [change] or [expected], a repository scope
  /// without [scopeRefId], a replace or remove without [targetRef], or an
  /// [expiresAt] not after [createdAt].
  ImprovementProposal({
    required this.id,
    required this.workspaceId,
    required this.agentId,
    this.spaceId,
    this.conversationId,
    this.goalId,
    this.reviewRunId,
    required this.kind,
    required this.scope,
    this.scopeRefId,
    required this.operation,
    this.targetRef,
    required this.change,
    ImprovementEvidence? evidence,
    required this.expected,
    this.status = ImprovementStatus.proposed,
    this.beforeText,
    this.afterText,
    this.appliedRef,
    this.candidateRevisionId,
    this.campaignId,
    this.campaignState = ImprovementCampaignState.none,
    this.decidedByUserId,
    DateTime? decidedAt,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) : decidedAt = decidedAt?.toUtc(),
       createdAt = createdAt.toUtc(),
       expiresAt = expiresAt.toUtc(),
       evidence = evidence ?? ImprovementEvidence.empty {
    for (final (value, name) in [
      (id, 'id'),
      (workspaceId, 'workspaceId'),
      (agentId, 'agentId'),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
    if (change.trim().isEmpty || change.length > maxChangeLength) {
      throw ArgumentError.value(
        change.length,
        'change',
        'must be 1 to $maxChangeLength characters',
      );
    }
    if (expected.trim().isEmpty || expected.length > maxExpectedLength) {
      throw ArgumentError.value(
        expected.length,
        'expected',
        'must be 1 to $maxExpectedLength characters',
      );
    }
    final ref = scopeRefId;
    if (scope == ImprovementScope.repository && (ref == null || ref.isEmpty)) {
      throw ArgumentError.value(
        scopeRefId,
        'scopeRefId',
        'a repository-scoped proposal names its repository',
      );
    }
    final target = targetRef;
    if (operation != ImprovementOperation.add &&
        (target == null || target.isEmpty)) {
      throw ArgumentError.value(
        targetRef,
        'targetRef',
        'a ${operation.wire} names what it changes',
      );
    }
    if (!expiresAt.isAfter(createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must be after createdAt',
      );
    }
  }

  /// The longest [change], in characters.
  static const int maxChangeLength = 600;

  /// The longest [expected], in characters.
  static const int maxExpectedLength = 600;

  /// How long a proposal waits for a person before it expires.
  static const Duration lifetime = Duration(days: 30);

  /// Unique proposal id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The agent whose work was reviewed.
  final String agentId;

  /// The space the work happened in.
  final String? spaceId;

  /// The conversation the work happened in.
  final String? conversationId;

  /// The goal that passed verification.
  final String? goalId;

  /// The review run that proposed it.
  final String? reviewRunId;

  /// What it would change.
  final ImprovementKind kind;

  /// Where it applies.
  final ImprovementScope scope;

  /// The repository id for a repository scope.
  final String? scopeRefId;

  /// Add, replace or remove.
  final ImprovementOperation operation;

  /// The id or name of the fact, policy, note or skill replaced or removed.
  final String? targetRef;

  /// The one change, at most [maxChangeLength] characters.
  final String change;

  /// What shows the problem and the fix.
  final ImprovementEvidence evidence;

  /// What should be different next time.
  final String expected;

  /// Where it is.
  final ImprovementStatus status;

  /// The text before acceptance (rollback restores it).
  final String? beforeText;

  /// The text acceptance wrote (rollback refuses unless the current text
  /// still equals it).
  final String? afterText;

  /// The id of what acceptance wrote.
  final String? appliedRef;

  /// The candidate skill revision of a skill change.
  final String? candidateRevisionId;

  /// The evaluation campaign that gates a skill change.
  final String? campaignId;

  /// Where that campaign is.
  final ImprovementCampaignState campaignState;

  /// The person who accepted, rejected or rolled it back.
  final String? decidedByUserId;

  /// When they did (UTC, like every time here).
  final DateTime? decidedAt;

  /// When it was proposed (UTC).
  final DateTime createdAt;

  /// When it expires if nobody decides (UTC).
  final DateTime expiresAt;

  /// Whether it is a skill change (gated by a campaign).
  bool get isSkillChange =>
      kind == ImprovementKind.skillEdit || kind == ImprovementKind.skillNew;

  /// Whether a person may accept it now: proposed, and a skill change only
  /// after its campaign passed.
  bool get canAccept =>
      status == ImprovementStatus.proposed &&
      (!isSkillChange || campaignState == ImprovementCampaignState.passed);

  /// A copy with the given fields replaced.
  ImprovementProposal copyWith({
    String? id,
    String? workspaceId,
    String? agentId,
    String? spaceId,
    String? conversationId,
    String? goalId,
    String? reviewRunId,
    ImprovementKind? kind,
    ImprovementScope? scope,
    String? scopeRefId,
    ImprovementOperation? operation,
    String? targetRef,
    String? change,
    ImprovementEvidence? evidence,
    String? expected,
    ImprovementStatus? status,
    String? beforeText,
    String? afterText,
    String? appliedRef,
    bool removeAppliedRef = false,
    String? candidateRevisionId,
    String? campaignId,
    ImprovementCampaignState? campaignState,
    String? decidedByUserId,
    DateTime? decidedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) => ImprovementProposal(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    agentId: agentId ?? this.agentId,
    spaceId: spaceId ?? this.spaceId,
    conversationId: conversationId ?? this.conversationId,
    goalId: goalId ?? this.goalId,
    reviewRunId: reviewRunId ?? this.reviewRunId,
    kind: kind ?? this.kind,
    scope: scope ?? this.scope,
    scopeRefId: scopeRefId ?? this.scopeRefId,
    operation: operation ?? this.operation,
    targetRef: targetRef ?? this.targetRef,
    change: change ?? this.change,
    evidence: evidence ?? this.evidence,
    expected: expected ?? this.expected,
    status: status ?? this.status,
    beforeText: beforeText ?? this.beforeText,
    afterText: afterText ?? this.afterText,
    appliedRef: removeAppliedRef ? null : (appliedRef ?? this.appliedRef),
    candidateRevisionId: candidateRevisionId ?? this.candidateRevisionId,
    campaignId: campaignId ?? this.campaignId,
    campaignState: campaignState ?? this.campaignState,
    decidedByUserId: decidedByUserId ?? this.decidedByUserId,
    decidedAt: decidedAt ?? this.decidedAt,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImprovementProposal &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          spaceId == other.spaceId &&
          conversationId == other.conversationId &&
          goalId == other.goalId &&
          reviewRunId == other.reviewRunId &&
          kind == other.kind &&
          scope == other.scope &&
          scopeRefId == other.scopeRefId &&
          operation == other.operation &&
          targetRef == other.targetRef &&
          change == other.change &&
          evidence == other.evidence &&
          expected == other.expected &&
          status == other.status &&
          beforeText == other.beforeText &&
          afterText == other.afterText &&
          appliedRef == other.appliedRef &&
          candidateRevisionId == other.candidateRevisionId &&
          campaignId == other.campaignId &&
          campaignState == other.campaignState &&
          decidedByUserId == other.decidedByUserId &&
          decidedAt == other.decidedAt &&
          createdAt == other.createdAt &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    agentId,
    spaceId,
    conversationId,
    goalId,
    reviewRunId,
    kind,
    scope,
    scopeRefId,
    operation,
    targetRef,
    change,
    evidence,
    expected,
    status,
    beforeText,
    afterText,
    appliedRef,
    candidateRevisionId,
    campaignId,
    campaignState,
    decidedByUserId,
    decidedAt,
    createdAt,
    expiresAt,
  ]);

  @override
  String toString() =>
      'ImprovementProposal($id, ${kind.wire} ${operation.wire}, '
      '${status.wire})';
}
