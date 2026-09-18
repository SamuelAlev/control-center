import 'package:cc_domain/core/domain/entities/working_memory_item.dart';
import 'package:cc_domain/features/memory/domain/repositories/working_memory_item_repository.dart';
import 'package:cc_mcp/src/tools/remember_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeWorking working;
  late RememberTool tool;

  setUp(() {
    working = _FakeWorking();
    tool = RememberTool(workingMemory: working);
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'agent_id': 'agent-1',
      'content': 'remember this',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('stores a hot working-memory item', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'agent_id': 'agent-1',
      'content': 'the API uses bearer tokens',
    });
    expect(result.isError, isFalse);
    expect(working.items, hasLength(1));
    expect(working.items.single.workspaceId, 'ws-1');
    expect(working.items.single.content, 'the API uses bearer tokens');
  });
}

class _FakeWorking implements WorkingMemoryItemRepository {
  final List<WorkingMemoryItem> items = [];

  @override
  Future<void> add(WorkingMemoryItem item) async {
    items.add(item);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
