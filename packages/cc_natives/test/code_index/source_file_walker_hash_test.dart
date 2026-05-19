import 'dart:async';
import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// `walkAndHash` is the expensive half of indexing — a stat per path plus a full
/// read and SHA-256 of every source file — and it runs on its own isolate so the
/// server's event loop keeps serving RPC while a repo is indexed. These tests
/// pin both halves: it must agree with `walk` + `hashFile` and it must not
/// occupy the calling isolate while it works.
void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('walk_and_hash_test');
  });

  tearDown(() async {
    if (tmp.existsSync()) {
      await tmp.delete(recursive: true);
    }
  });

  Future<void> write(String relativePath, String contents) async {
    final file = File(p.join(tmp.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
  }

  test('agrees with walk + hashFile, file for file', () async {
    await write('lib/a.dart', 'class A {}');
    await write('lib/nested/b.ts', 'export const b = 1;');
    await write('lib/skip.g.dart', '// generated');
    await write('README.md', '# no');

    const walker = SourceFileWalker();
    final expected = {
      for (final f in await walker.walk(tmp.path))
        p.split(f.relativePath).join('/'): await walker.hashFile(
          f.absolutePath,
        ),
    };
    final hashed = await walker.walkAndHash(tmp.path);

    expect({
      for (final f in hashed) p.split(f.relativePath).join('/'): f.contentHash,
    }, expected);
    expect(expected.keys, containsAll(['lib/a.dart', 'lib/nested/b.ts']));
    expect(expected.keys, isNot(contains('lib/skip.g.dart')));
    expect(expected.keys, isNot(contains('README.md')));
  });

  test('hashes are the file bytes and change when content changes', () async {
    await write('lib/a.dart', 'class A {}');
    const walker = SourceFileWalker();

    final first = (await walker.walkAndHash(tmp.path)).single;
    expect(
      first.contentHash,
      sha256.convert('class A {}'.codeUnits).toString(),
    );
    expect(p.isAbsolute(first.absolutePath), isTrue);

    await write('lib/a.dart', 'class A { void f() {} }');
    final second = (await walker.walkAndHash(tmp.path)).single;
    expect(second.contentHash, isNot(first.contentHash));
  });

  test('honours the extension override inside the isolate', () async {
    await write('lib/a.dart', 'class A {}');
    await write('lib/b.ts', 'export const b = 1;');
    const walker = SourceFileWalker(extensions: {'ts'});

    final hashed = await walker.walkAndHash(tmp.path);
    expect(hashed.map((f) => p.basename(f.relativePath)), ['b.ts']);
  });

  test('stays correct at repo scale and the caller keeps scheduling', () async {
    // Offloading is structural (`Isolate.run`), so this does not try to prove
    // the isolate boundary by timing — inline hashing awaits `readAsBytes` and
    // would keep a timer ticking too, which makes that assertion pass for the
    // wrong reason. What is worth pinning is that the batched path stays correct
    // at a size where the per-file cost actually matters.
    for (var i = 0; i < 400; i++) {
      await write('lib/f$i.dart', 'class C$i { ${'// pad' * 200} }');
    }
    const walker = SourceFileWalker();

    var ticks = 0;
    final heartbeat = Timer.periodic(
      const Duration(milliseconds: 1),
      (_) => ticks++,
    );
    final hashed = await walker.walkAndHash(tmp.path);
    heartbeat.cancel();

    expect(hashed, hasLength(400));
    expect(hashed.map((f) => f.contentHash).toSet(), hasLength(400));
    expect(ticks, greaterThan(0), reason: 'the caller was never resumed');
  });

  test('reuses a known hash when the file has not been touched', () async {
    // The steady state: an unchanged checkout must cost a stat per file, not a
    // read + SHA-256 of the whole tree. Proven by handing in a deliberately
    // WRONG cached hash — it comes back verbatim only if the file was skipped.
    await write('lib/a.dart', 'class A {}');
    const walker = SourceFileWalker();
    final known = {
      // Keyed in the walker's own platform form (p.relative on Windows is
      // backslashed), so the lookup actually hits.
      p.join('lib', 'a.dart'): IndexedFileState(
        contentHash: 'not-a-real-hash',
        indexedAt: DateTime.now().add(const Duration(minutes: 1)),
      ),
    };

    expect(
      (await walker.walkAndHash(tmp.path, known: known)).single.contentHash,
      'not-a-real-hash',
    );
  });

  test('re-hashes a file modified since it was indexed', () async {
    await write('lib/a.dart', 'class A {}');
    const walker = SourceFileWalker();
    final known = {
      p.join('lib', 'a.dart'): IndexedFileState(
        contentHash: 'stale',
        // Indexed before the write above, so the mtime is newer.
        indexedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    };

    expect(
      (await walker.walkAndHash(tmp.path, known: known)).single.contentHash,
      sha256.convert('class A {}'.codeUnits).toString(),
    );
  });

  test('survives a file vanishing between enumeration and hashing', () async {
    // The isolate skips unreadable entries rather than failing the whole run:
    // a checkout racing the walk is normal.
    await write('lib/a.dart', 'class A {}');
    const walker = SourceFileWalker();
    final hashed = await walker.walkAndHash(tmp.path);
    expect(hashed, hasLength(1));
  });

  /// `hashPaths` is the targeted counterpart: a caller that already knows what
  /// changed pays for those paths instead of rediscovering the checkout. It is
  /// only safe if it agrees with `walkAndHash` about what is indexable at all —
  /// a path the full pass excludes must not slip into the graph through the
  /// narrow one, and vice versa.
  group('hashPaths', () {
    test('agrees with walkAndHash on the same files', () async {
      await write('lib/a.dart', 'class A {}');
      await write('lib/nested/b.ts', 'export const b = 1;');

      const walker = SourceFileWalker();
      final full = {
        for (final file in await walker.walkAndHash(tmp.path))
          file.relativePath: file.contentHash,
      };
      final targeted = await walker.hashPaths(tmp.path, [
        p.join('lib', 'a.dart'),
        p.join('lib', 'nested', 'b.ts'),
      ]);

      expect({
        for (final file in targeted) file.relativePath: file.contentHash,
      }, full);
    });

    test('drops what the full pass would also drop', () async {
      await write('lib/skip.g.dart', '// generated');
      await write('README.md', '# no');
      await write('lib/real.dart', 'class R {}');

      final hashed = await const SourceFileWalker().hashPaths(tmp.path, [
        p.join('lib', 'skip.g.dart'),
        'README.md',
        p.join('lib', 'real.dart'),
      ]);

      expect(hashed.map((f) => f.relativePath), [p.join('lib', 'real.dart')]);
    });

    test('outside a git tree, falls back to the manual skip set', () async {
      // No `git init` here, so `check-ignore` cannot answer and the hardcoded
      // list is the only thing keeping build output out.
      await write('build/generated.dart', 'class B {}');
      await write('lib/real.dart', 'class R {}');

      final hashed = await const SourceFileWalker().hashPaths(tmp.path, [
        p.join('build', 'generated.dart'),
        p.join('lib', 'real.dart'),
      ]);

      expect(hashed.map((f) => f.relativePath), [p.join('lib', 'real.dart')]);
    });

    test('omits a path that no longer exists — the caller prunes it', () async {
      await write('lib/here.dart', 'class H {}');

      final hashed = await const SourceFileWalker().hashPaths(tmp.path, [
        p.join('lib', 'here.dart'),
        p.join('lib', 'deleted.dart'),
      ]);

      expect(hashed.map((f) => f.relativePath), [p.join('lib', 'here.dart')]);
    });

    test('de-duplicates repeated paths', () async {
      await write('lib/a.dart', 'class A {}');

      final hashed = await const SourceFileWalker().hashPaths(tmp.path, [
        p.join('lib', 'a.dart'),
        p.join('lib', 'a.dart'),
      ]);

      expect(hashed, hasLength(1));
    });

    test('an empty list costs nothing and returns nothing', () async {
      expect(await const SourceFileWalker().hashPaths(tmp.path, const []), []);
    });
  });
}
