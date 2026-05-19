import 'dart:io';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// The RPC client coalesces identical in-flight requests, and it decides which
/// ops are safe to coalesce from their NAME — it has no access to the server's
/// `RepoOpKind`. See `isReadShapedOp`.
///
/// That is only sound while the naming convention holds. If a MUTATION were
/// ever registered as `something.getFoo` or `something.listBar`, two genuinely
/// separate concurrent writes could collapse into one and a user's second
/// action would silently vanish.
///
/// So this pins the convention against the real catalog. It parses the op
/// declarations out of the source rather than building the catalog, because
/// constructing it needs a database and a full runtime — and a ratchet that is
/// expensive to run is a ratchet that gets skipped.
void main() {
  test('no mutating op has a read-shaped name', () {
    final source = _catalogSource();

    // `RepoOp(\n  name: '<op>',\n  kind: RepoOpKind.<kind>`
    final declarations = RegExp(
      r"RepoOp\(\s*\n\s*name:\s*'([^']+)',\s*\n\s*kind:\s*RepoOpKind\.(\w+)",
    ).allMatches(source);

    final ops = [
      for (final m in declarations) (name: m.group(1)!, kind: m.group(2)!),
    ];
    expect(
      ops.length,
      greaterThan(300),
      reason:
          'the declaration regex stopped matching the catalog — fix the '
          'regex, do not delete this test',
    );

    final offenders = [
      for (final op in ops)
        if (op.kind != 'read' && isReadShapedOp(op.name))
          '${op.name} (${op.kind})',
    ];
    expect(
      offenders,
      isEmpty,
      reason:
          'these ops are named like reads but mutate. The RPC client '
          'coalesces identical in-flight requests for read-shaped names, so '
          'two concurrent identical calls to these would collapse into one '
          'write. Either rename the op, or drop its verb from '
          'kReadOpVerbPrefixes.',
    );
  });

  test('the read verbs actually appear in the catalog', () {
    // Guards the other direction: a prefix list that matches nothing is not
    // protecting anything, and would hide a typo.
    final source = _catalogSource();
    final unused = [
      for (final verb in kReadOpVerbPrefixes)
        if (!RegExp("name: '[\\w.]+\\.$verb").hasMatch(source)) verb,
    ];
    expect(
      unused,
      isEmpty,
      reason:
          'these read verbs match no op in the catalog — either a typo, '
          'or a prefix that should be dropped',
    );
  });
}

/// The catalog source, located by walking up from the CWD.
///
/// Not `File('lib/src/…')`: `dart test packages/cc_server_core` from the repo
/// root and `dart test` from the package root have different working
/// directories, and a ratchet that only passes from one of them is a ratchet
/// that gets reported as broken and then skipped.
String _catalogSource() {
  const relative = 'packages/cc_server_core/lib/src/remote_rpc_catalog.dart';
  var dir = Directory.current;
  while (true) {
    for (final candidate in [
      File('${dir.path}/lib/src/remote_rpc_catalog.dart'),
      File('${dir.path}/$relative'),
    ]) {
      if (candidate.existsSync()) {
        return candidate.readAsStringSync();
      }
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('Could not locate the catalog from ${Directory.current.path}');
    }
    dir = parent;
  }
}
