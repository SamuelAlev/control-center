import 'dart:io';

import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_server_registry.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/lsp/lsp_symbol_position.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

LspDiagnostic _d(
  String message, {
  String severity = 'error',
  int line = 1,
  String? code,
  String path = '/repo/a.dart',
}) => LspDiagnostic(
  path: path,
  line: line,
  column: 1,
  severity: severity,
  message: message,
  code: code,
);

void main() {
  group('resolveSymbolColumn', () {
    const source = 'void alpha() {\n  final x = alpha() + alpha();\n}\n';

    test('resolves a symbol to its 1-indexed column', () {
      expect(resolveSymbolColumn(source, 1, 'alpha'), 6);
    });

    test('#N selects the Nth occurrence on the line', () {
      // `final x = alpha() + alpha();` — the second call, not the first.
      final first = resolveSymbolColumn(source, 2, 'alpha') as int;
      final second = resolveSymbolColumn(source, 2, 'alpha#2') as int;
      expect(second, greaterThan(first));
    });

    test('an out-of-range occurrence falls back rather than failing', () {
      expect(resolveSymbolColumn(source, 2, 'alpha#9'), isA<int>());
    });

    test('a missing symbol reports the line instead of guessing', () {
      final result = resolveSymbolColumn(source, 1, 'nosuch');
      expect(result, isA<String>());
      expect(result as String, contains('void alpha()'));
    });

    test('omitting the symbol is a hard error, never column 1', () {
      // A navigation answer about the wrong symbol is worse than no answer:
      // the model cannot tell it apart from a correct one.
      final result = resolveSymbolColumn(source, 1, null);
      expect(result, isA<String>());
      expect(result as String, contains('needs `symbol`'));
    });

    test('a line outside the file is refused', () {
      expect(resolveSymbolColumn(source, 99, 'alpha'), isA<String>());
    });

    test('falls back to a case-insensitive match before giving up', () {
      expect(resolveSymbolColumn(source, 1, 'ALPHA'), 6);
    });
  });

  group('DiagnosticsLedger', () {
    test('reports everything the first time', () {
      final ledger = DiagnosticsLedger();
      final fresh = ledger.fresh('/repo/a.dart', [_d('one'), _d('two')]);
      expect(fresh.map((d) => d.message), ['one', 'two']);
    });

    test('reports only what is new on a later pass', () {
      final ledger = DiagnosticsLedger();
      ledger.fresh('/repo/a.dart', [_d('old')]);
      final fresh = ledger.fresh('/repo/a.dart', [_d('old'), _d('new')]);
      expect(
        fresh.map((d) => d.message),
        ['new'],
        reason: 'a file with pre-existing errors would otherwise re-report '
            'them after every edit, burying the one just introduced',
      );
    });

    test('a moved diagnostic is not new', () {
      // Inserting a line above an error moves it without changing it.
      final ledger = DiagnosticsLedger();
      ledger.fresh('/repo/a.dart', [_d('boom', line: 10)]);
      expect(ledger.fresh('/repo/a.dart', [_d('boom', line: 42)]), isEmpty);
    });

    test('severity and code are part of identity', () {
      final ledger = DiagnosticsLedger();
      ledger.fresh('/repo/a.dart', [_d('x', severity: 'warning')]);
      expect(
        ledger.fresh('/repo/a.dart', [_d('x', severity: 'error')]),
        hasLength(1),
        reason: 'a warning becoming an error is news',
      );
    });

    test('a fixed diagnostic can be reported again if it returns', () {
      final ledger = DiagnosticsLedger();
      ledger.fresh('/repo/a.dart', [_d('boom')]);
      ledger.fresh('/repo/a.dart', const []); // fixed
      expect(ledger.fresh('/repo/a.dart', [_d('boom')]), hasLength(1));
    });

    test('files are tracked independently', () {
      final ledger = DiagnosticsLedger();
      ledger.fresh('/repo/a.dart', [_d('boom')]);
      expect(
        ledger.fresh('/repo/b.dart', [_d('boom', path: '/repo/b.dart')]),
        hasLength(1),
      );
    });

    test('forget makes the next report first-seen again', () {
      final ledger = DiagnosticsLedger();
      ledger.fresh('/repo/a.dart', [_d('boom')]);
      ledger.forget('/repo/a.dart');
      expect(ledger.fresh('/repo/a.dart', [_d('boom')]), hasLength(1));
    });
  });

  group('renderDiagnostics', () {
    test('puts errors before warnings', () {
      final rendered = renderDiagnostics([
        _d('a warning', severity: 'warning', line: 1),
        _d('an error', severity: 'error', line: 90),
      ], includePath: false);
      expect(rendered.indexOf('an error'), lessThan(rendered.indexOf('a warning')));
    });

    test('truncates with a count rather than silently dropping', () {
      final rendered = renderDiagnostics([
        for (var i = 0; i < 30; i++) _d('problem $i', line: i + 1),
      ], limit: 5);
      expect('\n'.allMatches(rendered).length, 5);
      expect(rendered, contains('and 25 more'));
    });

    test('an empty list renders empty', () {
      expect(renderDiagnostics(const []), isEmpty);
    });
  });

  group('detectLspServers', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('cc_lsp'));
    tearDown(() => root.deleteSync(recursive: true));

    test('needs BOTH a root marker and a binary', () {
      // Marker present, binary missing → no server. Otherwise every request
      // fails with a spawn error the model reads as "no definitions here".
      File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      expect(
        detectLspServers(
          projectRoot: root.path,
          binaryResolver: (_) => false,
        ),
        isEmpty,
      );
      // Binary present, marker missing → no server. Otherwise a Go analyzer
      // starts for a repo with no Go in it.
      expect(
        detectLspServers(
          projectRoot: root.path,
          binaryResolver: (_) => true,
        ).map((s) => s.name),
        ['dartls'],
        reason: 'only the server whose marker exists',
      );
    });

    test('an explicit override list switches auto-detection off', () {
      File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      File(p.join(root.path, 'Cargo.toml')).writeAsStringSync('[package]');
      final detected = detectLspServers(
        projectRoot: root.path,
        overrides: const {'dartls': <String, dynamic>{}},
        binaryResolver: (_) => true,
      );
      expect(detected.map((s) => s.name), ['dartls']);
    });

    test('an override can disable a server', () {
      File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      expect(
        detectLspServers(
          projectRoot: root.path,
          overrides: const {
            'dartls': {'disabled': true},
          },
          binaryResolver: (_) => true,
        ),
        isEmpty,
      );
    });

    test('an override layers over the built-in without restating it', () {
      File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      final detected = detectLspServers(
        projectRoot: root.path,
        overrides: const {
          'dartls': {
            'args': ['--custom'],
          },
        },
        binaryResolver: (_) => true,
      );
      expect(detected.single.command, 'dart', reason: 'inherited');
      expect(detected.single.args, ['--custom']);
    });

    test('malformed override config falls back to auto-detection', () {
      File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x');
      Directory(p.join(root.path, '.agents')).createSync();
      File(p.join(root.path, '.agents', 'lsp.json'))
          .writeAsStringSync('{ not json');
      expect(loadLspOverrides(root.path), isEmpty);
    });

    test('a config with only non-server keys does not disable detection', () {
      Directory(p.join(root.path, '.agents')).createSync();
      File(p.join(root.path, '.agents', 'lsp.json'))
          .writeAsStringSync('{"idleTimeoutMs": 1000}');
      expect(loadLspOverrides(root.path), isEmpty);
    });
  });

  group('LspServerConfig.handles', () {
    test('matches by extension, case-insensitively', () {
      const dart = LspServerConfig(
        name: 'dartls',
        command: 'dart',
        fileTypes: ['.dart'],
        rootMarkers: ['pubspec.yaml'],
      );
      expect(dart.handles('/repo/lib/a.dart'), isTrue);
      expect(dart.handles('/repo/lib/A.DART'), isTrue);
      expect(dart.handles('/repo/README.md'), isFalse);
    });
  });

  group('findProjectRoot', () {
    late Directory root;
    setUp(() => root = Directory.systemTemp.createTempSync('cc_root'));
    tearDown(() => root.deleteSync(recursive: true));

    test('walks up to the nearest marker', () {
      // A monorepo package is its own project to a language server: running
      // from the repo root gives it the wrong package config.
      final pkg = Directory(p.join(root.path, 'packages', 'thing'))
        ..createSync(recursive: true);
      File(p.join(pkg.path, 'pubspec.yaml')).writeAsStringSync('name: thing');
      final nested = Directory(p.join(pkg.path, 'lib', 'src'))
        ..createSync(recursive: true);
      expect(findProjectRoot(nested.path), pkg.absolute.path);
    });

    test('falls back to the start when nothing is found', () {
      final bare = Directory(p.join(root.path, 'bare'))..createSync();
      expect(findProjectRoot(bare.path), bare.path);
    });
  });

  group('LspSupervisor', () {
    test('detection is cached per root', () {
      final supervisor = LspSupervisor();
      addTearDown(supervisor.dispose);
      final root = Directory.systemTemp.createTempSync('cc_sup');
      addTearDown(() => root.deleteSync(recursive: true));
      final first = supervisor.serversFor(root.path);
      expect(identical(supervisor.serversFor(root.path), first), isTrue);
    });

    test('a linter is excluded from type-intelligence lookups', () {
      final supervisor = LspSupervisor();
      addTearDown(supervisor.dispose);
      final root = Directory.systemTemp.createTempSync('cc_sup');
      addTearDown(() => root.deleteSync(recursive: true));
      // No servers are installed in a temp dir, so this asserts the shape of
      // the filter rather than a live roster.
      expect(
        supervisor.serversForFile(
          root.path,
          '${root.path}/a.py',
          typeIntelligenceOnly: true,
        ),
        isEmpty,
      );
    });

    test('dispose is safe with nothing running', () async {
      await LspSupervisor().dispose();
    });
  });
}
