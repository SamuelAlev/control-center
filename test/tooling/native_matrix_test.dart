import 'dart:io';

import 'package:cc_natives/src/code_index/code_languages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ratchet over the required-native matrix.
///
/// This list is consumed by four audiences and used to be WRITTEN four times:
/// `verify_natives.sh`'s gate (prefix + extension, dot-bounded),
/// `cc_server_package.sh`'s separate glob-list gate, the runtime table built
/// with `nativeRequirement` in cc_server_runtime.dart and native_preflight.dart.
/// Each carried a comment asking the reader to "change them together".
///
/// The two shell copies are gone — both now read scripts/lib/natives.sh. The
/// Dart table cannot be generated from it (each entry is a probe *closure*, not
/// a filename), so this test pins the two together instead. A native added to
/// one and forgotten in the other is a boot failure on a user's machine: the
/// packaging gate passes because its list never heard of the library and then
/// cc_server refuses to start because the preflight did.
void main() {
  final root = Directory.current.path;
  final matrix = File('$root/scripts/lib/natives.sh').readAsStringSync();
  final runtime = File(
    '$root/packages/cc_server_core/lib/src/cc_server_runtime.dart',
  ).readAsStringSync();

  /// The rows of `CC_NATIVES`, parsed the same way the shell does.
  final rows = <({String base, Set<String> roles, String platforms})>[
    for (final line in matrix.split('\n'))
      if (RegExp(r'^\s*"[^"|]+\|').hasMatch(line))
        () {
          final fields = line.trim().replaceAll('"', '').split('|');
          return (
            base: fields[0],
            roles: fields[1].split(',').toSet(),
            platforms: fields[2],
          );
        }(),
  ];

  test('the matrix parses and is not silently empty', () {
    // A typo in the row format would make every other check here vacuous.
    expect(rows.length, greaterThanOrEqualTo(10));
    for (final row in rows) {
      expect(row.base, isNotEmpty);
      expect(row.roles, isNotEmpty);
      expect(
        row.roles.difference({'desktop', 'server'}),
        isEmpty,
        reason: '${row.base}: roles must be desktop and/or server',
      );
      expect(
        row.platforms,
        anyOf('all', '!windows'),
        reason: '${row.base}: platforms must be `all` or `!windows`',
      );
    }
  });

  test('every server-role native is probed by the boot preflight', () {
    // cc_server_runtime.dart names each library inside a nativeRequirement(...)
    // description — `platformLibraryFileName('fff_c')`,
    // `platformLibraryFileName(inferenceLibraryBaseName)`, `ptyLibraryBaseName`,
    // etc. Rather than parse Dart, assert the base name appears somewhere in
    // that file: the point is to catch a native that exists in one list and not
    // the other.
    const aliases = <String, List<String>>{
      // Named through a base-name constant instead of a literal.
      'ccpty': ['ptyLibraryBaseName'],
      'cc_watcher': ['watcherLibraryBaseName'],
      // Named through a base-name constant (one native, both ML workloads).
      'cc_inference': ['inferenceLibraryBaseName'],
      // Named through a base-name constant (SAML SSO crypto seam).
      'cc_saml': ['samlLibraryBaseName'],
      // The grammar rows are generated from kLanguageByExtension in a loop.
      'tree-sitter-dart': ['tree-sitter-\$languageId'],
      'tree-sitter-javascript': ['tree-sitter-\$languageId'],
      'tree-sitter-typescript': ['tree-sitter-\$languageId'],
      'tree-sitter-tsx': ['tree-sitter-\$languageId'],
      'tree-sitter-php': ['tree-sitter-\$languageId'],
    };
    for (final row in rows.where((r) => r.roles.contains('server'))) {
      final needles = [row.base, ...?aliases[row.base]];
      expect(
        needles.any(runtime.contains),
        isTrue,
        reason:
            'scripts/lib/natives.sh requires "${row.base}" for the server, but '
            'cc_server_runtime.dart never probes it. Either the packaging gate '
            'is checking for something the server does not need, or the server '
            'boots without something packaging guarantees.',
      );
    }
  });

  test('the shipped grammars are exactly kLanguageByExtension', () {
    // The indexer throws on a recognised language whose grammar is missing, so
    // kLanguageByExtension IS the shipped set. `tsx` gets its own grammar
    // library even though it reuses the typescript *query* (queryIdFor).
    final fromDart = kLanguageByExtension.values.toSet();
    final fromMatrix = rows
        .where((r) => r.base.startsWith('tree-sitter-'))
        .map((r) => r.base.substring('tree-sitter-'.length))
        .toSet();
    expect(
      fromMatrix,
      fromDart,
      reason:
          'scripts/lib/natives.sh and kLanguageByExtension disagree about which '
          'grammars ship. A language in the Dart map with no grammar row means '
          'the indexer throws on files the packaging gate never checked for.',
    );
  });

  test('rift is the only platform exemption and it is server-only', () {
    // Windows has no MSVC copy-on-write backend, so `git worktree` is the
    // BACKEND there rather than a degradation. Any OTHER exemption would be a
    // degraded mode, which this pipeline does not have.
    final exempt = rows.where((r) => r.platforms != 'all').toList();
    expect(exempt.map((r) => r.base), ['rift_ffi']);
    expect(exempt.single.roles, {'server'});
    expect(
      runtime,
      contains('requiredOnWindows: false'),
      reason:
          'the matrix exempts rift on Windows but the runtime table does not',
    );
  });

  test('no shell script hardcodes a native list any more', () {
    // The whole point of scripts/lib/natives.sh. cc_server_package.sh used to
    // carry a second, differently-implemented copy.
    final pkg = File(
      '$root/scripts/release/cc_server_package.sh',
    ).readAsStringSync();
    expect(
      pkg,
      isNot(contains('require_native ')),
      reason:
          'cc_server_package.sh reintroduced its own native list; it should '
          'call verify_natives.sh, which reads scripts/lib/natives.sh',
    );
  });
}
