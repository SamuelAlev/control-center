import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/cc_paths.dart' show PrivateDirectoryException;
import 'package:cc_server_core/cc_server_core.dart'
    show
        bindFailureLines,
        bootFailureLine,
        commandFailureLine,
        refusedExitCode,
        runCcServer,
        runConnectCommand,
        runOrRefuse,
        runPairCommand,
        runUpdateCommand,
        shutdownFailureLine;
import 'package:cc_server_core/src/cc_server_config.dart'
    show CcServerConfig, CodeModeFlagInvalid;
import 'package:cc_server_core/src/connect/connect_settings.dart'
    show ConnectEnvironmentInvalid;
import 'package:cc_server_core/src/identity/server_identity_store.dart'
    show ServerIdentityUnreadable;
import 'package:cc_server_core/src/server_boot_refusal.dart'
    show
        DataDirNotPrivate,
        DataDirUnusable,
        GlobalDatabaseDamaged,
        GlobalDatabaseForeign,
        GlobalDatabaseNewer,
        NativeLibrariesMissing,
        ServerBootRefusal,
        bootingLine,
        printableText,
        readyLine,
        terminalText;
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';

/// Every command of `cc_server` ends a refusal the same way: one line on
/// stderr, exit 78, no stack and nothing created in the data directory.
/// `pair` let a missing native escape as an unhandled exception (exit 255
/// and a stack) before this.
void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('cc_cmd_refusal'));
  tearDown(() => deleteDirBestEffort(tmp));

  Future<void> missingNative(String dataDir) async =>
      throw NativeLibrariesMissing(const ['libx'], searched: [dataDir]);

  /// One line on stderr, no stack, and the data directory still empty.
  void expectRefused(int code, String err) {
    expect(code, refusedExitCode);
    expect(err.trim(), isNot(contains('\n')), reason: err);
    expect(err, startsWith('cc_server: '));
    expect(err, isNot(contains('#0')));
    expect(tmp.listSync(), isEmpty);
  }

  Future<(int, String)> run(
    Future<int> Function(IOSink out, IOSink err) command,
  ) async {
    final out = _Lines();
    final err = _Lines();
    final outSink = IOSink(out);
    final errSink = IOSink(err);
    final code = await command(outSink, errSink);
    await outSink.close();
    await errSink.close();
    return (code, err.text);
  }

  group('pair', () {
    test('a missing native ends it with 78 and one line', () async {
      final (code, err) = await run(
        (out, err) => runPairCommand(
          args: ['--data-dir', tmp.path],
          out: out,
          err: err,
          checkNatives: missingNative,
        ),
      );
      expectRefused(code, err);
      expect(err, contains('libx'));
    });

    test('a refused setting ends it with 78 and one line', () async {
      final (code, err) = await run(
        (out, err) => runPairCommand(
          args: ['--data-dir', tmp.path, '--code-mode-max-processes', '0'],
          out: out,
          err: err,
          checkNatives: (_) async {},
        ),
      );
      expectRefused(code, err);
      expect(err, contains('--code-mode-max-processes is "0"'));
    });
  });

  test('update: a refused setting ends it with 78 and one line', () async {
    final (code, err) = await run(
      (out, err) => runUpdateCommand(
        args: ['--data-dir', tmp.path, '--code-mode-max-heap-mb', 'big'],
        out: out,
        err: err,
      ),
    );
    expectRefused(code, err);
    expect(err, contains('--code-mode-max-heap-mb is "big"'));
  });

  test('connect: a missing native ends it with 78 and one line', () async {
    final (code, err) = await run(
      (out, err) => runConnectCommand(
        args: ['status', '--data-dir', tmp.path],
        out: out,
        err: err,
        checkNatives: missingNative,
      ),
    );
    expectRefused(code, err);
  });

  group('a data directory that cannot be used (review 6, finding 6)', () {
    late File file;
    setUp(() => file = File('${tmp.path}/not-a-dir')..writeAsStringSync('x'));

    void expectUnusable(int code, String err) {
      expect(code, refusedExitCode);
      expect(err.trim(), isNot(contains('\n')), reason: err);
      expect(err, startsWith('cc_server: cannot start \u2014 the data '));
      expect(err, contains('cannot be used'));
      expect(err, isNot(contains('#0')));
      expect(file.readAsStringSync(), 'x');
    }

    test('serve: a regular file in its place ends the boot with 78', () async {
      final (code, err) = await run(
        (out, err) async =>
            await runOrRefuse(
                  () => runCcServer(
                    args: ['--data-dir', file.path, '--port', '0'],
                  ),
                  err: err,
                ) ==
                null
            ? refusedExitCode
            : 0,
      );
      expectUnusable(code, err);
    });

    test('serve: under a regular file it cannot be created', () async {
      final (code, err) = await run(
        (out, err) async =>
            await runOrRefuse(
                  () => runCcServer(
                    args: ['--data-dir', '${file.path}/data', '--port', '0'],
                  ),
                  err: err,
                ) ==
                null
            ? refusedExitCode
            : 0,
      );
      expectUnusable(code, err);
    });

    test('pair and connect: the same refusal', () async {
      final (pairCode, pairErr) = await run(
        (out, err) => runPairCommand(
          args: ['--data-dir', file.path],
          out: out,
          err: err,
          checkNatives: (_) async {},
        ),
      );
      expectUnusable(pairCode, pairErr);
      final (connectCode, connectErr) = await run(
        (out, err) => runConnectCommand(
          args: ['status', '--data-dir', file.path],
          out: out,
          err: err,
          checkNatives: (_) async {},
        ),
      );
      expectUnusable(connectCode, connectErr);
    });
  });

  group('a token across a cut is redacted before the cut (review 8)', () {
    // A token of GitHub's shape. Cut first, `ghp_` and up to 19 characters
    // of it showed when it started a few characters before the cut.
    final token = 'ghp_${'aB3dE5fG7h' * 3}J9kL1m';

    /// Neither the prefix nor any of the token's first characters shows:
    /// nothing of it is left beyond what the redaction leaves.
    void expectNoPart(String message, String why) {
      expect(message, isNot(contains('ghp')), reason: '$why: $message');
      expect(message, isNot(contains('aB3d')), reason: '$why: $message');
      expect(message, isNot(contains(token.substring(4, 8))), reason: why);
    }

    test('in a path cut at 1,024: the token at characters 1,005 to 1,020', () {
      for (final at in [1005, 1010, 1015, 1020]) {
        // `/` is character 1, the token starts at character [at].
        final path = '/${'f' * (at - 2)}$token/data';
        final refusals = <String, String>{
          'DataDirUnusable': DataDirUnusable(
            path,
            FileSystemException('x', path, const OSError('Not a dir', 20)),
          ).message,
          'DataDirNotPrivate': DataDirNotPrivate(
            PrivateDirectoryException(path, 0x1ED),
          ).message,
          'GlobalDatabaseDamaged': GlobalDatabaseDamaged(path, 'bad').message,
          'GlobalDatabaseNewer': GlobalDatabaseNewer(path, 9, 8).message,
          'GlobalDatabaseForeign': GlobalDatabaseForeign(path, 7).message,
          'ServerIdentityUnreadable': ServerIdentityUnreadable(
            path: path,
            quarantinedAt: path,
          ).message,
          'NativeLibrariesMissing': NativeLibrariesMissing(
            const ['libx'],
            searched: [path],
          ).message,
          'bootingLine': bootingLine(path),
          'readyLine': readyLine(
            host: '127.0.0.1',
            port: 1,
            dataDir: path,
            workspaces: 0,
          ),
        };
        for (final MapEntry(key: name, value: message) in refusals.entries) {
          expectNoPart(message, '$name at $at');
        }
      }
    });

    test('in a value cut at 80: the token at characters 61 to 76', () {
      for (final at in [61, 66, 71, 76]) {
        final value = '${'x' * (at - 1)}$token';
        expectNoPart(
          CodeModeFlagInvalid(
            name: '--code-mode-max-processes',
            value: value,
            accepted: 'a whole number',
          ).message,
          'value at $at',
        );
        // And as the boot refuses it.
        for (final args in [
          ['--code-mode-max-processes', value],
        ]) {
          expect(
            () => CcServerConfig.resolve(args, environment: const {}),
            throwsA(
              isA<ServerBootRefusal>().having(
                (e) => e.message,
                'message',
                isNot(contains('ghp')),
              ),
            ),
          );
        }
      }
    });
  });

  test('every refusal escapes ESC, OSC, BEL, CR and LF from a value or a '
      'path, and bounds its length (review 6, finding 5)', () {
    const raw = {
      'ESC': ('/srv/a\x1B[2Jb', r'/srv/a\u{001B}[2Jb'),
      'OSC': ('/srv/a\x1B]0;pwned\x07b', r'/srv/a\u{001B}]0;pwned\u{0007}b'),
      'BEL': ('/srv/a\x07b', r'/srv/a\u{0007}b'),
      'CR': ('/srv/a\rb', r'/srv/a\u{000D}b'),
      'LF': ('/srv/a\nb', r'/srv/a\u{000A}b'),
    };
    for (final MapEntry(key: what, value: (value, shown)) in raw.entries) {
      final refusals = <String, ServerBootRefusal>{
        'DataDirNotPrivate': DataDirNotPrivate(
          PrivateDirectoryException(value, 0x1ED),
        ),
        'DataDirUnusable path': DataDirUnusable(
          value,
          const FileSystemException('Creation failed'),
        ),
        'DataDirUnusable reason': DataDirUnusable(
          '/srv/x',
          FileSystemException('Creation failed', '/srv/x', OSError(value, 20)),
        ),
        'GlobalDatabaseDamaged path': GlobalDatabaseDamaged(value, 'bad'),
        'GlobalDatabaseDamaged finding': GlobalDatabaseDamaged('/g.db', value),
        'GlobalDatabaseNewer': GlobalDatabaseNewer(value, 9, 8),
        'GlobalDatabaseForeign': GlobalDatabaseForeign(value, 7),
        'ServerIdentityUnreadable path': ServerIdentityUnreadable(
          path: value,
          quarantinedAt: '/q',
        ),
        'ServerIdentityUnreadable kept': ServerIdentityUnreadable(
          path: '/p',
          quarantinedAt: value,
        ),
      };
      for (final MapEntry(key: name, value: refusal) in refusals.entries) {
        expect(refusal.message, contains(shown), reason: '$what in $name');
        expect(
          refusal.message,
          isNot(matches(RegExp(r'[\x00-\x1F\x7F]'))),
          reason: '$what in $name',
        );
      }
      // A native's description is read as one line: its whitespace, a
      // line break among it, is one space; a control is escaped.
      final natives = NativeLibrariesMissing([value], searched: [value]);
      expect(
        natives.message,
        isNot(matches(RegExp(r'[\x00-\x1F\x7F]'))),
        reason: what,
      );
      final connect = ConnectEnvironmentInvalid(value);
      expect(connect.message, contains(shown), reason: what);
      expect(
        connect.message,
        isNot(matches(RegExp(r'[\x00-\x1F\x7F]'))),
        reason: what,
      );
    }
    final long = '/srv/${'\u00E9' * 5000}';
    expect(
      GlobalDatabaseForeign(long, 7).message,
      allOf(contains('/srv/\u00E9\u00E9'), hasLength(lessThan(1400))),
    );
  });

  test('printableText keeps letters, accents and symbols, and escapes what '
      'does not print', () {
    expect(
      printableText('/home/j\u00FCrgen/caf\u0065\u0301/\u65E5\u672C/\u2603'),
      '/home/j\u00FCrgen/caf\u0065\u0301/\u65E5\u672C/\u2603',
    );
    expect(
      printableText('a\u200Bb\u202Ec\u00A0d\u2028e\u2800f\uFEFF'),
      r'a\u{200B}b\u{202E}c\u{00A0}d\u{2028}e\u{2800}f\u{FEFF}',
    );
    expect(printableText('x' * 300, max: 10), '${'x' * 9}\u2026');
    // A refusal's own line breaks stay; every other control is escaped.
    expect(
      terminalText('a\nb\x1Bc'),
      'a\nb'
      r'\u{001B}c',
    );
  });

  group('a line printed outside the logger (review 7, N2 and N3)', () {
    // A token of the shape GitHub issues, as an exception's text, a path or
    // an argument may carry it.
    final token = 'ghp_${'Ab3' * 12}';
    const control = 'x\x1B[2Jy';
    final error = StateError('open /srv/data/$token/logs: $control');

    void expectClean(String line) {
      expect(line, isNot(contains('ghp_')), reason: line);
      expect(line, isNot(contains(token.substring(4, 20))), reason: line);
      expect(line, isNot(matches(RegExp(r'[\x00-\x09\x0B-\x1F\x7F]'))));
      expect(line, contains(r'x\u{001B}[2Jy'), reason: line);
    }

    test('the line an error before ready ends the boot with (exit 70)', () {
      final line = bootFailureLine(error, logged: true);
      expectClean(line);
      expect(line, startsWith('cc_server: cannot start \u2014 '));
      expect(line, endsWith(' (the stack is in the log)'));
      expect(bootFailureLine(error, logged: false), isNot(contains('stack')));
    });

    test('the line a failed command ends with, and the shutdown line', () {
      expectClean(commandFailureLine(error));
      expectClean(shutdownFailureLine(error));
    });

    test('the lines a failed bind ends the boot with', () {
      final lines = bindFailureLines(
        SocketException(
          'bind $token $control',
          address: InternetAddress.loopbackIPv4,
          port: 9030,
        ),
      );
      expectClean(lines);
      expect(lines.split('\n'), hasLength(2));
    });

    test('a token is redacted before the line is cut at 300 characters: cut '
        'first, the head of a token at the cut was shown', () {
      for (final pad in [270, 280, 290, 296]) {
        final long = StateError('${'a ' * (pad ~/ 2)}$token');
        for (final line in [
          bootFailureLine(long, logged: false),
          commandFailureLine(long),
          shutdownFailureLine(long),
        ]) {
          expect(line, isNot(contains('ghp_')), reason: '$pad: $line');
          expect(line.runes.length, lessThan(360), reason: line);
        }
      }
    });

    test('the booting and ready lines show the data directory printable', () {
      const dir = '/srv/cc\u202Eatad\x1B]0;x\x07/caf\u00E9';
      for (final line in [
        bootingLine(dir),
        readyLine(host: '127.0.0.1', port: 9030, dataDir: dir, workspaces: 2),
      ]) {
        expect(line, contains(r'/srv/cc\u{202E}atad\u{001B}]0;x\u{0007}/'));
        expect(line, contains('caf\u00E9'));
        expect(line, isNot(contains('\u202E')));
        expect(line, isNot(matches(RegExp(r'[\x00-\x1F\x7F]'))));
      }
      expect(
        bootingLine('/srv/cc'),
        'cc_server: booting (data: /srv/cc)\u2026',
      );
      expect(
        readyLine(host: '0.0.0.0', port: 1, dataDir: '/d', workspaces: 0),
        'cc_server ready on 0.0.0.0:1 (data: /d, workspaces: 0)',
      );
    });

    test('pair prints what the operator passed redacted and printable; the '
        'pairing key as it is', () async {
      final dataDir = '${tmp.path}/$token';
      final out = _Lines();
      final err = _Lines();
      final outSink = IOSink(out);
      final errSink = IOSink(err);
      final code = await runPairCommand(
        args: ['--data-dir', dataDir, '--host', 'h$control$token'],
        out: outSink,
        err: errSink,
        checkNatives: (_) async {},
      );
      await outSink.close();
      await errSink.close();
      expect(code, 0, reason: err.text);
      final printed = out.text;
      expect(printed, isNot(contains('ghp_')), reason: printed);
      expect(printed, isNot(matches(RegExp(r'[\x00-\x09\x0B-\x1F\x7F]'))));
      expect(printed, contains(r'hx\u{001B}[2Jy'));
      expect(printed, matches(RegExp(r'Pairing key \S{16,}')));
    });

    test('connect: a token in an unknown command is redacted', () async {
      final (code, err) = await run(
        (out, err) => runConnectCommand(
          args: ['$token $control', '--data-dir', tmp.path],
          out: out,
          err: err,
          checkNatives: (_) async {},
        ),
      );
      expect(code, isNot(0));
      expectClean(err.split('\n').first);
    });
  });

  test('connect: an unknown command is echoed escaped', () async {
    final (code, err) = await run(
      (out, err) => runConnectCommand(
        args: ['st\x1B]0;x\x07atus', '--data-dir', tmp.path],
        out: out,
        err: err,
        checkNatives: (_) async {},
      ),
    );
    expect(code, isNot(0));
    expect(err, contains(r'st\u{001B}]0;x\u{0007}atus'));
    expect(err, isNot(matches(RegExp(r'[\x00-\x09\x0B-\x1F\x7F]'))));
  });

  group('serve', () {
    Future<(int, String)> serve(Future<Object> Function() start) => run(
      (out, err) async =>
          await runOrRefuse(start, err: err) == null ? refusedExitCode : 0,
    );

    test('a refused setting ends the boot with 78 and one line', () async {
      final (code, err) = await serve(
        () => runCcServer(
          args: [
            '--data-dir',
            tmp.path,
            '--port',
            '0',
            '--code-mode-max-processes',
            '0',
          ],
        ),
      );
      expectRefused(code, err);
      expect(err, contains('--code-mode-max-processes is "0"'));
    });

    test('a missing native ends the boot with 78 and one line', () async {
      final (code, err) = await serve(() async {
        await missingNative(tmp.path);
        return Object();
      });
      expectRefused(code, err);
    });

    test('any other error is not a refusal: it is rethrown', () async {
      await expectLater(
        runOrRefuse<Object>(() async => throw StateError('crash')),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class _Lines implements StreamConsumer<List<int>> {
  final _buffer = BytesBuilder();
  String get text => utf8.decode(_buffer.toBytes());

  @override
  Future<void> addStream(Stream<List<int>> stream) =>
      stream.forEach(_buffer.add);

  @override
  Future<void> close() async {}
}
