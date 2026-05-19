import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/messaging/active_stream_registry.dart';
import 'package:cc_infra/src/messaging/agent_stream_processor.dart';
import 'package:test/test.dart';

/// Exercises the tool-argument-echo guard in [AgentStreamProcessor].
///
/// Some OpenAI-compatible servers stream a single tool call twice — once as
/// `delta.content` (the `<tool_call>` markup with its tags stripped one by one,
/// so the bare argument values survive as prose) and once as `delta.tool_calls`.
/// The transcript then shows the command/path as a text bubble directly above
/// the rich tool row for the same call. The guard blanks a text segment that
/// turns out to be nothing but an echo of the arguments that followed it, and
/// must leave every segment carrying real prose alone.
void main() {
  late FakeMessagingRepository repo;
  late ActiveStreamRegistry registry;
  late AgentStreamProcessor processor;
  late StreamController<AgentProcessEvent> events;

  const messageId = 'msg-1';

  setUp(() {
    repo = FakeMessagingRepository();
    registry = ActiveStreamRegistry();
    processor = AgentStreamProcessor(
      agentDispatchService: FakeAgentDispatchService(),
      repo: repo,
      streamRegistry: registry,
    );
    events = StreamController<AgentProcessEvent>();
    registry.register(messageId, channelId: 'chan-1');
    processor.processStream(
      workspaceId: 'ws-1',
      stream: events.stream,
      dispatchResult: AgentDispatchResult(
        stream: const Stream.empty(),
        dispatchId: 'dispatch-1',
        runLog: AgentRunLog(
          id: 'run-1',
          workspaceId: 'ws-1',
          agentId: 'agent-1',
          status: RunStatus.running,
          startedAt: DateTime.utc(2026, 7, 25),
        ),
      ),
      channelId: 'chan-1',
      agentId: 'agent-1',
      agentName: 'ceo',
      messageId: messageId,
    );
  });

  tearDown(() async {
    await events.close();
  });

  /// Pushes [event] and lets the processor's listener drain it.
  Future<void> emit(AgentProcessEvent event) async {
    events.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> text(String value) => emit(TextEvent(content: value));

  Future<void> toolCall(
    String name,
    String callId,
    Map<String, dynamic> inputs,
  ) => emit(ToolCallEvent(toolName: name, toolCallId: callId, inputs: inputs));

  List<TranscriptSegment> segments() =>
      registry.snapshot(messageId) ?? const [];

  String? textAt(int index) {
    final seg = segments()[index];
    return seg is TextSegment ? seg.text : null;
  }

  group('tool-argument echo', () {
    test('blanks a text segment that only echoes one tool call', () async {
      await text('\n\n\n\n\ncat lib/main.dart | head -100\n\n\n');
      await toolCall('bash', 'call_fda93156', {
        'command': 'cat lib/main.dart | head -100',
      });

      expect(segments(), hasLength(2));
      expect(textAt(0), isEmpty);
      expect(segments()[1], isA<ToolSegment>());
    });

    test('blanks only once every call in the run is subtracted', () async {
      // One text segment can precede several calls, so the residue is drained
      // cumulatively — the first call alone must not fire the guard.
      await text('\n\n\n\n\ncat a.dart\n\n\n\n\n\n\ncat b.dart\n\n\n');
      await toolCall('bash', 'call_4c0b9d34', {'command': 'cat a.dart'});
      expect(
        textAt(0),
        isNotEmpty,
        reason: 'residue still holds the second command',
      );

      await toolCall('bash', 'call_c10907b3', {'command': 'cat b.dart'});
      expect(textAt(0), isEmpty);
      expect(segments(), hasLength(3));
    });

    test('subtracts every string argument of a multi-argument call', () async {
      await text('\n\n\n\n\n97f166cd\n\n\npr detail tabs\n\n\n');
      await toolCall('search_code', 'call_715d6e28', {
        'repo_id': '97f166cd',
        'query': 'pr detail tabs',
      });

      expect(textAt(0), isEmpty);
    });

    test('keeps prose that merely mentions the argument', () async {
      await text('Let me inspect lib/main.dart to see the entry point.');
      await toolCall('read', 'call_1', {'path': 'lib/main.dart'});

      expect(textAt(0), 'Let me inspect lib/main.dart to see the entry point.');
    });

    test('keeps prose when the call has no string arguments', () async {
      await text('Checking the todo list.');
      await toolCall('todo_read', 'call_2', {'limit': 20});

      expect(textAt(0), 'Checking the todo list.');
    });

    test('never blanks an incidentally-empty text segment', () async {
      // No argument value matched, so nothing was subtracted — a whitespace-only
      // segment must not be mistaken for a fully-drained echo (it is already
      // invisible, but firing here would mask a real bug elsewhere).
      await text('   ');
      await toolCall('read', 'call_3', {'path': 'lib/main.dart'});

      expect(textAt(0), '   ');
    });

    test('a reasoning block between text and tool protects the text', () async {
      await text('cat lib/main.dart');
      await emit(ThinkingEvent(content: 'Now I will run it.'));
      await toolCall('bash', 'call_4', {'command': 'cat lib/main.dart'});

      expect(textAt(0), 'cat lib/main.dart');
    });

    test('an earlier turn-echo does not disarm a later real answer', () async {
      await text('\n\n\n\n\ncat a.dart\n\n\n');
      await toolCall('bash', 'call_5', {'command': 'cat a.dart'});
      await text('Here is what a.dart does.');
      await toolCall('bash', 'call_6', {'command': 'cat b.dart'});

      expect(textAt(0), isEmpty);
      expect(textAt(2), 'Here is what a.dart does.');
    });

    test('the echo leaves the persisted message body', () async {
      await text('\n\n\n\n\ncat a.dart\n\n\n');
      await toolCall('bash', 'call_7', {'command': 'cat a.dart'});
      await text('All done.');
      // Let the flush debounce elapse so the row is rewritten.
      await Future<void>.delayed(const Duration(milliseconds: 1300));

      expect(repo.lastContent, 'All done.');
    });
  });
}

class FakeMessagingRepository implements MessagingRepository {
  String? lastContent;

  @override
  Future<void> updateMessage(
    String workspaceId,
    String messageId, {
    String? content,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    lastContent = content;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAgentDispatchService implements AgentDispatchService {
  @override
  Future<void> completeRun(
    AgentRunLog runLog,
    String? summary, {
    RunCost? cost,
  }) async {}

  @override
  Future<void> failRun(AgentRunLog runLog, String error) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
