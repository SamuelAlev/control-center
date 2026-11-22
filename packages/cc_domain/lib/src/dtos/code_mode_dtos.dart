part of 'dtos.dart';

// ---- Code mode (`codeMode.*`) ----
//
// The status a settings screen shows and the envelopes around the execution
// records the observability pages read. The records themselves travel in the
// domain's own wire form (`CodeExecution.toJson`, `CodeExecutionPayload.toJson`,
// `CodeExecutionCall.toJson`), which is already documented as the wire form, so
// nothing here restates their fields. The host injects the workspace per call;
// no `workspace_id` travels back. Nothing here names a host path.

/// `codeMode.status`: whether this server can run scripts, why not when it
/// cannot, its caps, and the limits a script in the workspace runs under.
class CodeModeStatusDto {
  /// Creates a status.
  const CodeModeStatusDto({
    required this.available,
    required this.limits,
    required this.limitOverrides,
    required this.maxProcesses,
    required this.maxParkedProcesses,
    required this.maxWorkspaceProcesses,
    required this.maxHeapBytes,
    this.reason,
    this.runnerVersion,
  });

  /// Rebuilds from [toJson]'s output. Anything other than an explicit
  /// `available: true` reads as unavailable, so a malformed answer can never
  /// show code mode as usable.
  factory CodeModeStatusDto.fromJson(Map<String, dynamic> json) {
    // Read leniently: a malformed field reads as its default, never as a
    // crash, and never as usable.
    final rawLimits = json['limits'];
    final limits = rawLimits is Map ? rawLimits.cast<String, dynamic>() : null;
    final rawOverrides = json['limit_overrides'];
    final overrides = rawOverrides is Map
        ? rawOverrides.cast<String, dynamic>()
        : null;
    return CodeModeStatusDto(
      available: json['available'] == true,
      reason: json['reason'] as String?,
      limits: limits == null
          ? CodeModeLimits.defaults
          : CodeModeLimits.fromJson(limits),
      limitOverrides: {
        for (final e in (overrides ?? const <String, dynamic>{}).entries)
          if (e.value is num) e.key: (e.value as num).toInt(),
      },
      runnerVersion: json['runner_version'] as String?,
      maxProcesses: (json['max_processes'] as num?)?.toInt() ?? 0,
      maxParkedProcesses: (json['max_parked_processes'] as num?)?.toInt() ?? 0,
      maxWorkspaceProcesses:
          (json['max_workspace_processes'] as num?)?.toInt() ?? 0,
      maxHeapBytes:
          (json['max_heap_bytes'] as num?)?.toInt() ??
          CodeModeLimits.heap.ceiling,
    );
  }

  /// Whether this server runs scripts: its runner passed the boot self-test
  /// and it is not a public demo. Every run here has `repl` exactly when
  /// this is true.
  final bool available;

  /// Why it is unavailable, with host paths removed; null when available.
  final String? reason;

  /// The limits a script in this workspace runs under, its heap already
  /// clamped to [maxHeapBytes].
  final CodeModeLimits limits;

  /// The workspace's stored overrides of [CodeModeLimits.defaults], keyed as
  /// `codeMode.setWorkspaceSetting` takes them.
  final Map<String, int> limitOverrides;

  /// The runner's version line, or null when it did not answer.
  final String? runnerVersion;

  /// The most scripts this server runs at once
  /// (`--code-mode-max-processes`).
  final int maxProcesses;

  /// The most runners kept alive on top of [maxProcesses] for scripts
  /// waiting on a person without a slot (four times [maxProcesses]). Live
  /// runner processes never exceed the sum of the two.
  final int maxParkedProcesses;

  /// The most of [maxProcesses] one workspace's scripts hold at once.
  final int maxWorkspaceProcesses;

  /// The server owner's heap ceiling for every script, in bytes
  /// (`--code-mode-max-heap-mb`): the highest heap limit a workspace can
  /// usefully set.
  final int maxHeapBytes;

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'available': available,
    'reason': ?reason,
    'limits': limits.toJson(),
    'limit_overrides': limitOverrides,
    'runner_version': ?runnerVersion,
    'max_processes': maxProcesses,
    'max_parked_processes': maxParkedProcesses,
    'max_workspace_processes': maxWorkspaceProcesses,
    'max_heap_bytes': maxHeapBytes,
  };
}

/// `codeMode.listExecutions`: one page of a workspace's executions, newest
/// first, summary fields only (no source, output or calls).
///
/// A page may hold fewer than the requested limit, even none, while
/// [nextCursor] is set: executions in spaces the caller may not read are
/// left out after the page is read. Keep paging while [nextCursor] is not
/// null.
class CodeExecutionPageDto {
  /// Creates a page.
  const CodeExecutionPageDto({required this.items, this.nextCursor});

  /// Rebuilds from [toJson]'s output, skipping rows that do not parse.
  factory CodeExecutionPageDto.fromJson(Map<String, dynamic> json) =>
      CodeExecutionPageDto(
        items: [
          for (final raw in (json['items'] as List?) ?? const [])
            if (raw is Map) ?_tryExecution(raw.cast<String, dynamic>()),
        ],
        nextCursor: json['next_cursor'] as String?,
      );

  /// The executions.
  final List<CodeExecution> items;

  /// The opaque cursor for the next (older) page, or null at the end.
  final String? nextCursor;

  /// The domain page.
  CodeExecutionPage toPage() =>
      CodeExecutionPage(items: items, nextCursor: nextCursor);

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'items': [for (final e in items) e.toJson()],
    'next_cursor': ?nextCursor,
  };
}

/// `codeMode.getExecution`: one execution with its source, output and nested
/// calls.
class CodeExecutionDetailDto {
  /// Creates a detail.
  const CodeExecutionDetailDto({
    required this.execution,
    required this.calls,
    this.payload,
  });

  /// From the domain detail.
  factory CodeExecutionDetailDto.fromDetail(CodeExecutionDetail detail) =>
      CodeExecutionDetailDto(
        execution: detail.execution,
        payload: detail.payload,
        calls: detail.calls,
      );

  /// Rebuilds from [toJson]'s output.
  factory CodeExecutionDetailDto.fromJson(Map<String, dynamic> json) {
    final payload = (json['payload'] as Map?)?.cast<String, dynamic>();
    return CodeExecutionDetailDto(
      execution: CodeExecution.fromJson(
        (json['execution'] as Map).cast<String, dynamic>(),
      ),
      payload: payload == null ? null : CodeExecutionPayload.fromJson(payload),
      calls: [
        for (final raw in (json['calls'] as List?) ?? const [])
          if (raw is Map)
            CodeExecutionCall.fromJson(raw.cast<String, dynamic>()),
      ]..sort((a, b) => a.sequence.compareTo(b.sequence)),
    );
  }

  /// The execution.
  final CodeExecution execution;

  /// Its source, output and console, or null when none was kept.
  final CodeExecutionPayload? payload;

  /// Its nested calls, by sequence.
  final List<CodeExecutionCall> calls;

  /// The domain detail.
  CodeExecutionDetail toDetail() =>
      CodeExecutionDetail(execution: execution, payload: payload, calls: calls);

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'execution': execution.toJson(),
    'payload': ?payload?.toJson(),
    'calls': [for (final c in calls) c.toJson()],
  };
}

CodeExecution? _tryExecution(Map<String, dynamic> json) {
  try {
    return CodeExecution.fromJson(json);
  } on Object {
    return null;
  }
}
