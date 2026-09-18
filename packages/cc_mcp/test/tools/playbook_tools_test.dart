import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_mcp/src/tools/playbook_tools.dart';
import 'package:test/test.dart';

void main() {
  late CreatePlaybookTool tool;

  setUp(() {
    tool = CreatePlaybookTool(
      playbooks: _FakePlaybooks(),
      orchestrations: _FakeOrchestrations(),
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'name': 'ship'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('refuses a create with neither orchestration nor proposal', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'name': 'ship',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('proposal'));
  });
}

class _FakePlaybooks implements PlaybookRepository {
  @override
  Future<Playbook?> getByName(String workspaceId, String name) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeOrchestrations implements OrchestrationRepository {
  @override
  Future<Orchestration?> getById(String workspaceId, String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
