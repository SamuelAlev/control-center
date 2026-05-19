import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/task_tool.dart';
import 'package:test/test.dart';

class _FakeSpawner implements SubagentSpawner {
  _FakeSpawner({this.result}) : throwOnSpawn = null;

  SubagentResult? result;
  Object? throwOnSpawn;
  SubagentSpawnRequest? lastRequest;

  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) async {
    lastRequest = request;
    if (throwOnSpawn != null) {
      throw throwOnSpawn!;
    }
    return result ?? const SubagentResult(text: 'default', childRunId: 'run-1');
  }
}

HarnessToolContext _ctx() =>
    const HarnessToolContext(workingDirectory: '/tmp/work');

void main() {
  group('TaskTool', () {
    test('metadata', () {
      final tool = TaskTool(_FakeSpawner());
      expect(tool.name, 'task');
      expect(tool.approvalTier, ToolApprovalTier.read);
      expect(tool.selfGuards, isTrue);
      expect(tool.description, contains('subagent'));
      expect(tool.inputSchema['required'], ['description', 'label']);
      final props = tool.inputSchema['properties'] as Map<String, dynamic>;
      expect(
        props.keys,
        containsAll(['description', 'label', 'subagent_type']),
      );
      final type = props['subagent_type'] as Map<String, dynamic>;
      expect(type['enum'], ['general', 'explore', 'plan']);
    });

    test('empty description returns error', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      final res = await tool.execute({
        'description': '',
        'label': 'lab',
      }, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, contains('description'));
      expect(spawner.lastRequest, isNull);
    });

    test('empty label returns error', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      final res = await tool.execute({
        'description': 'do it',
        'label': '',
      }, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, contains('label'));
    });

    test('whitespace-only inputs return error', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      final res = await tool.execute({
        'description': '   ',
        'label': '  ',
      }, _ctx());
      expect(res.isError, isTrue);
      expect(spawner.lastRequest, isNull);
    });

    test('happy path success returns success content', () async {
      final spawner = _FakeSpawner(
        result: const SubagentResult(text: 'result-text', childRunId: 'c1'),
      );
      final tool = TaskTool(spawner);
      final res = await tool.execute({
        'description': 'do thing',
        'label': 'thing',
      }, _ctx());
      expect(res.isError, isFalse);
      expect(res.content, 'result-text');
      final req = spawner.lastRequest!;
      expect(req.description, 'do thing');
      expect(req.label, 'thing');
      expect(req.type, SubagentType.general);
      expect(req.modelOverride, isNull);
      expect(req.effortOverride, isNull);
      expect(req.context.workingDirectory, '/tmp/work');
    });

    test('trims description and label', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      await tool.execute({'description': '  hi  ', 'label': '  lab  '}, _ctx());
      expect(spawner.lastRequest!.description, 'hi');
      expect(spawner.lastRequest!.label, 'lab');
    });

    test('subagent_type explore is resolved', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      await tool.execute({
        'description': 'explore',
        'label': 'l',
        'subagent_type': 'explore',
      }, _ctx());
      expect(spawner.lastRequest!.type, SubagentType.explore);
    });

    test('subagent_type plan is resolved', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      await tool.execute({
        'description': 'plan',
        'label': 'l',
        'subagent_type': 'plan',
      }, _ctx());
      expect(spawner.lastRequest!.type, SubagentType.plan);
    });

    test('unknown subagent_type falls back to general', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      await tool.execute({
        'description': 'x',
        'label': 'l',
        'subagent_type': 'bogus',
      }, _ctx());
      expect(spawner.lastRequest!.type, SubagentType.general);
    });

    test('null subagent_type defaults to general', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      await tool.execute({'description': 'x', 'label': 'l'}, _ctx());
      expect(spawner.lastRequest!.type, SubagentType.general);
    });

    test('model override is forwarded and trimmed', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      await tool.execute({
        'description': 'x',
        'label': 'l',
        'model': '  anthropic/claude  ',
      }, _ctx());
      expect(spawner.lastRequest!.modelOverride, 'anthropic/claude');
    });

    test('effort override is forwarded and trimmed', () async {
      final spawner = _FakeSpawner();
      final tool = TaskTool(spawner);
      await tool.execute({
        'description': 'x',
        'label': 'l',
        'effort': '  high  ',
      }, _ctx());
      expect(spawner.lastRequest!.effortOverride, 'high');
    });

    test('error result surfaces error text', () async {
      final spawner = _FakeSpawner(
        result: const SubagentResult(text: 'boom', isError: true),
      );
      final tool = TaskTool(spawner);
      final res = await tool.execute({
        'description': 'x',
        'label': 'l',
      }, _ctx());
      expect(res.isError, isTrue);
      expect(res.content, 'boom');
    });
  });
}
