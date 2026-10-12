import 'dart:async';

import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

const _deadline = Duration(seconds: 5);

class _Tool extends HarnessTool {
  _Tool(
    this.name, {
    this.approvalTier = ToolApprovalTier.read,
    this.speculativeReadSafe = false,
  });

  @override
  final String name;
  @override
  final ToolApprovalTier approvalTier;
  @override
  final bool speculativeReadSafe;
  final cancellationTokens = <CancellationToken?>[];
  final started = Completer<void>();
  final finish = Completer<HarnessToolResult>();
  int executions = 0;

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
    cancellationTokens.add(context.cancel);
    if (!started.isCompleted) {
      started.complete();
    }
    return finish.future;
  }

  void complete() {
    if (!finish.isCompleted) {
      finish.complete(HarnessToolResult.success('Evidence from $name.'));
    }
  }
}

class _Provider implements LlmProviderPort {
  _Provider(this.names);

  final List<String> names;
  int calls = 0;

  @override
  String get displayName => 'Scheduling scenario';
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
      yield const LlmTextDelta('All observations received.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

class _StreamingProvider extends _Provider {
  _StreamingProvider(this.streams) : super(const []);

  final List<Stream<LlmEvent>> streams;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) {
    final index = calls++;
    return index < streams.length
        ? streams[index]
        : Stream.fromIterable(const [
            LlmTextDelta('All observations received.'),
            LlmDone(stopReason: LlmStopReason.endTurn),
          ]);
  }
}

class _RetryRead extends _Tool {
  _RetryRead() : super('read', speculativeReadSafe: true);

  final retryStarted = Completer<void>();
  final retryFinish = Completer<HarnessToolResult>();

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) {
    if (executions == 0) {
      return super.execute(args, context);
    }
    executions++;
    cancellationTokens.add(context.cancel);
    retryStarted.complete();
    return retryFinish.future;
  }
}

class _Run {
  _Run({
    required List<_Tool> tools,
    required this.history,
    AgentLoopConfig config = const AgentLoopConfig(maxParallelToolCalls: 2),
    CancellationToken? cancel,
    LlmProviderPort? provider,
  }) {
    done = const AgentLoopRunner()
        .run(
          history: history,
          userMessage: 'Inspect the independent inputs, then continue.',
          tools: tools,
          provider:
              provider ?? _Provider(tools.map((tool) => tool.name).toList()),
          config: config,
          cancel: cancel,
        )
        .forEach((event) {
          events.add(event);
          if (event is LoopTextDelta && !textReceived.isCompleted) {
            textReceived.complete();
          }
          if (event is LoopToolCallResult) {
            final result = resultFor(event.toolName);
            if (!result.isCompleted) {
              result.complete(event);
            }
          }
        });
  }

  final List<HarnessMessage> history;
  final events = <AgentLoopEvent>[];
  final textReceived = Completer<void>();
  final _results = <String, Completer<LoopToolCallResult>>{};
  late final Future<void> done;

  Completer<LoopToolCallResult> resultFor(String name) =>
      _results.putIfAbsent(name, Completer<LoopToolCallResult>.new);
}

void main() {
  test('a free slot advances while a slower read is still running', () async {
    final slow = _Tool('slow');
    final fast = _Tool('fast');
    final next = _Tool('next');
    final tools = [slow, fast, next];
    final history = <HarnessMessage>[];
    final run = _Run(tools: tools, history: history);
    addTearDown(() async {
      for (final tool in tools) {
        tool.complete();
      }
      await run.done;
    });

    await Future.wait([
      slow.started.future,
      fast.started.future,
    ]).timeout(_deadline);
    expect(next.started.isCompleted, isFalse);
    fast.complete();
    await run.resultFor('fast').future.timeout(_deadline);
    await next.started.future.timeout(_deadline);
    expect(slow.finish.isCompleted, isFalse);

    next.complete();
    await run.resultFor('next').future.timeout(_deadline);
    expect(run.events.whereType<LoopToolCallResult>().map((e) => e.toolName), [
      'fast',
      'next',
    ], reason: 'completed work is visible without waiting for the first call');
    slow.complete();
    await run.done.timeout(_deadline);
    final results = history
        .where((message) => message.role == HarnessRole.tool)
        .single
        .content
        .cast<HarnessToolResultBlock>();
    expect(results.map((result) => result.toolUseId), [
      'call_slow',
      'call_fast',
      'call_next',
    ]);
    expect(results.map((result) => result.content), [
      'Evidence from slow.',
      'Evidence from fast.',
      'Evidence from next.',
    ]);
  });

  test('an effectful call is a barrier between independent regions', () async {
    final slow = _Tool('before_slow');
    final fast = _Tool('before_fast');
    final mutation = _Tool('mutation', approvalTier: ToolApprovalTier.write);
    final after = _Tool('after');
    final tools = [slow, fast, mutation, after];
    final approvals = <String>[];
    final run = _Run(
      tools: tools,
      history: [],
      config: AgentLoopConfig(
        maxParallelToolCalls: 2,
        autoApprove: false,
        approvalCallback: (tool, _) async {
          approvals.add(tool.name);
          return const ToolGateDecision.allow();
        },
      ),
    );
    addTearDown(() async {
      for (final tool in tools) {
        tool.complete();
      }
      await run.done;
    });

    await Future.wait([
      slow.started.future,
      fast.started.future,
    ]).timeout(_deadline);
    fast.complete();
    await run.resultFor(fast.name).future.timeout(_deadline);
    expect(mutation.started.isCompleted, isFalse);
    expect(after.started.isCompleted, isFalse);
    expect(approvals, isEmpty);

    slow.complete();
    await mutation.started.future.timeout(_deadline);
    expect(approvals, ['mutation']);
    expect(after.started.isCompleted, isFalse);
    mutation.complete();
    await after.started.future.timeout(_deadline);
    after.complete();
    await run.done.timeout(_deadline);
    expect(
      run.events.whereType<LoopDone>().single.reason,
      LoopDoneReason.completed,
    );
  });

  test(
    'cancellation stops admission and pairs every requested result',
    () async {
      final first = _Tool('first');
      final second = _Tool('second');
      final queued = _Tool('queued');
      final tools = [first, second, queued];
      final source = CancellationTokenSource();
      final history = <HarnessMessage>[];
      final run = _Run(tools: tools, history: history, cancel: source.token);
      addTearDown(() {
        for (final tool in tools) {
          tool.complete();
        }
      });

      await Future.wait([
        first.started.future,
        second.started.future,
      ]).timeout(_deadline);
      source.cancel('The user stopped the run.');
      await run.done.timeout(_deadline);
      expect(queued.executions, 0);
      expect(
        run.events.whereType<LoopDone>().single.reason,
        LoopDoneReason.cancelled,
      );
      final results = history
          .where((message) => message.role == HarnessRole.tool)
          .single
          .content
          .cast<HarnessToolResultBlock>();
      expect(results.map((result) => result.toolUseId), [
        'call_first',
        'call_second',
        'call_queued',
      ]);
      expect(results.every((result) => result.isError), isTrue);
    },
  );

  test('opted-in read finishes while the model stream is still open', () async {
    final read = _Tool('read', speculativeReadSafe: true);
    final stream = StreamController<LlmEvent>();
    final history = <HarnessMessage>[];
    final run = _Run(
      tools: [read],
      history: history,
      provider: _StreamingProvider([stream.stream]),
      config: const AgentLoopConfig(overlapReadOnlyTools: true),
    );
    addTearDown(() {
      read.complete();
      if (!stream.isClosed) {
        unawaited(stream.close());
      }
    });

    stream.add(
      const LlmToolUseDelta(
        id: 'read_before_end',
        name: 'read',
        argumentsJson: '{}',
      ),
    );
    await read.started.future.timeout(_deadline);
    read.complete();
    await run.resultFor('read').future.timeout(_deadline);
    expect(stream.isClosed, isFalse);
    expect(run.events.whereType<LoopDone>(), isEmpty);
    stream.add(const LlmDone(stopReason: LlmStopReason.toolUse));
    await stream.close();
    await run.done.timeout(_deadline);
    expect(
      read.executions,
      1,
      reason: 'the final turn must reuse the early read',
    );
    final result =
        history
                .where((message) => message.role == HarnessRole.tool)
                .single
                .content
                .single
            as HarnessToolResultBlock;
    expect(result.toolUseId, 'read_before_end');
    expect(result.content, 'Evidence from read.');
  });

  test(
    'a write blocks itself and later reads from streaming overlap',
    () async {
      final write = _Tool(
        'write',
        approvalTier: ToolApprovalTier.write,
        speculativeReadSafe: true,
      );
      final read = _Tool('read', speculativeReadSafe: true);
      final stream = StreamController<LlmEvent>();
      final run = _Run(
        tools: [write, read],
        history: [],
        provider: _StreamingProvider([stream.stream]),
        config: const AgentLoopConfig(overlapReadOnlyTools: true),
      );
      addTearDown(() {
        write.complete();
        read.complete();
        if (!stream.isClosed) {
          unawaited(stream.close());
        }
      });

      stream
        ..add(
          const LlmToolUseDelta(
            id: 'write',
            name: 'write',
            argumentsJson: '{}',
          ),
        )
        ..add(
          const LlmToolUseDelta(
            id: 'read_after_write',
            name: 'read',
            argumentsJson: '{}',
          ),
        )
        ..add(const LlmTextDelta('The invocation batch is not finished yet.'));
      await run.textReceived.future.timeout(_deadline);
      expect(write.started.isCompleted, isFalse);
      expect(read.started.isCompleted, isFalse);
      stream.add(const LlmDone(stopReason: LlmStopReason.toolUse));
      await stream.close();
      await write.started.future.timeout(_deadline);
      expect(read.started.isCompleted, isFalse);
      write.complete();
      await read.started.future.timeout(_deadline);
      read.complete();
      await run.done.timeout(_deadline);
    },
  );

  test(
    'retry cancels abandoned reads and cannot reuse stale results',
    () async {
      final read = _RetryRead();
      final first = StreamController<LlmEvent>();
      final retry = StreamController<LlmEvent>();
      final history = <HarnessMessage>[];
      final run = _Run(
        tools: [read],
        history: history,
        provider: _StreamingProvider([first.stream, retry.stream]),
        config: const AgentLoopConfig(overlapReadOnlyTools: true),
      );
      addTearDown(() {
        read.complete();
        if (!read.retryFinish.isCompleted) {
          read.retryFinish.complete(HarnessToolResult.success('retry cleanup'));
        }
        if (!first.isClosed) {
          unawaited(first.close());
        }
        if (!retry.isClosed) {
          unawaited(retry.close());
        }
      });

      first.add(
        const LlmToolUseDelta(
          id: 'abandoned_read',
          name: 'read',
          argumentsJson: '{}',
        ),
      );
      await read.started.future.timeout(_deadline);
      first.add(
        const LlmError(
          'The provider disconnected.',
          code: 'overloaded_error',
          retryable: true,
          retryAfterMs: 0,
        ),
      );
      await first.close();
      retry.add(
        const LlmToolUseDelta(
          id: 'retry_read',
          name: 'read',
          argumentsJson: '{}',
        ),
      );
      await read.retryStarted.future.timeout(_deadline);
      expect(read.cancellationTokens.first!.isCancelled, isTrue);
      read.finish.complete(
        HarnessToolResult.success('Stale abandoned evidence.'),
      );
      read.retryFinish.complete(
        HarnessToolResult.success('Fresh retry evidence.'),
      );
      retry.add(const LlmDone(stopReason: LlmStopReason.toolUse));
      await retry.close();
      await run.done.timeout(_deadline);
      final results = history
          .where((message) => message.role == HarnessRole.tool)
          .single
          .content
          .cast<HarnessToolResultBlock>();
      expect(results.map((result) => result.toolUseId), ['retry_read']);
      expect(results.single.content, 'Fresh retry evidence.');
    },
  );

  test('read overlap remains off unless explicitly enabled', () async {
    final read = _Tool('read', speculativeReadSafe: true);
    final stream = StreamController<LlmEvent>();
    final run = _Run(
      tools: [read],
      history: [],
      provider: _StreamingProvider([stream.stream]),
    );
    addTearDown(() {
      read.complete();
      if (!stream.isClosed) {
        unawaited(stream.close());
      }
    });
    stream
      ..add(
        const LlmToolUseDelta(id: 'read', name: 'read', argumentsJson: '{}'),
      )
      ..add(const LlmTextDelta('Still preparing the invocation batch.'));
    await run.textReceived.future.timeout(_deadline);
    expect(read.started.isCompleted, isFalse);
    stream.add(const LlmDone(stopReason: LlmStopReason.toolUse));
    await stream.close();
    await read.started.future.timeout(_deadline);
    read.complete();
    await run.done.timeout(_deadline);
  });

  test('cancellation closes an idle overlapped model stream', () async {
    final source = CancellationTokenSource();
    final stream = StreamController<LlmEvent>();
    final history = <HarnessMessage>[];
    final run = _Run(
      tools: [],
      history: history,
      cancel: source.token,
      provider: _StreamingProvider([stream.stream]),
      config: const AgentLoopConfig(overlapReadOnlyTools: true),
    );
    addTearDown(() {
      if (!stream.isClosed) {
        unawaited(stream.close());
      }
    });
    stream.add(const LlmTextDelta('A partial response.'));
    await run.textReceived.future.timeout(_deadline);
    source.cancel('The user stopped the run.');
    await run.done.timeout(_deadline);
    expect(
      run.events.whereType<LoopDone>().single.reason,
      LoopDoneReason.cancelled,
    );
    expect(
      history.where((message) => message.role == HarnessRole.assistant),
      isEmpty,
    );
  });

  test('cancellation closes an idle model stream with overlap OFF', () async {
    // The DEFAULT configuration. Consuming the provider stream directly meant
    // cancellation was only noticed when an event arrived, so an idle stream —
    // the shape a wall-clock-limited turn exists to bound, and the shape a
    // worker drain has to interrupt — stayed open until the provider chose to
    // send something.
    final source = CancellationTokenSource();
    final stream = StreamController<LlmEvent>();
    var providerCancelled = false;
    stream.onCancel = () => providerCancelled = true;
    final ledger = ProviderCallLedger(runId: 'run-1');
    final history = <HarnessMessage>[];
    final run = _Run(
      tools: [],
      history: history,
      cancel: source.token,
      provider: ObservedLlmProvider(
        _StreamingProvider([stream.stream]),
        observer: ledger,
        identity: ledger.identity,
      ),
      config: const AgentLoopConfig(),
    );
    addTearDown(() {
      if (!stream.isClosed) {
        unawaited(stream.close());
      }
    });

    stream.add(const LlmTextDelta('A partial response.'));
    await run.textReceived.future.timeout(_deadline);
    source.cancel('The user stopped the run.');
    await run.done.timeout(_deadline);

    expect(
      run.events.whereType<LoopDone>().single.reason,
      LoopDoneReason.cancelled,
    );
    expect(
      history.where((message) => message.role == HarnessRole.assistant),
      isEmpty,
      reason: 'a cancelled turn banks no assistant message',
    );
    expect(
      providerCancelled,
      isTrue,
      reason: 'the stream must actually be unsubscribed, not merely abandoned',
    );
    expect(
      ledger.records,
      hasLength(1),
      reason: 'the observed provider finalizes its call exactly once',
    );
    expect(ledger.records.single.outcome, ProviderCallOutcome.cancelled);
    expect(
      run.events.whereType<LoopTextDelta>().single.text,
      'A partial response.',
      reason: 'no speculation: the tokens that did arrive are still delivered',
    );
  });

  test('overlap OFF does not start a safe read early', () async {
    // The other half of the contract: making the default path cancellable must
    // not make it eager. A tool the model has fully specified still waits for
    // the turn to end.
    final read = _Tool('read', speculativeReadSafe: true);
    final stream = StreamController<LlmEvent>();
    final run = _Run(
      tools: [read],
      history: <HarnessMessage>[],
      provider: _StreamingProvider([stream.stream]),
      config: const AgentLoopConfig(),
    );
    addTearDown(() {
      if (!stream.isClosed) {
        unawaited(stream.close());
      }
    });

    stream.add(
      const LlmToolUseDelta(id: 'call_read', name: 'read', argumentsJson: '{}'),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(
      read.started.isCompleted,
      isFalse,
      reason: 'the default must not read ahead of the model turn',
    );

    stream.add(const LlmDone(stopReason: LlmStopReason.toolUse));
    await stream.close();
    await read.started.future.timeout(_deadline);
    read.complete();
    await run.done.timeout(_deadline);
    expect(read.executions, 1);
  });

  test('a cancelled call is accounted for before the terminal event', () async {
    // The ordering that must be verified rather than assumed: the delegate's
    // cleanup can be slow (a socket teardown, a worker drain) and the run's
    // terminal event and the host's flush follow the cancellation. A record
    // emitted only after that cleanup could therefore land after the UI was
    // told the run finished — unaccounted spend.
    final token = CancellationTokenSource();
    final raw = StreamController<LlmEvent>();
    final cleanupGate = Completer<void>();
    addTearDown(() async {
      if (!cleanupGate.isCompleted) {
        cleanupGate.complete();
      }
      await raw.close();
    });
    final timeline = <String>[];
    var delegateCleanupDone = false;
    raw.onCancel = () async {
      timeline.add('delegateCleanupStart');
      await cleanupGate.future;
      timeline.add('delegateCleanupDone');
      delegateCleanupDone = true;
    };

    final records = <ProviderCallRecord>[];
    final events = <AgentLoopEvent>[];
    final provider = ObservedLlmProvider(
      _StreamingProvider([raw.stream]),
      observer: _TimelineObserver(timeline, records),
      identity: ProviderCallIdentityAllocator(),
    );
    final done = const AgentLoopRunner()
        .run(
          history: <HarnessMessage>[],
          userMessage: 'go',
          tools: const [],
          provider: provider,
          config: const AgentLoopConfig(),
          cancel: token.token,
        )
        .listen((event) {
          events.add(event);
          if (event is LoopDone) {
            timeline.add('loopDone');
          }
        })
        .asFuture<void>();

    raw.add(const LlmTextDelta('Partial.'));
    raw.add(const LlmUsage(inputTokens: 400, outputTokens: 6));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    token.cancel('The user stopped the run.');
    // Let the cancellation propagate while the delegate's cleanup is held open.
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(timeline, contains('delegateCleanupStart'));
    expect(
      records,
      hasLength(1),
      reason:
          'the cancelled call is banked while the delegate is still closing',
    );
    expect(records.single.outcome, ProviderCallOutcome.cancelled);
    expect(
      records.single.usage.inputTokens,
      400,
      reason: 'the partial usage already reported is kept, not discarded',
    );
    expect(timeline, contains('record'));
    expect(
      timeline.indexOf('record'),
      lessThan(timeline.indexOf('delegateCleanupStart')),
      reason: 'banked BEFORE the delegate cleanup is awaited',
    );
    expect(
      timeline,
      isNot(contains('loopDone')),
      reason: 'the loop drains the delegate before terminating',
    );
    expect(delegateCleanupDone, isFalse);

    cleanupGate.complete();
    await done.timeout(_deadline);

    expect(
      timeline.indexOf('delegateCleanupDone'),
      lessThan(timeline.indexOf('loopDone')),
      reason: 'the terminal event follows the drain',
    );
    expect(records, hasLength(1), reason: 'banked exactly once');
    expect(
      events.whereType<LoopDone>().single.reason,
      LoopDoneReason.cancelled,
    );
  });
}

/// Records the arrival order of a provider call alongside the record itself.
class _TimelineObserver implements ProviderCallObserver {
  _TimelineObserver(this.timeline, this.records);

  final List<String> timeline;
  final List<ProviderCallRecord> records;

  @override
  void onProviderCall(ProviderCallRecord record) {
    records.add(record);
    timeline.add('record');
  }
}
