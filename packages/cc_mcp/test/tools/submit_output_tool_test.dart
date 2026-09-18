import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_mcp/src/tools/submit_output_tool.dart';
import 'package:test/test.dart';

void main() {
  late SubmitOutputTool tool;

  setUp(() {
    tool = SubmitOutputTool(runLogRepository: _FakeRunLogs());
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'agent_id': 'agent-1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('no active run is refused', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'agent_id': 'agent-1',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('No active run'));
  });
}

class _FakeRunLogs implements AgentRunLogRepository {
  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
