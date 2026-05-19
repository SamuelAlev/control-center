import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

/// `affectsIndex` gates the code-graph file watcher. It must agree with what
/// [SourceFileWalker.walk] enumerates: too loose and every build write costs a
/// full walk plus a hash of every source file; too tight and edits to real
/// tracked source never reindex.
void main() {
  test('indexable source triggers', () {
    expect(SourceFileWalker.affectsIndex('lib/src/foo.dart'), isTrue);
    expect(SourceFileWalker.affectsIndex('/abs/repo/lib/foo.ts'), isTrue);
    expect(SourceFileWalker.affectsIndex(r'lib\src\foo.dart'), isTrue);
  });

  test('build output and tool caches do not', () {
    expect(
      SourceFileWalker.affectsIndex('.dart_tool/package_config.json'),
      isFalse,
    );
    expect(SourceFileWalker.affectsIndex('build/out/app.dart'), isFalse);
    expect(SourceFileWalker.affectsIndex('node_modules/pkg/index.js'), isFalse);
    expect(SourceFileWalker.affectsIndex('.git/refs/heads/main'), isFalse);
  });

  test('generated and non-source files do not', () {
    expect(SourceFileWalker.affectsIndex('lib/model.g.dart'), isFalse);
    expect(SourceFileWalker.affectsIndex('lib/model.freezed.dart'), isFalse);
    expect(SourceFileWalker.affectsIndex('README.md'), isFalse);
    expect(SourceFileWalker.affectsIndex('Makefile'), isFalse);
  });

  test('.gitignore triggers — it changes what is indexable', () {
    expect(SourceFileWalker.affectsIndex('.gitignore'), isTrue);
    expect(SourceFileWalker.affectsIndex('lib/.gitignore'), isTrue);
  });

  test('vendored and dist source still triggers', () {
    // git commits these in some ecosystems, so `walk` indexes them; the watcher
    // must not be blind to their edits.
    expect(SourceFileWalker.affectsIndex('vendor/acme/lib/Thing.php'), isTrue);
    expect(SourceFileWalker.affectsIndex('dist/bundle.js'), isTrue);
  });

  test('watchIgnoredDirs and affectsIndex never diverge', () {
    // The native cc_watcher is fed watchIgnoredDirs so no watch is installed
    // under these; affectsIndex is the Dart-side gate on delivered events.
    // If a name were in one set but not the other, the two filters would
    // disagree about what matters and events would be silently lost (or
    // churn would leak through). This guard pins them together.
    for (final dir in SourceFileWalker.watchIgnoredDirs) {
      expect(
        SourceFileWalker.affectsIndex('$dir/x.dart'),
        isFalse,
        reason: '$dir is native-ignored, so affectsIndex must ignore it too',
      );
    }
  });
}
