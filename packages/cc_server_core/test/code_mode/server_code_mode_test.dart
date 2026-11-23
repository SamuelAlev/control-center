import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/testing/fake_workspace_repository.dart';
import 'package:cc_infra/cc_infra.dart'
    show BundledCodeRunner, CcInfraLog, CcInfraLogLevel;
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart'
    show CodeSandboxProcess;
import 'package:cc_infra/src/code_mode/host_path_scrub.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/code_mode/server_code_mode.dart';
import 'package:cc_server_core/src/dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// The fake runners here are `/bin/sh` scripts made executable with
/// `/bin/chmod`, which Windows has neither of.
final String? _shRunner = Platform.isWindows
    ? 'the fake runner is a /bin/sh script'
    : null;

/// Whether this server runs scripts, the limits a workspace's scripts get,
/// and the runner host's boot self-test and startup line.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late FakeWorkspaceRepository workspaces;
  late DaoWorkspaceSettingsRepository settings;
  final now = DateTime.utc(2026, 11, 17);

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    workspaces = FakeWorkspaceRepository();
    for (final id in ['ws-a', 'ws-b']) {
      await workspaces.upsert(
        Workspace(id: id, name: id, createdAt: now, updatedAt: now),
      );
    }
    await workspaces.upsert(
      Workspace(
        id: 'ws-gone',
        name: 'gone',
        createdAt: now,
        updatedAt: now,
        deletedAt: now,
      ),
    );
    settings = DaoWorkspaceSettingsRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  CodeModeSettings resolver({
    CodeRunnerAvailability availability =
        const CodeRunnerAvailability.available(),
  }) => CodeModeSettings(
    availability: () => availability,
    workspaces: workspaces,
    settings: settings,
  );

  test('availability is what the runner reports, read when asked', () {
    CodeRunnerAvailability now = const CodeRunnerAvailability.available();
    final settings = CodeModeSettings(
      availability: () => now,
      workspaces: workspaces,
      settings: DaoWorkspaceSettingsRepository(dbs),
    );
    expect(settings.availability.isAvailable, isTrue);
    now = const CodeRunnerAvailability.unavailable('lockdown is partial');
    expect(settings.availability.isAvailable, isFalse);
  });

  group('stored values are read leniently', () {
    test('malformed or out-of-bounds limits are the defaults', () async {
      for (final raw in [
        'not json',
        '[1, 2]',
        jsonEncode({'wall_clock_ms': 1}),
        jsonEncode({'no_such_limit': 5}),
        jsonEncode({'wall_clock_ms': 'soon'}),
      ]) {
        await settings.set('ws-a', kCodeModeLimitsSettingKey, raw);
        expect(
          await resolver().limitsFor('ws-a'),
          CodeModeLimits.defaults,
          reason: raw,
        );
      }
    });

    test('valid limits override the defaults', () async {
      const wall = CodeModeLimits.wallClock;
      await settings.set(
        'ws-a',
        kCodeModeLimitsSettingKey,
        jsonEncode({wall.key: wall.floor}),
      );
      final limits = await resolver().limitsFor('ws-a');
      expect(limits.wallClockMs, wall.floor);
      expect(limits.cpuMs, CodeModeLimits.defaults.cpuMs);
    });
  });

  group('the workspace is checked before its database is opened', () {
    test(
      'limits refuse an unknown or deleted workspace as not found',
      () async {
        for (final id in ['ws-unknown', 'ws-gone']) {
          await expectLater(
            resolver().limitsFor(id),
            throwsA(isA<NotFoundException>()),
            reason: id,
          );
          expect(dbs.openIds, isNot(contains(id)), reason: id);
        }
      },
    );
  });

  group('host paths never leave the server', () {
    test('known paths and absolute paths are scrubbed', () {
      const reason =
          'The code mode runner could not be started: ProcessException: '
          'No such file or directory\n  Command: /opt/Control Center/bin/'
          'codemode/cc_codemode --self-test (see /var/log/x.log or '
          r'C:\Users\me\cc.log)';
      final scrubbed = scrubHostPaths(
        reason,
        knownPaths: const ['/opt/Control Center/bin/codemode/cc_codemode'],
      );
      expect(scrubbed, isNot(contains('/opt')));
      expect(scrubbed, isNot(contains('/var/log')));
      expect(scrubbed, isNot(contains(r'C:\Users')));
      expect(scrubbed, contains('could not be started'));
      expect(scrubbed, contains('--self-test'));
    });
  });

  group('runner host', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('cc_code_runner'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('a bundle without the runner has no host', () {
      expect(
        CodeRunnerHost.locate(
          appSupportRoot: tmp.path,
          processEnvironment: {
            BundledCodeRunner.environmentOverride: p.join(
              tmp.path,
              'codemode',
              'cc_codemode',
            ),
          },
        ),
        isNull,
      );
    });

    test('a natives directory set only in .env does not move the runner', () {
      // A runner planted where the .env points, and none anywhere else.
      final planted = Directory(p.join(tmp.path, 'planted'));
      File(p.join(planted.path, 'codemode', BundledCodeRunner.executableName))
        ..createSync(recursive: true)
        ..writeAsStringSync('#!/bin/sh\n');
      final checkout = Directory(p.join(tmp.path, 'checkout'))..createSync();
      File(
        p.join(checkout.path, '.env'),
      ).writeAsStringSync('CC_NATIVE_LIB_DIR=${planted.path}\n');
      final merged = environmentWithDotenv(
        processEnvironment: const {},
        workingDirectory: checkout,
      );
      expect(
        merged['CC_NATIVE_LIB_DIR'],
        planted.path,
        reason: 'the .env is read for the rest of the server',
      );
      final data = Directory(p.join(tmp.path, 'data'))..createSync();
      expect(
        CodeRunnerHost.locate(
          appSupportRoot: data.path,
          processEnvironment: const {},
        ),
        isNull,
      );
      expect(
        BundledCodeRunner.candidates(
          appSupportRoot: data.path,
          processEnvironment: const {},
        ),
        everyElement(isNot(startsWith(planted.path))),
      );
      expect(
        BundledCodeRunner.installDirectories(processEnvironment: const {}),
        everyElement(isNot(startsWith(planted.path))),
      );
    });

    String fakeRunner(
      String name, {
      required String build,
      required String version,
    }) {
      final fake = File(p.join(tmp.path, name, 'cc_codemode'))
        ..createSync(recursive: true)
        ..writeAsStringSync('''
#!/bin/sh
if [ "\$1" = "--version" ]; then
  printf '$version\\n'
  exit 0
fi
echo '{"selftest":{"ok":true,"os":"test",$build"lockdown":{"level":"full","failed":[]},"checks":[{"name":"file_read","denied":true}],"session":{"passed":true,"runs":8}}}'
exit 0
''');
      Process.runSync('/bin/chmod', ['+x', fake.path]);
      return fake.path;
    }

    Future<CodeRunnerHost> started(String path) async {
      final host = CodeRunnerHost.locate(
        appSupportRoot: tmp.path,
        processEnvironment: {BundledCodeRunner.environmentOverride: path},
      )!;
      addTearDown(host.sandbox.dispose);
      await host.start();
      return host;
    }

    // What a runner of this server's protocol prints after its version.
    const protocol = 'protocol ${CodeSandboxProcess.protocolVersion}';

    test('a runner that is not a release build leaves code mode unavailable '
        'and says so; one that does not say is unavailable too', () async {
      // None of these reports a protocol: a runner that says it is not a
      // release build is told that, whatever its protocol says.
      for (final (build, says) in [
        ('"build":"debug",', 'is a debug build'),
        ('', 'does not report its build'),
        ('"build":"fast",', 'reports its build as "fast"'),
      ]) {
        final host = await started(
          fakeRunner(
            'b${build.length}',
            build: build,
            version: 'cc_codemode 9',
          ),
        );
        expect(host.availability.isAvailable, isFalse, reason: build);
        expect(host.publicReason, contains(says), reason: build);
        expect(host.publicReason, contains('not a release build'));
        expect(host.version, isNull);
      }
      final release = await started(
        fakeRunner(
          'release',
          build: '"build":"release",',
          version: 'cc_codemode 9 $protocol',
        ),
      );
      expect(release.availability.isAvailable, isTrue);
      expect(release.version, 'cc_codemode 9 $protocol');
      // A release build that names no protocol is refused for that.
      final silent = await started(
        fakeRunner(
          'silent',
          build: '"build":"release",',
          version: 'cc_codemode 9',
        ),
      );
      expect(silent.availability.isAvailable, isFalse);
      expect(silent.publicReason, contains('does not report its protocol'));
    }, skip: _shRunner);

    test('what a runner prints for its version reaches the startup line as '
        'one short line of printable characters', () async {
      final host = await started(
        fakeRunner(
          'loud',
          build: '"build":"release",',
          version:
              'cc_codemode \\033[2J\\342\\200\\256 ${'v' * 300} $protocol',
        ),
      );
      expect(host.availability.isAvailable, isTrue);
      final version = host.version!;
      expect(version, startsWith('cc_codemode '));
      expect(version.length, lessThanOrEqualTo(CodeRunnerHost.maxVersionChars));
      expect(version, matches(RegExp(r'^[\x20-\x7e]+$')));
      final line = host.startupLine(
        maxProcesses: 4,
        maxParked: 16,
        workspaceShare: 3,
        maxHeapBytes: 256 * 1024 * 1024,
      );
      expect(line, contains('code_mode=available ($version;'));
    }, skip: _shRunner);

    test('the status reason names no known path, even one whose name holds '
        '", " and a quote, and holds no control or secret', () async {
      final root = Directory(p.join(tmp.path, "o'brien, x: y"));
      final fake = File(p.join(root.path, 'codemode', 'cc_codemode'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '#!/bin/sh\n'
          'if [ "\$1" = "--version" ]; then\n'
          '  echo "cc_codemode 0.0.0-test $protocol"\n'
          r"""
  exit 0
fi
printf 'cannot open %s/lib/x.so now \033[31m\302\205 token=ghp_a1B2c3D4e5a1B2c3D4e5a1B2c3D4e5a1B2c3D4e5\n' "$0" >&2
exit 1
""",
        );
      Process.runSync('/bin/chmod', ['+x', fake.path]);
      final host = CodeRunnerHost.locate(
        appSupportRoot: root.path,
        processEnvironment: {BundledCodeRunner.environmentOverride: fake.path},
      )!;
      addTearDown(host.sandbox.dispose);
      await host.start();
      final reason = host.publicReason!;
      expect(reason, contains('cannot open <path> now'));
      expect(reason, isNot(contains('brien')));
      expect(reason, isNot(contains(', x')));
      expect(reason, isNot(contains('ghp_a1B2')));
      expect(reason, isNot(matches(RegExp(r'[\x00-\x1f\x7f-\x9f]'))));
    }, skip: _shRunner);

    test('a runner that cannot fully lock down leaves code mode unavailable, '
        'with a reason that names no path', () async {
      final fake = File(p.join(tmp.path, 'codemode', 'cc_codemode'))
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '#!/bin/sh\n'
          'if [ "\$1" = "--version" ]; then\n'
          '  echo "cc_codemode 0.0.0-test $protocol"\n'
          r'''
  exit 0
fi
echo '{"selftest":{"lockdown":{"level":"partial","failed":["seatbelt"]},"checks":[]}}'
exit 1
''',
        );
      Process.runSync('/bin/chmod', ['+x', fake.path]);
      final host = CodeRunnerHost.locate(
        appSupportRoot: tmp.path,
        processEnvironment: {BundledCodeRunner.environmentOverride: fake.path},
      )!;
      addTearDown(host.sandbox.dispose);
      expect(host.availability.isAvailable, isFalse);
      await host.start();
      expect(host.availability.isAvailable, isFalse);
      expect(host.publicReason, isNotNull);
      expect(host.publicReason, isNot(contains(tmp.path)));
      // A binary that did not prove itself reports no version.
      expect(host.version, isNull);
      final line = host.startupLine(
        maxProcesses: 4,
        maxParked: 16,
        workspaceShare: 3,
        maxHeapBytes: 256 * 1024 * 1024,
      );
      expect(line, startsWith('cc_server: code_mode=unavailable ('));
      expect(line, isNot(contains('0.0.0-test')));
      expect(line, isNot(contains(tmp.path)));

      // Settings over this host say no run gets repl.
      expect(
        CodeModeSettings(
          availability: () => host.availability,
          workspaces: workspaces,
          settings: settings,
        ).availability.isAvailable,
        isFalse,
      );
    }, skip: _shRunner);

    test(
      'the real runner passes its self-test and reports its version',
      () async {
        final host = CodeRunnerHost.locate(appSupportRoot: tmp.path);
        expect(
          host,
          isNotNull,
          reason:
              'set CC_CODEMODE_RUNNER to the absolute path of a built '
              'cc_codemode',
        );
        addTearDown(host!.sandbox.dispose);
        await host.start();
        expect(
          host.availability.isAvailable,
          isTrue,
          reason: '${host.availability}',
        );
        expect(host.publicReason, isNull);
        expect(host.version, startsWith('cc_codemode '));
        // The line says what is really bounded: running scripts, one
        // workspace's share, the parked runners besides, and the heap.
        expect(
          host.startupLine(
            maxProcesses: 6,
            maxParked: 24,
            workspaceShare: 5,
            maxHeapBytes: 512 * 1024 * 1024,
          ),
          allOf(
            contains('code_mode=available'),
            contains('6 scripts at once'),
            contains('at most 5 per workspace'),
            contains('up to 24 more runners'),
            contains('heap at most 512 MiB'),
          ),
        );
      },
      skip: Platform.isWindows ? 'the runner is not built on Windows' : false,
    );
  });
  group('the code mode log lines', () {
    String line(CodeRunnerAvailability availability, {int processes = 6}) =>
        CodeRunnerHost.startupLineFor(
          availability,
          version: 'cc_codemode 0.1.0',
          maxProcesses: processes,
          maxParked: processes == 1 ? 1 : 24,
          workspaceShare: processes == 1 ? 1 : 5,
          maxHeapBytes: 512 * 1024 * 1024,
        );

    test('are one line, whatever the runner wrote', () {
      final lost = line(
        const CodeRunnerAvailability.unavailable(
          'the self-test exited with code 1:\nline two\r\n  line three',
        ),
      );
      expect(lost, isNot(matches(RegExp('[\r\n]'))));
      expect(lost, contains('code 1: line two line three'));
      expect(
        line(const CodeRunnerAvailability.available()),
        isNot(contains('\n')),
      );
    });

    test('hold no control, separator or secret (review L5)', () {
      final token = 'ghp_${'a1B2c3D4e5' * 4}';
      final lost = line(
        CodeRunnerAvailability.unavailable(
          'the runner said \x1b[31mred\x1b[0m\u0085next\x0b\x0c\u2028x '
          'token=$token \u202Eevil',
        ),
      );
      expect(lost, contains('the runner said'));
      expect(
        lost,
        isNot(matches(RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029\u202E]'))),
      );
      expect(lost, isNot(contains(token)));
    });

    test('count one as one', () {
      expect(
        line(const CodeRunnerAvailability.available(), processes: 1),
        allOf(
          contains('1 script at once'),
          contains('up to 1 more runner kept'),
        ),
      );
      expect(
        line(const CodeRunnerAvailability.available()),
        allOf(contains('6 scripts at once'), contains('24 more runners')),
      );
    });
  });
  test('the loss and the return are each logged once, in one line, the '
      'return at least as loud as the loss', () async {
    final records = <(CcInfraLogLevel, String)>[];
    final saved = CcInfraLog.sink;
    CcInfraLog.sink = (level, message, [error, stackTrace]) =>
        records.add((level, message));
    addTearDown(() => CcInfraLog.sink = saved);
    final changes = StreamController<CodeRunnerAvailability>();
    final sub = CodeRunnerHost.logChanges(
      changes.stream,
      lineFor: (availability) => CodeRunnerHost.startupLineFor(
        availability,
        version: 'cc_codemode 0.1.0',
        maxProcesses: 6,
        maxParked: 24,
        workspaceShare: 5,
        maxHeapBytes: 512 * 1024 * 1024,
      ),
    );
    changes
      ..add(
        const CodeRunnerAvailability.unavailable(
          'The code mode runner could not be started: ProcessException: '
          'No such file or directory\n  Command: <path> --self-test',
        ),
      )
      ..add(const CodeRunnerAvailability.available());
    await changes.close();
    await sub.cancel();
    expect(records, hasLength(2));
    final (lostLevel, lost) = records[0];
    final (backLevel, back) = records[1];
    expect(lost, contains('code_mode=unavailable'));
    expect(back, contains('code_mode=available'));
    for (final (_, line) in records) {
      expect(line, isNot(matches(RegExp('[\r\n]'))));
    }
    // The server shows warnings by default; the return is not hidden where
    // the loss was shown.
    expect(lostLevel, CcInfraLogLevel.warning);
    expect(backLevel.index, greaterThanOrEqualTo(lostLevel.index));
  });
}
