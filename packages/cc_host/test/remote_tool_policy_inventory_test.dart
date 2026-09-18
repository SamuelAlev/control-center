import 'package:cc_host/src/policy/remote_tool_policy.dart';
import 'package:test/test.dart';

/// Freeze the phone's mutating MCP surface (QUALITY.md R8).
///
/// Adding a write the phone can invoke requires updating this inventory in the
/// same change as [RemoteToolPolicy.mutating]. The dual gate with
/// `fullClientOnly` repo-ops is covered by `repo_op_capability_test.dart`.
void main() {
  test('phone mutating MCP verbs stay the frozen local-only set', () {
    expect(
      RemoteToolPolicy.mutating,
      equals({'update_ticket', 'assign_ticket', 'send_message'}),
    );
  });
}
