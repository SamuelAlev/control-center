import 'package:control_center/core/infrastructure/code_index/tree_sitter_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TreeSitterLoader.linuxCandidates', () {
    test('tries the bundled <exeDir>/lib path before the bare soname', () {
      final candidates = TreeSitterLoader.linuxCandidates(
        'libtree-sitter.so',
        '/opt/control_center',
      );

      expect(candidates.first, '/opt/control_center/lib/libtree-sitter.so');
      expect(candidates, containsAllInOrder(<String>[
        '/opt/control_center/lib/libtree-sitter.so',
        'libtree-sitter.so',
      ]));
      // The versioned soname remains a fallback for system installs.
      expect(candidates, contains('libtree-sitter.so.0'));
    });

    test('resolves a bundled path for per-language grammar libs', () {
      final candidates = TreeSitterLoader.linuxCandidates(
        'libtree-sitter-dart.so',
        '/usr/bin',
      );

      expect(candidates.first, '/usr/bin/lib/libtree-sitter-dart.so');
    });
  });
}
