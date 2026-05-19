import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

void main() {
  group('nativeLibraryCandidates', () {
    test('orders env override → app-support → bundled', () {
      final candidates = nativeLibraryCandidates(
        'rift_ffi',
        appSupportRoot: '/data/app',
        // An almost-certainly-unset var: no override entry is produced.
        envVar: 'CC_NATIVES_TEST_UNSET_ENV',
      );

      final fileName = platformLibraryFileName('rift_ffi');
      // App-support install is tried first (no env override present)...
      expect(candidates.first, '/data/app/$fileName');
      // ...then the bundle-relative defaults, in order, at the end.
      expect(
        candidates,
        containsAllInOrder(bundledLibraryCandidates('rift_ffi')),
      );
      // No repo-local macos/Frameworks or build/ dev candidate any more.
      expect(
        candidates.any((c) => c.contains('macos/Frameworks')),
        isFalse,
      );
    });
  });

  group('bundledLibraryCandidates', () {
    test('follows the platform packaging convention', () {
      final candidates = bundledLibraryCandidates('tree-sitter');
      if (Platform.isMacOS) {
        expect(candidates, <String>[
          '@executable_path/../Frameworks/libtree-sitter.dylib',
          '@executable_path/../Resources/libtree-sitter.dylib',
          'libtree-sitter.dylib',
        ]);
      } else if (Platform.isLinux) {
        // dlopen-by-soname ignores the exe's RUNPATH, so the bundled
        // <exeDir>/lib path is tried before the bare soname.
        expect(candidates.first, endsWith('/lib/libtree-sitter.so'));
        expect(candidates, containsAllInOrder(<String>['libtree-sitter.so']));
        expect(candidates.last, 'libtree-sitter.so.0');
      } else if (Platform.isWindows) {
        expect(candidates, <String>['tree-sitter.dll', 'libtree-sitter.dll']);
      }
    });

    test('decorates per-language grammar base names', () {
      final candidates = bundledLibraryCandidates('tree-sitter-dart');
      final expectedName = platformLibraryFileName('tree-sitter-dart');
      expect(candidates, contains(expectedName));
    });
  });
}
