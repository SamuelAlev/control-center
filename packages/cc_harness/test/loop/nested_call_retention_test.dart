import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// What the loop keeps of the calls a tool makes through its reentry until
/// the turn ends: never their arguments, only a bounded digest and what the
/// checklist reads of a checklist write. The guards that read nested calls
/// still do their job.
void main() {
  group('a script\'s calls leave nothing large behind until the turn ends', () {
    /// Runs the fixture under a heap far smaller than the arguments the run
    /// sends in total; it completes only when no call's arguments outlive it.
    Future<void> expectCompletesUnderCap(String shape) async {
      final packages = (await Isolate.packageConfig)!.toFilePath();
      const fixture = 'test/loop/fixtures/nested_retention_main.dart';
      final result = await Process.run(Platform.resolvedExecutable, [
        '--old_gen_heap_size=160',
        '--packages=$packages',
        fixture,
        shape,
      ]);
      expect(
        (result.exitCode, (result.stdout as String).trim()),
        (0, 'ok'),
        reason: '${result.stderr}',
      );
    }

    test(
      '300 calls of about 1 MB each',
      () => expectCompletesUnderCap('strings'),
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      '150 calls of small JSON that decodes large (lists of empty objects)',
      () => expectCompletesUnderCap('maps'),
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      '150 checklist writes of long lists',
      () => expectCompletesUnderCap('checklist'),
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });

  group('the checklist reads a script\'s writes', () {
    test('a script that writes the checklist counts as a write, and the '
        'nudge later quotes the item it left in progress', () async {
      final run = await _run(
        turns: 4,
        nested: (turn) => turn == 0
            ? [
                (
                  'todo_write',
                  {
                    'todos': [
                      {'content': 'Write the tests', 'status': 'completed'},
                      {'content': 'Port the parser', 'status': 'in_progress'},
                      {'content': 'Ship it', 'status': 'pending'},
                    ],
                  },
                ),
              ]
            : [('noop', const {})],
      );
      expect(run.notices, contains(contains('Task checklist is stale')));
      expect(run.steers.single, contains('"Port the parser" as in_progress'));
    });

    test('the last write in call order is the one that counts: a later write '
        'that closes everything leaves nothing to nudge about', () async {
      final run = await _run(
        turns: 4,
        nested: (turn) => turn == 0
            ? [
                (
                  'todo_write',
                  {
                    'todos': [
                      {'content': 'Port the parser', 'status': 'in_progress'},
                    ],
                  },
                ),
                (
                  'todo_write',
                  {
                    'todos': [
                      {'content': 'Port the parser', 'status': 'completed'},
                    ],
                  },
                ),
              ]
            : [('noop', const {})],
      );
      expect(run.steers, isEmpty);
    });

    test('with nothing in progress the nudge names the first pending item; '
        'a long item is quoted clipped', () async {
      final long = 'Refactor ${'z' * 3000}';
      final run = await _run(
        turns: 4,
        nested: (turn) => turn == 0
            ? [
                (
                  'todo_write',
                  {
                    'todos': [
                      {'content': 'Done already', 'status': 'completed'},
                      {'content': long, 'status': 'pending'},
                    ],
                  },
                ),
              ]
            : [('noop', const {})],
      );
      expect(
        run.steers.single,
        contains(
          '"${long.substring(0, ChecklistSupervisor.retainedItemChars)}" is '
          'still pending',
        ),
      );
    });

    test('a write the model makes itself is read whole, as before', () async {
      final long = 'Refactor ${'z' * 3000}';
      final run = await _run(
        turns: 4,
        direct: {
          'todos': [
            {'content': long, 'status': 'in_progress'},
          ],
        },
        nested: (_) => [('noop', const {})],
      );
      expect(run.steers.single, contains('"$long" as in_progress'));
    });
  });

  test('the repetition guard keys on the model\'s own calls: the same script '
      'three turns running is caught whatever it called inside', () async {
    final run = await _run(
      turns: 3,
      nested: (turn) => [
        ('noop', {'path': 'file_$turn'}),
      ],
    );
    expect(run.notices, contains(contains('Repetition detected')));
  });

  test('the digest still names every call while names fit, with the '
      'identifying arguments of the earliest', () async {
    final run = await _run(
      turns: 1,
      nested: (_) => [
        for (var i = 0; i < 400; i++)
          ('noop', {'path': '${'d' * 200}/$i', 'content': 'x' * 100000}),
      ],
    );
    final digest = run.parentBlocks.single.nestedCalls;
    expect(digest, hasLength(400));
    expect(digest.first.args, {'path': '${'d' * 200}/0'});
    expect(digest.last.args, isEmpty);
  });
}

typedef _Nested = List<(String, Map<String, dynamic>)>;

class _Outcome {
  _Outcome(this.events, this.history);

  final List<AgentLoopEvent> events;
  final List<HarnessMessage> history;

  List<String> get notices => [
    for (final e in events.whereType<LoopNotice>()) e.message,
  ];

  List<String> get steers => [
    for (final m in history)
      if (m.role == HarnessRole.system &&
          m.textContent.contains('checklist is out of date'))
        m.textContent,
  ];

  List<HarnessToolResultBlock> get parentBlocks => [
    for (final m in history)
      if (m.role == HarnessRole.tool)
        for (final b in m.content.whereType<HarnessToolResultBlock>())
          if (b.toolUseId.startsWith('call_parent')) b,
  ];
}

/// [turns] turns, each calling `parent` (the same arguments every turn),
/// whose body makes the calls [nested] gives for that turn through its
/// reentry. With [direct], the first turn also calls `todo_write` itself.
Future<_Outcome> _run({
  required int turns,
  required _Nested Function(int turn) nested,
  Map<String, dynamic>? direct,
}) async {
  var turn = 0;
  final parent = _Tool('parent', selfGuards: true, (_, context) async {
    for (final (name, args) in nested(turn++)) {
      await context.reentry!.call(name, args);
    }
    return HarnessToolResult.success('script finished');
  });
  final history = <HarnessMessage>[];
  final events = await const AgentLoopRunner()
      .run(
        history: history,
        userMessage: 'Work.',
        tools: [
          parent,
          _Tool('noop', (_, _) async => HarnessToolResult.success('.')),
          _Tool('todo_write', (_, _) async => HarnessToolResult.success('ok')),
        ],
        provider: _Provider(turns, direct),
        config: const AgentLoopConfig(
          steering: LoopSteeringConfig(checklistStaleAfterTurns: 2),
        ),
      )
      .toList()
      .timeout(const Duration(seconds: 20));
  return _Outcome(events, history);
}

class _Tool extends HarnessTool {
  _Tool(this.name, this._body, {this.selfGuards = false});

  @override
  final String name;
  @override
  final bool selfGuards;
  final Future<HarnessToolResult> Function(
    Map<String, dynamic> args,
    HarnessToolContext context,
  )
  _body;

  @override
  String get description => 'A test tool.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  bool get parallelSafe => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) => _body(args, context);
}

/// Calls `parent` with the same arguments for [turns] turns (the first turn
/// also `todo_write` with [direct], when given), then answers in text.
class _Provider extends LlmProviderPort {
  _Provider(this.turns, this.direct);

  final int turns;
  final Map<String, dynamic>? direct;
  var _calls = 0;

  @override
  String get displayName => 'Retention scenario';
  @override
  String get defaultModel => 'controlled';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final n = _calls++;
    if (n >= turns) {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
      return;
    }
    if (n == 0 && direct != null) {
      yield LlmToolUseDelta(
        id: 'call_todo',
        name: 'todo_write',
        argumentsJson: jsonEncode(direct),
      );
    }
    yield LlmToolUseDelta(
      id: 'call_parent_$n',
      name: 'parent',
      argumentsJson: '{"script":"same"}',
    );
    yield const LlmDone(stopReason: LlmStopReason.toolUse);
  }
}
