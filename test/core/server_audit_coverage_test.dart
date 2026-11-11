import 'dart:io';

import 'package:test/test.dart';

/// Every install-wide mutating op goes to the server-scope audit trail.
///
/// The dispatcher records a call when the op is not workspace-scoped, not a
/// read, and `audited` (the default). This ratchet makes opting out a reviewed
/// decision: an unscoped op that sets `audited: false`, or that states its
/// scope, kind or audit flag as an expression the scan cannot read, must be
/// listed below with the reason. Source-level grep, like the authority and
/// permission ratchets: building the catalog needs the whole server graph.
void main() {
  /// Unscoped mutating ops that stay out of the trail, with why. Empty: every
  /// install-wide change today is recorded.
  const exempt = <String, String>{};

  Directory repoRoot() {
    var dir = Directory.current;
    while (true) {
      if (File(
        '${dir.path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
      ).existsSync()) {
        return dir;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        return Directory.current;
      }
      dir = parent;
    }
  }

  final nameRe = RegExp(r"name:\s*'([^'$]+)'");
  String? valueOf(String head, String field) =>
      RegExp('$field:\\s*([^,\\n]+)').firstMatch(head)?.group(1)?.trim();

  /// Every declared `RepoOp(...)` head (the text before `handler:`), per file.
  List<({String file, String head})> declarations() {
    final src = Directory('${repoRoot().path}/packages/cc_server_core/lib/src');
    final out = <({String file, String head})>[];
    for (final entity in src.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final text = entity.readAsStringSync().replaceAll(
        RegExp(r'^\s*//.*', multiLine: true),
        '',
      );
      for (final chunk in text.split('RepoOp(').skip(1)) {
        final handlerAt = chunk.indexOf('handler:');
        out.add((
          file: entity.path,
          head: handlerAt >= 0 ? chunk.substring(0, handlerAt) : chunk,
        ));
      }
    }
    return out;
  }

  test('every unscoped mutating op is audited or exempt with a reason', () {
    final decls = declarations();
    expect(decls, isNotEmpty, reason: 'catalog parse found no ops');

    final unaudited = <String>[];
    final unreadable = <String>[];
    for (final (:file, :head) in decls) {
      final scoped = valueOf(head, 'workspaceScoped');
      final kind = valueOf(head, 'kind');
      final audited = valueOf(head, 'audited');
      // A copy of an existing op (`audited: op.audited`) keeps whatever the
      // original declared, which this scan checks at the original.
      if (audited == 'op.audited') {
        continue;
      }
      if (scoped == null || scoped == 'true') {
        continue;
      }
      final name = nameRe.firstMatch(head)?.group(1);
      final label = name ?? '<unnamed op in $file>';
      if (scoped != 'false' ||
          (kind != null && !kind.startsWith('RepoOpKind.')) ||
          (audited != null && audited != 'true' && audited != 'false')) {
        if (!exempt.containsKey(name)) {
          unreadable.add(label);
        }
        continue;
      }
      if (kind == 'RepoOpKind.read') {
        continue;
      }
      if (audited == 'false' && !exempt.containsKey(name)) {
        unaudited.add(label);
      }
    }

    expect(
      unaudited,
      isEmpty,
      reason:
          'Install-wide mutating ops that opted out of the server audit '
          'trail. Remove `audited: false`, or add the op to `exempt` with the '
          'reason its calls need no record.',
    );
    expect(
      unreadable,
      isEmpty,
      reason:
          'Unscoped ops whose scope, kind or audit flag is not a literal, so '
          'this ratchet cannot tell whether they are recorded. State them as '
          'literals, or add the op to `exempt` with the reason.',
    );
  });

  test('every exempt op still exists and still opts out', () {
    final names = {
      for (final d in declarations())
        if (valueOf(d.head, 'audited') == 'false')
          nameRe.firstMatch(d.head)?.group(1),
    };
    expect(exempt.keys.toSet().difference(names), isEmpty);
    for (final reason in exempt.values) {
      expect(reason.trim(), isNotEmpty);
    }
  });
}
