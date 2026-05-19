import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

void main() {
  group('resolveApproval', () {
    test('always-ask: read auto-approves, write/exec prompt', () {
      const mode = ApprovalMode.alwaysAsk;
      expect(resolveApproval(ToolApproval.read, mode), ApprovalDecision.allow);
      expect(resolveApproval(ToolApproval.write, mode), ApprovalDecision.prompt);
      expect(resolveApproval(ToolApproval.exec, mode), ApprovalDecision.prompt);
    });

    test('write mode: read+write auto-approve, exec prompts', () {
      const mode = ApprovalMode.write;
      expect(resolveApproval(ToolApproval.read, mode), ApprovalDecision.allow);
      expect(resolveApproval(ToolApproval.write, mode), ApprovalDecision.allow);
      expect(resolveApproval(ToolApproval.exec, mode), ApprovalDecision.prompt);
    });

    test('yolo: everything auto-approves unless override', () {
      const mode = ApprovalMode.yolo;
      expect(resolveApproval(ToolApproval.exec, mode), ApprovalDecision.allow);
      expect(
        resolveApproval(
          const ToolApproval(CapabilityTier.exec, override: true),
          mode,
        ),
        ApprovalDecision.prompt,
      );
    });

    test('override forces a prompt even when the mode would allow', () {
      expect(
        resolveApproval(
          const ToolApproval(CapabilityTier.read, override: true),
          ApprovalMode.alwaysAsk,
        ),
        ApprovalDecision.prompt,
      );
    });
  });

  group('per-args tier (gh-style)', () {
    // Mirrors the acceptance criterion: gh view = read (auto), gh merge = exec.
    ToolApproval ghTier(Map<String, dynamic> args) {
      final sub = (args['command'] as String?) ?? '';
      if (sub.contains('merge') || sub.contains('close')) {
        return const ToolApproval(CapabilityTier.exec, reason: 'mutates the PR');
      }
      return ToolApproval.read;
    }

    test('gh pr view is read-tier → auto-approved', () {
      expect(
        resolveApproval(ghTier({'command': 'gh pr view 1'}), ApprovalMode.alwaysAsk),
        ApprovalDecision.allow,
      );
    });

    test('gh pr merge is exec-tier → prompts', () {
      expect(
        resolveApproval(ghTier({'command': 'gh pr merge 1'}), ApprovalMode.alwaysAsk),
        ApprovalDecision.prompt,
      );
    });
  });

  group('ApprovalMode wire round-trip', () {
    test('parses and serialises', () {
      for (final mode in ApprovalMode.values) {
        expect(ApprovalMode.fromWire(mode.wire), mode);
      }
    });
  });
}
