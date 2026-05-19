import 'dart:io';

import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  const loader = WatchdogRosterLoader();

  group('parseRoster', () {
    test('reads a full roster', () {
      final roster = loader.parseRoster('''
instructions: |
  Everyone: prefer diffs that keep tests unified.

advisors:
  - name: Architecture
    model: claude-sonnet-5
    tools: [read, search]
    every-turns: 2
    instructions: |
      Watch cross-module coupling and public-API growth.
  - name: Fixer
    model: claude-haiku-4-5
    tools: read, search, bash
    instructions: |
      You may run tests to prove a fix, then advise.
''');
      expect(roster.shared, contains('tests unified'));
      expect(roster.advisors, hasLength(2));

      final architecture = roster.advisors.first;
      expect(architecture.name, 'Architecture');
      expect(architecture.model, 'claude-sonnet-5');
      expect(architecture.tools, ['read', 'search']);
      expect(architecture.everyTurns, 2);
      expect(architecture.instructions, contains('cross-module coupling'));

      final fixer = roster.advisors.last;
      expect(fixer.name, 'Fixer');
      expect(
        fixer.tools,
        ['read', 'search', 'bash'],
        reason: 'a bare comma list is as valid as a bracketed one',
      );
    });

    test('an inline instruction works without a block scalar', () {
      final roster = loader.parseRoster('''
advisors:
  - name: Quick
    instructions: Watch for silent catch blocks.
''');
      expect(
        roster.advisors.single.instructions,
        'Watch for silent catch blocks.',
      );
    });

    test('comments and blank lines are ignored', () {
      final roster = loader.parseRoster('''
# the roster
advisors:

  # the first one
  - name: A
''');
      expect(roster.advisors.single.name, 'A');
    });

    test('an entry with no name is skipped, not guessed at', () {
      final roster = loader.parseRoster('''
advisors:
  - model: x
  - name: Real
''');
      expect(roster.advisors.map((a) => a.name), ['Real']);
    });

    test('caps how many advisors are accepted', () {
      // Each advisor is a whole extra model reviewing every turn, so this is a
      // cost ceiling, not just a sanity check.
      const capped = WatchdogRosterLoader(maxAdvisors: 2);
      final roster = capped.parseRoster('''
advisors:
  - name: A
  - name: B
  - name: C
  - name: D
''');
      expect(roster.advisors, hasLength(2));
    });

    test('an empty document is the empty roster', () {
      expect(loader.parseRoster('').isEmpty, isTrue);
      expect(loader.parseRoster('# nothing here').isEmpty, isTrue);
    });
  });

  group('load', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('cc_watchdog'));
    tearDown(() => root.deleteSync(recursive: true));

    test('finds WATCHDOG.yml at the project root', () async {
      File(
        p.join(root.path, 'WATCHDOG.yml'),
      ).writeAsStringSync('advisors:\n  - name: A\n');
      final roster = await loader.load(root.path);
      expect(roster.advisors.single.name, 'A');
    });

    test('finds it under .agents too', () async {
      Directory(p.join(root.path, '.agents')).createSync();
      File(
        p.join(root.path, '.agents', 'WATCHDOG.yaml'),
      ).writeAsStringSync('advisors:\n  - name: B\n');
      expect((await loader.load(root.path)).advisors.single.name, 'B');
    });

    test('a malformed file degrades to the empty roster', () async {
      // One bad project config must not take the session down.
      File(p.join(root.path, 'WATCHDOG.yml')).writeAsStringSync(':::: not yaml');
      expect((await loader.load(root.path)).isEmpty, isTrue);
    });

    test('a missing file is the empty roster', () async {
      expect((await loader.load(root.path)).isEmpty, isTrue);
      expect((await loader.load(null)).isEmpty, isTrue);
    });

    test('refuses an oversized file', () async {
      File(
        p.join(root.path, 'WATCHDOG.yml'),
      ).writeAsStringSync('advisors:\n  - name: A\n${'#' * 100000}');
      const small = WatchdogRosterLoader(maxBytes: 512);
      expect((await small.load(root.path)).isEmpty, isTrue);
    });
  });
}
