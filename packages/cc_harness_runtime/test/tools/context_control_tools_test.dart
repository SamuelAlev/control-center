import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/context_control_tools.dart';
import 'package:test/test.dart';

/// Exercises [CheckpointTool] + [RewindTool] — the loop-owned context-control
/// tools. Their `execute` is never invoked by the loop (handled inline), so
/// the contract is the schema advertised to the model + the stub error result.
void main() {
  const ctx = HarnessToolContext(workingDirectory: '/ws');

  group('CheckpointTool', () {
    final t = CheckpointTool();

    test('metadata + schema', () {
      expect(t.name, 'checkpoint');
      expect(t.approvalTier, ToolApprovalTier.read);
      expect(t.description, contains('rewind'));
      final props = t.inputSchema['properties'] as Map<String, dynamic>;
      expect(props.keys, contains('label'));
    });

    test('execute returns the loop-handled stub error', () async {
      final res = await t.execute({'label': 'x'}, ctx);
      expect(res.isError, isTrue);
      expect(res.content, contains('handled by the loop'));
    });
  });

  group('RewindTool', () {
    final t = RewindTool();

    test('metadata + schema', () {
      expect(t.name, 'rewind');
      expect(t.approvalTier, ToolApprovalTier.read);
      expect(t.description, contains('Discard'));
      final props = t.inputSchema['properties'] as Map<String, dynamic>;
      expect(props.keys, contains('checkpoint'));
    });

    test('execute returns the loop-handled stub error', () async {
      final res = await t.execute({'checkpoint': 'x'}, ctx);
      expect(res.isError, isTrue);
      expect(res.content, contains('handled by the loop'));
    });
  });
}
