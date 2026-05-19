import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Drift guard (cheap floor): every `@isolateManagerWorker` /
/// `@isolateManagerCustomWorker` function under `lib/` must have a committed
/// `web/<functionName>.js` Web Worker, so `flutter build web` serves an
/// off-main-thread worker instead of silently falling back to the main isolate.
///
/// This catches "added/renamed a worker but forgot to run tool/gen_workers.sh".
/// The byte-level "source changed, asset stale" case is covered by
/// tool/check_workers.sh (regenerate + diff).
void main() {
  test('every annotated Web Worker has a committed web/<name>.js asset', () {
    final root = Directory.current.path;
    final libDir = Directory('$root/lib');
    expect(libDir.existsSync(), isTrue, reason: 'run from the repo root');

    final annotation = RegExp(r'@isolateManager(?:Custom)?Worker\b');
    final identBeforeParen = RegExp(r'(\w+)\s*\(');

    final workerNames = <String>{};
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final content = entity.readAsStringSync();
      for (final match in annotation.allMatches(content)) {
        // Walk forward from the annotation, skipping blank lines and any other
        // annotation / `@pragma(...)` lines, to the function signature and grab
        // the identifier immediately before its `(`.
        final rest = content.substring(match.end);
        for (final rawLine in rest.split('\n')) {
          final line = rawLine.trim();
          if (line.isEmpty || line.startsWith('@')) {
            continue;
          }
          final name = identBeforeParen.firstMatch(line)?.group(1);
          if (name != null) {
            workerNames.add(name);
          }
          break;
        }
      }
    }

    expect(
      workerNames,
      isNotEmpty,
      reason:
          'no annotated Web Workers found — did the annotation name change?',
    );

    final missing = <String>[];
    for (final name in workerNames) {
      final js = File('$root/web/$name.js');
      if (!js.existsSync() || js.lengthSync() == 0) {
        missing.add('web/$name.js');
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          'Missing/empty Web Worker assets for annotated workers $workerNames. '
          'Run: tool/gen_workers.sh, then commit web/*.js',
    );
  });

  test('the shiki tokenize worker asset is committed', () {
    // Not an isolate_manager worker (so the scan above can't see it): shiki's
    // prebuilt Web Worker backs `asyncWeb` highlighting, installed by
    // tool/gen_workers.sh via `dart run shiki_flutter:install`. Missing it
    // silently degrades web highlighting to the main thread.
    final js = File('${Directory.current.path}/web/shiki_tokenize_worker.js');
    expect(
      js.existsSync() && js.lengthSync() > 0,
      isTrue,
      reason:
          'web/shiki_tokenize_worker.js is missing/empty. '
          'Run: tool/gen_workers.sh, then commit web/*.js',
    );
  });
}
