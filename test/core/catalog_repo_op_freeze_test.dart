import 'dart:io';

import 'package:test/test.dart';

/// Freeze `RepoOp(` literals in `remote_rpc_catalog.dart` (QUALITY.md R10).
///
/// New ops go through `extraOps` packs (`buildXOps`) so the 20k-line catalog
/// does not grow. Lower the freeze when a pack is extracted.
void main() {
  test('remote_rpc_catalog.dart does not gain RepoOp literals', () {
    const freeze = 500;
    final root = _repoRoot();
    final file = File(
      '$root/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
    );
    expect(file.existsSync(), isTrue);
    final count = RegExp(r'RepoOp\(').allMatches(file.readAsStringSync()).length;
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
