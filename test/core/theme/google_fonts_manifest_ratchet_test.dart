import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/source_files.dart';

/// Ratchet: nothing may depend on `package:google_fonts` again.
///
/// Its manifest is one const map over ~1900 families, so a single reference
/// retains every `google_fonts_parts/part_*.dart`. Measured with
/// `flutter build web --release --dump-info`, that was 14.3 MB of a 27 MB
/// `main.dart.js` — over half the web bundle and enough to break the Cloudflare
/// deploy (hard 25 MiB per-asset limit).
///
/// The replacement inverts the tradeoff: the catalogue is fetched at runtime and
/// cached by the host (`fonts.list`) and one variant's bytes are loaded on
/// demand through `/proxy/font` and registered by `CcFontRegistry`. So the
/// bundle carries no font metadata at all and the user picks from every family
/// rather than a compiled-in subset.
void main() {
  final projectRoot = Directory.current.path;

  group('google_fonts ratchet', () {
    test('no pubspec declares google_fonts as a dependency', () {
      final pubspecs = [
        File('$projectRoot/pubspec.yaml'),
        for (final dir in ['packages', 'apps'])
          ...Directory('$projectRoot/$dir')
              .listSync()
              .whereType<Directory>()
              .map((d) => File('${d.path}/pubspec.yaml')),
      ].where((file) => file.existsSync());

      final violations = <String>[];
      for (final pubspec in pubspecs) {
        final declarations = pubspec
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('#'))
            .where((line) => line.contains('google_fonts:'));
        if (declarations.isNotEmpty) {
          violations.add(pubspec.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'google_fonts compiles a ~1900-family manifest into the bundle '
            '(~14 MB of JS). Families load at runtime through the host '
            'instead — see CcFontRegistry:\n${violations.join('\n')}',
      );
    });

    test('no source file imports or references google_fonts', () {
      // Enumerate through the shared helper, NOT `listSync(recursive: true)`:
      // that walks `apps/cc_server/data/` — a gitignored runtime tree holding
      // provisioned worktree CLONES OF THIS REPO — so the scan both took
      // minutes and flagged this very file, found inside a clone of itself.
      // `dartSourceFiles` enumerates via git and honours .gitignore.
      final violations = <String>[];
      for (final file in dartSourceFiles(includeTests: true)) {
        // Comment lines are exempt: the ban is explained in prose in
        // CcFontRegistry, which would otherwise flag itself.
        final code = file
            .readAsLinesSync()
            .where((line) => !line.trimLeft().startsWith('//'))
            .join('\n');
        if (code.contains('package:google_fonts') ||
            code.contains('GoogleFonts.')) {
          violations.add(file.path);
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'These reach the compiled-in family manifest. Load the family at '
            'runtime via CcFontRegistry instead:\n${violations.join('\n')}',
      );
    });
  });
}
