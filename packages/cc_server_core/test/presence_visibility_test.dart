import 'package:cc_server_core/src/catalog/presence_visibility.dart';
import 'package:test/test.dart';

void main() {
  // A viewer granted `r-open` only; space `s-closed` exposes `r-closed`.
  PresenceViewer viewer({List<String>? spaceChecks}) =>
      PresenceViewer.restricted(
        readableRepoIds: {'r-open'},
        repoIdsByCoordinate: {'acme/open': 'r-open', 'acme/closed': 'r-closed'},
        canReadSpace: (spaceId) async {
          spaceChecks?.add(spaceId);
          return spaceId != 's-closed';
        },
      );

  Map<String, dynamic> entry(Map<String, dynamic> extra) => {
    'p': 'user:u2',
    'n': 'Ada',
    'a': 'online',
    ...extra,
  };

  test('an ungranted locus is hidden, online state is kept', () async {
    final roster = await viewer().redact([
      entry({
        'l': {'t': 'file', 'r': 'r-closed', 'p': 'lib/secret.dart'},
      }),
      entry({
        'l': {'t': 'pr', 'r': 'Acme/Closed', 'n': 4},
      }),
      entry({
        'l': {'t': 'sp', 'c': 's-closed'},
      }),
      entry({
        'l': {'t': 'pr', 'r': 'acme/unlinked', 'n': 1},
      }),
    ]);
    for (final e in roster) {
      expect(e.containsKey('l'), isFalse);
      expect(e['a'], 'online');
      expect(e['n'], 'Ada');
    }
  });

  test('a granted locus and workspace-scoped records pass through', () async {
    final roster = await viewer().redact([
      entry({
        'l': {'t': 'file', 'r': 'r-open', 'p': 'a.dart'},
      }),
      entry({
        'l': {'t': 'pr', 'r': 'acme/open', 'n': 2},
      }),
      entry({
        'l': {'t': 'sp', 'c': 's-open'},
      }),
      entry({
        'l': {'t': 'tk', 'id': 't1'},
      }),
    ]);
    expect([for (final e in roster) e.containsKey('l')], everyElement(true));
  });

  test(
    'typing, spotlight and worktree claims follow the space grant',
    () async {
      final checks = <String>[];
      final roster = await viewer(spaceChecks: checks).redact([
        entry({
          'ty': 's-closed',
          'sp': 's-closed',
          'cl': [
            {'t': 'worktree', 'id': 's-closed'},
            {'t': 'ticket', 'id': 't1'},
          ],
        }),
        entry({
          'ty': 's-open',
          'cl': [
            {'t': 'worktree', 'id': 's-closed'},
          ],
        }),
      ]);
      expect(roster[0].containsKey('ty'), isFalse);
      expect(roster[0].containsKey('sp'), isFalse);
      expect(roster[0]['cl'], [
        {'t': 'ticket', 'id': 't1'},
      ]);
      expect(roster[1]['ty'], 's-open');
      expect(roster[1].containsKey('cl'), isFalse);
      expect(checks.toSet(), {'s-closed', 's-open'});
      expect(checks.where((s) => s == 's-closed'), hasLength(1));
    },
  );

  test('an unrestricted viewer sees the roster untouched', () async {
    final roster = [
      entry({
        'l': {'t': 'file', 'r': 'r-closed', 'p': 'x'},
      }),
    ];
    expect(
      await const PresenceViewer.unrestricted().redact(roster),
      same(roster),
    );
  });
}
