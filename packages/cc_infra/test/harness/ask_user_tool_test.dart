import 'dart:async';

import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/ask_user_tool.dart';
import 'package:test/test.dart';

/// A port that records what it was asked and answers with a scripted reply.
class _RecordingPort implements AgentQuestionPort {
  _RecordingPort(this._answer);
  final AgentQuestionAnswer? _answer;
  AgentQuestionRequest? seen;

  @override
  Future<AgentQuestionAnswer?> ask(AgentQuestionRequest request) async {
    seen = request;
    return _answer;
  }
}

const _ctx = HarnessToolContext(workingDirectory: '.');

AskUserTool _tool(AgentQuestionPort port) => AskUserTool(
  port: port,
  workspaceId: 'ws1',
  spaceId: 'space1',
  askedByAgentId: 'agent1',
  askedByName: 'Scout',
);

void main() {
  group('AskUserTool', () {
    test('renders the question into the run workspace + space', () async {
      final port = _RecordingPort(
        const AgentQuestionAnswer(selectedLabels: ['Postgres']),
      );
      final result = await _tool(port).execute({
        'question': 'Which database?',
        'context': 'Both are already in the lockfile.',
        'options': [
          {'label': 'Postgres', 'description': 'What the rest of the app uses'},
          {'label': 'SQLite'},
        ],
      }, _ctx);

      expect(result.isError, isFalse);
      expect(result.content, contains('Postgres'));
      final asked = port.seen!;
      expect(asked.workspaceId, 'ws1');
      expect(asked.spaceId, 'space1');
      expect(asked.askedByAgentId, 'agent1');
      expect(asked.askedByName, 'Scout');
      expect(asked.options.map((o) => o.label), ['Postgres', 'SQLite']);
      expect(asked.options.first.description, isNotNull);
      expect(
        asked.options.last.description,
        isNull,
        reason: 'an omitted description must not become an empty string',
      );
    });

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
      final result = await _tool(port).execute({
        'question': 'Which?',
        'allow_free_text': false,
      }, _ctx);

      expect(result.isError, isTrue);
      expect(result.content, contains('allow_free_text'));
      expect(
        port.seen,
        isNull,
        reason: 'nothing should reach the user for a question they cannot '
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

    test('options are capped so one call cannot flood the form', () async {
      final port = _RecordingPort(
        const AgentQuestionAnswer(selectedLabels: ['o0']),
      );
      await AskUserTool(
        port: port,
        workspaceId: 'ws1',
        spaceId: 'space1',
        maxOptions: 3,
      ).execute({
        'question': 'Which?',
        'options': [for (var i = 0; i < 20; i++) {'label': 'o$i'},],
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

    test('never joins a parallel batch', () {
      // Two forms competing for one human is not a race worth running.
      expect(_tool(_RecordingPort(null)).parallelSafe, isFalse);
    });

    test('is read-tier so it is never itself approval-gated', () {
      expect(_tool(_RecordingPort(null)).approvalTier, ToolApprovalTier.read);
    });
  });
}
