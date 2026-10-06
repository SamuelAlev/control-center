import 'dart:convert';

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/messaging/providers/recent_files_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppPreferences prefs;

  setUp(() => prefs = AppPreferences.inMemory());

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  const a = (workspaceId: 'ws-a', spaceId: 's1');

  test('touch keeps the newest file first without duplicates', () {
    final c = container();
    final n = c.read(recentFilesProvider(a).notifier)
      ..touch(repoId: 'r1', path: 'lib/a.dart')
      ..touch(repoId: 'r1', path: 'lib/b.dart')
      ..touch(repoId: 'r1', path: 'lib/a.dart');

    expect(c.read(recentFilesProvider(a)), [
      (repoId: 'r1', path: 'lib/a.dart'),
      (repoId: 'r1', path: 'lib/b.dart'),
    ]);

    // A repo-less report of the same path is the same file, not a second row.
    n.touch(repoId: '', path: 'lib/b.dart');
    expect(c.read(recentFilesProvider(a)).map((f) => f.path), [
      'lib/b.dart',
      'lib/a.dart',
    ]);
  });

  test('the same path in two repos stays two entries', () {
    final c = container();
    c.read(recentFilesProvider(a).notifier)
      ..touch(repoId: 'r1', path: 'README.md')
      ..touch(repoId: 'r2', path: 'README.md');

    expect(c.read(recentFilesProvider(a)), hasLength(2));
  });

  test('remove forgets one file', () {
    final c = container();
    c.read(recentFilesProvider(a).notifier)
      ..touch(repoId: 'r1', path: 'a')
      ..touch(repoId: 'r1', path: 'b')
      ..remove(repoId: 'r1', path: 'a');

    expect(c.read(recentFilesProvider(a)), [(repoId: 'r1', path: 'b')]);
  });

  test('the list survives a restart and is scoped per workspace and space', () {
    container().read(recentFilesProvider(a).notifier)
      ..touch(repoId: 'r1', path: 'a')
      ..touch(repoId: 'r1', path: 'b');

    final c = container();
    expect(c.read(recentFilesProvider(a)).map((f) => f.path), ['b', 'a']);
    expect(
      c.read(recentFilesProvider((workspaceId: 'ws-a', spaceId: 's2'))),
      isEmpty,
    );
    expect(
      c.read(recentFilesProvider((workspaceId: 'ws-b', spaceId: 's1'))),
      isEmpty,
    );
  });

  test('is bounded per space and per workspace', () {
    final c = container();
    final n = c.read(recentFilesProvider(a).notifier);
    for (var i = 0; i < RecentFilesNotifier.maxFiles + 5; i++) {
      n.touch(repoId: 'r1', path: 'f$i');
    }
    expect(
      c.read(recentFilesProvider(a)),
      hasLength(RecentFilesNotifier.maxFiles),
    );
    expect(
      c.read(recentFilesProvider(a)).first.path,
      'f${RecentFilesNotifier.maxFiles + 4}',
    );

    for (var i = 0; i < RecentFilesNotifier.maxSpaces; i++) {
      c
          .read(
            recentFilesProvider((workspaceId: 'ws-a', spaceId: 'x$i')).notifier,
          )
          .touch(repoId: 'r1', path: 'f');
    }
    final stored =
        jsonDecode(prefs.getString('${recentFilesKeyPrefix}ws-a')!) as Map;
    expect(stored, hasLength(RecentFilesNotifier.maxSpaces));
    // The least recently touched conversation was dropped first.
    expect(stored.containsKey('s1'), isFalse);
  });

  test('a malformed blob reads as empty', () {
    prefs.setString('${recentFilesKeyPrefix}ws-a', '{not json');
    expect(container().read(recentFilesProvider(a)), isEmpty);
  });
}
