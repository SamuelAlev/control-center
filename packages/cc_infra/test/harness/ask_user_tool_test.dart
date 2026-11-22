import 'dart:async';

import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_infra/src/harness/ask_user_tool.dart';
import 'package:test/test.dart';

/// A port that records what it was asked and answers with a scripted reply.
class _RecordingPort implements AgentQuestionPort {
  _RecordingPort(this._answer);
  final AgentQuestionAnswer? _answer;
  AgentQuestionRequest? seen;
  Future<void>? seenAbandoned;

  @override
  Future<AgentQuestionAnswer?> ask(
    AgentQuestionRequest request, {
    Future<void>? abandoned,
  }) async {
    seen = request;
    seenAbandoned = abandoned;
    return _answer;
  }
}

const _ctx = HarnessToolContext(workingDirectory: '.');

AskUserTool _tool(AgentQuestionPort port) => AskUserTool(
  port: port,
  workspaceId: 'ws1',
  spaceId: 'space1',
  conversationId: 'conv-side',
  askedByAgentId: 'agent1',
  askedByName: 'Scout',
);

void main() {
  group('AskUserTool', () {
    test(
      'renders in the run conversation despite a model-selected destination',
      () async {
        final port = _RecordingPort(
          const AgentQuestionAnswer(selectedLabels: ['Postgres']),
        );
        final result = await _tool(port).execute({
          'question': 'Which database?',
          'context': 'Both are already in the lockfile.',
          'conversation_id': 'conv-standing',
          'space_id': 'space-other',
          'workspace_id': 'ws-other',
          'options': [
            {
              'label': 'Postgres',
              'description': 'What the rest of the app uses',
            },
            {'label': 'SQLite'},
          ],
        }, _ctx);

        expect(result.isError, isFalse);
        expect(result.content, contains('Postgres'));
        final asked = port.seen!;
        expect(asked.workspaceId, 'ws1');
        expect(asked.spaceId, 'space1');
        expect(asked.conversationId, 'conv-side');
        expect(asked.askedByAgentId, 'agent1');
        expect(asked.askedByName, 'Scout');
        expect(asked.options.map((o) => o.label), ['Postgres', 'SQLite']);
        expect(asked.options.first.description, isNotNull);
        expect(
          asked.options.last.description,
          isNull,
          reason: 'an omitted description must not become an empty string',
        );
      },
    );

    test('free text defaults on when no options are offered', () async {
      final port = _RecordingPort(
        const AgentQuestionAnswer(freeText: 'use the staging bucket'),
      );
      await _tool(port).execute({'question': 'Which bucket?'}, _ctx);
      expect(
        port.seen!.allowFreeText,
        isTrue,
        reason: 'a question with neither options nor free text is unanswerable',
      );
    });

    test('free text defaults off when options are offered', () async {
      final port = _RecordingPort(
        const AgentQuestionAnswer(selectedLabels: ['a']),
      );
      await _tool(port).execute({
        'question': 'Which?',
        'options': [
          {'label': 'a'},
          {'label': 'b'},
        ],
      }, _ctx);
      expect(port.seen!.allowFreeText, isFalse);
    });

    test('an unanswerable question is refused before it is posted', () async {
      final port = _RecordingPort(const AgentQuestionAnswer());
      final result = await _tool(
        port,
      ).execute({'question': 'Which?', 'allow_free_text': false}, _ctx);

      expect(result.isError, isTrue);
      expect(result.content, contains('allow_free_text'));
      expect(
        port.seen,
        isNull,
        reason:
            'nothing should reach the user for a question they cannot '
            'answer',
      );
    });

    test('an empty question is refused', () async {
      final port = _RecordingPort(const AgentQuestionAnswer());
      final result = await _tool(port).execute({'question': '   '}, _ctx);
      expect(result.isError, isTrue);
      expect(port.seen, isNull);
    });

    test('a timeout tells the agent to proceed, not to re-ask', () async {
      final port = _RecordingPort(null);
      final result = await _tool(port).execute({'question': 'Which?'}, _ctx);

      expect(result.isError, isTrue);
      expect(result.content, contains('Do not ask'));
      expect(
        result.content,
        contains('assumption'),
        reason: 'the model needs a next move, not just a failure',
      );
    });

    test('an empty answer is a success, distinct from a timeout', () async {
      final port = _RecordingPort(const AgentQuestionAnswer());
      final result = await _tool(port).execute({'question': 'Which?'}, _ctx);

      expect(result.isError, isFalse);
      expect(result.content, contains('empty answer'));
    });

    test(
      'a skipped question tells the agent to proceed, not to re-ask',
      () async {
        final port = _RecordingPort(const AgentQuestionAnswer(skipped: true));
        final result = await _tool(port).execute({'question': 'Which?'}, _ctx);

        expect(result.isError, isFalse);
        expect(result.content, contains('skipped'));
        expect(result.content, contains('Do not ask again'));
      },
    );

    test('options are capped so one call cannot flood the form', () async {
      final port = _RecordingPort(
        const AgentQuestionAnswer(selectedLabels: ['o0']),
      );
      await AskUserTool(
        port: port,
        workspaceId: 'ws1',
        spaceId: 'space1',
        conversationId: 'conv-side',
        maxOptions: 3,
      ).execute({
        'question': 'Which?',
        'options': [
          for (var i = 0; i < 20; i++) {'label': 'o$i'},
        ],
      }, _ctx);

      expect(port.seen!.options.length, 3);
    });

    test('malformed option entries are skipped, not fatal', () async {
      final port = _RecordingPort(
        const AgentQuestionAnswer(selectedLabels: ['real']),
      );
      await _tool(port).execute({
        'question': 'Which?',
        'options': [
          'not a map',
          {'label': ''},
          {'nope': 1},
          {'label': 'real'},
        ],
      }, _ctx);

      expect(port.seen!.options.map((o) => o.label), ['real']);
    });

    test('a stopped run closes the question it was waiting on', () async {
      final port = _RecordingPort(null);
      final source = CancellationTokenSource();
      await _tool(
        port,
      ).execute({'question': 'Which?'}, _ctx.withCancel(source.token));

      expect(port.seenAbandoned, isNotNull);
      var fired = false;
      unawaited(port.seenAbandoned!.then((_) => fired = true));
      source.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(fired, isTrue);
    });

    test('never joins a parallel batch', () {
      // Two forms competing for one human is not a race worth running.
      expect(_tool(_RecordingPort(null)).parallelSafe, isFalse);
    });

    test('is read-tier so it is never itself approval-gated', () {
      expect(_tool(_RecordingPort(null)).approvalTier, ToolApprovalTier.read);
    });
  });

  group('AskUserTool from a script', () {
    late RunScriptOrigins origins;
    setUp(() => origins = RunScriptOrigins(runId: 'run-1'));

    AskUserTool scripted(AgentQuestionPort port, {String? runId}) =>
        AskUserTool(
          port: port,
          workspaceId: 'ws1',
          spaceId: 'space1',
          conversationId: 'conv-side',
          runId: runId,
          scriptOrigins: origins,
        );

    test('waits on a person for the whole call', () {
      expect(_tool(_RecordingPort(null)).waitsOnPerson, isTrue);
    });

    test('declares the structured answer a script reads', () {
      final schema = _tool(_RecordingPort(null)).outputSchema;
      expect(schema['required'], ['selected', 'text', 'skipped']);
      expect((schema['properties'] as Map).keys, [
        'selected',
        'text',
        'skipped',
      ]);
    });

    test(
      'answers with the structured value beside the unchanged text',
      () async {
        final port = _RecordingPort(
          const AgentQuestionAnswer(
            selectedLabels: ['Postgres', 'SQLite'],
            freeText: '  keep both  ',
          ),
        );
        final result = await _tool(port).execute({
          'question': 'Which databases?',
          'options': [
            {'label': 'Postgres'},
            {'label': 'SQLite'},
          ],
          'multi_select': true,
          'allow_free_text': true,
        }, _ctx);

        expect(result.isError, isFalse);
        expect(
          result.content,
          const AgentQuestionAnswer(
            selectedLabels: ['Postgres', 'SQLite'],
            freeText: '  keep both  ',
          ).toPromptString(),
        );
        expect(result.structured, {
          'selected': ['Postgres', 'SQLite'],
          'text': 'keep both',
          'skipped': false,
        });
      },
    );

    test('a skipped question is a value, not a rejection', () async {
      final port = _RecordingPort(const AgentQuestionAnswer(skipped: true));
      final result = await _tool(port).execute({'question': 'Which?'}, _ctx);

      expect(result.isError, isFalse);
      expect(result.structured, {
        'selected': <String>[],
        'text': null,
        'skipped': true,
      });
    });

    test('a question that times out or is dismissed stays an error', () async {
      final port = _RecordingPort(null);
      final result = await _tool(port).execute({'question': 'Which?'}, _ctx);

      expect(result.isError, isTrue);
      expect(result.structured, isNull);
    });

    test('a script\'s question carries the script as its origin', () async {
      final port = _RecordingPort(const AgentQuestionAnswer(skipped: true));
      await scripted(port, runId: 'run-log-1').execute({
        'question': 'Which?',
      }, _ctx.withToolCallId('r/1').withParentToolCallId('r'));

      final origin = port.seen!.origin!;
      expect(origin.parentToolCallId, 'r');
      // No execution is registered under `r`: the form links no record.
      expect(origin.executionId, isNull);
      expect(port.seen!.runId, 'run-log-1');
    });

    test(
      'names the execution the script runs as, once it is registered',
      () async {
        final port = _RecordingPort(const AgentQuestionAnswer(skipped: true));
        origins.begin('r', 'run-1/r#2');
        await scripted(
          port,
        ).execute({'question': 'Which?'}, _ctx.withParentToolCallId('r'));
        expect(port.seen!.origin!.executionId, 'run-1/r#2');

        origins.end('r', 'run-1/r#2');
        await scripted(
          port,
        ).execute({'question': 'Which?'}, _ctx.withParentToolCallId('r'));
        expect(port.seen!.origin!.executionId, isNull);
      },
    );

    test('a run log id alone names no script', () async {
      final port = _RecordingPort(const AgentQuestionAnswer(skipped: true));
      await _toolWithRun(
        port,
        'run-log-1',
      ).execute({'question': 'Which?'}, _ctx.withParentToolCallId('r'));

      expect(port.seen!.origin, isNull);
      expect(port.seen!.runId, 'run-log-1');
    });

    test('a question the model asked directly has no origin', () async {
      final port = _RecordingPort(const AgentQuestionAnswer(skipped: true));
      await scripted(port).execute({'question': 'Which?'}, _ctx);

      expect(port.seen!.origin, isNull);
    });

    test('with no run id at all a script\'s question has no origin', () async {
      final port = _RecordingPort(const AgentQuestionAnswer(skipped: true));
      await _tool(
        port,
      ).execute({'question': 'Which?'}, _ctx.withParentToolCallId('r'));

      expect(port.seen!.origin, isNull);
    });
  });
}

AskUserTool _toolWithRun(AgentQuestionPort port, String runId) => AskUserTool(
  port: port,
  workspaceId: 'ws1',
  spaceId: 'space1',
  conversationId: 'conv-side',
  runId: runId,
);
