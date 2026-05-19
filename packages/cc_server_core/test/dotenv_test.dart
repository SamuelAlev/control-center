import 'dart:io';

import 'package:cc_server_core/src/dotenv.dart';
import 'package:test/test.dart';

/// The `.env` reader, which lives HERE because the server is the process that
/// needs the values — and which FINDS the file itself, because a client that
/// had to point it at one would be a client that knows what a `.env` is.
///
/// It used to live in the desktop app, which parsed the file and copied it
/// into the environment of the server it spawned: the file then worked for
/// exactly one deployment and did nothing for a packaged binary, a systemd
/// unit or docker.
void main() {
  late Directory dir;

  /// A directory with no `.env`, pinned as the working directory so that
  /// running this suite from a checkout that HAS one cannot change an answer.
  late Directory empty;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cc_dotenv_');
    empty = Directory.systemTemp.createTempSync('cc_dotenv_empty_');
  });
  tearDown(() {
    dir.deleteSync(recursive: true);
    empty.deleteSync(recursive: true);
  });

  void write(String contents) =>
      File('${dir.path}/.env').writeAsStringSync(contents);

  test('reads a plain value', () {
    write('GITHUB_APP_ID=123456\n');
    expect(readDotenv(directory: dir)['GITHUB_APP_ID'], '123456');
  });

  test('an escaped \\n in a quoted value decodes to a newline', () {
    // A PEM is the one value here that is not a flat token; it rides on one
    // line and a key that decodes wrong fails far away from this file.
    write(r'GITHUB_APP_PRIVATE_KEY="-----BEGIN-----\nbody\n-----END-----"');
    expect(
      readDotenv(directory: dir)['GITHUB_APP_PRIVATE_KEY'],
      '-----BEGIN-----\nbody\n-----END-----',
    );
  });

  test('a single-quoted value is literal', () {
    write(r"GITHUB_CLIENT_ID='Iv1.abc\ndef'");
    expect(readDotenv(directory: dir)['GITHUB_CLIENT_ID'], r'Iv1.abc\ndef');
  });

  test('comments and blank lines are skipped', () {
    write('# a comment\n\n  # indented\nGITHUB_APP_ID=7\n');
    expect(readDotenv(directory: dir), {'GITHUB_APP_ID': '7'});
  });

  test('an empty value is absent, not empty', () {
    // `KEY=` in a copied template means "I did not set this" — it must not
    // shadow the credential the build ships.
    write('GITHUB_APP_ID=\nGITHUB_CLIENT_ID=abc\n');
    final parsed = readDotenv(directory: dir);
    expect(parsed.containsKey('GITHUB_APP_ID'), isFalse);
    expect(parsed['GITHUB_CLIENT_ID'], 'abc');
  });

  test('no file at all is not an error', () {
    expect(readDotenv(directory: dir), isEmpty);
  });

  group('locating the file', () {
    test('finds one beside the executable', () {
      // Somebody unpacked the server archive and dropped a `.env` next to the
      // binary. Deliberate placement, taken at face value.
      write('GITHUB_CLIENT_ID=beside\n');
      final fakeExe = '${dir.path}/cc_server';
      File(fakeExe).writeAsStringSync('');
      expect(
        locateDotenvDirectory(executable: fakeExe, workingDirectory: empty)?.path,
        dir.path,
      );
    });

    test('walks up to a source checkout', () {
      // The dev layout: the binary lives under
      // <repo>/apps/cc_server/build/cli/<arch>/bundle/bin/.
      final repo = Directory('${dir.path}/repo')..createSync();
      File('${repo.path}/pubspec.yaml').writeAsStringSync('name: x');
      File('${repo.path}/.env').writeAsStringSync('GITHUB_CLIENT_ID=repo\n');
      final binDir = Directory(
        '${repo.path}/apps/cc_server/build/cli/macos_arm64/bundle/bin',
      )..createSync(recursive: true);
      final exe = '${binDir.path}/cc_server';
      File(exe).writeAsStringSync('');

      expect(locateDotenvDirectory(executable: exe, workingDirectory: empty)?.path, repo.path);
    });

    test('will not adopt a stray file with no checkout marker', () {
      // A packaged app under /Applications must never pick up somebody's
      // unrelated `.env` on the way to the filesystem root.
      final loose = Directory('${dir.path}/loose')..createSync();
      File('${loose.path}/.env').writeAsStringSync('GITHUB_CLIENT_ID=nope\n');
      final binDir = Directory('${loose.path}/App/Contents/bin')
        ..createSync(recursive: true);
      final exe = '${binDir.path}/cc_server';
      File(exe).writeAsStringSync('');

      expect(locateDotenvDirectory(executable: exe, workingDirectory: empty), isNull);
    });
  });

  group('layering', () {
    test('a real environment variable beats the file', () {
      // `docker run -e` and a systemd `Environment=` are deliberate; a file
      // sitting in the working directory is ambient.
      write('GITHUB_APP_ID=from-file\n');
      final fakeExe = '${dir.path}/cc_server';
      File(fakeExe).writeAsStringSync('');
      final env = environmentWithDotenv(
        workingDirectory: empty,
        executable: fakeExe,
        processEnvironment: const {'GITHUB_APP_ID': 'from-env'},
      );
      expect(env['GITHUB_APP_ID'], 'from-env');
    });

    test('the file fills in what the environment does not set', () {
      write('GITHUB_CLIENT_ID=from-file\n');
      final fakeExe = '${dir.path}/cc_server';
      File(fakeExe).writeAsStringSync('');
      final env = environmentWithDotenv(
        workingDirectory: empty,
        executable: fakeExe,
        processEnvironment: const {'OTHER': 'x'},
      );
      expect(env['GITHUB_CLIENT_ID'], 'from-file');
      expect(env['OTHER'], 'x');
    });
  });
}
