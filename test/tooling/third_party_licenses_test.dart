import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over the third-party attribution that ships inside every artifact.
///
/// Control Center is MIT, but its packages redistribute a dozen third-party
/// components — and one of them, libmp3lame, is LGPL-2.1 and statically linked.
/// Before this existed, the artifacts carried no notice at all: not the MIT and
/// BSD attributions those licenses require to travel with a binary, and not the
/// LGPL section 6 relink offer.
///
/// The failure mode this guards is silent. A native gets added to the build
/// matrix, ships, and nobody notices that its license never joined it — so the
/// check is "every native has a decided disposition", not "the table is
/// non-empty".
void main() {
  final root = Directory.current.path;
  final natives = File('$root/scripts/lib/natives.sh').readAsStringSync();
  final table = File('$root/scripts/lib/third_party.sh').readAsStringSync();
  final licenseDir = Directory('$root/third_party/licenses');

  /// `base name → the third-party component it carries`, or [_firstParty] when
  /// the library is ours and vendors nothing.
  ///
  /// Adding a native means adding a row here, which is the point: the choice
  /// between "this needs attribution" and "this is ours" is made once, in the
  /// open, instead of being skipped.
  const firstParty = '<first-party>';
  const carries = <String, String>{
    'aec_ffi': 'webrtc-audio-processing',
    'fff_c': 'fff',
    'tree-sitter': 'tree-sitter',
    'tree-sitter-dart': 'tree-sitter-dart',
    'tree-sitter-javascript': 'tree-sitter-javascript',
    'tree-sitter-typescript': 'tree-sitter-typescript',
    'tree-sitter-tsx':
        'tree-sitter-typescript', // one grammar repo, two parsers
    'tree-sitter-php': 'tree-sitter-php',
    'ccpty': 'flutter_pty (vendored C)',
    'cc_watcher': firstParty,
    'lame_ffi': 'LAME (libmp3lame)',
    'cc_inference': 'sherpa-onnx',
    'cc_saml': firstParty,
    'rift_ffi': 'rift',
  };

  /// The `name|version|spdx|homepage|license_file|linkage|roles` rows.
  List<List<String>> parseComponents() {
    final rows = <List<String>>[];
    final body = RegExp(
      r'CC_THIRD_PARTY=\((.*?)\n\)',
      dotAll: true,
    ).firstMatch(table);
    expect(body, isNotNull, reason: 'CC_THIRD_PARTY array not found');
    for (final line in body!.group(1)!.split('\n')) {
      final quoted = RegExp(r'^\s*"([^"]+)"\s*$').firstMatch(line);
      if (quoted == null) {
        continue; // a comment inside the array
      }
      final parts = quoted.group(1)!.split('|');
      expect(
        parts.length,
        7,
        reason: 'malformed third-party row: ${quoted.group(1)}',
      );
      rows.add(parts);
    }
    return rows;
  }

  test('every shipped native has a decided attribution disposition', () {
    final matrix = RegExp(
      r'CC_NATIVES=\((.*?)\n\)',
      dotAll: true,
    ).firstMatch(natives);
    expect(matrix, isNotNull, reason: 'CC_NATIVES array not found');
    final bases = <String>[
      for (final line in matrix!.group(1)!.split('\n'))
        if (RegExp(r'^\s*"([^|]+)\|').firstMatch(line) case final m?)
          m.group(1)!,
    ];
    expect(bases, isNotEmpty);

    final componentNames = {for (final row in parseComponents()) row[0]};
    final undecided = <String>[];
    for (final base in bases) {
      final carrier = carries[base];
      if (carrier == null) {
        undecided.add('$base — add it to `carries` in this test');
        continue;
      }
      if (carrier != firstParty && !componentNames.contains(carrier)) {
        undecided.add('$base names "$carrier", which is not in CC_THIRD_PARTY');
      }
    }
    expect(
      undecided,
      isEmpty,
      reason:
          'These natives ship without a decided license disposition:\n'
          '${undecided.join('\n')}',
    );
  });

  test('every component points at a license text that exists', () {
    final missing = <String>[];
    for (final row in parseComponents()) {
      final file = File('${licenseDir.path}/${row[4]}');
      if (!file.existsSync()) {
        missing.add('${row[0]} → third_party/licenses/${row[4]} (absent)');
      } else if (file.lengthSync() < 200) {
        // A stub instead of a license is the same problem wearing a filename.
        missing.add('${row[0]} → ${row[4]} is only ${file.lengthSync()} bytes');
      }
    }
    expect(missing, isEmpty, reason: missing.join('\n'));
  });

  test('no orphan license texts', () {
    final referenced = {for (final row in parseComponents()) row[4]};
    final orphans = [
      for (final f in licenseDir.listSync().whereType<File>())
        if (!referenced.contains(f.uri.pathSegments.last))
          f.uri.pathSegments.last,
    ]..sort();
    expect(
      orphans,
      isEmpty,
      reason:
          'Unreferenced files in third_party/licenses/ (delete them, or add '
          'the component to CC_THIRD_PARTY):\n${orphans.join('\n')}',
    );
  });

  test('both roles generate, and the LGPL notice survives', () {
    // Regression: the notice was gated on `cc_third_party_for | grep -q LGPL`.
    // `-q` exits on the first match, the producer takes SIGPIPE, and under
    // `set -o pipefail` the condition evaluated FALSE — so the one legally
    // load-bearing paragraph in the file silently never printed. Assert the
    // OUTPUT, not the table.
    final tmp = Directory.systemTemp.createTempSync('cc-tpl');
    addTearDown(() => tmp.deleteSync(recursive: true));

    for (final role in const ['desktop', 'server']) {
      final out = '${tmp.path}/$role.txt';
      final result = Process.runSync('bash', [
        'scripts/release/gen_third_party_licenses.sh',
        role,
        out,
      ], workingDirectory: root);
      expect(
        result.exitCode,
        0,
        reason: 'generator failed for $role: ${result.stderr}',
      );

      final text = File(out).readAsStringSync();
      for (final row in parseComponents()) {
        if (!row[6].split(',').contains(role)) {
          continue;
        }
        expect(
          text,
          contains(row[0]),
          reason: '$role output never names ${row[0]}',
        );
      }
      // Both artifacts embed a cc_server, so both carry libmp3lame.
      expect(
        text,
        contains('LGPL COMPONENTS AND RELINKING'),
        reason: 'the $role artifact ships LAME but states no relink offer',
      );
    }
  }, skip: Platform.isWindows ? 'needs bash' : null);
}
