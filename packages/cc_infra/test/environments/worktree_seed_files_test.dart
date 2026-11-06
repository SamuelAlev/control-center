import 'dart:io';

import 'package:cc_infra/src/environments/worktree_seed_files.dart';
import 'package:test/test.dart';

import 'helpers/environment_fakes.dart';

void main() {
  late Directory root;
  late String source;
  late String worktree;
  late Directory outside;

  setUp(() {
    root = tempDir(addTearDown);
    source = '${root.path}/source';
    worktree = '${root.path}/worktree';
    outside = Directory('${root.path}/outside')..createSync();
    Directory(source).createSync();
    Directory(worktree).createSync();
    File('${outside.path}/secret').writeAsStringSync('secret');
  });

  void write(String path, String text) {
    File('$source/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(text);
  }

  Future<WorktreeSeedResult> copy(
    List<String> files, {
    bool isForkPr = false,
    WorktreeFileCopier? copier,
  }) => WorktreeSeedFiles(copier: copier ?? copyWorktreeFile).copy(
    sourceRoot: source,
    worktreeRoot: worktree,
    seedFiles: files,
    isForkPr: isForkPr,
  );

  test('copies named files, creating their directories', () async {
    write('.env.local', 'KEY=1');
    write('docker/local/seed.sh', 'echo seed');
    final result = await copy(['.env.local', 'docker/local/seed.sh']);
    expect(result.copied, ['.env.local', 'docker/local/seed.sh']);
    expect(File('$worktree/.env.local').readAsStringSync(), 'KEY=1');
    expect(
      File('$worktree/docker/local/seed.sh').readAsStringSync(),
      'echo seed',
    );
  });

  test('keeps a secret file\'s mode', () async {
    write('.env.local', 'KEY=1');
    await Process.run('chmod', ['600', '$source/.env.local']);
    await copy(['.env.local']);
    expect(File('$worktree/.env.local').statSync().modeString(), 'rw-------');
  });

  test('copies a directory file by file', () async {
    write('certs/a.pem', 'a');
    write('certs/deep/b.pem', 'b');
    final result = await copy(['certs']);
    expect(result.copied, unorderedEquals(['certs/a.pem', 'certs/deep/b.pem']));
  });

  test('reports a file the source lacks and carries on', () async {
    write('present', 'x');
    final result = await copy(['absent', 'present']);
    expect(result.missing, ['absent']);
    expect(result.copied, ['present']);
  });

  test('never overwrites the worktree', () async {
    write('.env.local', 'new');
    File('$worktree/.env.local').writeAsStringSync('edited');
    final result = await copy(['.env.local']);
    expect(result.kept, ['.env.local']);
    expect(File('$worktree/.env.local').readAsStringSync(), 'edited');
  });

  test('a fork PR gets nothing', () async {
    write('.env.local', 'KEY=1');
    final result = await copy(['.env.local'], isForkPr: true);
    expect(result.skippedForFork, isTrue);
    expect(File('$worktree/.env.local').existsSync(), isFalse);
  });

  group('refuses', () {
    Matcher refused(String text) => throwsA(
      isA<WorktreeSeedException>().having(
        (e) => e.message,
        'message',
        contains(text),
      ),
    );

    test('absolute and climbing paths', () async {
      await expectLater(copy(['/etc/passwd']), refused('relative'));
      await expectLater(copy(['../outside/secret']), refused('relative'));
    });

    test('a link in the source pointing outside', () async {
      Link('$source/.env.local').createSync('${outside.path}/secret');
      await expectLater(copy(['.env.local']), refused('outside the source'));
      expect(File('$worktree/.env.local').existsSync(), isFalse);
    });

    test('a linked directory in the source pointing outside', () async {
      Link('$source/config').createSync(outside.path);
      await expectLater(copy(['config/secret']), refused('outside the source'));
    });

    test('a link inside a seeded directory pointing outside', () async {
      write('certs/a.pem', 'a');
      Link('$source/certs/leak').createSync('${outside.path}/secret');
      await expectLater(copy(['certs']), refused('outside the source'));
      expect(File('$worktree/certs/a.pem').existsSync(), isFalse);
    });

    test('a link planted in the worktree', () async {
      write('config/app.env', 'KEY=1');
      Link('$worktree/config').createSync(outside.path);
      await expectLater(
        copy(['config/app.env']),
        refused('outside the worktree'),
      );
      expect(File('${outside.path}/app.env').existsSync(), isFalse);
    });

    test('a broken link', () async {
      Link('$source/dangling').createSync('$source/nowhere');
      final result = await copy(['dangling']);
      expect(result.missing, ['dangling']);
    });
  });

  test('a link that stays inside the source is fine', () async {
    write('real.env', 'KEY=1');
    Link('$source/.env.local').createSync('$source/real.env');
    await copy(['.env.local']);
    expect(File('$worktree/.env.local').readAsStringSync(), 'KEY=1');
  });

  test('falls back to a plain copy when CoW can\'t work', () async {
    write('a', 'x');
    // Not a CoW volume necessarily: whichever path runs, the bytes arrive.
    await copyWorktreeFile('$source/a', '$worktree/a');
    expect(File('$worktree/a').readAsStringSync(), 'x');
  });
}
