import 'dart:io';

import 'package:test/test.dart';

/// The undo-class ratchet (PRD 19 §5): keeps "universal undo" from silently
/// rotting or over-promising.
///
/// Every mutating `RepoOp` has an undo class — `UndoClass.irreversible` by
/// default (fail-safe: not undoable), or an explicit `reversible`/`compensable`
/// that puts it in the ActionJournal. This source-level (grep) test enforces
/// two invariants against the real catalog:
///
///   1. The set of ops declaring `reversible`/`compensable` is EXACTLY a
///      documented allowlist — a new undoable op is a deliberate edit here, and
///      a removed one can't silently drop out of the undo surface.
///   2. Ops with external side effects (publishing to GitHub, vendor sync,
///      merging) are NEVER reversible/compensable, and the marquee ones are
///      declared `irreversible` explicitly.
void main() {
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

  final src = File(
    '${repoRoot().path}/packages/cc_server_core/lib/src/remote_rpc_catalog.dart',
  ).readAsStringSync();

  final nameRe = RegExp(r"""name:\s*(['"])([^'"$]+)\1""");
  final undoRe = RegExp(
    r'undoClass:\s*UndoClass\.(reversible|compensable|irreversible)',
  );

  /// name → undoClass for every op that declares one, resolved by taking the
  /// nearest preceding `name:` before each `undoClass:` occurrence.
  Map<String, String> declaredUndoClasses() {
    final names = nameRe.allMatches(src).toList();
    final result = <String, String>{};
    for (final u in undoRe.allMatches(src)) {
      // The op name is the last `name:` literal before this undoClass.
      String? owner;
      for (final n in names) {
        if (n.start < u.start) {
          owner = n.group(2);
        } else {
          break;
        }
      }
      if (owner != null) {
        result[owner] = u.group(1)!;
      }
    }
    return result;
  }

  // The curated undoable set (PRD 19 §5). Growing this is a deliberate act.
  const allowedUndoable = <String, String>{
    'tickets.update': 'reversible',
    'tickets.patch': 'reversible',
    'tickets.assign': 'reversible',
    'tickets.insert': 'compensable',
    'messaging.updateMessage': 'reversible',
    'todos.setStatus': 'reversible',
    'plan.updateStatus': 'reversible',
  };

  test('reversible/compensable ops are exactly the documented allowlist', () {
    final declared = declaredUndoClasses();
    final undoable = {
      for (final e in declared.entries)
        if (e.value != 'irreversible') e.key: e.value,
    };
    expect(
      undoable,
      allowedUndoable,
      reason:
          'A RepoOp declares an undo class outside the curated allowlist (or one '
          'went missing). Undo coverage is a deliberate, growing set — update '
          'allowedUndoable in this test AND the ActionJournal inverse mapping '
          'when adding a reversible/compensable op.',
    );
  });

  test(
    'external-effect ops are never undoable and are marked irreversible',
    () {
      final declared = declaredUndoClasses();
      // Marquee external-effect ops must be explicitly irreversible.
      for (final op in const [
        'pr_lifecycle.createOnGitHub',
        'pr_review.submitReview',
        'pr_review.mergePullRequest',
        'ticket_sync.syncNow',
      ]) {
        expect(
          declared[op],
          'irreversible',
          reason:
              '$op publishes/merges/syncs an external side effect — it must be '
              'declared UndoClass.irreversible (PRD 19 §4/§5) so it gets '
              'preview/confirm and never enters the undo stack.',
        );
      }
      // No op whose name signals an external effect may be undoable.
      final externalPattern = RegExp(
        r'(createOnGitHub|mergePullRequest|submitReview|\.syncNow)',
      );
      for (final e in declared.entries) {
        if (externalPattern.hasMatch(e.key)) {
          expect(
            e.value,
            'irreversible',
            reason: '${e.key} is an external-effect op and cannot be undoable.',
          );
        }
      }
    },
  );
}
