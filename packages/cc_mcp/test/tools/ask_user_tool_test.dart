import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_mcp/src/tools/ask_user_tool.dart';
import 'package:test/test.dart';

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

void main() {
  group('AskUserTool', () {
    test('name is ask_user so Claude can select the prefixed tool', () {
      final tool = AskUserTool(port: _RecordingPort(null));
      expect(tool.name, 'ask_user');
      expect(tool.forcedScopeKeys, containsAll(['space_id', 'agent_id']));
    });

    test('renders into the scoped workspace and space', () async {
      final port = _RecordingPort(
        const AgentQuestionAnswer(selectedLabels: ['Postgres']),
      );
      final tool = AskUserTool(port: port);
      final args = const McpCallScope(
        workspaceId: 'ws1',
        agentId: 'agent1',
        spaceId: 'space1',
      ).apply(
        {
          'question': 'Which database?',
          'context': 'Both are already in the lockfile.',
          'options': [
            {
              'label': 'Postgres',
              'description': 'What the rest of the app uses',
            },
            {'label': 'SQLite'},
          ],
          // A model-supplied space must not win: the form has to land where
          // the human is watching.
          'space_id': 'space-other',
          'agent_id': 'someone-else',
        },
        tool.inputSchema,
        force: tool.forcedScopeKeys,
      );

      final result = await tool.call(args);

      expect(result.isError, isFalse);
      expect(result.content.single.text, contains('Postgres'));
      final asked = port.seen!;
      expect(asked.workspaceId, 'ws1');
      expect(asked.spaceId, 'space1');
      expect(asked.askedByAgentId, 'agent1');
      expect(asked.options.map((o) => o.label), ['Postgres', 'SQLite']);
    });

    test('refuses a question with nowhere to render', () async {
      final port = _RecordingPort(null);
      final result = await AskUserTool(port: port).call({
        'workspace_id': 'ws1',
        'question': 'Which?',
      });
      expect(result.isError, isTrue);
      expect(result.content.single.text, contains('space_id'));
      expect(port.seen, isNull);
    });

    test('a timeout is an error the agent can continue from', () async {
      final result = await AskUserTool(port: _RecordingPort(null)).call({
        'workspace_id': 'ws1',
        'space_id': 'space1',
        'question': 'Which?',
      });
      expect(result.isError, isTrue);
      expect(result.content.single.text, contains('timed out'));
    });
  });
}
