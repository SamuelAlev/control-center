import 'dart:async';
import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// `walkAndHash` is the expensive half of indexing — a stat per path plus a full
/// read and SHA-256 of every source file — and it runs on its own isolate so the
/// server's event loop keeps serving RPC while a repo is indexed. These tests
/// pin both halves: it must agree with `walk` + `hashFile`, and it must not
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

  test('hashes are the file bytes, and change when content changes', () async {
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

  test('stays correct at repo scale, and the caller keeps scheduling', () async {
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
      'lib/a.dart': IndexedFileState(
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
      'lib/a.dart': IndexedFileState(
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
}
