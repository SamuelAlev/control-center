import 'dart:async';
import 'dart:convert';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

const _deadline = Duration(seconds: 10);
const _parentId = 'call_parent';

typedef _Body =
    Future<HarnessToolResult> Function(
      Map<String, dynamic> args,
      HarnessToolContext context,
    );

/// A tool with a controllable body and every gate-relevant property settable.
class _Tool extends HarnessTool {
  _Tool(
    this.name, {
    this.approvalTier = ToolApprovalTier.read,
    this.parallelSafeOverride,
    this.scriptCallable = true,
    this.waitsOnPerson = false,
    this.selfGuards = false,
    this.argumentRefusal,
    this._body,
  });

  @override
  final String name;
  @override
  final ToolApprovalTier approvalTier;
  final bool? parallelSafeOverride;
  @override
  final bool scriptCallable;
  @override
  final bool waitsOnPerson;
  @override
  final bool selfGuards;
  final String? Function(Map<String, dynamic> args)? argumentRefusal;
  final _Body? _body;
  final contexts = <HarnessToolContext>[];
  int executions = 0;

  @override
  bool get parallelSafe => parallelSafeOverride ?? super.parallelSafe;

  @override
  String? scriptArgumentRefusal(Map<String, dynamic> args) =>
      argumentRefusal?.call(args);

  @override
  String get description => 'A controlled operation.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) {
    executions++;
    contexts.add(context);
    final body = _body;
    return body == null
        ? Future.value(HarnessToolResult.success('$name ran.'))
        : body(args, context);
  }
}

/// The parent: a read-tier, self-guarding, not parallel-safe tool (the shape
/// `repl` has) whose body uses its reentry.
_Tool _parent(_Body body) =>
    _Tool('parent', selfGuards: true, parallelSafeOverride: false, body: body);

/// Calls [name] on turn one, then answers in text.
class _Provider extends LlmProviderPort {
  _Provider(this.name);

  final String name;
  int calls = 0;
  final sentTools = <List<String>>[];

  @override
  String get displayName => 'Reentry scenario';
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
    sentTools.add([for (final t in tools) t.name]);
    if (calls++ == 0) {
      yield LlmToolUseDelta(
        id: name == 'parent' ? _parentId : 'call_$name',
        name: name,
        argumentsJson: '{}',
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

/// Calls every name in [names] in one turn, then answers in text.
class _BatchProvider extends _Provider {
  _BatchProvider(this.names) : super('batch');

  final List<String> names;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    if (calls++ == 0) {
      for (final name in names) {
        yield LlmToolUseDelta(
          id: 'call_$name',
          name: name,
          argumentsJson: '{}',
        );
      }
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

class _Hooks implements AgentLoopHooks {
  _Hooks({this.throwOn});

  final String? throwOn;
  final pre = <String>[];
  final post = <String>[];

  @override
  bool get interceptsTools => true;
  @override
  Future<void> onSessionStart() async {}
  @override
  Future<bool> preToolUse(String toolName, Map<String, dynamic> args) async {
    pre.add(toolName);
    if (toolName == throwOn) {
      throw StateError('hook exploded');
    }
    return true;
  }

  @override
  Future<void> postToolUse(
    String toolName,
    String result, {
    required bool isError,
  }) async => post.add(toolName);
}

class _Run {
  _Run(
    List<HarnessTool> tools, {
    List<HarnessTool> deferredTools = const [],
    List<HarnessTool> scriptTools = const [],
    AgentLoopConfig config = const AgentLoopConfig(),
    String call = 'parent',
    CancellationToken? cancel,
  }) : provider = _Provider(call) {
    done = const AgentLoopRunner()
        .run(
          history: history,
          userMessage: 'Run the script.',
          tools: tools,
          deferredTools: deferredTools,
          scriptTools: scriptTools,
          provider: provider,
          config: config,
          cancel: cancel,
        )
        .forEach(events.add);
  }

  final _Provider provider;
  final history = <HarnessMessage>[];
  final events = <AgentLoopEvent>[];
  late final Future<void> done;

  HarnessToolResultBlock get parentBlock => history
      .where((m) => m.role == HarnessRole.tool)
      .expand((m) => m.content)
      .whereType<HarnessToolResultBlock>()
      .single;
}

/// Runs a parent whose body calls [body] with its reentry and returns the
/// outcome(s) it produced as the test's value.
Future<(_Run, T)> _script<T>(
  Future<T> Function(ToolReentry reentry, HarnessToolContext context) body, {
  List<HarnessTool> tools = const [],
  List<HarnessTool> scriptTools = const [],
  AgentLoopConfig config = const AgentLoopConfig(),
  CancellationToken? cancel,
}) async {
  final value = Completer<T>();
  final parent = _parent((args, context) async {
    try {
      value.complete(await body(context.reentry!, context));
    } on Object catch (e, st) {
      value.completeError(e, st);
    }
    return HarnessToolResult.success('script finished');
  });
  final run = _Run(
    [parent, ...tools],
    scriptTools: scriptTools,
    config: config,
    cancel: cancel,
  );
  final result = await value.future.timeout(_deadline);
  await run.done.timeout(_deadline);
  return (run, result);
}

void main() {
  group('surface and arguments', () {
    test('a tool outside the surface is unknownTool', () async {
      final (_, outcome) = await _script(
        (reentry, _) => reentry.call('not_admitted', const {}),
      );
      expect(outcome.status, ToolReentryStatus.unknownTool);
      expect(outcome.result.isError, isTrue);
      expect(outcome.gate, isNull);
    });

    test('non-object arguments are invalidArgs', () async {
      final read = _Tool('read');
      final (_, outcomes) = await _script(
        (reentry, _) async => [
          await reentry.call('read', [1, 2]),
          await reentry.call('read', 'path'),
          await reentry.call('read', null),
        ],
        tools: [read],
      );
      expect(
        outcomes.map((o) => o.status),
        everyElement(ToolReentryStatus.invalidArgs),
      );
      expect(read.executions, 0);
    });

    test(
      'scriptCallable false tools and loop-handled tools are refused',
      () async {
        final pinned = _Tool('mark', scriptCallable: false);
        final (_, outcomes) = await _script(
          (reentry, _) async => [
            await reentry.call('mark', const {}),
            await reentry.call('checkpoint', const {}),
          ],
          tools: [pinned, _Tool('checkpoint')],
        );
        expect(outcomes[0].status, ToolReentryStatus.unknownTool);
        expect(outcomes[0].result.content, contains('Call it directly'));
        expect(outcomes[1].status, ToolReentryStatus.unknownTool);
        expect(pinned.executions, 0);
      },
    );

    test('a nested call knows the call that made it; a direct call does '
        'not', () async {
      final probe = _Tool('probe');
      final (run, _) = await _script((reentry, _) async {
        await reentry.call('probe', const {});
        await reentry.call('probe', const {});
      }, tools: [probe]);
      expect(probe.contexts.map((c) => c.parentToolCallId), [
        _parentId,
        _parentId,
      ]);
      expect(probe.contexts.map((c) => c.toolCallId), [
        '$_parentId/1',
        '$_parentId/2',
      ]);
      final direct = _Tool('probe');
      final second = _Run([direct], call: 'probe');
      await second.done.timeout(_deadline);
      expect(direct.contexts.single.toolCallId, 'call_probe');
      expect(direct.contexts.single.parentToolCallId, isNull);
      expect(run.events.whereType<LoopToolCallResult>(), hasLength(3));
    });

    test('a nested call has no reentry and callable is the surface', () async {
      final read = _Tool('read');
      final hidden = _Tool('hidden', scriptCallable: false);
      final (_, callable) = await _script((reentry, _) async {
        await reentry.call('read', const {});
        return reentry.callable.keys.toSet();
      }, tools: [read, hidden]);
      expect(read.contexts.single.reentry, isNull);
      expect(read.contexts.single.toolCallId, '$_parentId/1');
      expect(callable, {'parent', 'read'});
    });
  });

  group('gate parity', () {
    test('a denying approval rejects and the tool never runs', () async {
      final origins = <ToolCallOrigin>[];
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final (_, outcome) = await _script(
        (reentry, _) => reentry.call('write', const {'path': 'a.txt'}),
        tools: [write],
        config: AgentLoopConfig(
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (request) async {
              origins.add(request.origin);
              return const ToolGateDecision.deny(reason: 'not here');
            },
          ),
        ),
      );
      expect(outcome.status, ToolReentryStatus.denied);
      expect(outcome.gate?.verdict, ToolGateVerdict.denied);
      expect(outcome.gate?.reason, 'Denied: not here');
      expect(write.executions, 0);
      expect(origins.single.isNested, isTrue);
      expect(origins.single.parentToolUseId, _parentId);
      expect(origins.single.toolCallId, '$_parentId/1');
    });

    test('no approver with autoApprove false denies', () async {
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final (_, outcome) = await _script(
        (reentry, _) => reentry.call('write', const {}),
        tools: [write],
        config: const AgentLoopConfig(
          tools: LoopToolConfig(autoApprove: false),
        ),
      );
      expect(outcome.status, ToolReentryStatus.denied);
      expect(outcome.result.content, contains('no approver'));
      expect(write.executions, 0);
    });

    test('a person approving is recorded as approved', () async {
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final (_, outcome) = await _script(
        (reentry, _) => reentry.call('write', const {}),
        tools: [write],
        config: AgentLoopConfig(
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (_) async =>
                const ToolGateDecision.allow(askedPerson: true),
          ),
        ),
      );
      expect(outcome.status, ToolReentryStatus.completed);
      expect(outcome.gate?.verdict, ToolGateVerdict.approved);
      expect(write.executions, 1);
    });

    test('the tool\'s start is reported once, with the verdict, before it '
        'runs; a refused call reports none', () async {
      final started = <(ToolGateVerdict, int)>[];
      late _Tool write;
      write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final (_, outcomes) = await _script(
        (reentry, _) async => [
          await reentry.call('write', const {
            'path': 'a',
          }, onToolStarted: (v) => started.add((v, write.executions))),
          await reentry.call('write', const {
            'path': 'no',
          }, onToolStarted: (v) => started.add((v, write.executions))),
        ],
        tools: [write],
        config: AgentLoopConfig(
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (request) async => request.args['path'] == 'a'
                ? const ToolGateDecision.allow(askedPerson: true)
                : const ToolGateDecision.deny(reason: 'no'),
          ),
        ),
      );
      expect(outcomes[0].status, ToolReentryStatus.completed);
      expect(outcomes[1].status, ToolReentryStatus.denied);
      // Reported before the tool's one execution, and only for the call
      // that passed.
      expect(started, [(ToolGateVerdict.approved, 0)]);
    });

    test('a throwing preToolUse hook denies', () async {
      final read = _Tool('read');
      final hooks = _Hooks(throwOn: 'read');
      final (_, outcome) = await _script(
        (reentry, _) => reentry.call('read', const {}),
        tools: [read],
        config: AgentLoopConfig(steering: LoopSteeringConfig(hooks: hooks)),
      );
      expect(outcome.status, ToolReentryStatus.denied);
      expect(outcome.gate?.verdict, ToolGateVerdict.denied);
      expect(read.executions, 0);
      expect(hooks.pre, ['parent', 'read']);
      expect(hooks.post, containsAll(['read', 'parent']));
    });

    test(
      'a read-tier tool with no action classes runs without asking',
      () async {
        var asked = 0;
        final read = _Tool('read');
        final (_, outcome) = await _script(
          (reentry, _) => reentry.call('read', const {}),
          tools: [read],
          config: AgentLoopConfig(
            tools: LoopToolConfig(
              autoApprove: false,
              approvalCallback: (_) async {
                asked++;
                return const ToolGateDecision.deny();
              },
            ),
          ),
        );
        expect(outcome.status, ToolReentryStatus.completed);
        expect(outcome.gate?.verdict, ToolGateVerdict.allowed);
        expect(outcome.result.content, 'read ran.');
        expect(asked, 0);
      },
    );

    test('a structured value reaches the caller unchanged', () async {
      final search = _Tool(
        'search',
        body: (_, _) async => HarnessToolResult.success(
          'a.dart:1: x',
          structured: const {
            'matches': [
              {'path': 'a.dart', 'line': 1, 'text': 'x'},
            ],
          },
        ),
      );
      final (_, outcome) = await _script(
        (reentry, _) => reentry.call('search', const {'pattern': 'x'}),
        tools: [search],
      );
      expect(outcome.result.structured, {
        'matches': [
          {'path': 'a.dart', 'line': 1, 'text': 'x'},
        ],
      });
    });
  });

  group('events', () {
    test('nested events fall between the parent start and result', () async {
      final read = _Tool('read');
      final (run, _) = await _script((reentry, _) async {
        await reentry.call('read', const {'path': 'a.txt'});
        await reentry.call('read', const {'path': 'b.txt'});
        return null;
      }, tools: [read]);
      final toolEvents = [
        for (final e in run.events)
          if (e is LoopToolCallStart)
            'start ${e.toolUseId} ${e.parentToolUseId}'
          else if (e is LoopToolCallResult)
            'result ${e.toolUseId} ${e.parentToolUseId}',
      ];
      expect(toolEvents, [
        'start $_parentId null',
        'start $_parentId/1 $_parentId',
        'result $_parentId/1 $_parentId',
        'start $_parentId/2 $_parentId',
        'result $_parentId/2 $_parentId',
        'result $_parentId null',
      ]);
    });

    test('nested results are not tool-result blocks; the parent records '
        'their digest', () async {
      final edit = _Tool('edit');
      final (run, _) = await _script((reentry, _) async {
        await reentry.call('edit', {
          'path': 'lib/a.dart',
          'old_text': 'x' * 2000,
          'new_text': 'y',
        });
        return null;
      }, tools: [edit]);
      final blocks = run.history
          .expand((m) => m.content)
          .whereType<HarnessToolResultBlock>()
          .toList();
      expect(blocks.map((b) => b.toolUseId), [_parentId]);
      final digest = blocks.single.nestedCalls.single;
      expect(digest.name, 'edit');
      expect(digest.args, {'path': 'lib/a.dart'});
      expect(collectActiveEditTargets(run.history), {'lib/a.dart'});
      final restored = HarnessContentBlock.fromJson(
        jsonDecode(jsonEncode(blocks.single.toJson())) as Map<String, dynamic>,
      );
      expect(restored, blocks.single);
    });

    test('the digest is bounded', () async {
      final read = _Tool('read');
      final (run, _) = await _script((reentry, _) async {
        for (var i = 0; i < 400; i++) {
          await reentry.call('read', {'path': '${'d' * 200}/$i'});
        }
        return null;
      }, tools: [read]);
      final digest = run.parentBlock.nestedCalls;
      final size = digest.fold<int>(
        0,
        (sum, c) => sum + jsonEncode(c.toJson()).length,
      );
      expect(size, lessThanOrEqualTo(harnessNestedCallDigestBytes));
      expect(digest.length, 400, reason: 'every name survives');
      expect(digest.first.args, isNotEmpty);
      expect(digest.last.args, isEmpty);
    });

    test(
      'a call after the parent settled is cancelled and emits nothing',
      () async {
        final read = _Tool('read');
        ToolReentry? kept;
        final parent = _parent((_, context) async {
          kept = context.reentry;
          return HarnessToolResult.success('done');
        });
        final run = _Run([parent, read]);
        await run.done.timeout(_deadline);
        final before = run.events.length;
        final outcome = await kept!.call('read', const {});
        expect(outcome.status, ToolReentryStatus.cancelled);
        expect(read.executions, 0);
        expect(run.events.length, before);
      },
    );
  });

  test('parallel-batch calls get a reentry of their own', () async {
    final read = _Tool('read');
    // Both parents are parallel-safe, so they run as one batch; each holds
    // its nested call open until the other has started one too.
    final bothStarted = Completer<void>();
    var started = 0;
    _Tool batchParent(String name) => _Tool(
      name,
      body: (_, context) async {
        final call = context.reentry!.call('read', {'path': '$name.txt'});
        if (++started == 2) {
          bothStarted.complete();
        }
        await bothStarted.future;
        await call;
        return HarnessToolResult.success('$name done');
      },
    );
    final history = <HarnessMessage>[];
    final events = <AgentLoopEvent>[];
    await const AgentLoopRunner()
        .run(
          history: history,
          userMessage: 'Run both.',
          tools: [batchParent('pa'), batchParent('pb'), read],
          provider: _BatchProvider(['pa', 'pb']),
        )
        .forEach(events.add)
        .timeout(_deadline);
    for (final parent in ['call_pa', 'call_pb']) {
      final start = events.indexWhere(
        (e) => e is LoopToolCallStart && e.toolUseId == parent,
      );
      final result = events.indexWhere(
        (e) => e is LoopToolCallResult && e.toolUseId == parent,
      );
      final nested = [
        for (var i = 0; i < events.length; i++)
          if (events[i] case LoopToolCallStart(
            :final parentToolUseId,
          ) when parentToolUseId == parent)
            i,
        for (var i = 0; i < events.length; i++)
          if (events[i] case LoopToolCallResult(
            :final parentToolUseId,
          ) when parentToolUseId == parent)
            i,
      ];
      expect(nested, hasLength(2));
      expect(nested, everyElement(allOf(greaterThan(start), lessThan(result))));
      expect(
        events
            .whereType<LoopToolCallStart>()
            .where((e) => e.parentToolUseId == parent)
            .single
            .toolUseId,
        '$parent/1',
      );
    }
    final blocks = history
        .expand((m) => m.content)
        .whereType<HarnessToolResultBlock>()
        .toList();
    expect(blocks.map((b) => b.toolUseId), ['call_pa', 'call_pb']);
    expect(blocks.map((b) => b.nestedCalls.single.args['path']), [
      'pa.txt',
      'pb.txt',
    ]);
    expect(read.contexts.map((c) => c.reentry), everyElement(isNull));
  });

  group('lanes', () {
    test('parallel-safe calls overlap up to the limit', () async {
      var active = 0;
      var peak = 0;
      final gate = Completer<void>();
      final read = _Tool(
        'read',
        body: (_, _) async {
          active++;
          peak = active > peak ? active : peak;
          await gate.future;
          active--;
          return HarnessToolResult.success('ok');
        },
      );
      final (_, outcomes) = await _script(
        (reentry, _) async {
          final calls = [
            for (var i = 0; i < 5; i++) reentry.call('read', {'i': i}),
          ];
          await Future<void>.delayed(const Duration(milliseconds: 50));
          final seen = peak;
          gate.complete();
          return (seen, await Future.wait(calls));
        },
        tools: [read],
        config: const AgentLoopConfig(
          tools: LoopToolConfig(maxParallelNestedCalls: 3),
        ),
      );
      expect(outcomes.$1, 3);
      expect(peak, 3);
      expect(
        outcomes.$2.map((o) => o.status),
        everyElement(ToolReentryStatus.completed),
      );
    });

    test('gated calls run one at a time in call order', () async {
      var active = 0;
      var peak = 0;
      final order = <int>[];
      final write = _Tool(
        'write',
        approvalTier: ToolApprovalTier.write,
        body: (args, _) async {
          active++;
          peak = active > peak ? active : peak;
          order.add(args['i'] as int);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          active--;
          return HarnessToolResult.success('ok');
        },
      );
      final approvals = <String>[];
      final (_, outcomes) = await _script(
        (reentry, _) => Future.wait([
          for (var i = 0; i < 4; i++) reentry.call('write', {'i': i}),
        ]),
        tools: [write],
        config: AgentLoopConfig(
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (request) async {
              approvals.add(request.origin.toolCallId);
              return const ToolGateDecision.allow();
            },
          ),
        ),
      );
      expect(peak, 1);
      expect(order, [0, 1, 2, 3]);
      expect(approvals, [for (var i = 1; i <= 4; i++) '$_parentId/$i']);
      expect(
        outcomes.map((o) => o.status),
        everyElement(ToolReentryStatus.completed),
      );
    });

    test(
      'every call takes the serial lane while a hook intercepts tools',
      () async {
        var active = 0;
        var peak = 0;
        final read = _Tool(
          'read',
          body: (_, _) async {
            active++;
            peak = active > peak ? active : peak;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            active--;
            return HarnessToolResult.success('ok');
          },
        );
        await _script(
          (reentry, _) => Future.wait([
            for (var i = 0; i < 3; i++) reentry.call('read', const {}),
          ]),
          tools: [read],
          config: AgentLoopConfig(
            steering: LoopSteeringConfig(hooks: _Hooks()),
          ),
        );
        expect(peak, 1);
      },
    );
  });

  group('cancellation and deadlines', () {
    test('cancelling the run settles every in-flight nested call', () async {
      final started = Completer<void>();
      final hang = _Tool(
        'hang',
        body: (_, _) {
          if (!started.isCompleted) {
            started.complete();
          }
          return Completer<HarnessToolResult>().future;
        },
      );
      final queued = _Tool(
        'queued',
        approvalTier: ToolApprovalTier.write,
        parallelSafeOverride: false,
      );
      final blocker = _Tool(
        'blocker',
        approvalTier: ToolApprovalTier.write,
        body: (_, _) {
          return Completer<HarnessToolResult>().future;
        },
      );
      final source = CancellationTokenSource();
      final outcomes = Completer<List<ToolReentryOutcome>>();
      final parent = _parent((_, context) async {
        final reentry = context.reentry!;
        final calls = [
          reentry.call('hang', const {}),
          reentry.call('blocker', const {}),
          reentry.call('queued', const {}),
        ];
        outcomes.complete(await Future.wait(calls));
        return HarnessToolResult.success('unreachable');
      });
      final run = _Run([parent, hang, queued, blocker], cancel: source.token);
      await started.future.timeout(_deadline);
      source.cancel('stop');
      final settled = await outcomes.future.timeout(_deadline);
      await run.done.timeout(_deadline);
      expect(
        settled.map((o) => o.status),
        everyElement(ToolReentryStatus.cancelled),
      );
      expect(queued.executions, 0);
      expect(
        run.events.whereType<LoopDone>().single.reason,
        LoopDoneReason.cancelled,
      );
    });

    test('the parent settling cancels what it left running', () async {
      final hang = _Tool(
        'hang',
        body: (_, _) => Completer<HarnessToolResult>().future,
      );
      final leftBehind = Completer<ToolReentryOutcome>();
      final parent = _parent((_, context) async {
        unawaited(
          context.reentry!.call('hang', const {}).then(leftBehind.complete),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return HarnessToolResult.success('done early');
      });
      final run = _Run([parent, hang]);
      final outcome = await leftBehind.future.timeout(_deadline);
      await run.done.timeout(_deadline);
      expect(outcome.status, ToolReentryStatus.cancelled);
    });

    test('a per-call timeout yields timedOut', () async {
      final hang = _Tool(
        'hang',
        body: (_, _) => Completer<HarnessToolResult>().future,
      );
      final (_, outcome) = await _script(
        (reentry, _) => reentry.call(
          'hang',
          const {},
          timeout: const Duration(milliseconds: 50),
        ),
        tools: [hang],
      );
      expect(outcome.status, ToolReentryStatus.timedOut);
      expect(outcome.result.isError, isTrue);
    });

    test('a caller cancel token cancels that call only', () async {
      final hang = _Tool(
        'hang',
        body: (_, _) => Completer<HarnessToolResult>().future,
      );
      final read = _Tool('read');
      final (_, outcomes) = await _script((reentry, _) async {
        final source = CancellationTokenSource();
        final pending = reentry.call('hang', const {}, cancel: source.token);
        source.cancel();
        return [await pending, await reentry.call('read', const {})];
      }, tools: [hang, read]);
      expect(outcomes[0].status, ToolReentryStatus.cancelled);
      expect(outcomes[1].status, ToolReentryStatus.completed);
    });

    group('a call given up on while its tool runs', () {
      test('at its deadline hands out the still-running execution, whose '
          'token was cancelled', () async {
        final held = Completer<HarnessToolResult>();
        CancellationToken? token;
        final hang = _Tool(
          'hang',
          body: (_, context) {
            token = context.cancel;
            return held.future;
          },
        );
        final (_, outcome) = await _script(
          (reentry, _) => reentry.call(
            'hang',
            const {},
            timeout: const Duration(milliseconds: 50),
          ),
          tools: [hang],
        );
        expect(outcome.status, ToolReentryStatus.timedOut);
        expect(outcome.gate?.verdict, ToolGateVerdict.allowed);
        final running = outcome.stillRunning;
        expect(running, isNotNull);
        expect(token?.isCancelled, isTrue);
        held.complete(HarnessToolResult.success('late'));
        expect((await running!.timeout(_deadline)).content, 'late');
      });

      test('at its caller\'s cancel hands it out too', () async {
        final held = Completer<HarnessToolResult>();
        final hang = _Tool('hang', body: (_, _) => held.future);
        final (_, outcome) = await _script((reentry, _) async {
          final source = CancellationTokenSource();
          final pending = reentry.call(
            'hang',
            const {},
            cancel: source.token,
            onToolStarted: (_) => source.cancel(),
          );
          return pending;
        }, tools: [hang]);
        expect(outcome.status, ToolReentryStatus.cancelled);
        expect(outcome.gate?.verdict, ToolGateVerdict.allowed);
        expect(outcome.stillRunning, isNotNull);
        held.complete(HarnessToolResult.success('late'));
      });

      test('before its tool started, or once it returned, has none', () async {
        final read = _Tool('read');
        final hang = _Tool(
          'hang',
          body: (_, _) => Completer<HarnessToolResult>().future,
        );
        final (_, outcomes) = await _script((reentry, _) async {
          final source = CancellationTokenSource()..cancel();
          return [
            await reentry.call('read', const {}),
            await reentry.call('hang', const {}, cancel: source.token),
          ];
        }, tools: [read, hang]);
        expect(outcomes[0].status, ToolReentryStatus.completed);
        expect(outcomes[1].status, ToolReentryStatus.cancelled);
        expect(hang.executions, 0);
        expect([for (final o in outcomes) o.stillRunning], [null, null]);
      });
    });

    test(
      'the parent timeout pauses while an approval waits on a person',
      () async {
        final write = _Tool('write', approvalTier: ToolApprovalTier.write);
        final waits = <bool>[];
        final (run, outcome) = await _script(
          (reentry, _) =>
              reentry.call('write', const {}, onPersonWait: waits.add),
          tools: [write],
          config: AgentLoopConfig(
            tools: LoopToolConfig(
              toolTimeout: const Duration(milliseconds: 500),
              autoApprove: false,
              approvalCallback: (request) async {
                request.onPersonWait(true);
                await Future<void>.delayed(const Duration(milliseconds: 1000));
                request.onPersonWait(false);
                return const ToolGateDecision.allow(askedPerson: true);
              },
            ),
          ),
        );
        expect(outcome.status, ToolReentryStatus.completed);
        expect(
          outcome.personWait,
          greaterThanOrEqualTo(const Duration(milliseconds: 950)),
        );
        expect(waits, [true, false]);
        final parentResult = run.events
            .whereType<LoopToolCallResult>()
            .singleWhere((e) => e.toolUseId == _parentId)
            .result;
        expect(parentResult.isError, isFalse);
        expect(parentResult.content, 'script finished');
      },
    );

    test('the parent timeout pauses while a tool waits on a person', () async {
      final ask = _Tool(
        'ask_user',
        waitsOnPerson: true,
        body: (_, _) async {
          await Future<void>.delayed(const Duration(milliseconds: 700));
          return HarnessToolResult.success('yes');
        },
      );
      // The parent spends 500 of its 1000 ms before asking; the question then
      // takes 700 ms, inside its own 1000 ms limit. Only a paused deadline lets
      // the parent finish.
      final (run, outcome) = await _script(
        (reentry, _) async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          return reentry.call(
            'ask_user',
            const {},
            // The caller's own clock excludes the wait, so its timeout does
            // not bound a question.
            timeout: const Duration(milliseconds: 50),
          );
        },
        tools: [ask],
        config: const AgentLoopConfig(
          tools: LoopToolConfig(toolTimeout: Duration(milliseconds: 1000)),
        ),
      );
      expect(outcome.status, ToolReentryStatus.completed);
      expect(
        outcome.personWait,
        greaterThanOrEqualTo(const Duration(milliseconds: 650)),
      );
      final parentResult = run.events
          .whereType<LoopToolCallResult>()
          .singleWhere((e) => e.toolUseId == _parentId)
          .result;
      expect(parentResult.isError, isFalse);
    });

    test('a self-guarding tool\'s own person wait stops every clock', () async {
      // The shape of `bash` asking for a command approval inside execute.
      final bash = _Tool(
        'bash',
        selfGuards: true,
        approvalTier: ToolApprovalTier.exec,
        body: (_, context) async {
          context.personWait!(true);
          await Future<void>.delayed(const Duration(milliseconds: 700));
          context.personWait!(false);
          return HarnessToolResult.success('ran');
        },
      );
      final heard = <bool>[];
      final (run, outcome) = await _script(
        (reentry, _) => reentry.call(
          'bash',
          const {},
          // Both far shorter than the person takes: the call's own deadline,
          // the parent's and the caller's clock all stop while they decide.
          timeout: const Duration(milliseconds: 50),
          onPersonWait: heard.add,
        ),
        tools: [bash],
        config: const AgentLoopConfig(
          tools: LoopToolConfig(toolTimeout: Duration(milliseconds: 300)),
        ),
      );
      expect(outcome.status, ToolReentryStatus.completed);
      expect(outcome.result.content, 'ran');
      expect(
        outcome.personWait,
        greaterThanOrEqualTo(const Duration(milliseconds: 650)),
      );
      expect(heard, [true, false]);
      final parentResult = run.events
          .whereType<LoopToolCallResult>()
          .singleWhere((e) => e.toolUseId == _parentId)
          .result;
      expect(parentResult.isError, isFalse);
      expect(parentResult.content, 'script finished');
    });

    test('a direct call is not abandoned while a person decides', () async {
      final bash = _Tool(
        'bash',
        selfGuards: true,
        approvalTier: ToolApprovalTier.exec,
        body: (_, context) async {
          context.personWait!(true);
          await Future<void>.delayed(const Duration(milliseconds: 600));
          context.personWait!(false);
          return HarnessToolResult.success('ran');
        },
      );
      final run = _Run(
        [bash],
        call: 'bash',
        config: const AgentLoopConfig(
          tools: LoopToolConfig(toolTimeout: Duration(milliseconds: 200)),
        ),
      );
      await run.done.timeout(_deadline);
      final result = run.events.whereType<LoopToolCallResult>().single;
      expect(result.result.isError, isFalse);
      expect(result.result.content, 'ran');
    });

    for (final (label, ends) in [
      ('throws', false),
      ('forgets to report the end', true),
    ]) {
      test('a tool that reports a wait and then $label leaves the parent '
          'deadline running', () async {
        final flaky = _Tool(
          'flaky',
          selfGuards: true,
          body: (_, context) async {
            context.personWait!(true);
            if (ends) {
              return HarnessToolResult.success('left the wait open');
            }
            throw StateError('runner exploded');
          },
        );
        final heard = <bool>[];
        final nested = Completer<ToolReentryOutcome>();
        final parent = _parent((_, context) async {
          nested.complete(
            await context.reentry!.call(
              'flaky',
              const {},
              onPersonWait: heard.add,
            ),
          );
          return Completer<HarnessToolResult>().future;
        });
        final run = _Run(
          [parent, flaky],
          config: const AgentLoopConfig(
            tools: LoopToolConfig(toolTimeout: Duration(milliseconds: 300)),
          ),
        );
        await run.done.timeout(_deadline);
        final outcome = await nested.future.timeout(_deadline);
        expect(
          outcome.status,
          ends ? ToolReentryStatus.completed : ToolReentryStatus.failed,
        );
        expect(heard, [true, false]);
        // A report from a call that has settled changes nothing.
        flaky.contexts.single.personWait!(true);
        expect(heard, [true, false]);
        final parentResult = run.events
            .whereType<LoopToolCallResult>()
            .singleWhere((e) => e.toolUseId == _parentId)
            .result;
        expect(parentResult.content, contains('time limit'));
      });
    }

    test(
      'the parent timeout still fires for a tool that simply hangs',
      () async {
        final parent = _parent((_, _) => Completer<HarnessToolResult>().future);
        final run = _Run(
          [parent],
          config: const AgentLoopConfig(
            tools: LoopToolConfig(toolTimeout: Duration(milliseconds: 100)),
          ),
        );
        await run.done.timeout(_deadline);
        final result = run.events.whereType<LoopToolCallResult>().single.result;
        expect(result.isError, isTrue);
        expect(result.content, contains('time limit'));
      },
    );

    test(
      'the parent timeout fires for a slow nested call that waits on no one',
      () async {
        final slow = _Tool(
          'slow',
          body: (_, _) => Completer<HarnessToolResult>().future,
        );
        final nested = Completer<ToolReentryOutcome>();
        final parent = _parent((_, context) async {
          nested.complete(await context.reentry!.call('slow', const {}));
          return HarnessToolResult.success('unreachable');
        });
        final run = _Run(
          [parent, slow],
          config: const AgentLoopConfig(
            tools: LoopToolConfig(toolTimeout: Duration(milliseconds: 300)),
          ),
        );
        await run.done.timeout(_deadline);
        final outcome = await nested.future.timeout(_deadline);
        final parentResult = run.events
            .whereType<LoopToolCallResult>()
            .singleWhere((e) => e.toolUseId == _parentId)
            .result;
        expect(parentResult.content, contains('time limit'));
        // The nested call's own deadline is the same 300 ms; whichever fires
        // first, it does not run on after its parent.
        expect(
          outcome.status,
          anyOf(ToolReentryStatus.cancelled, ToolReentryStatus.timedOut),
        );
      },
    );
  });

  group('contract and script-only tools', () {
    test(
      'a pinned verb called through reentry satisfies the contract',
      () async {
        final submit = _Tool('submit_plan');
        final (run, outcome) = await _script(
          (reentry, _) => reentry.call('submit_plan', const {'plan': 'p'}),
          tools: [submit],
          config: const AgentLoopConfig(
            guards: LoopGuardConfig(
              contract: CompletionContract(
                id: 'plan.submitted',
                requiredToolNames: {'submit_plan'},
                nudge: 'Submit the plan.',
                unmetSummary: 'No plan.',
                maxNudges: 0,
              ),
            ),
          ),
        );
        expect(outcome.status, ToolReentryStatus.completed);
        final done = run.events.whereType<LoopDone>().single;
        expect(done.reason, LoopDoneReason.completed);
        expect(done.unmetContractId, isNull);
      },
    );

    test('without the nested call the same contract is unmet', () async {
      final submit = _Tool('submit_plan');
      final (run, _) = await _script(
        (reentry, _) async => null,
        tools: [submit],
        config: const AgentLoopConfig(
          guards: LoopGuardConfig(
            contract: CompletionContract(
              id: 'plan.submitted',
              requiredToolNames: {'submit_plan'},
              nudge: 'Submit the plan.',
              unmetSummary: 'No plan.',
              maxNudges: 0,
            ),
          ),
        ),
      );
      expect(
        run.events.whereType<LoopDone>().single.reason,
        LoopDoneReason.contractUnmet,
      );
    });

    test('a direct call to a script-only tool is redirected', () async {
      final scriptOnly = _Tool('lookup');
      final run = _Run(
        [_Tool('read')],
        scriptTools: [scriptOnly],
        call: 'lookup',
      );
      await run.done.timeout(_deadline);
      final result = run.events.whereType<LoopToolCallResult>().single.result;
      expect(result.isError, isTrue);
      expect(result.content, contains('await tools["lookup"](args)'));
      expect(scriptOnly.executions, 0);
      expect(run.events.whereType<LoopToolsActivated>(), isEmpty);
      expect(run.provider.sentTools, everyElement(['read']));
    });

    test('a script-only tool is callable through reentry', () async {
      final scriptOnly = _Tool('lookup');
      final (run, outcome) = await _script(
        (reentry, _) => reentry.call('lookup', const {}),
        scriptTools: [scriptOnly],
      );
      expect(outcome.status, ToolReentryStatus.completed);
      expect(scriptOnly.executions, 1);
      expect(run.provider.sentTools, everyElement(['parent']));
    });

    test('activation requests from nested results are ignored', () async {
      final search = _Tool(
        'search_tools',
        body: (_, _) async => HarnessToolResult.success(
          'found',
          activateTools: const {'deferred_one'},
        ),
      );
      final deferred = _Tool('deferred_one');
      final value = Completer<void>();
      final parent = _parent((_, context) async {
        await context.reentry!.call('search_tools', const {});
        value.complete();
        return HarnessToolResult.success('done');
      });
      final run = _Run([parent, search], deferredTools: [deferred]);
      await value.future.timeout(_deadline);
      await run.done.timeout(_deadline);
      expect(run.events.whereType<LoopToolsActivated>(), isEmpty);
      expect(run.provider.sentTools.last, isNot(contains('deferred_one')));
    });
  });

  test(
    'a tool that never uses its reentry behaves exactly as before',
    () async {
      final read = _Tool('read', parallelSafeOverride: false);
      final run = _Run([read], call: 'read');
      await run.done.timeout(_deadline);
      final toolEvents = [
        for (final e in run.events)
          if (e is LoopToolCallStart)
            'start ${e.toolUseId}'
          else if (e is LoopToolCallResult)
            'result ${e.toolUseId} ${e.result.content}',
      ];
      expect(toolEvents, ['start call_read', 'result call_read read ran.']);
      expect(read.contexts.single.reentry, isNotNull);
      expect(run.parentBlock.nestedCalls, isEmpty);
    },
  );

  group('the approval callback', () {
    test('a decision policy makes alone is no person wait', () async {
      // Policy lookups only (autonomy, rules): no card, no person. Nothing
      // may stop the script's clock or release its runner slot for that.
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final waits = <bool>[];
      final (_, outcome) = await _script(
        (reentry, _) =>
            reentry.call('write', const {}, onPersonWait: waits.add),
        tools: [write],
        config: AgentLoopConfig(
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (_) async {
              await Future<void>.delayed(const Duration(milliseconds: 300));
              return const ToolGateDecision.allow();
            },
          ),
        ),
      );
      expect(outcome.gate?.verdict, ToolGateVerdict.allowed);
      expect(waits, isEmpty);
      expect(outcome.personWait, lessThan(const Duration(milliseconds: 100)));
    });

    test('the wait the callback reports is the call\'s wait, once', () async {
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final waits = <bool>[];
      final (_, outcome) = await _script(
        (reentry, _) =>
            reentry.call('write', const {}, onPersonWait: waits.add),
        tools: [write],
        config: AgentLoopConfig(
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (request) async {
              // Policy first, then the card.
              await Future<void>.delayed(const Duration(milliseconds: 200));
              request
                ..onPersonWait(true)
                ..onPersonWait(true);
              await Future<void>.delayed(const Duration(milliseconds: 200));
              // Left open: the gate closes it when the callback returns.
              return const ToolGateDecision.allow(askedPerson: true);
            },
          ),
        ),
      );
      expect(outcome.gate?.verdict, ToolGateVerdict.approved);
      expect(waits, [true, false]);
      expect(
        outcome.personWait,
        allOf(
          greaterThanOrEqualTo(const Duration(milliseconds: 150)),
          lessThan(const Duration(milliseconds: 350)),
        ),
      );
    });

    test('a nested call withdraws its request when it stops waiting', () async {
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final asked = Completer<ToolApprovalRequest>();
      final stop = CancellationTokenSource();
      final (_, outcome) = await _script(
        (reentry, _) async {
          final pending = reentry.call('write', const {}, cancel: stop.token);
          final request = await asked.future;
          expect(request.withdrawn.isCancelled, isFalse);
          stop.cancel();
          return pending;
        },
        tools: [write],
        config: AgentLoopConfig(
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (request) {
              asked.complete(request);
              // A person who never answers.
              return Completer<ToolGateDecision>().future;
            },
          ),
        ),
      );
      expect(outcome.status, ToolReentryStatus.cancelled);
      final request = await asked.future;
      expect(request.withdrawn.isCancelled, isTrue);
      expect(request.origin.parentToolUseId, _parentId);
      expect(write.executions, 0);
    });

    test('a direct call\'s request is withdrawn by the run', () async {
      final write = _Tool('write', approvalTier: ToolApprovalTier.write);
      final asked = Completer<ToolApprovalRequest>();
      final stop = CancellationTokenSource();
      final run = _Run(
        [write],
        call: 'write',
        cancel: stop.token,
        config: AgentLoopConfig(
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (request) async {
              asked.complete(request);
              // A host that honours the withdrawal answers no.
              await request.withdrawn.whenCancelled;
              return const ToolGateDecision.deny(reason: 'withdrawn');
            },
          ),
        ),
      );
      final request = await asked.future.timeout(_deadline);
      expect(request.origin.isNested, isFalse);
      expect(request.withdrawn.isCancelled, isFalse);
      stop.cancel();
      await run.done.timeout(_deadline);
      expect(request.withdrawn.isCancelled, isTrue);
      expect(write.executions, 0);
    });
  });

  group('reach', () {
    final orchestrate = _Tool('orchestrate', scriptCallable: false);
    final plain = _Tool('plain');

    test('a script reaches only script-callable tools', () async {
      final (_, outcomes) = await _script(
        (reentry, _) async => [
          reentry.callable.keys.toSet(),
          (await reentry.call('orchestrate', const {})).status,
          (await reentry.call('plain', const {})).status,
          (await reentry.call('checkpoint', const {})).status,
        ],
        tools: [orchestrate, plain],
      );
      expect(outcomes[0], isNot(contains('orchestrate')));
      expect(outcomes[0], contains('plain'));
      expect(outcomes[1], ToolReentryStatus.unknownTool);
      expect(outcomes[2], ToolReentryStatus.completed);
      expect(outcomes[3], ToolReentryStatus.unknownTool);
    });

    test('a script is refused an argument the tool refuses it, before any '
        'hook or card', () async {
      const refusal = 'assign with a direct call';
      final asks = <Object>[];
      final hooks = _Hooks();
      final assign = _Tool(
        'create',
        approvalTier: ToolApprovalTier.write,
        argumentRefusal: (args) =>
            args.containsKey('assignee') ? refusal : null,
      );
      final (_, outcomes) = await _script(
        (reentry, _) async => [
          await reentry.call('create', const {'assignee': 'agent-2'}),
          await reentry.call('create', const {'title': 'x'}),
        ],
        tools: [assign],
        config: AgentLoopConfig(
          steering: LoopSteeringConfig(hooks: hooks),
          tools: LoopToolConfig(
            autoApprove: false,
            approvalCallback: (request) async {
              asks.add(request);
              return const ToolGateDecision.allow(askedPerson: true);
            },
          ),
        ),
      );
      final refused = outcomes[0];
      expect(refused.status, ToolReentryStatus.denied);
      expect(refused.gate?.verdict, ToolGateVerdict.denied);
      expect(refused.gate?.reason, refusal);
      expect(refused.result.content, refusal);
      // Without the argument the same tool is asked about and runs.
      expect(outcomes[1].status, ToolReentryStatus.completed);
      expect(assign.executions, 1);
      expect(asks, hasLength(1));
      expect(hooks.pre.where((n) => n == 'create'), hasLength(1));
    });

    test('a direct call is never asked the script\'s argument rule', () async {
      final assign = _Tool('create', argumentRefusal: (_) => 'never direct');
      final run = _Run([assign], call: 'create');
      await run.done.timeout(_deadline);
      expect(assign.executions, 1);
    });
  });
}
