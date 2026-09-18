import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_mcp/src/tools/rig_use_tool.dart';
import 'package:test/test.dart';

void main() {
  late ComputerUseTool tool;

  setUp(() {
    tool = ComputerUseTool(rigs: _FakeRigs());
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'action': 'screenshot'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('missing action is refused', () async {
    final result = await tool.run({'workspace_id': 'ws-1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('action'));
  });

  test('invalid action is refused', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'action': 'explode',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('action'));
  });
}

class _FakeRigs implements RigPort {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
