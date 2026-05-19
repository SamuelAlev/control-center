import 'dart:convert';
import 'dart:io';

import 'package:cc_harness_runtime/src/context/harness_run_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [HarnessRunConfig.load] — the opt-in `.agents/harness.json`
/// reader. Covers: absent file → none, a fully-populated file (stream rules,
/// advisor, hooks), the parse-failure → none fallback, the advisor-field
/// defaults/coercion and relative-vs-absolute hook path resolution.
void main() {
  late Directory base;

  setUp(() => base = Directory.systemTemp.createTempSync('harness_cfg_'));
  tearDown(() => base.deleteSync(recursive: true));

  /// Writes `.agents/harness.json` under [dir] (defaults to [base]).
  void writeConfig(Map<String, dynamic> json, {Directory? dir}) {
    final target = dir ?? base;
    final agentsDir = Directory(p.join(target.path, '.agents'))
      ..createSync(recursive: true);
    File(
      p.join(agentsDir.path, 'harness.json'),
    ).writeAsStringSync(jsonEncode(json));
  }

  group('HarnessRunConfig.load — absent / invalid', () {
    test('returns none when no base has the file', () async {
      expect(await HarnessRunConfig.load([base.path]), HarnessRunConfig.none);
    });

    test('skips null/empty bases and continues to the next', () async {
      expect(
        await HarnessRunConfig.load([null, '', base.path]),
        HarnessRunConfig.none,
      );
    });

    test('returns none when the JSON is malformed', () async {
      File(p.join(base.path, '.agents', 'harness.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync('{ not valid json');
      expect(await HarnessRunConfig.load([base.path]), HarnessRunConfig.none);
    });

    test('returns none when the top-level value is not a map', () async {
      final agentsDir = Directory(p.join(base.path, '.agents'))
        ..createSync(recursive: true);
      File(
        p.join(agentsDir.path, 'harness.json'),
      ).writeAsStringSync(jsonEncode([1, 2, 3]));
      expect(await HarnessRunConfig.load([base.path]), HarnessRunConfig.none);
    });

    test('returns none when a stream-rule regex is invalid', () async {
      // RegExp('[') throws FormatException → caught by the `on Object` → none.
      writeConfig({
        'streamRules': [
          {'pattern': '[', 'reminder': 'unclosed'},
        ],
      });
      expect(await HarnessRunConfig.load([base.path]), HarnessRunConfig.none);
    });
  });

  group('HarnessRunConfig.load — hook trust', () {
    Future<void> writeConfig(Directory dir) async {
      final agents = Directory(p.join(dir.path, '.agents'))
        ..createSync(recursive: true);
      File(p.join(agents.path, 'harness.json')).writeAsStringSync(
        jsonEncode({
          'streamRules': [
            {'pattern': 'Box::leak', 'reminder': 'Use Arc.'},
          ],
          'hooks': {
            'sessionStart': '.agents/hooks/start.sh',
            'preTool': '.agents/hooks/pre.sh',
          },
        }),
      );
    }

    test('hooks from an UNTRUSTED base are dropped, data is kept', () async {
      // The working tree is a cloned repository. Honoring its hooks meant
      // cloning a hostile repo and dispatching an agent in it executed that
      // repo's scripts on the host.
      await writeConfig(base);
      final cfg = await HarnessRunConfig.load([base.path]);

      expect(cfg.hasHooks, isFalse);
      expect(cfg.hookSessionStart, isNull);
      expect(cfg.hookPreTool, isNull);
      expect(cfg.droppedHookBase, base.path);
      // Everything that is DATA still applies.
      expect(cfg.streamRules, hasLength(1));
    });

    test('hooks from a trusted base are honored', () async {
      await writeConfig(base);
      final cfg = await HarnessRunConfig.load(
        [base.path],
        hookTrustedBases: [base.path],
      );

      expect(cfg.hasHooks, isTrue);
      expect(cfg.hookSessionStart, endsWith('start.sh'));
      expect(cfg.droppedHookBase, isNull);
    });
  });

  group('HarnessRunConfig.load — stream rules', () {
    test('parses valid rules and ignores malformed entries', () async {
      writeConfig({
        'streamRules': [
          {'pattern': 'Box::leak', 'reminder': 'Use Arc instead.'},
          {'pattern': '', 'reminder': 'ignored — empty pattern'},
          {'reminder': 'ignored — missing pattern'},
          'not-a-map',
          {'pattern': 'TODO', 'reminder': 'Track it.'},
        ],
      });
      final cfg = await HarnessRunConfig.load([base.path]);
      expect(cfg.streamRules, hasLength(2));
      expect(cfg.streamRules[0].pattern, isA<RegExp>());
      expect((cfg.streamRules[0].pattern as RegExp).pattern, 'Box::leak');
      expect(cfg.streamRules[0].reminder, 'Use Arc instead.');
      expect((cfg.streamRules[1].pattern as RegExp).pattern, 'TODO');
    });
  });

  group('HarnessRunConfig.load — advisor', () {
    test('parses a fully-populated advisor', () async {
      writeConfig({
        'advisor': {
          'enabled': true,
          'model': '  claude-haiku-4-5  ',
          'everyTurns': 5,
          'instructions': '  watch for errors  ',
        },
      });
      final cfg = await HarnessRunConfig.load([base.path]);
      expect(cfg.advisorEnabled, isTrue);
      expect(cfg.advisorModel, 'claude-haiku-4-5');
      expect(cfg.advisorEveryTurns, 5);
      expect(cfg.advisorInstructions, 'watch for errors');
    });

    test('coerces everyTurns < 1 to the default (3)', () async {
      writeConfig({
        'advisor': {'enabled': true, 'everyTurns': 0},
      });
      expect((await HarnessRunConfig.load([base.path])).advisorEveryTurns, 3);
    });

    test('coerces non-int everyTurns to the default (3)', () async {
      writeConfig({
        'advisor': {'enabled': true, 'everyTurns': 'five'},
      });
      expect((await HarnessRunConfig.load([base.path])).advisorEveryTurns, 3);
    });

    test('ignores a blank model string', () async {
      writeConfig({
        'advisor': {'enabled': true, 'model': '   '},
      });
      expect((await HarnessRunConfig.load([base.path])).advisorModel, isNull);
    });

    test('disabled advisor when enabled is not true', () async {
      writeConfig({
        'advisor': {'enabled': false},
      });
      expect(
        (await HarnessRunConfig.load([base.path])).advisorEnabled,
        isFalse,
      );
    });

    test('no advisor block → disabled with defaults', () async {
      writeConfig({});
      final cfg = await HarnessRunConfig.load([base.path]);
      expect(cfg.advisorEnabled, isFalse);
      expect(cfg.advisorEveryTurns, 3);
    });
  });

  // These pin hook PATH RESOLUTION, so they load with the base trusted; the
  // trust gate itself is covered by the `hook trust` group above.
  group('HarnessRunConfig.load — hooks', () {
    test('resolves relative hook paths against the file base', () async {
      writeConfig({
        'hooks': {
          'sessionStart': '.agents/hooks/start.sh',
          'preTool': '.agents/hooks/pre.sh',
          'postTool': '.agents/hooks/post.sh',
        },
      });
      final cfg = await HarnessRunConfig.load([base.path], hookTrustedBases: [base.path]);
      expect(cfg.hasHooks, isTrue);
      expect(cfg.hookSessionStart, p.join(base.path, '.agents/hooks/start.sh'));
      expect(cfg.hookPreTool, p.join(base.path, '.agents/hooks/pre.sh'));
      expect(cfg.hookPostTool, p.join(base.path, '.agents/hooks/post.sh'));
    });

    test('keeps absolute hook paths as-is', () async {
      writeConfig({
        'hooks': {'preTool': '/usr/local/bin/pre.sh'},
      });
      expect(
        (await HarnessRunConfig.load([base.path], hookTrustedBases: [base.path])).hookPreTool,
        '/usr/local/bin/pre.sh',
      );
    });

    test('nulls out empty hook paths', () async {
      writeConfig({
        'hooks': {'sessionStart': ''},
      });
      final cfg = await HarnessRunConfig.load([base.path], hookTrustedBases: [base.path]);
      expect(cfg.hookSessionStart, isNull);
      expect(cfg.hasHooks, isFalse);
    });

    test('no hooks block → hasHooks is false', () async {
      writeConfig({
        'advisor': {'enabled': true},
      });
      expect((await HarnessRunConfig.load([base.path], hookTrustedBases: [base.path])).hasHooks, isFalse);
    });

    test('hooks is not a map → all hooks null', () async {
      writeConfig({'hooks': 'not-a-map'});
      final cfg = await HarnessRunConfig.load([base.path], hookTrustedBases: [base.path]);
      expect(cfg.hookSessionStart, isNull);
      expect(cfg.hookPreTool, isNull);
      expect(cfg.hookPostTool, isNull);
      expect(cfg.hasHooks, isFalse);
    });
  });

  group('HarnessRunConfig.load — base precedence', () {
    test('uses the first base that has the file', () async {
      final other = Directory.systemTemp.createTempSync('harness_cfg2_');
      addTearDown(() => other.deleteSync(recursive: true));
      // Put a config in `other`; first base is a non-existent dir.
      writeConfig({
        'advisor': {'enabled': true, 'model': 'from-other'},
      }, dir: other);
      final cfg = await HarnessRunConfig.load([
        p.join(base.path, 'does-not-exist'),
        other.path,
      ]);
      expect(cfg.advisorModel, 'from-other');
    });
  });

  group('HarnessRunConfig.none', () {
    test('everything is off by default', () {
      const cfg = HarnessRunConfig.none;
      expect(cfg.streamRules, isEmpty);
      expect(cfg.advisorEnabled, isFalse);
      expect(cfg.hasHooks, isFalse);
      expect(cfg.advisorEveryTurns, 3);
    });
  });
}
