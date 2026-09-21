// Embeds tree-sitter `.scm` queries into Dart (`dart build cli` cannot bundle
// loose data assets). Edit `.scm`, regenerate, commit both; CI byte-diffs.
// Usage: fvm dart run tool/gen_embedded_queries.dart

import 'dart:io';

/// `c_sharp` → `cSharp`. Query ids stay snake_case on disk and in the map.
String _dartConstName(String id) => id.replaceAllMapped(
  RegExp(r'_([a-z0-9])'),
  (m) => m.group(1)!.toUpperCase(),
);

void main() {
  final queriesDir = Directory('scripts/natives/queries');
  if (!queriesDir.existsSync()) {
    stderr.writeln('Run from the repo root: ${queriesDir.path} not found.');
    exit(1);
  }

  final files =
      queriesDir
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
    final constName = _dartConstName(id);
    // The newline right after the opening quotes is not part of the literal.
    constants
      ..writeln()
      ..write("const String _\$$constName = r'''\n$content''';\n");
  }

  buffer.writeln('\n/// Query id → `.scm` source.');
  buffer.writeln('const Map<String, String> embeddedTreeSitterQueries = {');
  for (final id in ids) {
    buffer.writeln("  '$id': _\$${_dartConstName(id)},");
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
