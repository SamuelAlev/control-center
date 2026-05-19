// Regenerates packages/cc_natives/lib/src/code_index/embedded_queries.dart
// from the canonical tree-sitter queries in scripts/natives/queries/*.scm.
//
// Usage (from the repo root):
//   fvm dart run tool/gen_embedded_queries.dart
//
// Same discipline as build_runner / tool/gen_workers.sh: edit the .scm, run
// the generator, commit both. test/tooling/embedded_queries_test.dart fails
// CI whenever the generated Dart drifts from the .scm files, so forgetting to
// regenerate (or to add a new language) cannot merge.
//
// Why embed at all: `dart build cli` only bundles `bin/` + `lib/` (dynamic
// libraries); the experimental data-assets hook protocol is not yet supported
// by the CLI, so a loose .scm cannot ride inside the server binary's bundle.
// Compiling the queries in keeps both hosts (desktop and cc_server)
// self-contained with zero data files to stage.

import 'dart:io';

void main() {
  final queriesDir = Directory('scripts/natives/queries');
  if (!queriesDir.existsSync()) {
    stderr.writeln('Run from the repo root: ${queriesDir.path} not found.');
    exit(1);
  }

  final files = queriesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.scm'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    stderr.writeln('No .scm files in ${queriesDir.path}.');
    exit(1);
  }

  final buffer = StringBuffer('''
// GENERATED FILE — DO NOT EDIT BY HAND.
//
// Generated from the canonical `scripts/natives/queries/*.scm` by
// `tool/gen_embedded_queries.dart`. To change a query, edit the .scm and run:
//
//   fvm dart run tool/gen_embedded_queries.dart
//
// test/tooling/embedded_queries_test.dart pins this file byte-identical to
// the .scm sources, so a stale regeneration fails CI.

/// The tree-sitter `.scm` extraction queries, embedded as Dart constants so
/// every host (the Flutter desktop AND the `dart build cli` server binary)
/// carries them without shipping loose data files — the grammar dylibs bundle
/// as code assets and these queries compile in beside them.
///
/// An on-disk `<queryId>.scm` beside the grammar libs still wins at runtime
/// (`GrammarManager.loadQuery`), staged by `build_tree_sitter.sh` as a
/// dev-time override.
///
/// Keyed by query id (see `queryIdFor` — `tsx` reuses the `typescript` query).
library;
''');

  final ids = <String>[];
  final constants = StringBuffer();
  for (final file in files) {
    final id = file.uri.pathSegments.last.replaceAll('.scm', '');
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id)) {
      stderr.writeln('Query id "$id" is not a valid Dart identifier suffix.');
      exit(1);
    }
    var content = file.readAsStringSync();
    if (content.contains("'''")) {
      stderr.writeln('${file.path} contains \'\'\' — cannot embed raw.');
      exit(1);
    }
    if (!content.endsWith('\n')) {
      content = '$content\n';
    }
    ids.add(id);
    // The newline right after the opening quotes is not part of the literal.
    constants
      ..writeln()
      ..write("const String _\$$id = r'''\n$content''';\n");
  }

  buffer.writeln('\n/// Query id → `.scm` source.');
  buffer.writeln('const Map<String, String> embeddedTreeSitterQueries = {');
  for (final id in ids) {
    buffer.writeln("  '$id': _\$$id,");
  }
  buffer
    ..writeln('};')
    ..write(constants);

  final outFile = File(
    'packages/cc_natives/lib/src/code_index/embedded_queries.dart',
  );
  outFile.writeAsStringSync(buffer.toString());
  stdout.writeln(
    'Wrote ${outFile.path} (${ids.length} queries: ${ids.join(', ')}).',
  );
}
