import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_remote/conversation_progress_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ContextInspection inspection(
    ContextRunner runner,
    List<ContextSegment> segments,
  ) => ContextInspection(
    workspaceId: 'workspace',
    spaceId: 'space',
    agentId: 'agent',
    agentName: 'Agent',
    mode: 'chat',
    runner: runner,
    windowTokens: 16000,
    segments: segments,
  );
  const system = ContextSegment(
    kind: ContextSegmentKind.systemPrompt,
    tokens: 2000,
    chars: 7000,
  );
  const history = ContextSegment(
    kind: ContextSegmentKind.conversation,
    tokens: 300,
    chars: 1000,
  );
  const tokens = ConversationTokenTotals(tokens: 1000, chars: 4000);

  test('missing readings and capacity stay unknown, not zero', () {
    final result = progressContextReading(null, null, null);
    expect(result.usedTokens, isNull);
    expect(result.windowTokens, isNull);
    expect(result.measured, isFalse);
  });

  test('provider-reported context wins over estimates and run window wins', () {
    final reading = progressContextReading(
      const ConversationTokenTotals(
        tokens: 1000,
        chars: 4000,
        reportedContextTokens: 7100,
        reportedWindowTokens: 8000,
      ),
      inspection(ContextRunner.harness, [system]),
      32000,
    );
    expect(reading.usedTokens, 7100);
    expect(reading.windowTokens, 8000);
    expect(reading.measured, isTrue);
  });

  test('harness estimate adds live conversation to persistent context', () {
    final reading = progressContextReading(
      tokens,
      inspection(ContextRunner.harness, [system]),
      null,
    );
    expect(reading.usedTokens, 3000);
    expect(reading.measured, isFalse);
  });

  test('Claude history inside server inspection is not counted twice', () {
    final reading = progressContextReading(
      tokens,
      inspection(ContextRunner.claudeCode, [system, history]),
      null,
    );
    expect(reading.usedTokens, 2300);
  });

  test('Claude server history remains readable while aggregate is loading', () {
    final reading = progressContextReading(
      null,
      inspection(ContextRunner.claudeCode, [system, history]),
      null,
    );
    expect(reading.usedTokens, 2300);
    expect(reading.windowTokens, 16000);
    expect(reading.measured, isFalse);
  });

  test('run tree retains subagents, orphans and cycles once each', () {
    AgentRunLogDto run(String id, [String? parent]) => AgentRunLogDto(
      id: id,
      agentId: 'agent',
      startedAt: '2025-01-01T00:00:00Z',
      status: 'completed',
      parentRunId: parent,
    );
    final ordered = progressRunTree([
      run('child', 'root'),
      run('root'),
      run('orphan', 'absent'),
      run('cycleA', 'cycleB'),
      run('cycleB', 'cycleA'),
    ]);
    expect(ordered.map((entry) => entry.$1.id).toList(), [
      'root',
      'child',
      'orphan',
      'cycleA',
      'cycleB',
    ]);
    expect(ordered.map((entry) => entry.$2).toList(), [0, 1, 0, 0, 1]);
  });
}
