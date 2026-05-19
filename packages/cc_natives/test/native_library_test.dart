@TestOn('vm')
library;

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Guards the runtime-native path-resolution *policy* (no dylib required).
///
/// Regression for the headless-server PTY gap: the `cc_server` binary loads
/// `libccpty` from its data dir (where a dev / remote deploy drops it beside
/// `control_center.db`), so `nativeLibraryCandidates` MUST emit that data-dir
/// path. `cc_server_runtime` wires `Pty.libraryResolver` to exactly this call;
/// if the data-dir entry ever disappears from the candidate list, `terminal.spawn`
/// silently regresses to `PtyUnavailable` again.
void main() {
  group('nativeLibraryCandidates', () {
    test('includes the app-support (data) dir entry for libccpty', () {
      const dataDir = '/srv/cc_server/data';
      final candidates = nativeLibraryCandidates(
        ptyLibraryBaseName,
        appSupportRoot: dataDir,
        envVar: ptyLibraryEnvVar,
      );

      final expected = p.join(dataDir, platformLibraryFileName(ptyLibraryBaseName));
      expect(
        candidates,
        contains(expected),
        reason: 'the PTY loader must search <dataDir>/${platformLibraryFileName(ptyLibraryBaseName)}',
      );
    });

    test('orders the env override before the data-dir entry', () {
      const dataDir = '/srv/cc_server/data';
      final candidates = nativeLibraryCandidates(
        ptyLibraryBaseName,
        appSupportRoot: dataDir,
        envVar: ptyLibraryEnvVar,
      );

      final dataDirEntry =
          p.join(dataDir, platformLibraryFileName(ptyLibraryBaseName));
      final dataDirIndex = candidates.indexOf(dataDirEntry);
      expect(dataDirIndex, greaterThanOrEqualTo(0));

      // The explicit env override (when set) must win over the data dir, which
      // must in turn precede the bare/bundled fallbacks.
      final bareName = platformLibraryFileName(ptyLibraryBaseName);
      final bareIndex = candidates.lastIndexOf(bareName);
      if (bareIndex >= 0) {
        expect(
          dataDirIndex,
          lessThan(bareIndex),
          reason: 'the data-dir entry must precede the bare/bundled fallback',
        );
      }
    });

    test('adds the data-dir entry only when a root is supplied', () {
      const dataDir = '/srv/cc_server/data';
      final expected =
          p.join(dataDir, platformLibraryFileName(ptyLibraryBaseName));

      final without = nativeLibraryCandidates(ptyLibraryBaseName);
      final with_ =
          nativeLibraryCandidates(ptyLibraryBaseName, appSupportRoot: dataDir);

      expect(
        without,
        isNot(contains(expected)),
        reason: 'no app-support root → no data-dir candidate',
      );
      expect(with_, contains(expected));
    });
  });
}
