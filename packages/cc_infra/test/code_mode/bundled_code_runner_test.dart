import 'dart:io';

import 'package:cc_infra/src/code_mode/bundled_code_runner.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('codemode-locate-');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test(
    'searches beside the server, the native directory, then app support',
    () {
      final paths = BundledCodeRunner.candidates(
        appSupportRoot: '/support',
        processEnvironment: const {'CC_NATIVE_LIB_DIR': '/natives'},
        serverExecutable: '/bundle/bin/cc_server',
      );
      final exe = BundledCodeRunner.executableName;
      expect(paths, [
        p.join('/bundle/bin', 'codemode', exe),
        p.join('/natives', 'codemode', exe),
        p.join('/support', 'codemode', exe),
      ]);
    },
  );

  test('the override is the only candidate', () {
    final paths = BundledCodeRunner.candidates(
      appSupportRoot: '/support',
      processEnvironment: const {'CC_CODEMODE_RUNNER': '/dev/runner'},
    );
    expect(paths, ['/dev/runner']);
  });

  test('the install directories follow the process environment', () {
    expect(
      BundledCodeRunner.installDirectories(
        processEnvironment: const {'CC_NATIVE_LIB_DIR': '/natives'},
        serverExecutable: '/bundle/bin/cc_server',
      ),
      [
        '/bundle/bin',
        p.join('/bundle/bin', 'codemode'),
        '/natives',
        p.join('/natives', 'codemode'),
      ],
    );
  });

  test(
    'a missing runner is an error naming every path tried; no PATH lookup',
    () {
      expect(
        () => BundledCodeRunner.locate(
          appSupportRoot: tmp.path,
          processEnvironment: const {'PATH': '/usr/bin:/bin'},
          serverExecutable: p.join(tmp.path, 'bin', 'cc_server'),
        ),
        throwsA(
          isA<CodeRunnerNotFoundException>()
              .having((e) => e.searched, 'searched', hasLength(2))
              .having((e) => e.message, 'message', contains(tmp.path)),
        ),
      );
    },
  );

  test('a relative override is refused', () {
    expect(
      () => BundledCodeRunner.locate(
        appSupportRoot: tmp.path,
        processEnvironment: const {'CC_CODEMODE_RUNNER': 'cc_codemode'},
      ),
      throwsA(isA<CodeRunnerNotFoundException>()),
    );
  });

  test('finds the development install under app support', () {
    final file = File(
      p.join(tmp.path, 'codemode', BundledCodeRunner.executableName),
    )..createSync(recursive: true);
    final found = BundledCodeRunner.locate(
      appSupportRoot: tmp.path,
      processEnvironment: const {},
      serverExecutable: p.join(tmp.path, 'nowhere', 'cc_server'),
    );
    expect(found.executable, file.resolveSymbolicLinksSync());
  });

  test('the real runner passes its self-test on this host', () async {
    final host = CodeSandboxProcess(executable: realRunnerPath());
    expect(host.availability.isAvailable, isFalse);
    final availability = await host.selfTest();
    expect(availability.isAvailable, isTrue, reason: '$availability');
  });
}
