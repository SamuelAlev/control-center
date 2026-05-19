@TestOn('vm')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:cc_natives/src/inference/cc_inference_bindings.dart';
import 'package:cc_natives/src/inference/inference_library.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Contract tests for the `cc_inference` loader and bindings.
///
/// Two properties matter enough to pin:
///
///  * resolution is a FILE STAT and returns an ABSOLUTE path. It must not open
///    the library (probing by open is what hung every JIT host at boot with the
///    old sherpa dylib), and a relative path would be rejected outright by the
///    hardened `dart build cli` server binary.
///  * binding refuses on an ABI mismatch or a missing symbol, rather than
///    misreading native memory.
void main() {
  group('resolveInferenceLibraryPath', () {
    test('returns null when nothing holds the library', () {
      final empty = Directory.systemTemp.createTempSync('cc-inference-none');
      addTearDown(() => empty.deleteSync(recursive: true));
      // No env override is set in the test environment, and an empty dir has no
      // dylib — the bundle-relative candidates below it will not resolve either.
      final resolved = resolveInferenceLibraryPath(appSupportRoot: empty.path);
      if (resolved != null) {
        // A developer machine may have the library installed on a
        // bundle-relative path; that is a resolution, not a failure.
        expect(File(resolved).existsSync(), isTrue);
      }
    });

    test('finds the library in an app-support root, absolutely', () {
      final dir = Directory.systemTemp.createTempSync('cc-inference-stub');
      addTearDown(() => dir.deleteSync(recursive: true));
      final name = platformInferenceLibraryFileName();
      File(p.join(dir.path, name)).writeAsBytesSync(const [0, 1, 2, 3]);

      // Deliberately a RELATIVE app-support root: the resolver must still hand
      // back an absolute path, because a hardened binary rejects `dlopen` of a
      // relative path and the failure would otherwise appear only at runtime.
      final relative = p.relative(dir.path, from: Directory.current.path);
      final resolved = resolveInferenceLibraryPath(appSupportRoot: relative);

      expect(resolved, isNotNull);
      expect(p.isAbsolute(resolved!), isTrue);
      expect(p.basename(resolved), name);
    });

    test('does not open the file it resolves', () {
      // The stub above is four bytes of garbage — not a loadable dylib. If the
      // resolver opened its candidates this would throw or return null.
      final dir = Directory.systemTemp.createTempSync('cc-inference-garbage');
      addTearDown(() => dir.deleteSync(recursive: true));
      File(
        p.join(dir.path, platformInferenceLibraryFileName()),
      ).writeAsBytesSync(const [0, 1, 2, 3]);

      expect(
        resolveInferenceLibraryPath(appSupportRoot: dir.path),
        isNotNull,
        reason:
            'resolution must be a stat, not a load — probing by open is what '
            'froze JIT hosts at boot',
      );
    });
  });

  group('the C ABI and the Dart bindings agree', () {
    // `cc_inference.h` is the contract. Dart binds it by NAME at load time, so a
    // function added natively but not bound here is simply unreachable, and a
    // name bound here but absent natively makes `tryFrom` return null — i.e. a
    // "broken install" that is really a typo. Both are silent until runtime,
    // which is why this is checked mechanically.
    // Paths are package-root relative, matching how this package's other
    // file-reading tests (e.g. the embedding goldens) resolve.
    final header = File('native/inference/cc_inference.h');

    test('every declared entry point is bound', () {
      if (!header.existsSync()) {
        markTestSkipped('cc_inference.h not found from ${Directory.current}');
        return;
      }
      final source = header.readAsStringSync();
      final declared = RegExp(r'\b(cc_[a-z_]+)\s*\(')
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();
      final bound = RegExp("'(cc_[a-z_]+)'")
          .allMatches(
            File(
              'lib/src/inference/cc_inference_bindings.dart',
            ).readAsStringSync(),
          )
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        declared.difference(bound),
        isEmpty,
        reason:
            'cc_inference.h declares entry points the Dart bindings never look '
            'up — they are unreachable from Dart',
      );
      // The reverse direction, minus the library base name, which is a constant
      // in the bindings file rather than a symbol.
      expect(
        bound.difference(declared).difference({inferenceLibraryBaseName}),
        isEmpty,
        reason:
            'the Dart bindings look up symbols the header does not declare — '
            'tryFrom will return null and read as a broken install',
      );
      expect(declared, hasLength(greaterThan(20)));
    });

    test('the ABI version matches the header', () {
      if (!header.existsSync()) {
        markTestSkipped('cc_inference.h not found');
        return;
      }
      final match = RegExp(
        r'#define CC_INFERENCE_ABI_VERSION (\d+)u',
      ).firstMatch(header.readAsStringSync());
      expect(match, isNotNull, reason: 'the header lost its ABI version define');
      expect(int.parse(match!.group(1)!), ccInferenceAbiVersion);
    });
  });

  group('CcInferenceBindings.tryFrom', () {
    test('refuses a library that does not export the ABI', () {
      // A real, loadable library that is definitely not ours. Deliberately NOT
      // `DynamicLibrary.executable()`: `dart test` runs suites as isolates in
      // ONE process, so a sibling suite that loaded cc_inference makes its
      // symbols visible there and the assertion silently inverts.
      final system = Platform.isMacOS
          ? '/usr/lib/libSystem.B.dylib'
          : Platform.isLinux
          ? 'libc.so.6'
          : null;
      if (system == null) {
        markTestSkipped('no known symbol-free system library for this platform');
        return;
      }
      final DynamicLibrary lib;
      try {
        lib = DynamicLibrary.open(system);
      } on Object {
        markTestSkipped('could not open $system');
        return;
      }
      expect(CcInferenceBindings.tryFrom(lib), isNull);
    });

    test('binds the real library when it is staged', () {
      final path = resolveInferenceLibraryPath();
      if (path == null) {
        markTestSkipped(
          'cc_inference not staged — run scripts/natives/build_inference.sh',
        );
        return;
      }
      final bindings = ensureInferenceBindings(explicitPath: path);
      expect(
        bindings,
        isNotNull,
        reason:
            'the staged library did not bind: either its ABI version moved '
            'without ccInferenceAbiVersion following, or a symbol is missing',
      );
      // A NULL-safe destroy is the cheapest possible proof we reached real code.
      bindings!.embedderDestroy(nullptr);
    });
  });
}

/// The platform file name for the inference library, without depending on the
/// package's internal path helpers being exported.
String platformInferenceLibraryFileName() {
  if (Platform.isWindows) {
    return '$inferenceLibraryBaseName.dll';
  }
  if (Platform.isMacOS) {
    return 'lib$inferenceLibraryBaseName.dylib';
  }
  return 'lib$inferenceLibraryBaseName.so';
}
