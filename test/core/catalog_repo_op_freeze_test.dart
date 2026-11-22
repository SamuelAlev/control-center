import 'dart:io';

import 'package:test/test.dart';

/// Freeze `RepoOp(` literals in `remote_rpc_catalog.dart` (QUALITY.md R10).
///
/// New ops go through `extraOps` packs (`buildXOps`) so the 20k-line catalog
/// does not grow. Lower the freeze when a pack is extracted.
void main() {
  test('remote_rpc_catalog.dart does not gain RepoOp literals', () {
    // Lowered 2026-11-18: the workspace settings ops moved to
    // catalog/workspace_settings_ops.dart.
    // Lowered 2026-11-19: the client write surface of the run log was
    // removed (only agent_run_log.stop remains, in its own pack).
    // Lowered 2026-11-20: the space read cursor became per-conversation
    // cursors (catalog/conversation_read_ops.dart).
    // Lowered 2026-11-20: orchestration.update moved to the cap pack
    // (catalog/orchestration_cap_ops.dart), then it and
    // orchestration.insert were deleted (no client wrote orchestrations).
    // Lowered 2026-11-20: the orchestration ops moved to their pack
    // (catalog/orchestration_ops.dart), behind the orchestration's space.
    // Lowered 2026-11-20: agents.killProcesses moved to the stop pack
    // (catalog/agent_run_log_write_ops.dart), behind the run's space; the
    // floor also takes the steering and goal ops removed the same day.
    const freeze = 370;
    final root = _repoRoot();
    final file = File(
      '$root/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
    );
    expect(file.existsSync(), isTrue);
    final count = RegExp(
      r'RepoOp\(',
    ).allMatches(file.readAsStringSync()).length;
    expect(
      count,
      lessThanOrEqualTo(freeze),
      reason:
          'New RepoOp( landed in remote_rpc_catalog.dart ($count, freeze '
          '$freeze). Add the op via extraOps instead, or lower this freeze '
          'when extracting a pack.',
    );
    expect(
      count,
      freeze,
      reason:
          'RepoOp count dropped to $count (freeze $freeze). Lower the freeze '
          'in catalog_repo_op_freeze_test.dart so the ratchet keeps the floor.',
    );
  });
}

String _repoRoot() {
  var dir = Directory.current;
  while (true) {
    final candidate = File(
      '${dir.path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
    );
    if (candidate.existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
