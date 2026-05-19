import 'dart:convert';
import 'dart:io';

import 'package:cc_server_core/src/demo/demo_script.dart';
import 'package:cc_server_core/src/demo/fixtures/demo_fixtures.g.dart';
import 'package:test/test.dart';

/// Finds the repo root by walking up until `tool/gen_demo_fixtures.dart` exists.
Directory _repoRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 6; i++) {
    if (File('${dir.path}/tool/gen_demo_fixtures.dart').existsSync()) {
      return dir;
    }
    dir = dir.parent;
  }
  fail('could not locate the repo root from ${Directory.current.path}');
}

void main() {
  test(
    'the committed fixtures match their authored JSON',
    () {
      // Same discipline as `test/tooling/web_workers_test.dart`: the generated
      // file is committed, so a fixture edited without regenerating would ship a
      // demo that silently plays yesterday's script.
      final root = _repoRoot();
      final result = Process.runSync('dart', [
        'run',
        'tool/gen_demo_fixtures.dart',
        '--check',
      ], workingDirectory: root.path);
      expect(
        result.exitCode,
        0,
        reason:
            'demo fixtures are stale — run '
            '`fvm dart run tool/gen_demo_fixtures.dart`.\n'
            '${result.stdout}${result.stderr}',
      );
    },
    // `dart run` re-bundles this package's native assets into `.dart_tool/`
    // before it executes anything, and THIS process already has
    // `sqlite3.dll` loaded from exactly there. Windows refuses to replace an
    // open DLL, so the nested run dies with "Cannot delete file …
    // sqlite3.dll (Access is denied)" and the check reports the fixtures as
    // stale when they are current — a false failure about a file nobody
    // touched. Nothing here is platform-specific (it compares committed
    // bytes to regenerated ones), so the Linux and macOS jobs cover it.
    skip: Platform.isWindows
        ? 'nested `dart run` cannot re-bundle sqlite3.dll while this process '
              'holds it open'
        : null,
  );

  test('every authored script parses and is well formed', () {
    final decoded = jsonDecode(kDemoRunScriptsJson);
    expect(decoded, isA<List<dynamic>>());
    final scripts = [
      for (final raw in decoded as List)
        DemoRunScript.fromJson(Map<String, dynamic>.from(raw as Map)),
    ];

    expect(scripts, isNotEmpty);
    for (final script in scripts) {
      expect(script.id, isNotEmpty, reason: 'a script needs an addressable id');
      expect(
        script.steps,
        isNotEmpty,
        reason: '${script.id} would stream nothing at all',
      );
      // A run that never speaks reads as a hang, whatever else it does.
      expect(
        script.steps.whereType<DemoSayStep>(),
        isNotEmpty,
        reason: '${script.id} never says anything',
      );
    }

    // Ids are unique, or `[[demo:script=<id>]]` is ambiguous.
    final ids = scripts.map((s) => s.id).toList();
    expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate script id');

    // Exactly one catch-all (no triggers) so an unmatched message has a home
    // and the fallback is deliberate rather than alphabetical.
    final catchAll = scripts.where((s) => s.triggers.isEmpty).toList();
    expect(
      catchAll,
      hasLength(1),
      reason: 'expected exactly one trigger-less fallback script',
    );
  });

  test('tool steps pair a name with a result', () {
    final decoded = jsonDecode(kDemoRunScriptsJson) as List;
    for (final raw in decoded) {
      final script = DemoRunScript.fromJson(
        Map<String, dynamic>.from(raw as Map),
      );
      for (final step in script.steps.whereType<DemoToolStep>()) {
        expect(step.tool, isNotEmpty, reason: '${script.id}: unnamed tool');
        expect(
          step.result,
          isNotEmpty,
          reason: '${script.id}: ${step.tool} renders an empty result card',
        );
      }
    }
  });
}
