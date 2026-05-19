import 'dart:async';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/dap/dap_adapter_registry.dart';
import 'package:cc_infra/src/dap/dap_client.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:path/path.dart' as p;

/// Drives a real debugger: breakpoints, stepping, stack frames, variables.
///
/// **What it replaces.** Adding a print statement, running the whole thing
/// again, reading the output, deleting the print statement. That loop costs a
/// full test run per question and only answers the question you thought to ask
/// before running. A stopped frame answers every question about that moment at
/// once — every local, every caller, and an expression evaluated in the frame's
/// own scope.
///
/// **Bounded output on purpose.** A `variables` expansion on a deep object
/// graph is unbounded by nature: one Flutter widget can reach the whole element
/// tree. Children per scope, string length and expansion depth are all capped,
/// the same discipline `read` and `grep` already apply, because a tool result
/// that fills the context window is a tool that ends the run it was helping.
class DebugTool extends HarnessTool {
  /// Creates a [DebugTool].
  DebugTool({
    required DebugSessionSupervisor supervisor,
    required String workingDirectory,
    required String sessionKey,
    Map<String, String>? environment,
  }) : _supervisor = supervisor,
       _workingDirectory = workingDirectory,
       _sessionKey = sessionKey,
       _environment = environment;

  final DebugSessionSupervisor _supervisor;
  final String _workingDirectory;
  final String _sessionKey;
  final Map<String, String>? _environment;

  /// Max children returned per `variables` call.
  static const int maxChildren = 50;

  /// Max characters of any one variable's rendered value.
  static const int maxValueChars = 400;

  /// Max stack frames returned.
  static const int maxFrames = 30;

  @override
  String get name => 'debug';

  @override
  String get description =>
      'Drive a debugger instead of adding print statements. `launch` starts a '
      'program stopped at your breakpoints; `stack`, `scopes`, `variables` and '
      '`evaluate` read the stopped frame; `step_over` / `step_in` / '
      '`step_out` / `continue` move it. Set breakpoints BEFORE launching. '
      'Always `terminate` when done.';

  /// Exec tier: launching a debuggee starts a process, and attaching takes
  /// control of one.
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;

  @override
  Set<ActionClass> get actionClasses => const {ActionClass.processSpawn};

  /// A debug session is stateful across calls, so two `debug` calls in one
  /// turn must not race: `continue` overtaking `stack` reads a frame that has
  /// already moved.
  @override
  bool get parallelSafe => false;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'op': {
        'type': 'string',
        'enum': [
          'status',
          'adapters',
          'breakpoints',
          'launch',
          'attach',
          'continue',
          'pause',
          'step_over',
          'step_in',
          'step_out',
          'threads',
          'stack',
          'scopes',
          'variables',
          'evaluate',
          'output',
          'terminate',
        ],
        'description': 'What to do.',
      },
      'program': {
        'type': 'string',
        'description': 'launch: the entrypoint to run, relative to the repo.',
      },
      'args': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'launch: arguments for the program.',
      },
      'port': {
        'type': 'integer',
        'description': 'attach: the debug port to connect to.',
      },
      'file': {
        'type': 'string',
        'description': 'breakpoints: the source file they belong to.',
      },
      'lines': {
        'type': 'array',
        'items': {'type': 'integer'},
        'description':
            'breakpoints: 1-indexed lines. An empty list clears the file.',
      },
      'thread_id': {
        'type': 'integer',
        'description': 'Which thread to act on.',
      },
      'frame_id': {
        'type': 'integer',
        'description': 'scopes/evaluate: the frame, from `stack`.',
      },
      'reference': {
        'type': 'integer',
        'description': 'variables: the variablesReference from scopes.',
      },
      'expression': {
        'type': 'string',
        'description': 'evaluate: an expression in the frame\'s own scope.',
      },
    },
    'required': ['op'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final op = args['op'];
    if (op is! String || op.isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: op');
    }

    try {
      switch (op) {
        case 'adapters':
          return _adapters();
        case 'status':
          return _status();
        case 'launch':
          return await _launch(args);
        case 'attach':
          return await _attach(args);
        case 'terminate':
          await _supervisor.stop(_sessionKey);
          return HarnessToolResult.success('Debug session terminated.');
        default:
          return await _onSession(op, args);
      }
    } on DapException catch (e) {
      return HarnessToolResult.error('${e.command} failed: ${e.message}');
    } on TimeoutException {
      return HarnessToolResult.error(
        'The debug adapter did not answer in time. It may be waiting on the '
        'debuggee — try `pause`, or `terminate` and start again.',
      );
    } on StateError catch (e) {
      return HarnessToolResult.error(e.message);
    }
  }

  HarnessToolResult _adapters() {
    final found = detectDapAdapters(_workingDirectory);
    if (found.isEmpty) {
      return HarnessToolResult.success(
        'No debug adapter is usable here. An adapter needs BOTH a project '
        'marker in the checkout and its binary installed.',
      );
    }
    return HarnessToolResult.success(
      'Available: ${found.map((a) => '${a.spec.id} (${a.executable})').join(', ')}.',
    );
  }

  HarnessToolResult _status() {
    final session = _supervisor.sessionFor(_sessionKey);
    if (session == null) {
      return HarnessToolResult.success('No debug session is running.');
    }
    final stop = session.lastStop;
    return HarnessToolResult.success(
      'Session ${session.id} on ${session.adapter.spec.id}, '
      '${stop == null ? 'running' : 'stopped (${stop.reason}'
                '${stop.description == null ? '' : ': ${stop.description}'})'}. '
      'Started ${DateTime.now().difference(session.startedAt).inSeconds}s ago.',
    );
  }

  Future<HarnessToolResult> _launch(Map<String, dynamic> args) async {
    final program = args['program'];
    if (program is! String || program.isEmpty) {
      return HarnessToolResult.error('launch needs `program`.');
    }
    final adapters = detectDapAdapters(_workingDirectory);
    final adapter =
        adapterForPath(program, adapters) ??
        (adapters.isEmpty ? null : adapters.first);
    if (adapter == null) {
      return HarnessToolResult.error(
        'No debug adapter is usable here — run `debug` with op "adapters" to '
        'see why.',
      );
    }

    final session = await _supervisor.start(
      key: _sessionKey,
      adapter: adapter,
      workingDirectory: _workingDirectory,
      environment: _environment,
    );
    // The DAP configuration sequence, in the order the spec requires:
    // `launch` is sent without awaiting its response (several adapters do not
    // answer it until the program terminates), then we wait for the
    // `initialized` EVENT before sending breakpoints, then
    // `configurationDone`. Sending breakpoints before that event is the
    // classic mistake — the adapter drops them, the program runs to
    // completion, and a breakpoint that never fires is indistinguishable from
    // code that never ran.
    unawaited(
      session.client
          .request('launch', {
            ...adapter.spec.launchDefaults,
            'program': p.isAbsolute(program)
                ? program
                : p.join(_workingDirectory, program),
            'args':
                (args['args'] as List?)?.whereType<String>().toList() ??
                const <String>[],
            'cwd': _workingDirectory,
          }, const Duration(minutes: 2))
          .catchError((Object _) => const <String, dynamic>{}),
    );
    await session.waitInitialized();
    await _replayBreakpoints(session);
    await session.configurationDone();

    // A launch either stops somewhere or runs to completion; both are answers,
    // and waiting forever for a `stopped` that is never coming is not.
    final stop = await _awaitStopOrExit(session);
    return HarnessToolResult.success(
      'Launched $program on ${adapter.spec.id} (session ${session.id}). $stop',
    );
  }

  Future<HarnessToolResult> _attach(Map<String, dynamic> args) async {
    final port = args['port'];
    if (port is! int) {
      return HarnessToolResult.error('attach needs `port`.');
    }
    final adapters = detectDapAdapters(_workingDirectory);
    if (adapters.isEmpty) {
      return HarnessToolResult.error('No debug adapter is usable here.');
    }
    final session = await _supervisor.start(
      key: _sessionKey,
      adapter: adapters.first,
      workingDirectory: _workingDirectory,
      environment: _environment,
    );
    await session.client.request('attach', {
      ...adapters.first.spec.launchDefaults,
      'port': port,
      'cwd': _workingDirectory,
    }, const Duration(seconds: 30));
    await session.waitInitialized();
    await _replayBreakpoints(session);
    await session.configurationDone();
    return HarnessToolResult.success(
      'Attached to port $port (session ${session.id}).',
    );
  }

  Future<HarnessToolResult> _onSession(
    String op,
    Map<String, dynamic> args,
  ) async {
    final session = _supervisor.sessionFor(_sessionKey);
    if (session == null) {
      // Breakpoints are the exception: setting them before a launch is the
      // documented order, so they are remembered and replayed rather than
      // refused for want of a session that does not exist yet.
      if (op == 'breakpoints') {
        return _stageBreakpoints(args);
      }
      return HarnessToolResult.error(
        'No debug session is running. Use op "launch" or "attach" first.',
      );
    }

    switch (op) {
      case 'breakpoints':
        final staged = _stageBreakpoints(args);
        if (staged.isError) {
          return staged;
        }
        return _applyBreakpoints(session, args['file'] as String);
      case 'continue':
        await session.client.request('continue', {
          'threadId': _threadId(args, session) ?? 0,
        });
        return HarnessToolResult.success(
          'Continued. ${await _awaitStopOrExit(session)}',
        );
      case 'pause':
        await session.client.request('pause', {
          'threadId': _threadId(args, session) ?? 0,
        });
        return HarnessToolResult.success(await _awaitStopOrExit(session));
      case 'step_over':
      case 'step_in':
      case 'step_out':
        const command = {
          'step_over': 'next',
          'step_in': 'stepIn',
          'step_out': 'stepOut',
        };
        await session.client.request(command[op]!, {
          'threadId': _threadId(args, session) ?? 0,
        });
        return HarnessToolResult.success(await _awaitStopOrExit(session));
      case 'threads':
        return _threads(session);
      case 'stack':
        return _stack(session, args);
      case 'scopes':
        return _scopes(session, args);
      case 'variables':
        return _variables(session, args);
      case 'evaluate':
        return _evaluate(session, args);
      case 'output':
        final out = session.output;
        return HarnessToolResult.success(
          out.isEmpty ? 'No output yet.' : out.join('\n'),
        );
      default:
        return HarnessToolResult.error('Unknown op: $op');
    }
  }

  // ---- breakpoints ----

  /// Breakpoints the model set, per file.
  ///
  /// Held here rather than in the session because they legitimately outlive
  /// one: the DAP order is "set breakpoints, launch, configurationDone", so a
  /// breakpoint set before a session exists is not a mistake to refuse — it is
  /// the intended sequence, and the only place to keep it is here.
  final Map<String, List<int>> _breakpoints = {};

  HarnessToolResult _stageBreakpoints(Map<String, dynamic> args) {
    final file = args['file'];
    if (file is! String || file.isEmpty) {
      return HarnessToolResult.error('breakpoints needs `file`.');
    }
    final lines =
        (args['lines'] as List?)
            ?.whereType<num>()
            .map((n) => n.toInt())
            .where((n) => n > 0)
            .toList() ??
        const <int>[];
    final absolute = p.isAbsolute(file)
        ? file
        : p.join(_workingDirectory, file);
    if (lines.isEmpty) {
      _breakpoints.remove(absolute);
      return HarnessToolResult.success('Cleared breakpoints in $file.');
    }
    _breakpoints[absolute] = lines;
    return HarnessToolResult.success(
      'Set ${lines.length} breakpoint(s) in $file at ${lines.join(', ')}. '
      'They apply on the next launch.',
    );
  }

  Future<void> _replayBreakpoints(DebugSession session) async {
    for (final entry in _breakpoints.entries) {
      try {
        final body = await session.client.request('setBreakpoints', {
          'source': {'path': entry.key},
          'breakpoints': [
            for (final line in entry.value) {'line': line},
          ],
        });
        // An accepted-but-unbound breakpoint confirms later with an event.
        // The session holds the program's entry pause until it does, so it
        // cannot run past a breakpoint that was still resolving.
        session.noteBreakpoints([
          for (final b in (body['breakpoints'] as List?) ?? const [])
            if (b is Map && b['id'] is num)
              (id: (b['id'] as num).toInt(), verified: b['verified'] == true),
        ]);
      } on Object {
        // One file's breakpoints failing must not abort the launch: the
        // adapter usually rejects a path it does not own, which is a mistake
        // in ONE breakpoint, not in the session.
      }
    }
  }

  Future<HarnessToolResult> _applyBreakpoints(
    DebugSession session,
    String file,
  ) async {
    final absolute = p.isAbsolute(file)
        ? file
        : p.join(_workingDirectory, file);
    final body = await session.client.request('setBreakpoints', {
      'source': {'path': absolute},
      'breakpoints': [
        for (final line in _breakpoints[absolute] ?? const <int>[])
          {'line': line},
      ],
    });
    final verified = (body['breakpoints'] as List?) ?? const [];
    final ok = verified.where((b) => b is Map && b['verified'] == true).length;
    return HarnessToolResult.success(
      // The unverified count matters: a breakpoint the adapter could not bind
      // never fires, and "I set it and nothing happened" is indistinguishable
      // from "the code never runs" unless this is said out loud.
      '$ok of ${verified.length} breakpoint(s) bound in $file'
      '${ok == verified.length ? '.' : ' — the rest could not be placed on '
                'those lines (blank, comment, or not compiled).'}',
    );
  }

  // ---- reads ----

  int? _threadId(Map<String, dynamic> args, DebugSession session) {
    final explicit = args['thread_id'];
    if (explicit is int) {
      return explicit;
    }
    return session.lastStop?.threadId;
  }

  Future<HarnessToolResult> _threads(DebugSession session) async {
    final body = await session.client.request('threads');
    final threads = (body['threads'] as List?) ?? const [];
    if (threads.isEmpty) {
      return HarnessToolResult.success('No threads.');
    }
    return HarnessToolResult.success(
      threads
          .whereType<Map>()
          .map((t) => '${t['id']}: ${t['name']}')
          .join('\n'),
    );
  }

  Future<HarnessToolResult> _stack(
    DebugSession session,
    Map<String, dynamic> args,
  ) async {
    var threadId = _threadId(args, session);
    if (threadId == null) {
      return HarnessToolResult.error(
        'Not stopped anywhere — nothing has a stack. Pass `thread_id`, or wait '
        'for a breakpoint.',
      );
    }
    // A `stackTrace` that FAILS is the same race as one that comes back empty,
    // so it feeds the same recovery instead of aborting the op. The adapter
    // answers with a `Collected` sentinel when the isolate id it is holding has
    // gone — which happens transiently on a loaded machine between the
    // `stopped` event and the pause being queryable. The last error is kept so
    // a genuine failure still reports itself rather than degrading into the
    // indistinguishable "Empty stack."
    Object? lastError;
    Future<List<Map>> framesOrEmpty(int id) async {
      try {
        return await _framesFor(session, id);
      } on Object catch (e) {
        lastError = e;
        return const [];
      }
    }

    var frames = await framesOrEmpty(threadId);
    // A stopped thread with no frames is a race, not an answer: the Dart
    // adapter can emit the `stopped` event before the isolate's pause is
    // queryable, and the first `stackTrace` then comes back empty. Retry so a
    // stopped-at-a-breakpoint thread doesn't read as "nowhere".
    for (var attempt = 0; attempt < 10 && frames.isEmpty; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      frames = await framesOrEmpty(threadId);
    }
    // Still nothing: the stop's thread may simply never answer with frames
    // (a pause that moved, or an adapter that reports the stop for a thread it
    // will not serve). Scan every thread — only a PAUSED thread answers with
    // frames, so the first non-empty stack IS the stopped one.
    if (frames.isEmpty) {
      try {
        final threads =
            (await session.client.request('threads'))['threads'] as List? ??
            const [];
        for (final thread in threads.whereType<Map>()) {
          final id = (thread['id'] as num?)?.toInt();
          if (id == null || id == threadId) {
            continue;
          }
          final scanned = await framesOrEmpty(id);
          if (scanned.isNotEmpty) {
            threadId = id;
            frames = scanned;
            break;
          }
        }
      } on Object {
        // The session answered nothing; the empty-stack report below stands.
      }
    }
    if (frames.isEmpty) {
      if (lastError != null) {
        // Every thread refused. Report WHY — an adapter error and a genuinely
        // empty stack are different problems and used to read identically.
        return HarnessToolResult.error('$lastError');
      }
      return HarnessToolResult.success('Empty stack.');
    }
    final lines = <String>[];
    for (final frame in frames.whereType<Map>()) {
      final source = frame['source'];
      final path = source is Map ? source['path'] : null;
      final relative = path is String
          ? p.relative(path, from: _workingDirectory)
          : '<unknown>';
      lines.add(
        '#${frame['id']} ${frame['name']} '
        '($relative:${frame['line']}:${frame['column']})',
      );
    }
    return HarnessToolResult.success(lines.join('\n'));
  }

  /// The stack frames of [threadId], top-first.
  Future<List<Map>> _framesFor(DebugSession session, int threadId) async {
    final body = await session.client.request('stackTrace', {
      'threadId': threadId,
      'startFrame': 0,
      'levels': maxFrames,
    });
    return (body['stackFrames'] as List?)?.whereType<Map>().toList() ??
        const [];
  }

  Future<HarnessToolResult> _scopes(
    DebugSession session,
    Map<String, dynamic> args,
  ) async {
    final frameId = args['frame_id'];
    if (frameId is! int) {
      return HarnessToolResult.error('scopes needs `frame_id` from `stack`.');
    }
    final body = await session.client.request('scopes', {'frameId': frameId});
    final scopes = (body['scopes'] as List?) ?? const [];
    if (scopes.isEmpty) {
      return HarnessToolResult.success('No scopes on that frame.');
    }
    return HarnessToolResult.success(
      scopes
          .whereType<Map>()
          .map(
            (s) =>
                '${s['name']} (reference ${s['variablesReference']}'
                '${s['expensive'] == true ? ', expensive' : ''})',
          )
          .join('\n'),
    );
  }

  Future<HarnessToolResult> _variables(
    DebugSession session,
    Map<String, dynamic> args,
  ) async {
    final reference = args['reference'];
    if (reference is! int) {
      return HarnessToolResult.error(
        'variables needs `reference` from `scopes` (or from another variable).',
      );
    }
    final body = await session.client.request('variables', {
      'variablesReference': reference,
      'count': maxChildren,
    });
    final variables = (body['variables'] as List?) ?? const [];
    if (variables.isEmpty) {
      return HarnessToolResult.success('No variables.');
    }
    final lines = <String>[];
    for (final v in variables.take(maxChildren).whereType<Map>()) {
      final value = '${v['value']}';
      final type = v['type'];
      final childRef = (v['variablesReference'] as num?)?.toInt() ?? 0;
      lines.add(
        '${v['name']}'
        '${type == null ? '' : ' ($type)'} = '
        '${value.length > maxValueChars ? '${value.substring(0, maxValueChars)}…' : value}'
        // Only offered when there is something behind it: an expandable
        // reference the model cannot use is an invitation to a wasted call.
        '${childRef > 0 ? '  [expand: reference $childRef]' : ''}',
      );
    }
    if (variables.length > maxChildren) {
      lines.add('… ${variables.length - maxChildren} more');
    }
    return HarnessToolResult.success(lines.join('\n'));
  }

  Future<HarnessToolResult> _evaluate(
    DebugSession session,
    Map<String, dynamic> args,
  ) async {
    final expression = args['expression'];
    if (expression is! String || expression.isEmpty) {
      return HarnessToolResult.error('evaluate needs `expression`.');
    }
    final body = await session.client.request('evaluate', {
      'expression': expression,
      'frameId': ?args['frame_id'],
      'context': 'repl',
    });
    final result = '${body['result']}';
    return HarnessToolResult.success(
      result.length > maxValueChars
          ? '${result.substring(0, maxValueChars)}…'
          : result,
    );
  }

  Future<String> _awaitStopOrExit(DebugSession session) async {
    if (session.isTerminated) {
      return 'The program exited.';
    }
    try {
      final stop = await session.stops.first.timeout(
        const Duration(seconds: 30),
      );
      return 'Stopped: ${stop.reason}'
          '${stop.description == null ? '' : ' (${stop.description})'}'
          '${stop.text == null ? '' : ' — ${stop.text}'}. '
          'Use `stack` to see where.';
    } on TimeoutException {
      return session.isTerminated
          ? 'The program exited.'
          : 'Still running — it has not hit a breakpoint. Use `pause` to stop '
                'it where it is.';
    }
  }
}
