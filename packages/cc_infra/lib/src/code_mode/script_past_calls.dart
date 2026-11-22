import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_sandbox_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/script_past_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_fix_hints.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_transcript_port.dart';
import 'package:cc_harness/context.dart'
    show ToolOutputReadStatus, isToolOutputHandle, newToolOutputHandle;
import 'package:cc_infra/src/code_mode/script_lookups.dart';
import 'package:cc_infra/src/code_mode/script_model_calls.dart'
    show kScriptLimitStatus;
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The host functions of one script that read its run's past (`history`,
/// `outputs`, `loadOutput`) and keep large values for later scripts
/// (`keep`), over the run's [ScriptPastPort].
///
/// Every argument comes from the runner, which runs model-written code: each
/// is checked for type and size before any work. The calls are answered one
/// at a time, in the order the script made them, on the isolate that serves
/// every workspace, so a script cannot start a burst of transcript loads;
/// each call's time is charged to the workspace's lookup bucket and a call
/// that finds it empty is refused unanswered. A script makes at most
/// [CodeModeLimits.maxPastReads] reads; what they return is bounded per call
/// (50 rows and 64 KiB of row text, [CodeModeLimits.maxLoadOutputChars]
/// characters), per script ([CodeModeLimits.maxPastReadBytesPerScript]) and
/// per run ([CodeModeLimits.maxPastReadBytesPerRun]), measured as the UTF-8
/// JSON the runner receives; a reply that would cross a bound is refused
/// whole. Nothing new starts while the script waits on a person.
///
/// A kept value gets its handle at once and is written only when the script
/// completes ([commit]); until then this script reads it from here. A
/// read-only run keeps nothing.
class ScriptPastCalls {
  /// Creates the calls of one script. `past` is null on a surface without
  /// one (every call then rejects and says so).
  ScriptPastCalls({
    required this._past,
    required this._readOnly,
    required this._buckets,
    required this._workspaceId,
    required this._ended,
    required this._mayStart,
    required this._reply,
    required this._reject,
  });

  /// The calls of the script [request] runs: its run's [ScriptPastPort]
  /// and whether the run is read-only come from the request, which the
  /// surface built from the run.
  factory ScriptPastCalls.of(
    CodeExecutionRequest request, {
    required WorkspaceLookupBuckets buckets,
    required bool Function() ended,
    required Future<void> Function() mayStart,
    required void Function(String id, Object? value) reply,
    required void Function(String id, String message, {String? status}) reject,
  }) => ScriptPastCalls(
    past: request.past,
    readOnly: request.readOnly,
    buckets: buckets,
    workspaceId: request.workspaceId,
    ended: ended,
    mayStart: mayStart,
    reply: reply,
    reject: reject,
  );

  final ScriptPastPort? _past;
  final bool _readOnly;
  final WorkspaceLookupBuckets _buckets;
  final String _workspaceId;
  final bool Function() _ended;
  final Future<void> Function() _mayStart;
  final void Function(String id, Object? value) _reply;
  final void Function(String id, String message, {String? status}) _reject;

  /// The host function names this class answers.
  static const Set<String> names = {'history', 'outputs', 'loadOutput', 'keep'};

  /// Why the calls are unavailable where the surface binds no [ScriptPastPort].
  static const String unavailable =
      'history(), outputs(), loadOutput() and keep() are not available here: '
      'this surface keeps no transcript or output store of the run.';

  /// Why a read-only run's script may not store a value (the runner's own
  /// refusal only names a zero size limit).
  static const String readOnlyStore =
      'store() is not available in a read-only run: nothing it does may '
      'outlive the run, so store() throws. load() and storedKeys() still '
      'read what earlier runs stored.';

  /// Why a read-only run's script may not keep a value.
  static const String readOnlyKeep =
      'keep() is not available in a read-only run: nothing it does may '
      'outlive the run. Return what you found instead.';

  Future<void> _tail = Future<void>.value();
  int _reads = 0;
  int _readBytes = 0;

  /// Values this script kept, by handle, in the order it kept them.
  final Map<String, ({String label, String content, int bytes})> _staged = {};

  /// Values this script kept that are not written yet.
  int get stagedCount => _staged.length;

  /// Answers the host call [call] after the calls the script made before it.
  Future<void> answer(CodeSandboxCall call) {
    final next = _tail.then((_) => _answerNow(call));
    _tail = next.catchError((Object _) {});
    return next;
  }

  Future<void> _answerNow(CodeSandboxCall call) async {
    if (_ended()) {
      return;
    }
    final past = _past;
    if (past == null) {
      _reject(call.id, unavailable, status: 'unavailable');
      return;
    }
    if (call.name == 'keep') {
      _keep(call, past);
      return;
    }
    final refusal = _readRefusal(call.name, call.arguments, past);
    if (refusal != null) {
      _reject(call.id, refusal.$1, status: refusal.$2);
      return;
    }
    await _mayStart();
    if (_ended()) {
      return;
    }
    _reads++;
    final clock = Stopwatch()..start();
    try {
      final value = await _read(call, past);
      if (_ended()) {
        return;
      }
      if (value is _Refused) {
        _reject(call.id, value.message, status: value.status);
        return;
      }
      final bytes = utf8Length(jsonEncode(value));
      final overrun = _overrun(bytes, past);
      if (overrun != null) {
        _reject(call.id, overrun, status: kScriptLimitStatus);
        return;
      }
      _readBytes += bytes;
      past.usage.readBytes += bytes;
      _reply(call.id, value);
    } on ScriptPastRefusal catch (e) {
      _reject(call.id, e.message);
    } on Object catch (e, st) {
      // A store's or a database's error can name a host path: it goes to
      // the log, and the script is told only that the read failed.
      CcInfraLog.error('code mode: ${call.name} failed', e, st);
      _reject(call.id, '${call.name}() failed on the server.');
    } finally {
      _buckets.charge(_workspaceId, clock.elapsedMicroseconds);
    }
  }

  /// Why a read is refused before any work, with its status, or null.
  (String, String?)? _readRefusal(
    String name,
    Map<String, dynamic> args,
    ScriptPastPort past,
  ) {
    if (_reads >= CodeModeLimits.maxPastReads) {
      return (
        'This script has made ${CodeModeLimits.maxPastReads} reads of the '
            "run's past (history, outputs, loadOutput), its limit. Return what "
            'you have and continue in another script.',
        kScriptLimitStatus,
      );
    }
    final overrun = _overrun(0, past);
    if (overrun != null) {
      return (overrun, kScriptLimitStatus);
    }
    if (!_buckets.hasTime(_workspaceId)) {
      return (
        'The lookup budget of this workspace is used up for now: the '
            'scripts of one workspace share ${_buckets.capacity.inMilliseconds} '
            'ms of server time for lookups and reads of the past, given back at '
            '${_buckets.refillPerSecond.inMilliseconds} ms per second. Keep what '
            'a read returned, or try again in a later script.',
        kScriptLimitStatus,
      );
    }
    final problem = switch (name) {
      'history' => _historyArgs(args).problem,
      'outputs' => _outputsArgs(args).problem,
      _ => _loadArgs(args).problem,
    };
    return problem == null ? null : (problem, null);
  }

  /// Why [bytes] more would cross the script's or the run's bound, or null.
  String? _overrun(int bytes, ScriptPastPort past) {
    const perScript = CodeModeLimits.maxPastReadBytesPerScript;
    const perRun = CodeModeLimits.maxPastReadBytesPerRun;
    if (_readBytes + bytes > perScript ||
        (bytes == 0 && _readBytes >= perScript)) {
      return 'This script has read ${perScript ~/ (1024 * 1024)} MiB of the '
          "run's past, its limit (this read would pass it). Return what you "
          'have, or read less: a role or tool filter, a smaller limit.';
    }
    if (past.usage.readBytes + bytes > perRun ||
        (bytes == 0 && past.usage.readBytes >= perRun)) {
      return "This run's scripts have read ${perRun ~/ (1024 * 1024)} MiB of "
          'its past, its limit. Work from what you already read.';
    }
    return null;
  }

  Future<Object?> _read(CodeSandboxCall call, ScriptPastPort past) async {
    final args = call.arguments;
    switch (call.name) {
      case 'history':
        final q = _historyArgs(args);
        final row = q.row;
        if (row != null) {
          final slice = await past.historyRow(rowId: row, offset: q.offset);
          if (slice == null) {
            return _Refused(
              'No row "$row" in this transcript, or offset ${q.offset} is '
                  'past its end.',
              'not_found',
            );
          }
          return slice.toJson();
        }
        final page = await past.history(
          start: q.start,
          limit: q.limit,
          roles: q.roles,
          tools: q.tools,
        );
        return page.toJson();
      case 'outputs':
        final q = _outputsArgs(args);
        final all = [
          for (final e in await past.outputs())
            if (q.tool == null || e.toolName == q.tool) e,
        ];
        return {
          'outputs': [
            for (final e in all.take(q.limit))
              {
                'handle': e.handle,
                'tool': e.toolName,
                'label': ?e.label,
                'chars': e.chars,
                'bytes': e.bytes,
                'is_error': e.isError,
                'at': e.createdAt.toUtc().toIso8601String(),
              },
          ],
          'total': all.length,
        };
      default:
        final q = _loadArgs(args);
        final staged = _staged[q.handle];
        if (staged != null) {
          return _page(q.handle, staged.content, q.offset, q.limit);
        }
        final read = await past.readOutput(
          q.handle,
          offset: q.offset,
          limit: q.limit,
        );
        final chunk = read.chunk;
        if (read.status != ToolOutputReadStatus.ok || chunk == null) {
          return _Refused(
            'No stored output "${q.handle}" that this run can read.',
            'not_found',
          );
        }
        return {
          'handle': q.handle,
          'text': chunk.text,
          'offset': chunk.offsetChars,
          'total_chars': chunk.totalChars,
          'next_offset': chunk.hasMore ? chunk.nextOffsetChars : null,
        };
    }
  }

  static Map<String, Object?> _page(
    String handle,
    String content,
    int offset,
    int limit,
  ) {
    // Never split a surrogate pair: a page starts on a pair's high half and
    // the next page starts with it (a page of one unit inside a pair is the
    // whole pair).
    final start = safeCutBefore(content, offset);
    var end = safeCutBefore(content, start + limit);
    if (end <= start && start < content.length) {
      end = safeCutAfter(content, start + 1);
    }
    return {
      'handle': handle,
      'text': content.substring(start, end),
      'offset': start,
      'total_chars': content.length,
      'next_offset': end < content.length ? end : null,
    };
  }

  // ---------------------------------------------------------------------
  // keep

  void _keep(CodeSandboxCall call, ScriptPastPort past) {
    if (_readOnly) {
      _reject(call.id, readOnlyKeep, status: 'read_only');
      return;
    }
    if (past.noOutputs case final why?) {
      _reject(call.id, why);
      return;
    }
    final args = call.arguments;
    final label = args['label'];
    if (!args.containsKey('value') || label is! String) {
      _reject(
        call.id,
        'keep(value, label) needs a JSON value and a string label.',
      );
      return;
    }
    final trimmed = label.trim();
    if (trimmed.isEmpty ||
        trimmed.length > CodeModeLimits.maxKeepLabelUnits ||
        hasUnsafeCharacters(trimmed)) {
      _reject(
        call.id,
        'keep() needs a label of 1 to ${CodeModeLimits.maxKeepLabelUnits} '
        'characters on one line.',
      );
      return;
    }
    final value = args['value'];
    final content = value is String ? value : jsonEncode(value);
    final bytes = utf8Length(content);
    if (bytes > CodeModeLimits.maxCallArgumentBytes) {
      _reject(
        call.id,
        'The value is $bytes bytes; keep() takes at most '
        '${CodeModeLimits.maxCallArgumentBytes ~/ (1024 * 1024)} MiB a value. '
        'Keep it in parts.',
      );
      return;
    }
    final stagedBytes = _staged.values.fold<int>(0, (n, v) => n + v.bytes);
    if (past.usage.keeps + _staged.length >= CodeModeLimits.maxKeepsPerRun ||
        past.usage.keptBytes + stagedBytes + bytes >
            CodeModeLimits.maxKeptBytesPerRun) {
      _reject(
        call.id,
        "This run's scripts may keep ${CodeModeLimits.maxKeepsPerRun} values "
        'of '
        '${CodeModeLimits.maxKeptBytesPerRun ~/ (1024 * 1024)} MiB together, '
        'and this one would pass that. Keep less: a digest, or the part a '
        'later script needs.',
        status: kScriptLimitStatus,
      );
      return;
    }
    final handle = newToolOutputHandle();
    _staged[handle] = (label: trimmed, content: content, bytes: bytes);
    _reply(call.id, {
      'handle': handle,
      'label': trimmed,
      'chars': content.length,
    });
  }

  /// Whether this script may `keep()`: a run that may write, with an output
  /// store.
  bool get _keeps => !_readOnly && _past != null && _past.noOutputs == null;

  /// Why a tool call past the call [limit] was refused, naming `store()`
  /// only where the script may store.
  String callLimit(int limit) =>
      ScriptFixHints.callLimit(limit, stores: !_readOnly);

  /// [detail] with the fix for [errorKind], naming `store()` and `keep()`
  /// only where the script may use them ([ScriptFixHints.withFix]).
  String? withFix(String? detail, String? errorKind) => ScriptFixHints.withFix(
    detail,
    errorKind,
    stores: !_readOnly,
    keeps: _keeps,
  );

  /// Writes the values this script kept when it ended [status]
  /// `completed`, and drops them otherwise. Returns the notes for the
  /// result: one for each value the store declined, or one saying the kept
  /// values were dropped.
  Future<List<String>> settle(CodeExecutionStatus status) async {
    if (status == CodeExecutionStatus.completed) {
      return commit();
    }
    if (_staged.isEmpty) {
      return const [];
    }
    final count = _staged.length;
    _staged.clear();
    final note =
        'The $count ${count == 1 ? 'value' : 'values'} passed to keep() '
        'were not saved, because the script did not complete; loadOutput '
        'will not find ${count == 1 ? 'it' : 'them'}.';
    return [note];
  }

  /// Writes the values this script kept, after it completed. Returns the
  /// notes for the result: one for each value the store declined.
  Future<List<String>> commit() async {
    final past = _past;
    if (past == null || _staged.isEmpty) {
      return const [];
    }
    final notes = <String>[];
    for (final MapEntry(key: handle, value: v) in _staged.entries) {
      var kept = false;
      try {
        kept = await past.keep(
          handle: handle,
          label: v.label,
          content: v.content,
        );
      } on Object catch (e, st) {
        CcInfraLog.error('code mode: keeping a value failed', e, st);
      }
      if (kept) {
        past.usage.keeps++;
        past.usage.keptBytes += v.bytes;
      } else {
        notes.add(
          'The value kept as "${v.label}" ($handle) could not be saved; '
          'loadOutput will not find it.',
        );
      }
    }
    _staged.clear();
    return notes;
  }

  // ---------------------------------------------------------------------
  // Arguments

  static const Set<String> _roles = {
    'person',
    'agent',
    'tool',
    'system',
    'compaction',
  };

  /// The most names one `role` or `tool` filter may hold.
  static const int maxFilterNames = 32;

  static ({
    String? problem,
    String? start,
    int limit,
    Set<TranscriptRole>? roles,
    Set<String>? tools,
    String? row,
    int offset,
  })
  _historyArgs(Map<String, dynamic> args) {
    const usage =
        'history({ start, limit, role, tool }) takes no start (or 0) or a '
        "page's next_start, a limit of 1 to "
        '${CodeModeLimits.maxHistoryRows}, a role or tool name or an array of '
        'them; history({ row, offset }) one row id and an '
        'offset of 0 or more.';
    ({
      String? problem,
      String? start,
      int limit,
      Set<TranscriptRole>? roles,
      Set<String>? tools,
      String? row,
      int offset,
    })
    bad([String why = usage]) => (
      problem: why,
      start: null,
      limit: 0,
      roles: null,
      tools: null,
      row: null,
      offset: 0,
    );
    // 0 is the first page, as no start is.
    final start = args['start'] == 0 ? null : args['start'];
    final limit = args['limit'] ?? CodeModeLimits.maxHistoryRows;
    final row = args['row'];
    final offset = args['offset'] ?? 0;
    if ((start != null &&
            (start is! String || !TranscriptCursor.isWellFormed(start))) ||
        limit is! int ||
        limit < 1 ||
        limit > CodeModeLimits.maxHistoryRows ||
        offset is! int ||
        offset < 0 ||
        (row != null && (row is! String || row.isEmpty || row.length > 512))) {
      return bad();
    }
    final roleNames = _names(args['role']);
    final toolNames = _names(args['tool']);
    if (roleNames == null || toolNames == null) {
      return bad();
    }
    if (roleNames.any((r) => !_roles.contains(r))) {
      return bad(
        'history role must be person, agent, tool, system or compaction.',
      );
    }
    return (
      problem: null,
      start: start as String?,
      limit: limit,
      roles: roleNames.isEmpty
          ? null
          : {for (final r in roleNames) TranscriptRole.tryParse(r)!},
      tools: toolNames.isEmpty ? null : toolNames.toSet(),
      row: row as String?,
      offset: offset,
    );
  }

  static ({String? problem, int limit, String? tool}) _outputsArgs(
    Map<String, dynamic> args,
  ) {
    final limit = args['limit'] ?? CodeModeLimits.maxHistoryRows;
    final tool = args['tool'];
    if (limit is! int ||
        limit < 1 ||
        limit > CodeModeLimits.maxHistoryRows ||
        (tool != null &&
            (tool is! String ||
                tool.length > CodeModeLimits.maxLookupNameUnits))) {
      return (
        problem:
            'outputs({ limit, tool }) takes a limit of 1 to '
            '${CodeModeLimits.maxHistoryRows} and a tool name.',
        limit: 0,
        tool: null,
      );
    }
    return (problem: null, limit: limit, tool: tool as String?);
  }

  static ({String? problem, String handle, int offset, int limit}) _loadArgs(
    Map<String, dynamic> args,
  ) {
    final handle = args['handle'];
    final offset = args['offset'] ?? 0;
    final limit = args['limit'] ?? CodeModeLimits.maxLoadOutputChars;
    if (handle is! String ||
        handle.length > 128 ||
        !isToolOutputHandle(handle) ||
        offset is! int ||
        offset < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > CodeModeLimits.maxLoadOutputChars) {
      return (
        problem:
            'loadOutput(handle, { offset, limit }) takes a handle such as '
            '"out_…", an offset of 0 or more and a limit of 1 to '
            '${CodeModeLimits.maxLoadOutputChars}.',
        handle: '',
        offset: 0,
        limit: 0,
      );
    }
    return (problem: null, handle: handle, offset: offset, limit: limit);
  }

  /// [raw] as a list of names: absent is empty, a string is one, an array
  /// of at most [maxFilterNames] short strings is itself; null otherwise.
  static List<String>? _names(Object? raw) {
    final list = switch (raw) {
      null => const <Object?>[],
      final String s => [s],
      final List<dynamic> l => l,
      _ => null,
    };
    if (list == null || list.length > maxFilterNames) {
      return null;
    }
    final names = <String>[];
    for (final n in list) {
      if (n is! String ||
          n.isEmpty ||
          n.length > CodeModeLimits.maxLookupNameUnits) {
        return null;
      }
      names.add(n);
    }
    return names;
  }
}

/// A read that found nothing to hand the script.
class _Refused {
  const _Refused(this.message, this.status);

  final String message;
  final String status;
}
