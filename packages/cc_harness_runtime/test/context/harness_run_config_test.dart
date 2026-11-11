import 'dart:convert';
import 'dart:io';

import 'package:cc_harness_runtime/src/context/harness_run_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [HarnessRunConfig.load] — the opt-in `.agents/harness.json`
/// reader and the hook folder's `hooks.json`. Covers: absent file → none, the
/// parse-failure → none fallback, the advisor-field defaults/coercion, hooks
/// declared outside the hook folder being dropped, and hook path containment.
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

  group('HarnessRunConfig.load — hooks outside the hook folder', () {
    test('a working tree or agent config dir cannot declare hooks', () async {
      // Members and runs write the agent config dir, and a working tree is
      // routinely a cloned repository: neither may make the host run code.
      // Written the way `fs.writeString` would write it.
      final scripts = Directory(p.join(base.path, '.agents', 'hooks'))
        ..createSync(recursive: true);
      File(p.join(scripts.path, 'pre.sh')).writeAsStringSync('exit 0');
      writeConfig({
        'streamRules': [
          {'pattern': 'Box::leak', 'reminder': 'Use Arc.'},
        ],
        'hooks': {
          'sessionStart': '.agents/hooks/start.sh',
          'preTool': '.agents/hooks/pre.sh',
        },
      });
      final hookFolder = Directory.systemTemp.createTempSync('hook_folder_');
      addTearDown(() => hookFolder.deleteSync(recursive: true));

      for (final cfg in [
        await HarnessRunConfig.load([base.path]),
        await HarnessRunConfig.load([base.path], hookBase: hookFolder.path),
      ]) {
        expect(cfg.hasHooks, isFalse);
        expect(cfg.hookSessionStart, isNull);
        expect(cfg.hookPreTool, isNull);
        expect(cfg.droppedHookBase, base.path);
        // Everything that is DATA still applies.
        expect(cfg.streamRules, hasLength(1));
      }
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

  group('HarnessRunConfig.load — the hook folder', () {
    late Directory folder;

    setUp(() {
      folder = Directory.systemTemp.createTempSync('hook_folder_');
      addTearDown(() => folder.deleteSync(recursive: true));
    });

    String script(String rel) {
      final file = File(p.join(folder.path, rel))
        ..createSync(recursive: true)
        ..writeAsStringSync('#!/bin/sh\nexit 0\n');
      return file.resolveSymbolicLinksSync();
    }

    void writeHooks(Object json) => File(
      p.join(folder.path, HarnessRunConfig.hooksFileName),
    ).writeAsStringSync(jsonEncode(json));

    Future<HarnessRunConfig> load() =>
        HarnessRunConfig.load([base.path], hookBase: folder.path);

    test('resolves relative paths inside the folder', () async {
      final start = script('start.sh');
      final pre = script('bin/pre.sh');
      final post = script('post.sh');
      writeHooks({
        'sessionStart': 'start.sh',
        'preTool': 'bin/pre.sh',
        'postTool': 'post.sh',
      });
      final cfg = await load();
      expect(cfg.hasHooks, isTrue);
      expect(cfg.hookSessionStart, start);
      expect(cfg.hookPreTool, pre);
      expect(cfg.hookPostTool, post);
      expect(cfg.refusedHooks, isEmpty);
      expect(cfg.preToolRefused, isFalse);
    });

    test('keeps the data settings of the working tree', () async {
      script('start.sh');
      writeHooks({'sessionStart': 'start.sh'});
      writeConfig({
        'advisor': {'enabled': true},
      });
      final cfg = await load();
      expect(cfg.advisorEnabled, isTrue);
      expect(cfg.hookSessionStart, isNotNull);
      expect(cfg.droppedHookBase, isNull);
    });

    test('refuses an absolute path, and the gate then denies', () async {
      writeHooks({'preTool': script('pre.sh')});
      final cfg = await load();
      expect(cfg.hookPreTool, isNull);
      expect(cfg.preToolRefused, isTrue);
      expect(cfg.hasHooks, isTrue);
      expect(cfg.refusedHooks, ['preTool: an absolute path']);
    });

    test('refuses a path that climbs out of the folder', () async {
      File(p.join(base.path, 'outside.sh')).writeAsStringSync('exit 0');
      writeHooks({
        'postTool': p.join('..', p.basename(base.path), 'outside.sh'),
      });
      final cfg = await load();
      expect(cfg.hookPostTool, isNull);
      expect(cfg.refusedHooks, ['postTool: outside the hook folder']);
      expect(cfg.preToolRefused, isFalse);
    });

    test(
      'refuses a link inside the folder that points out of it',
      () async {
        final outside = File(p.join(base.path, 'outside.sh'))
          ..writeAsStringSync('exit 0');
        Link(p.join(folder.path, 'pre.sh')).createSync(outside.path);
        writeHooks({'preTool': 'pre.sh'});
        final cfg = await load();
        expect(cfg.hookPreTool, isNull);
        expect(cfg.preToolRefused, isTrue);
        expect(cfg.refusedHooks, ['preTool: outside the hook folder']);
      },
      skip: Platform.isWindows
          ? 'file links need privileges on Windows'
          : false,
    );

    test('refuses a missing script and an empty path', () async {
      writeHooks({'sessionStart': 'nope.sh', 'postTool': ''});
      final cfg = await load();
      expect(cfg.hasHooks, isFalse);
      expect(cfg.refusedHooks, [
        'sessionStart: no such file',
        'postTool: not a path',
      ]);
    });

    test('an unreadable declaration file denies every tool call', () async {
      File(
        p.join(folder.path, HarnessRunConfig.hooksFileName),
      ).writeAsStringSync('{not json');
      final cfg = await load();
      expect(cfg.preToolRefused, isTrue);
      expect(cfg.refusedHooks, ['not valid JSON']);
    });

    test('no declaration file → no hooks', () async {
      final cfg = await load();
      expect(cfg.hasHooks, isFalse);
      expect(cfg.refusedHooks, isEmpty);
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
