import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_mcp/src/tools/submit_plan_tool.dart';
import 'package:test/test.dart';

void main() {
  late SubmitPlanTool tool;

  setUp(() {
    tool = SubmitPlanTool(
      runLogRepository: _FakeRunLogs(),
      planDocuments: _FakePlans(),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'agent_id': 'agent-1',
      'goal': 'Ship it',
      'nodes': <Map<String, dynamic>>[
        {'key': 'a', 'title': 'Do the work'},
      ],
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('no active run is refused', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'agent_id': 'agent-1',
      'goal': 'Ship it',
      'nodes': <Map<String, dynamic>>[
        {'key': 'a', 'title': 'Do the work'},
      ],
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

class _FakePlans implements PlanDocumentRepository {
  @override
  Future<PlanDocument?> latestForConversation(
    String workspaceId,
    String conversationId,
  ) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
