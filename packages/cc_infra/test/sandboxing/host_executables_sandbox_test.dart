// Run sandboxes are Seatbelt and bubblewrap; Windows has none.
@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_infra/src/sandboxing/host_executables.dart';
import 'package:cc_infra/src/sandboxing/macos_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:test/test.dart';

/// A sandboxed run (a member's, chat mode) must not be able to change what
/// the host runs outside every sandbox: the directories on its `PATH` and in
/// the binary resolver's prefixes, the links on the way and the packages a
/// linked command resolves into. Nor may it write a start-up file the server
/// user's own shells run, or a secret it cannot read.
///
/// Real Seatbelt, against a home made for the test (the real one is never
/// touched).
void main() {
  late Directory root;
  late String home;
  late String work;
  late String path;

  void file(String rel, String content, {bool executable = false}) {
    final f = File('$home/$rel')..createSync(recursive: true);
    f.writeAsStringSync(content);
    if (executable) {
      Process.runSync('/bin/chmod', ['755', f.path]);
    }
  }

  setUp(() {
    root = Directory.systemTemp.createTempSync('cc-hostexe-');
    // The kernel's spelling (`/var` is a link), so the rules name what the
    // processes touch.
    home = '${root.resolveSymbolicLinksSync()}/home';
    work = '$home/work';
    Directory(work).createSync(recursive: true);
    file('.local/bin/tool', '#!/bin/sh\necho host-tool\n', executable: true);
    // An fvm-style SDK: `default` links to a version, whose `bin` holds the
    // launchers and a `cache` the SDK writes at run time.
    file('fvm/versions/1/bin/flutter', '#!/bin/sh\n', executable: true);
    Directory('$home/fvm/versions/1/bin/cache').createSync();
    Link('$home/fvm/default').createSync('$home/fvm/versions/1');
    // A node version: `npm` is a link into its global package.
    file(
      'node/lib/node_modules/npm/bin/npm-cli.js',
      '#!/usr/bin/env node\n',
      executable: true,
    );
    Link(
      '$home/node/bin/npm',
    ).createSync('../lib/node_modules/npm/bin/npm-cli.js', recursive: true);
    // Caches a toolchain downloads into and runs from.
    Directory('$home/.npm/_npx').createSync(recursive: true);
    Directory('$home/.cache/node/corepack').createSync(recursive: true);
    path = [
      '$home/.local/bin',
      '$home/fvm/default/bin',
      '$home/node/bin',
      'relative/bin',
    ].join(':');
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  HostExecutableDirs scan() =>
      scanHostExecutables(path: path, home: home, scanRoots: [home]);

  group('the boot list', () {
    test('holds PATH entries, every symlink hop, and linked packages', () {
      final found = scan();
      expect(
        found.dirs,
        containsAll([
          '$home/.local/bin',
          '$home/fvm/default/bin',
          '$home/fvm/versions/1/bin',
          '$home/node/bin',
        ]),
      );
      expect(found.dirs.where((d) => d.startsWith('relative')), isEmpty);
      expect(found.links, contains('$home/fvm/default'));
      expect(found.installRoots, contains('$home/node/lib/node_modules/npm'));
      // An SDK whose bin is on PATH is never protected whole.
      expect(found.installRoots, isNot(contains('$home/fvm/versions/1')));
      // The binary resolver's own prefixes are in it too.
      final realHome = Platform.environment['HOME'];
      if (realHome != null && realHome.isNotEmpty) {
        expect(found.dirs, contains('$realHome/.local/bin'));
      }
    });

    test('holds the extra directories the host runs programs from', () {
      final runnerDir = Directory('$home/app/bin/codemode')
        ..createSync(recursive: true);
      final found = scanHostExecutables(
        path: path,
        home: home,
        scanRoots: [home],
        extraDirs: ['$home/app/bin', runnerDir.path, 'relative/codemode', ''],
      );
      expect(found.dirs, containsAll(['$home/app/bin', runnerDir.path]));
      expect(found.dirs.where((d) => d.contains('relative')), isEmpty);
    });

    test('adds a few profile rules per entry', () async {
      final config = await _config(home: home, work: work);
      final found = scan();
      String profile(HostExecutableDirs dirs) =>
          MacosSandbox.generateSeatbeltProfile(
            config.copyWith(
              filesystem: config.filesystem.copyWith(hostExecutables: dirs),
            ),
          );
      final added =
          profile(found).split('\n').length -
          profile(HostExecutableDirs.none).split('\n').length;
      final entries =
          found.dirs.length + found.links.length + found.installRoots.length;
      // Two rules per directory, one per link or root, and one per distinct
      // ancestor (shared between entries).
      expect(added, lessThan(3 * entries + 20));
    });
  });

  test('every read-denied secret is write-denied too', () {
    final policy = const SandboxPolicyResolver().resolve(
      spec: SandboxSpec(
        sessionId: 's',
        workspaceId: 'ws',
        agentId: 'agent',
        bindMounts: const [],
        guestWorkdir: work,
        networkEnabled: false,
        mode: Mode.chat,
      ),
      homeDir: home,
    );
    for (final rel in SandboxPolicyResolver.secretsDenyReadRels) {
      expect(policy.denyRead, contains('$home/$rel'));
      expect(policy.denyWrite, contains('$home/$rel'));
    }
  });

  group('sandboxed (real process)', () {
    Future<ProcessResult> run(
      String script, {
      HostExecutableDirs? hostExecutables,
    }) async {
      final manager = SandboxManager(
        hiddenPaths: const [],
        hostExecutables: hostExecutables ?? scan(),
      );
      addTearDown(manager.reset);
      final wrap = await manager.wrap(
        config: await _config(home: home, work: work),
        argv: ['/bin/sh', '-c', script],
        workingDirectory: work,
      );
      return Process.run(
        wrap.executable,
        wrap.argv,
        workingDirectory: work,
        environment: {...wrap.environment, 'H': home},
      );
    }

    test('without these rules a run can plant a program the host runs '
        '(the escape this closes)', () async {
      final result = await run(
        r'printf "#!/bin/sh\necho planted\n" > "$H/.local/bin/x"',
        hostExecutables: HostExecutableDirs.none,
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(File('$home/.local/bin/x').existsSync(), isTrue);
    });

    test('cannot create or replace a command in a PATH dir', () async {
      await run(
        r'printf x > "$H/.local/bin/x"; '
        r'printf x > "$H/.local/bin/tool"; '
        r'printf x > "$H/new"; /bin/mv "$H/new" "$H/.local/bin/tool"; '
        r'/bin/chmod 644 "$H/.local/bin/tool"',
      );
      expect(File('$home/.local/bin/x').existsSync(), isFalse);
      expect(
        File('$home/.local/bin/tool').readAsStringSync(),
        contains('host-tool'),
      );
      expect(
        File('$home/.local/bin/tool').statSync().modeString(),
        'rwxr-xr-x',
      );
    });

    test('cannot rename a PATH dir or the directories above it', () async {
      await run(
        r'/bin/mv "$H/.local/bin" "$H/.local/bin2"; '
        r'/bin/mv "$H/.local" "$H/.local2"',
      );
      expect(File('$home/.local/bin/tool').existsSync(), isTrue);
      expect(Directory('$home/.local2').existsSync(), isFalse);
      expect(Directory('$home/.local/bin2').existsSync(), isFalse);
    });

    test('cannot replace a symlinked PATH entry or write through it', () async {
      Directory('$home/evil/bin').createSync(recursive: true);
      await run(
        r'/bin/ln -sfn "$H/evil" "$H/fvm/default"; '
        r'/bin/mv "$H/fvm/default" "$H/fvm/old"; '
        r'printf x > "$H/fvm/default/bin/x"; '
        r'printf x > "$H/fvm/versions/1/bin/flutter"',
      );
      expect(Link('$home/fvm/default').targetSync(), '$home/fvm/versions/1');
      expect(File('$home/fvm/versions/1/bin/x').existsSync(), isFalse);
      expect(
        File('$home/fvm/versions/1/bin/flutter').readAsStringSync(),
        '#!/bin/sh\n',
      );
    });

    test('cannot change the package a linked command runs', () async {
      await run(
        r'printf x > "$H/node/lib/node_modules/npm/bin/npm-cli.js"; '
        r'printf x > "$H/node/lib/node_modules/npm/lib.js"',
      );
      expect(
        File(
          '$home/node/lib/node_modules/npm/bin/npm-cli.js',
        ).readAsStringSync(),
        '#!/usr/bin/env node\n',
      );
      expect(
        File('$home/node/lib/node_modules/npm/lib.js').existsSync(),
        isFalse,
      );
    });

    test('SDK caches, package caches and npx-style runs still work', () async {
      final result = await run(
        r'set -e; '
        r'printf ok > "$H/fvm/default/bin/cache/stamp"; '
        r'mkdir -p "$H/.cache/node/corepack/v1"; '
        r'printf ok > "$H/.cache/node/corepack/v1/pnpm.js"; '
        r'bin="$H/.npm/_npx/k/node_modules/.bin"; mkdir -p "$bin"; '
        r'printf "#!/bin/sh\necho downloaded-and-ran\n" > "$bin/hello"; '
        r'/bin/chmod 755 "$bin/hello"; "$bin/hello"; '
        r'mkdir -p "$H/node/lib/node_modules/other"; '
        r'printf ok > "$H/node/lib/node_modules/other/index.js"',
      );
      expect(result.exitCode, 0, reason: '${result.stderr}');
      expect(result.stdout, contains('downloaded-and-ran'));
      expect(
        File('$home/fvm/versions/1/bin/cache/stamp').readAsStringSync(),
        'ok',
      );
      expect(
        File('$home/.cache/node/corepack/v1/pnpm.js').existsSync(),
        isTrue,
      );
    });

    test('cannot write a start-up file or a read-denied secret', () async {
      final rels = [
        ...SandboxPolicyResolver.homeRcDenyRels,
        ...SandboxPolicyResolver.secretsDenyReadRels,
      ];
      final script = StringBuffer();
      for (final rel in rels) {
        script.write(
          'printf x > "\$H/$rel" 2>/dev/null; '
          'mkdir -p "\$H/$rel" 2>/dev/null && '
          'printf x > "\$H/$rel/x" 2>/dev/null; ',
        );
      }
      await run(script.toString());
      final written = [
        for (final rel in rels)
          if (File('$home/$rel').existsSync() ||
              File('$home/$rel/x').existsSync())
            rel,
      ];
      expect(written, isEmpty);
    });
  }, skip: Platform.isMacOS ? false : 'real Seatbelt only');
}

Future<SandboxConfig> _config({required String home, required String work}) =>
    buildSandboxConfigFromPolicy(
      const SandboxPolicyResolver().resolve(
        spec: SandboxSpec(
          sessionId: 'host-executables',
          workspaceId: 'ws',
          agentId: 'agent',
          bindMounts: [SandboxBindMount(hostPath: work, guestPath: work)],
          guestWorkdir: work,
          networkEnabled: false,
          mode: Mode.chat,
        ),
        homeDir: home,
        runDir: '$work/.cc-runs/host-executables',
      ),
    );
