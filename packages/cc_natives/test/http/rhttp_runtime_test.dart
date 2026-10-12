@TestOn('vm')
library;

import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Guards the rhttp native's *path policy* (no dylib required).
///
/// The headless server loads `librhttp` from a directory it is told about —
/// its own data dir (what `build_natives.sh` installs beside
/// `control_center.db`), the bundled `lib/` of its `dart build cli` bundle, or
/// `CC_NATIVE_LIB_DIR` when the desktop spawns it — and `initializeRhttp()`
/// opens exactly this path. If the data-dir entry ever disappears from the
/// candidate list the server stops starting, because a missing native here is a
/// broken install with no fallback transport.
void main() {
  final fileName = platformLibraryFileName(rhttpLibraryBaseName);

  test('the base name is the dylib the natives build stages', () {
    // scripts/natives/build_rhttp.sh copies cargo's `librhttp.<ext>` straight
    // into the staging dir, and scripts/lib/natives.sh requires that name.
    expect(rhttpLibraryBaseName, 'rhttp');
    expect(fileName, anyOf('librhttp.dylib', 'librhttp.so', 'rhttp.dll'));
  });

  test('includes the data-dir entry, which is how cc_server finds it', () {
    const dataDir = '/srv/cc_server/data';
    expect(
      rhttpLibraryCandidates(appSupportRoot: dataDir),
      contains(p.join(dataDir, fileName)),
    );
  });

  test('orders the explicit path, the shared lib dir and the data dir first', () {
    // CC_NATIVE_LIB_DIR is a DIRECTORY (the desktop passes the bundle's native
    // dir when it spawns a local server) while RHTTP_DYLIB names a FILE — the
    // two must not be confused, and both must precede the app-support copy.
    const explicit = '/opt/cc/librhttp.dylib';
    const dataDir = '/srv/cc_server/data';
    final candidates = rhttpLibraryCandidates(
      explicitPath: explicit,
      appSupportRoot: dataDir,
    ).toList();

    expect(candidates.first, explicit);
    expect(
      candidates.indexOf(p.join(dataDir, fileName)),
      lessThan(candidates.length - 1),
      reason: 'the bundle candidates stay last',
    );
    expect(
      candidates.any((c) => c.endsWith(p.join('lib', fileName))),
      isTrue,
      reason: 'the dart build cli bundle lib/ dir must stay searchable',
    );
  });

  test('resolves an existing staged native to an absolute path', () {
    final dir = Directory.systemTemp.createTempSync('cc-rhttp');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File(p.join(dir.path, fileName))..writeAsBytesSync(const [1, 2, 3]);

    expect(
      resolveRhttpLibraryPath(appSupportRoot: dir.path),
      file.absolute.path,
      reason: 'a hardened program rejects dlopen of a relative path',
    );
  });

  test('a missing native resolves to null, never to another transport', () {
    final dir = Directory.systemTemp.createTempSync('cc-rhttp-empty');
    addTearDown(() => dir.deleteSync(recursive: true));

    expect(resolveRhttpLibraryPath(appSupportRoot: dir.path), isNull);
  }, skip: _envOverridesPointAtANative());

  test('a missing native is fatal, not a transport fallback', () {
    // The seam is deliberately a null from the resolver and a throw from
    // initializeRhttp(): there is no alternative transport to select.
    expect(
      rhttpLibraryUnavailableMessage(searchedPath: '/nonexistent'),
      contains('no fallback transport'),
    );
  });
}

/// True when the environment itself supplies a native, which would make the
/// "nothing is installed" cases resolve for reasons the test did not set up
/// (a developer with CC_NATIVE_LIB_DIR exported, or RHTTP_DYLIB pinned).
Object _envOverridesPointAtANative() {
  for (final name in [rhttpLibraryEnvVar, nativeLibDirEnvVar]) {
    final value = Platform.environment[name];
    if (value != null && value.isNotEmpty) {
      return 'the $name override is set in this environment';
    }
  }
  return false;
}
