import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:collection/collection.dart';

const _deepEquality = DeepCollectionEquality();

enum SkillEvaluationComparison {
  absent,
  previous,
  forced,
  composition;

  String get wire => name;

  static SkillEvaluationComparison fromWire(String value) =>
      SkillEvaluationComparison.values.firstWhere(
        (comparison) => comparison.name == value,
        orElse: () => throw FormatException('Unknown comparison: $value'),
      );
}

enum SkillEvaluationCampaignStatus {
  queued,
  running,
  cancelling,
  cancelled,
  completed,
  failed,
  interrupted;

  String get wire => name;

  static SkillEvaluationCampaignStatus fromWire(String value) =>
      SkillEvaluationCampaignStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => throw FormatException('Unknown campaign status: $value'),
      );

  bool get isTerminal => switch (this) {
    cancelled || completed || failed || interrupted => true,
    queued || running || cancelling => false,
  };
}

String _nonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be empty');
  }
  return value;
}

bool _sameInstant(DateTime? first, DateTime? second) =>
    first?.microsecondsSinceEpoch == second?.microsecondsSinceEpoch;

/// Copies and validates a JSON object recursively, rejecting non-JSON values.
/// Nested collections cannot be changed through a caller-held reference.
Map<String, dynamic> _freezeJson(Map<String, dynamic> value) =>
    Map.unmodifiable(
      value.map((key, item) => MapEntry(key, _freezeValue(item))),
    );

dynamic _freezeValue(dynamic value) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double && value.isFinite) {
    return value;
  }
  if (value is Map<String, dynamic>) {
    return _freezeJson(value);
  }
  if (value is List) {
    return List<dynamic>.unmodifiable(value.map(_freezeValue));
  }
  throw const FormatException('Campaign payload contains a non-JSON value');
}

/// Detached mutable JSON for wire encoders and callers.
Map<String, dynamic> _jsonCopy(Map<String, dynamic> map) =>
    map.map((key, value) => MapEntry(key, _copyValue(value)));

dynamic _copyValue(dynamic value) => switch (value) {
  Map<String, dynamic> map => _jsonCopy(map),
  List list => list.map(_copyValue).toList(),
  _ => value,
};

Map<String, dynamic> _object(dynamic value, String field) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected JSON object at $field');
  }
  return value;
}

/// One immutable, revision-specific paired evaluation in a workspace.
class SkillEvaluationCampaign {
  factory SkillEvaluationCampaign.fromJson(
    Map<String, dynamic> json,
  ) => SkillEvaluationCampaign(
    id: json['id'] as String,
    workspaceId: json['workspaceId'] as String,
    skillKey: json['skillKey'] as String,
    skillSlug: json['skillSlug'] as String,
    skillHash: json['skillHash'] as String,
    corpusId: json['corpusId'] as String,
    providerId: json['providerId'] as String,
    modelId: json['modelId'] as String,
    configurationHash: json['configurationHash'] as String,
    baselineHash: json['baselineHash'] as String?,
    repoId: json['repoId'] as String?,
    comparison: SkillEvaluationComparison.fromWire(
      json['comparison'] as String,
    ),
    status: SkillEvaluationCampaignStatus.fromWire(json['status'] as String),
    repetitions: json['repetitions'] as int,
    budgetMicros: json['budgetMicros'] as int,
    plannedAttempts: json['plannedAttempts'] as int,
    completedAttempts: json['completedAttempts'] as int,
    spentMicros: json['spentMicros'] as int?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    startedAt: json['startedAt'] == null
        ? null
        : DateTime.parse(json['startedAt'] as String),
    finishedAt: json['finishedAt'] == null
        ? null
        : DateTime.parse(json['finishedAt'] as String),
    actor: Principal.parse(json['actor'] as String),
    triggeredBy: json['triggeredBy'] as String,
    staleReason: json['staleReason'] as String?,
    error: json['error'] as String?,
    configuration: _object(json['configuration'], 'configuration'),
    report: json['report'] == null ? null : _object(json['report'], 'report'),
  );

  SkillEvaluationCampaign({
    required String id,
    required String workspaceId,
    required String skillKey,
    required String skillSlug,
    required String skillHash,
    required String corpusId,
    required String providerId,
    required String modelId,
    required String configurationHash,
    required this.comparison,
    required this.status,
    required this.repetitions,
    required this.budgetMicros,
    required this.plannedAttempts,
    required this.completedAttempts,
    required this.createdAt,
    required this.actor,
    required String triggeredBy,
    required Map<String, dynamic> configuration,
    this.baselineHash,
    this.repoId,
    this.spentMicros,
    this.startedAt,
    this.finishedAt,
    this.staleReason,
    this.error,
    Map<String, dynamic>? report,
  }) : id = _nonEmpty(id, 'id'),
       workspaceId = _nonEmpty(workspaceId, 'workspaceId'),
       skillKey = _nonEmpty(skillKey, 'skillKey'),
       skillSlug = _nonEmpty(skillSlug, 'skillSlug'),
       skillHash = _nonEmpty(skillHash, 'skillHash'),
       corpusId = _nonEmpty(corpusId, 'corpusId'),
       providerId = _nonEmpty(providerId, 'providerId'),
       modelId = _nonEmpty(modelId, 'modelId'),
       configurationHash = _nonEmpty(configurationHash, 'configurationHash'),
       triggeredBy = _nonEmpty(triggeredBy, 'triggeredBy'),
       configuration = _freezeJson(configuration),
       report = report == null ? null : _freezeJson(report) {
    if (triggeredBy != 'manual' && triggeredBy != 'skill_update') {
      throw ArgumentError.value(triggeredBy, 'triggeredBy');
    }
    if (repetitions < 1 ||
        budgetMicros < 0 ||
        plannedAttempts < 1 ||
        completedAttempts < 0 ||
        completedAttempts > plannedAttempts ||
        (spentMicros != null && spentMicros! < 0)) {
      throw ArgumentError('Invalid campaign repetitions, budget or progress');
    }
    if (comparison == SkillEvaluationComparison.previous &&
        (baselineHash == null || baselineHash!.trim().isEmpty)) {
      throw ArgumentError('Previous comparison requires a baseline hash');
    }
    if (actor.id.trim().isEmpty) {
      throw ArgumentError('Actor id must not be empty');
    }
  }

  final String id;
  final String workspaceId;
  final String skillKey;
  final String skillSlug;
  final String skillHash;
  final String corpusId;
  final String providerId;
  final String modelId;
  final String configurationHash;
  final String? baselineHash;
  final String? repoId;
  final SkillEvaluationComparison comparison;
  final SkillEvaluationCampaignStatus status;
  final int repetitions;
  final int budgetMicros;
  final int plannedAttempts;
  final int completedAttempts;

  /// Null means the cost could not be determined, not that it was free.
  final int? spentMicros;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final Principal actor;
  final String triggeredBy;
  final String? staleReason;
  final String? error;
  final Map<String, dynamic> configuration;
  final Map<String, dynamic>? report;

  bool get isTerminal => status.isTerminal;

  /// Nullable values survive partial updates unless explicitly cleared.
  SkillEvaluationCampaign copyWith({
    SkillEvaluationCampaignStatus? status,
    int? completedAttempts,
    int? spentMicros,
    bool clearSpentMicros = false,
    DateTime? startedAt,
    DateTime? finishedAt,
    String? staleReason,
    bool clearStaleReason = false,
    String? error,
    bool clearError = false,
    Map<String, dynamic>? report,
    bool clearReport = false,
  }) => SkillEvaluationCampaign(
    id: id,
    workspaceId: workspaceId,
    skillKey: skillKey,
    skillSlug: skillSlug,
    skillHash: skillHash,
    corpusId: corpusId,
    providerId: providerId,
    modelId: modelId,
    configurationHash: configurationHash,
    baselineHash: baselineHash,
    repoId: repoId,
    comparison: comparison,
    status: status ?? this.status,
    repetitions: repetitions,
    budgetMicros: budgetMicros,
    plannedAttempts: plannedAttempts,
    completedAttempts: completedAttempts ?? this.completedAttempts,
    spentMicros: clearSpentMicros ? null : spentMicros ?? this.spentMicros,
    createdAt: createdAt,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    actor: actor,
    triggeredBy: triggeredBy,
    staleReason: clearStaleReason ? null : staleReason ?? this.staleReason,
    error: clearError ? null : error ?? this.error,
    configuration: configuration,
    report: clearReport ? null : report ?? this.report,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'skillKey': skillKey,
    'skillSlug': skillSlug,
    'skillHash': skillHash,
    'corpusId': corpusId,
    'providerId': providerId,
    'modelId': modelId,
    'configurationHash': configurationHash,
    'baselineHash': baselineHash,
    'repoId': repoId,
    'comparison': comparison.name,
    'status': status.name,
    'repetitions': repetitions,
    'budgetMicros': budgetMicros,
    'plannedAttempts': plannedAttempts,
    'completedAttempts': completedAttempts,
    'spentMicros': spentMicros,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'startedAt': startedAt?.toUtc().toIso8601String(),
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'actor': actor.wire,
    'triggeredBy': triggeredBy,
    'staleReason': staleReason,
    'error': error,
    'configuration': _jsonCopy(configuration),
    'report': report == null ? null : _jsonCopy(report!),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillEvaluationCampaign &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          skillKey == other.skillKey &&
          skillSlug == other.skillSlug &&
          skillHash == other.skillHash &&
          corpusId == other.corpusId &&
          providerId == other.providerId &&
          modelId == other.modelId &&
          configurationHash == other.configurationHash &&
          baselineHash == other.baselineHash &&
          repoId == other.repoId &&
          comparison == other.comparison &&
          status == other.status &&
          repetitions == other.repetitions &&
          budgetMicros == other.budgetMicros &&
          plannedAttempts == other.plannedAttempts &&
          completedAttempts == other.completedAttempts &&
          spentMicros == other.spentMicros &&
          _sameInstant(createdAt, other.createdAt) &&
          _sameInstant(startedAt, other.startedAt) &&
          _sameInstant(finishedAt, other.finishedAt) &&
          actor == other.actor &&
          triggeredBy == other.triggeredBy &&
          staleReason == other.staleReason &&
          error == other.error &&
          _deepEquality.equals(configuration, other.configuration) &&
          _deepEquality.equals(report, other.report);

  @override
  int get hashCode => Object.hash(
    Object.hash(
      id,
      workspaceId,
      skillKey,
      skillSlug,
      skillHash,
      corpusId,
      providerId,
      modelId,
      configurationHash,
      baselineHash,
      repoId,
    ),
    Object.hash(
      comparison,
      status,
      repetitions,
      budgetMicros,
      plannedAttempts,
      completedAttempts,
      spentMicros,
      createdAt.microsecondsSinceEpoch,
      startedAt?.microsecondsSinceEpoch,
      finishedAt?.microsecondsSinceEpoch,
    ),
    Object.hash(
      actor,
      triggeredBy,
      staleReason,
      error,
      _deepEquality.hash(configuration),
      _deepEquality.hash(report),
    ),
  );
}

/// One indexed attempt and its redacted behavioral/verifier evidence.
class SkillEvaluationAttemptRecord {
  factory SkillEvaluationAttemptRecord.fromJson(Map<String, dynamic> json) =>
      SkillEvaluationAttemptRecord(
        id: json['id'] as String,
        workspaceId: json['workspaceId'] as String,
        campaignId: json['campaignId'] as String,
        taskId: json['taskId'] as String,
        armId: json['armId'] as String,
        repetition: json['repetition'] as int,
        ordinal: json['ordinal'] as int,
        evidence: _object(json['evidence'], 'evidence'),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  SkillEvaluationAttemptRecord({
    required String id,
    required String workspaceId,
    required String campaignId,
    required String taskId,
    required String armId,
    required this.repetition,
    required this.ordinal,
    required Map<String, dynamic> evidence,
    required this.createdAt,
  }) : id = _nonEmpty(id, 'id'),
       workspaceId = _nonEmpty(workspaceId, 'workspaceId'),
       campaignId = _nonEmpty(campaignId, 'campaignId'),
       taskId = _nonEmpty(taskId, 'taskId'),
       armId = _nonEmpty(armId, 'armId'),
       evidence = _freezeJson(evidence) {
    if (repetition < 0 || ordinal < 0) {
      throw ArgumentError('Invalid attempt index');
    }
  }

  final String id;
  final String workspaceId;
  final String campaignId;
  final String taskId;
  final String armId;
  final int repetition;
  final int ordinal;
  final Map<String, dynamic> evidence;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'campaignId': campaignId,
    'taskId': taskId,
    'armId': armId,
    'repetition': repetition,
    'ordinal': ordinal,
    'evidence': _jsonCopy(evidence),
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillEvaluationAttemptRecord &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          campaignId == other.campaignId &&
          taskId == other.taskId &&
          armId == other.armId &&
          repetition == other.repetition &&
          ordinal == other.ordinal &&
          _deepEquality.equals(evidence, other.evidence) &&
          _sameInstant(createdAt, other.createdAt);

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    campaignId,
    taskId,
    armId,
    repetition,
    ordinal,
    _deepEquality.hash(evidence),
    createdAt.microsecondsSinceEpoch,
  );
}

/// Workspace/skill-scoped explicit opt-in for bounded reevaluation.
class SkillEvaluationPolicy {
  factory SkillEvaluationPolicy.fromJson(Map<String, dynamic> json) =>
      SkillEvaluationPolicy(
        workspaceId: json['workspaceId'] as String,
        skillKey: json['skillKey'] as String,
        enabled: json['enabled'] as bool,
        actor: Principal.parse(json['actor'] as String),
        configuration: _object(json['configuration'], 'configuration'),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  SkillEvaluationPolicy({
    required String workspaceId,
    required String skillKey,
    required this.enabled,
    required this.actor,
    required Map<String, dynamic> configuration,
    required this.updatedAt,
  }) : workspaceId = _nonEmpty(workspaceId, 'workspaceId'),
       skillKey = _nonEmpty(skillKey, 'skillKey'),
       configuration = _freezeJson(configuration) {
    if (actor.id.trim().isEmpty) {
      throw ArgumentError('Actor id must not be empty');
    }
  }

  final String workspaceId;
  final String skillKey;
  final bool enabled;
  final Principal actor;
  final Map<String, dynamic> configuration;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'workspaceId': workspaceId,
    'skillKey': skillKey,
    'enabled': enabled,
    'actor': actor.wire,
    'configuration': _jsonCopy(configuration),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkillEvaluationPolicy &&
          workspaceId == other.workspaceId &&
          skillKey == other.skillKey &&
          enabled == other.enabled &&
          actor == other.actor &&
          _deepEquality.equals(configuration, other.configuration) &&
          _sameInstant(updatedAt, other.updatedAt);

  @override
  int get hashCode => Object.hash(
    workspaceId,
    skillKey,
    enabled,
    actor,
    _deepEquality.hash(configuration),
    updatedAt.microsecondsSinceEpoch,
  );
}
