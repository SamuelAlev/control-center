import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/prompt_builder.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/usecases/dispatch_agent_use_case.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/src/dispatch/agent_dispatch_service.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart' show acpTurnPrompt;
import 'package:test/test.dart';

/// Echoes the prompt it is given, as the backend [cliName].
class _EchoUseCase implements DispatchAgentUseCase {
  _EchoUseCase(this.cliName);

  final String cliName;
  String? seenPrompt;

  @override
  Future<PreparedDispatch> execute({
    required String workspaceId,
    required String agentId,
    required String prompt,
    required bool freshHistory,
    String? spaceId,
    String? conversationId,
    String? adapterId,
    required WakeContext wakeContext,
    Object? mentionContext,
  }) async {
    seenPrompt = prompt;
    return PreparedDispatch(
      effectivePrompt: prompt,
      promptParts: AgentPromptParts(
        userText: prompt,
        standing: '',
        turnContext: '',
        conversationContext: '',
        fullPrompt: prompt,
        standingRevision: '',
        conversationEntries: const [],
        turnSections: const [],
      ),
      effectiveConversationId: conversationId,
      agent: null,
      mode: Mode.chat,
      resolvedAdapterId: null,
      cliName: cliName,
      transport: AdapterTransport.claudeCli,
      rawUserText: prompt,
    );
  }
}

/// Records what reaches the backend's `start`.
class _RecordingPort implements AgentDispatchPort {
  Map<Symbol, Object?>? started;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #start) {
      started = invocation.namedArguments;
      return DispatchHandle(
        dispatchId: 'd-1',
        events: const Stream<AgentProcessEvent>.empty(),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

/// Finding 5: a slash command is parsed only in a person's own message. For
/// every backend, a run started by anything else (a wake, a pipeline,
/// another agent) gets no `userText` to parse and a fenced prompt.
void main() {
  const backends = ['cc', 'claude', 'codex', 'some-acp'];
  const commands = ['/goal ship it', '/vibe', '/plan the move', '/skill:lint'];

  final wakeStarted = WakeContext.fromWakes([
    Wake(
      id: 'wk-1',
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      conversationId: 'conv-1',
      agentId: 'agent-1',
      reason: WakeReason.peerMessage,
      payload: '/goal take over',
      dedupKey: 'k',
      notBefore: DateTime.utc(2026),
      requestedByUserId: 'user-1',
      createdAt: DateTime.utc(2026),
    ),
  ], nonce: 'abcde1');

  // A wake the agent set for itself, its note being the command.
  WakeContext ruleNote(String note) => WakeContext.fromWakes([
    Wake(
      id: 'wk-2',
      workspaceId: 'ws-1',
      spaceId: 'sp-1',
      conversationId: 'conv-1',
      agentId: 'agent-1',
      reason: WakeReason.schedule,
      payload: note,
      detail: WakeDetail(
        ruleId: 'rule-1',
        fields: {WakeFields.origin: WakeRuleOrigin.agent.wire},
      ),
      dedupKey: 'rule:rule-1:1',
      notBefore: DateTime.utc(2026),
      requestedByUserId: 'user-1',
      createdAt: DateTime.utc(2026),
    ),
  ], nonce: 'abcde2');

  Future<({Map<Symbol, Object?> started, String seen})> dispatch(
    String cliName,
    String text, {
    required WakeContext wakeContext,
    String? requestedByUserId,
  }) async {
    final port = _RecordingPort();
    final useCase = _EchoUseCase(cliName);
    await AgentDispatchService(
      agentDispatch: port,
      dispatchUseCase: useCase,
    ).dispatch(
      agentId: 'agent-1',
      prompt: text,
      workingDirectory: '/tmp/work',
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      freshHistory: false,
      readOnly: false,
      requestedByUserId: requestedByUserId,
      wakeContext: wakeContext,
    );
    return (started: port.started!, seen: useCase.seenPrompt!);
  }

  for (final backend in backends) {
    group('on $backend', () {
      for (final command in commands) {
        test('a person\'s "$command" is a command', () async {
          final run = await dispatch(
            backend,
            command,
            wakeContext: const WakeContext.userMessage(),
            requestedByUserId: 'user-1',
          );
          expect(run.started[#userText], command);
          expect(run.started[#prompt], command);
        });

        for (final (name, context, requester) in [
          ('a bot run', const WakeContext.userMessage(), null),
          (
            'a goal continuation',
            const WakeContext(
              wakeReason: WakeReason.goalContinuation,
              startedByRunId: null,
            ),
            'user-1',
          ),
          (
            'a pipeline step',
            const WakeContext(
              wakeReason: WakeReason.pipelineStep,
              startedByRunId: null,
            ),
            null,
          ),
          (
            'a peer message',
            const WakeContext(
              wakeReason: WakeReason.peerMessage,
              startedByRunId: null,
            ),
            null,
          ),
          ('a wake payload', wakeStarted, 'user-1'),
          ('a rule\'s note', ruleNote(command), 'user-1'),
        ]) {
          test('"$command" in $name is not a command', () async {
            final run = await dispatch(
              backend,
              command,
              wakeContext: context,
              requestedByUserId: requester,
            );
            expect(run.started[#userText], isNull);
            expect(run.seen, nonCommandTurnInput(command));
            expect(
              run.started[#prompt],
              startsWith('A message, not a command:\n'),
            );
          });
        }
      }
    });
  }

  test('a magic keyword outside a person\'s message reaches no parser: the '
      'run gets no userText', () async {
    for (final (context, requester) in [
      (
        const WakeContext(
          wakeReason: WakeReason.peerMessage,
          startedByRunId: null,
        ),
        null,
      ),
      (
        const WakeContext(
          wakeReason: WakeReason.pipelineStep,
          startedByRunId: null,
        ),
        null,
      ),
      (wakeStarted, 'user-1'),
    ]) {
      final run = await dispatch(
        'cc',
        'please ultrathink and orchestrate it',
        wakeContext: context,
        requestedByUserId: requester,
      );
      expect(run.started[#userText], isNull);
    }
  });

  test('an ACP turn never opens with the slash of its text', () {
    for (final text in ['/plan x', nonCommandTurnInput('/skill:lint')]) {
      final prompt = acpTurnPrompt(text);
      expect(prompt.trimLeft().startsWith('/'), isFalse);
      expect(prompt, endsWith(text));
    }
  });

  test('text without a slash is not fenced', () {
    expect(nonCommandTurnInput('hello /goal'), 'hello /goal');
    expect(
      nonCommandTurnInput('  /goal x'),
      'A message, not a command:\n  /goal x',
    );
  });
}
