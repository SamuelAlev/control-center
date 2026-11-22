import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_catalog.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';

/// The catalog lookups of one script: `searchTools`, `describeTool` and
/// `describeNamespace`.
///
/// They are answered synchronously, on the isolate that serves every
/// workspace: so their arguments are checked before any work, and the
/// script's lookups are bounded in number ([CodeModeLimits.maxLookups]) and
/// in the server time they take together (`budget`, by default
/// [CodeModeLimits.maxLookupMs]). The time of each lookup is measured around
/// the whole answer (the catalog's work and the reply's encoding); once the
/// sum passes the budget, later lookups are refused unanswered, so the
/// budget is overshot by at most one lookup. The same measure is charged
/// to the workspace's bucket ([WorkspaceLookupBuckets]), which bounds the
/// lookups of all its scripts together.
class ScriptLookups {
  /// Creates the lookups of one script. `catalog` is read on each lookup,
  /// once the script's catalog is built.
  ScriptLookups({
    required this._catalog,
    required this._budget,
    required this._buckets,
    required this._workspaceId,
    required this._reply,
    required this._reject,
  });

  final ScriptCatalog Function() _catalog;
  final Duration _budget;
  final WorkspaceLookupBuckets _buckets;
  final String _workspaceId;
  final void Function(String id, Object? value) _reply;
  final void Function(String id, String message, {String? status}) _reject;

  /// Lookups answered so far, and the server time they took.
  int _lookups = 0;
  int _lookupMicros = 0;

  /// Answers the lookup host call [call], or refuses it.
  void answer(CodeSandboxCall call) {
    final refusal = _refusal(call.name, call.arguments);
    if (refusal != null) {
      _reject(call.id, refusal);
      return;
    }
    _lookups++;
    final clock = Stopwatch()..start();
    try {
      _answer(call);
    } finally {
      final micros = clock.elapsedMicroseconds;
      _lookupMicros += micros;
      _buckets.charge(_workspaceId, micros);
    }
  }

  /// Why [name] with [args] is refused before any work, or null.
  String? _refusal(String name, Map<String, dynamic> args) {
    if (_lookups >= CodeModeLimits.maxLookups ||
        _lookupMicros >= _budget.inMicroseconds) {
      return 'lookup budget used up: a script may make '
          '${CodeModeLimits.maxLookups} lookups (searchTools, describeTool, '
          'describeNamespace) taking at most ${_budget.inMilliseconds} ms of '
          'server time together. Use ALL_TOOLS, or keep what a lookup '
          'returned.';
    }
    if (!_buckets.hasTime(_workspaceId)) {
      return 'lookup budget of this workspace used up: the scripts of one '
          'workspace may take ${_buckets.capacity.inMilliseconds} ms of '
          'server time for lookups together, given back at '
          '${_buckets.refillPerSecond.inMilliseconds} ms per second. Use '
          'ALL_TOOLS, or keep what a lookup returned.';
    }
    const nameUnits = CodeModeLimits.maxLookupNameUnits;
    if (name == 'searchTools') {
      final query = args['query'];
      final limit = args['limit'];
      final namespace = args['namespace'];
      if (query is! String ||
          (limit != null && limit is! int) ||
          (namespace != null && namespace is! String)) {
        return 'searchTools(query, { limit, namespace }) needs a string '
            'query, an integer limit and a string namespace.';
      }
      if (query.length > CodeModeLimits.maxLookupQueryUnits) {
        return 'searchTools query is ${query.length} characters; the limit '
            'is ${CodeModeLimits.maxLookupQueryUnits}. Search with a few '
            'words.';
      }
      if (limit is int &&
          (limit < 0 || limit > ScriptCatalog.maxSearchResults)) {
        return 'searchTools limit must be 0 to '
            '${ScriptCatalog.maxSearchResults}.';
      }
      if (namespace is String && namespace.length > nameUnits) {
        return 'searchTools namespace is ${namespace.length} characters; '
            'the limit is $nameUnits.';
      }
      return null;
    }
    final lookedUp = args['name'];
    if (lookedUp is! String) {
      return '$name(name) needs a string.';
    }
    if (lookedUp.length > nameUnits) {
      return '$name name is ${lookedUp.length} characters; the limit is '
          '$nameUnits.';
    }
    return null;
  }

  /// Answers a lookup whose arguments [_refusal] passed.
  void _answer(CodeSandboxCall call) {
    final args = call.arguments;
    final catalog = _catalog();
    if (call.name == 'searchTools') {
      _reply(
        call.id,
        catalog.searchTools(
          args['query'] as String,
          limit: args['limit'] as int? ?? 8,
          namespace: args['namespace'] as String?,
        ),
      );
      return;
    }
    final name = args['name'] as String;
    final answer = call.name == 'describeTool'
        ? catalog.describeTool(name)
        : catalog.describeNamespace(name);
    switch (answer) {
      case ScriptCatalogFound(:final value):
        _reply(call.id, value);
      case final ScriptCatalogUnknown unknown:
        _reject(
          call.id,
          unknown.message,
          status: unknown.kind == 'tool'
              ? NestedCallStatus.unknownTool.wire
              : 'unknown_namespace',
        );
    }
  }
}

/// The lookup time of every workspace's scripts together: one bucket per
/// workspace holding at most [capacity] of server time, refilled at
/// [refillPerSecond] per second of wall time and charged with each lookup's
/// measured time. A lookup is answered while its workspace's bucket holds
/// time, so a bucket goes below zero by at most one lookup; over time a
/// workspace's lookups take at most [refillPerSecond] of each second.
class WorkspaceLookupBuckets {
  /// Creates the buckets; [nowMicros] is a monotonic clock in microseconds
  /// (by default, time since creation).
  WorkspaceLookupBuckets({
    this.capacity = const Duration(
      milliseconds: CodeModeLimits.workspaceLookupMs,
    ),
    this.refillPerSecond = const Duration(
      milliseconds: CodeModeLimits.workspaceLookupRefillMsPerS,
    ),
    int Function()? nowMicros,
  }) : _now = nowMicros ?? _sinceCreation();

  static int Function() _sinceCreation() {
    final clock = Stopwatch()..start();
    return () => clock.elapsedMicroseconds;
  }

  /// The most lookup time a workspace holds.
  final Duration capacity;

  /// Lookup time given back per second of wall time.
  final Duration refillPerSecond;

  final int Function() _now;

  /// Each workspace's level in microseconds and when it was read; a
  /// workspace whose bucket is full has no entry.
  final Map<String, (int, int)> _levels = {};

  /// Whether [workspaceId]'s bucket holds time now.
  bool hasTime(String workspaceId) => _level(workspaceId) > 0;

  /// Takes [micros] of lookup time from [workspaceId]'s bucket.
  void charge(String workspaceId, int micros) {
    _levels[workspaceId] = (_level(workspaceId) - micros, _now());
  }

  /// [workspaceId]'s level now, refilled for the time since it was last
  /// charged (each charge rounds down by less than a microsecond).
  int _level(String workspaceId) {
    final full = capacity.inMicroseconds;
    final entry = _levels[workspaceId];
    if (entry == null) {
      return full;
    }
    final (level, at) = entry;
    final now = _now();
    final rate = refillPerSecond.inMicroseconds;
    // Full once it rested as long as its deficit takes to refill; checked
    // first, so the product below stays in range however long it rested.
    if (rate <= 0) {
      return level;
    }
    if (now - at >= (full - level) * 1000000 ~/ rate + 1) {
      _levels.remove(workspaceId);
      return full;
    }
    final refilled = level + (now - at) * rate ~/ 1000000;
    if (refilled >= full) {
      _levels.remove(workspaceId);
      return full;
    }
    return refilled;
  }
}
