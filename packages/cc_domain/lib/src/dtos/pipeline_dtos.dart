part of 'dtos.dart';

// ---- Pipeline runs ----

/// PipelineRun wire DTO — a single execution of a pipeline template
/// (workspace-scoped). Reconstructs losslessly: enum `status` as its `.name`,
/// timestamps as ISO-8601 strings, `state`/`trigger_payload` as raw JSON maps.
class PipelineRunDto {
  PipelineRunDto({
    required this.id,
    required this.templateId,
    required this.workspaceId,
    required this.status,
    Map<String, dynamic>? state,
    this.triggerEventType,
    this.triggerPayload,
    this.dedupKey,
    required this.startedAt,
    this.attemptStartedAt,
    this.attemptCount = 1,
    this.finishedAt,
    this.activeMs = 0,
    this.lastResumedAt,
    this.errorMessage,
    this.errorStackTrace,
    this.parentPipelineRunId,
    this.parentStepId,
    this.templateVersion = 1,
    this.templateSnapshot,
    this.totalCostCents = 0,
    this.totalTokens = 0,
    this.dryRun = false,
  }) : state = state ?? <String, dynamic>{};

  factory PipelineRunDto.fromJson(Map<String, dynamic> json) => PipelineRunDto(
    id: json['id'] as String,
    templateId: json['template_id'] as String? ?? '',
    workspaceId: json['workspace_id'] as String? ?? '',
    status: json['status'] as String? ?? 'pending',
    state: json['state'] is Map
        ? (json['state'] as Map).cast<String, dynamic>()
        : <String, dynamic>{},
    triggerEventType: json['trigger_event_type'] as String?,
    triggerPayload: json['trigger_payload'] is Map
        ? (json['trigger_payload'] as Map).cast<String, dynamic>()
        : null,
    dedupKey: json['dedup_key'] as String?,
    startedAt: json['started_at'] as String? ?? '',
    attemptStartedAt: json['attempt_started_at'] as String?,
    attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 1,
    finishedAt: json['finished_at'] as String?,
    activeMs: (json['active_ms'] as num?)?.toInt() ?? 0,
    lastResumedAt: json['last_resumed_at'] as String?,
    errorMessage: json['error_message'] as String?,
    errorStackTrace: json['error_stack_trace'] as String?,
    parentPipelineRunId: json['parent_pipeline_run_id'] as String?,
    parentStepId: json['parent_step_id'] as String?,
    templateVersion: (json['template_version'] as num?)?.toInt() ?? 1,
    templateSnapshot: (json['template_snapshot'] as Map?)
        ?.cast<String, dynamic>(),
    totalCostCents: (json['total_cost_cents'] as num?)?.toInt() ?? 0,
    totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
    dryRun: json['dry_run'] as bool? ?? false,
  );

  final String id;
  final String templateId;
  final String workspaceId;
  final String status;
  final Map<String, dynamic> state;
  final String? triggerEventType;
  final Map<String, dynamic>? triggerPayload;
  final String? dedupKey;
  final String startedAt;
  final String? attemptStartedAt;
  final int attemptCount;
  final String? finishedAt;
  final int activeMs;
  final String? lastResumedAt;
  final String? errorMessage;
  final String? errorStackTrace;
  final String? parentPipelineRunId;
  final String? parentStepId;
  final int templateVersion;

  /// The pinned template graph (`PipelineDefinition.toJson`). Sent on the
  /// single-run reads only (`getRun` / `watchRun`), never in list views.
  final Map<String, dynamic>? templateSnapshot;
  final int totalCostCents;
  final int totalTokens;
  final bool dryRun;

  Map<String, dynamic> toJson() => {
    'id': id,
    'template_id': templateId,
    'workspace_id': workspaceId,
    'status': status,
    'state': state,
    if (triggerEventType != null) 'trigger_event_type': triggerEventType,
    if (triggerPayload != null) 'trigger_payload': triggerPayload,
    if (dedupKey != null) 'dedup_key': dedupKey,
    'started_at': startedAt,
    if (attemptStartedAt != null) 'attempt_started_at': attemptStartedAt,
    'attempt_count': attemptCount,
    if (finishedAt != null) 'finished_at': finishedAt,
    'active_ms': activeMs,
    if (lastResumedAt != null) 'last_resumed_at': lastResumedAt,
    if (errorMessage != null) 'error_message': errorMessage,
    if (errorStackTrace != null) 'error_stack_trace': errorStackTrace,
    if (parentPipelineRunId != null)
      'parent_pipeline_run_id': parentPipelineRunId,
    if (parentStepId != null) 'parent_step_id': parentStepId,
    'template_version': templateVersion,
    'template_snapshot': ?templateSnapshot,
    'total_cost_cents': totalCostCents,
    'total_tokens': totalTokens,
    'dry_run': dryRun,
  };
}

/// PipelineStepRun wire DTO — a single step execution within a PipelineRun.
/// Owned (workspace-wise) through its parent run. Enum `status` as its `.name`,
/// timestamps as ISO-8601 strings.
class PipelineStepRunDto {
  PipelineStepRunDto({
    required this.id,
    required this.pipelineRunId,
    required this.stepId,
    required this.status,
    this.inputJson,
    this.outputJson,
    this.spaceId,
    this.errorMessage,
    this.attemptCount = 0,
    this.priorAttempts = const [],
    required this.startedAt,
    this.finishedAt,
  });

  factory PipelineStepRunDto.fromJson(Map<String, dynamic> json) =>
      PipelineStepRunDto(
        id: json['id'] as String,
        pipelineRunId: json['pipeline_run_id'] as String? ?? '',
        stepId: json['step_id'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        inputJson: json['input_json'] as String?,
        outputJson: json['output_json'] as String?,
        spaceId: json['space_id'] as String?,
        errorMessage: json['error_message'] as String?,
        attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 0,
        priorAttempts: ((json['prior_attempts'] as List?) ?? const [])
            .whereType<Map>()
            .map((a) => a.cast<String, dynamic>())
            .toList(),
        startedAt: json['started_at'] as String? ?? '',
        finishedAt: json['finished_at'] as String?,
      );

  final String id;
  final String pipelineRunId;
  final String stepId;
  final String status;
  final String? inputJson;
  final String? outputJson;
  final String? spaceId;
  final String? errorMessage;
  final int attemptCount;

  /// Archived previous firings of the step (oldest first), each a
  /// `PipelineStepAttempt.toJson()` map. Empty until the row is retried.
  final List<Map<String, dynamic>> priorAttempts;
  final String startedAt;
  final String? finishedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'pipeline_run_id': pipelineRunId,
    'step_id': stepId,
    'status': status,
    if (inputJson != null) 'input_json': inputJson,
    if (outputJson != null) 'output_json': outputJson,
    if (spaceId != null) 'space_id': spaceId,
    if (errorMessage != null) 'error_message': errorMessage,
    'attempt_count': attemptCount,
    if (priorAttempts.isNotEmpty) 'prior_attempts': priorAttempts,
    'started_at': startedAt,
    if (finishedAt != null) 'finished_at': finishedAt,
  };
}

/// Wire shape for a pipeline template (`PipelineDefinition`). The graph shape —
/// `steps` (each carrying its nested `triggers`/`config` as inline maps) and
/// declared `inputs` — round-trips losslessly so the client can reconstruct the
/// full entity. Enums travel as `.name`; the host owns version bumping.
class PipelineTemplateDto {
  PipelineTemplateDto({
    required this.templateId,
    required this.workspaceId,
    required this.name,
    this.description,
    this.steps = const [],
    this.inputs = const [],
    this.isBuiltIn = false,
    this.isEnabled = true,
    this.maxParallelRuns,
    this.version = 1,
  });

  factory PipelineTemplateDto.fromJson(Map<String, dynamic> json) =>
      PipelineTemplateDto(
        templateId: json['template_id'] as String,
        workspaceId: json['workspace_id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        steps: ((json['steps'] as List?) ?? const [])
            .whereType<Map>()
            .map((s) => s.cast<String, dynamic>())
            .toList(),
        inputs: ((json['inputs'] as List?) ?? const [])
            .whereType<Map>()
            .map((i) => i.cast<String, dynamic>())
            .toList(),
        isBuiltIn: json['is_built_in'] as bool? ?? false,
        isEnabled: json['is_enabled'] as bool? ?? true,
        maxParallelRuns: (json['max_parallel_runs'] as num?)?.toInt(),
        version: (json['version'] as num?)?.toInt() ?? 1,
      );

  final String templateId;
  final String workspaceId;
  final String name;
  final String? description;
  final List<Map<String, dynamic>> steps;
  final List<Map<String, dynamic>> inputs;
  final bool isBuiltIn;
  final bool isEnabled;

  /// Run-concurrency cap. Older payloads omit it (null = unlimited). Carried
  /// on the wire so a thin-client upsert cannot silently drop a cap the
  /// operator set in the editor.
  final int? maxParallelRuns;
  final int version;

  Map<String, dynamic> toJson() => {
    'template_id': templateId,
    'workspace_id': workspaceId,
    'name': name,
    if (description != null) 'description': description,
    'steps': steps,
    'inputs': inputs,
    'is_built_in': isBuiltIn,
    'is_enabled': isEnabled,
    'max_parallel_runs': maxParallelRuns,
    'version': version,
  };
}

/// PipelineTrigger wire DTO — a workspace-scoped declarative trigger that
/// auto-starts a pipeline template when a domain event fires (or on a
/// schedule). Reconstructs losslessly: enums are plain strings, `match` is a
/// JSON object, timestamps are ISO-8601 strings.
class PipelineTriggerDto {
  PipelineTriggerDto({
    required this.id,
    required this.eventType,
    required this.templateId,
    required this.workspaceId,
    required this.createdAt,
    this.enabled = false,
    this.cronExpression,
    this.timezone,
    this.nextRunAt,
    this.webhookToken,
    this.eventFilters = const {},
    this.match = const {},
    this.lastFiredAt,
    this.catchUpPolicy = 'catchUpLatestOnly',
  });

  factory PipelineTriggerDto.fromJson(Map<String, dynamic> json) =>
      PipelineTriggerDto(
        id: json['id'] as String? ?? '',
        eventType: json['event_type'] as String? ?? '',
        templateId: json['template_id'] as String? ?? '',
        workspaceId: json['workspace_id'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? false,
        cronExpression: json['cron_expression'] as String?,
        timezone: json['timezone'] as String?,
        nextRunAt: json['next_run_at'] as String?,
        webhookToken: json['webhook_token'] as String?,
        eventFilters: json['event_filters'] is Map
            ? (json['event_filters'] as Map).cast<String, dynamic>()
            : const {},
        match: json['match'] is Map
            ? (json['match'] as Map).cast<String, dynamic>()
            : const {},
        lastFiredAt: json['last_fired_at'] as String?,
        catchUpPolicy:
            json['catch_up_policy'] as String? ?? 'catchUpLatestOnly',
        createdAt: json['created_at'] as String? ?? '',
      );

  final String id;
  final String eventType;
  final String templateId;
  final String workspaceId;
  final bool enabled;

  /// Schedule expression for time-based triggers (`every:<seconds>` or a
  /// standard 5-field cron), or null.
  final String? cronExpression;

  /// IANA timezone the cron expression is evaluated in (null/empty = UTC).
  final String? timezone;

  /// ISO-8601 timestamp of the next cron fire, or null.
  final String? nextRunAt;

  /// Secret path token for webhook triggers, or null.
  final String? webhookToken;

  /// Per-event action filters for webhook triggers. Empty fires on every
  /// delivery.
  final Map<String, dynamic> eventFilters;

  /// Value filter applied to the event payload before firing. Empty means
  /// "fire on every matching event".
  final Map<String, dynamic> match;

  /// ISO-8601 timestamp of the last firing, or null until first fired.
  final String? lastFiredAt;

  /// The [CronCatchUpPolicy] name for missed scheduled fires
  /// (`catchUpLatestOnly` default, or `skip`).
  final String catchUpPolicy;

  /// ISO-8601 creation timestamp.
  final String createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_type': eventType,
    'template_id': templateId,
    'workspace_id': workspaceId,
    'enabled': enabled,
    if (cronExpression != null) 'cron_expression': cronExpression,
    if (timezone != null) 'timezone': timezone,
    if (nextRunAt != null) 'next_run_at': nextRunAt,
    if (webhookToken != null) 'webhook_token': webhookToken,
    'event_filters': eventFilters,
    'match': match,
    if (lastFiredAt != null) 'last_fired_at': lastFiredAt,
    'catch_up_policy': catchUpPolicy,
    'created_at': createdAt,
  };
}
