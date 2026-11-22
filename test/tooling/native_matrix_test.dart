import 'dart:io';

import 'package:cc_natives/src/code_index/code_languages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ratchet over the required-native matrix.
///
/// This list is consumed by four audiences and used to be WRITTEN four times:
/// `verify_natives.sh`'s gate (prefix + extension, dot-bounded),
/// `cc_server_package.sh`'s separate glob-list gate, the runtime table built
/// with `nativeRequirement` in cc_server_runtime.dart and native_preflight.dart.
/// Each carried a comment asking the reader to "change them together".
///
/// The two shell copies are gone — both now read scripts/lib/natives.sh. The
/// Dart table cannot be generated from it (each entry is a probe *closure*, not
/// a filename), so this test pins the two together instead. A native added to
/// one and forgotten in the other is a boot failure on a user's machine: the
/// packaging gate passes because its list never heard of the library and then
/// cc_server refuses to start because the preflight did.
void main() {
  final root = Directory.current.path;
  final matrix = File('$root/scripts/lib/natives.sh').readAsStringSync();
  final runtime = File(
    '$root/packages/cc_server_core/lib/src/runtime/server_native_preflight.dart',
  ).readAsStringSync();

  /// The rows of `CC_NATIVES`, parsed the same way the shell does.
  final rows = <({String base, Set<String> roles, String platforms})>[
    for (final line in matrix.split('\n'))
      if (RegExp(r'^\s*"[^"|]+\|').hasMatch(line))
        () {
          final fields = line.trim().replaceAll('"', '').split('|');
          return (
            base: fields[0],
            roles: fields[1].split(',').toSet(),
            platforms: fields[2],
          );
        }(),
  ];

  test('the matrix parses and is not silently empty', () {
    // A typo in the row format would make every other check here vacuous.
    expect(rows.length, greaterThanOrEqualTo(10));
    for (final row in rows) {
      expect(row.base, isNotEmpty);
      expect(row.roles, isNotEmpty);
      expect(
        row.roles.difference({'desktop', 'server'}),
        isEmpty,
        reason: '${row.base}: roles must be desktop and/or server',
      );
      expect(
        row.platforms,
        anyOf('all', '!windows'),
        reason: '${row.base}: platforms must be `all` or `!windows`',
      );
    }
  });

  test('every server-role native is probed by the boot preflight', () {
    // server_native_preflight.dart names each library inside a nativeRequirement(...)
    // description — `platformLibraryFileName('fff_c')`,
    // `platformLibraryFileName(inferenceLibraryBaseName)`, `ptyLibraryBaseName`,
    // etc. Rather than parse Dart, assert the base name appears somewhere in
    // that file: the point is to catch a native that exists in one list and not
    // the other.
    const aliases = <String, List<String>>{
      // Named through a base-name constant instead of a literal.
      'ccpty': ['ptyLibraryBaseName'],
      'cc_watcher': ['watcherLibraryBaseName'],
      // Named through a base-name constant (one native, both ML workloads).
      'cc_inference': ['inferenceLibraryBaseName'],
      // Named through a base-name constant (SAML SSO crypto seam).
      'cc_saml': ['samlLibraryBaseName'],
      // Named through a base-name constant (desktop app windows).
      'cc_window': ['windowLibraryBaseName'],
    };
    for (final row in rows.where((r) => r.roles.contains('server'))) {
      // Grammar rows are generated from kLanguageByExtension in a loop, so
      // the preflight never names `tree-sitter-dart` literally.
      final needles = [
        row.base,
        ...?aliases[row.base],
        if (row.base.startsWith('tree-sitter-')) 'tree-sitter-\$languageId',
      ];
      expect(
        needles.any(runtime.contains),
        isTrue,
        reason:
            'scripts/lib/natives.sh requires "${row.base}" for the server, but '
            'server_native_preflight.dart never probes it. Either the packaging gate '
            'is checking for something the server does not need, or the server '
            'boots without something packaging guarantees.',
      );
    }
  });

  test('windows_natives.sh builds every native Windows requires', () {
    // The Windows libraries are built by their own script rather than by
    // build_natives.sh, so adding a row here reaches macOS and Linux and
    // silently misses Windows. cc_saml did exactly that: it landed in the
    // matrix and the runtime table, every unix build produced it, and the
    // Windows release job failed at verify_natives.sh 18 minutes in — after
    // compiling all twelve other libraries.
    final script = File(
      '$root/scripts/release/windows_natives.sh',
    ).readAsStringSync();
    for (final row in rows.where((r) => r.platforms != '!windows')) {
      // Grammars are built by a helper from a name, so `tree-sitter-dart.dll`
      // never appears literally; every other row names its output DLL.
      final needle = row.base.startsWith('tree-sitter-')
          ? 'build_grammar ${row.base.substring('tree-sitter-'.length)} '
          : '${row.base}.dll';
      expect(
        script,
        contains(needle),
        reason:
            'scripts/lib/natives.sh requires "${row.base}" on Windows, but '
            'scripts/release/windows_natives.sh never builds it. The release '
            'job would compile every other native and then fail verification.',
      );
    }
  });

  test('the shipped grammars are exactly kLanguageByExtension', () {
    // The indexer throws on a recognised language whose grammar is missing, so
    // kLanguageByExtension IS the shipped set. `tsx` gets its own grammar
    // library even though it reuses the typescript *query* (queryIdFor).
    final fromDart = kLanguageByExtension.values.toSet();
    final fromMatrix = rows
        .where((r) => r.base.startsWith('tree-sitter-'))
        .map((r) => r.base.substring('tree-sitter-'.length))
        .toSet();
    expect(
      fromMatrix,
      fromDart,
      reason:
          'scripts/lib/natives.sh and kLanguageByExtension disagree about which '
          'grammars ship. A language in the Dart map with no grammar row means '
          'the indexer throws on files the packaging gate never checked for.',
    );
  });

  test('only rift and cc_window are exempt, and both are server-only', () {
    // Windows has no MSVC copy-on-write backend, so `git worktree` is the
    // BACKEND there rather than a degradation. cc_window's exemption is
    // TEMPORARY: its Windows source has never been compiled, and it ends when
    // windows_natives.sh builds it. Any OTHER exemption would be a degraded
    // mode, which this pipeline does not have.
    final exempt = rows.where((r) => r.platforms != 'all').toList();
    expect(exempt.map((r) => r.base), ['rift_ffi', 'cc_window']);
    for (final row in exempt) {
      expect(row.roles, {'server'});
    }
    expect(
      RegExp('requiredOnWindows: false').allMatches(runtime).length,
      exempt.length,
      reason:
          'the matrix exempts these on Windows but the runtime table does not',
    );
  });

  test('the container base image matches the declared ABI floor', () {
    // The natives are compiled on the release runner and only COPIED into the
    // container, so the base image IS the ABI contract. When they disagree the
    // libraries fail `dlopen` and the boot preflight — which probes by loading
    // — calls them MISSING with every file present in the image, an error that
    // reads as a packaging bug and is not one. That shipped once: Debian 12
    // (glibc 2.36) against natives needing GLIBC_2.38/2.39.
    //
    // verify_natives.sh enforces the floor against the actual libraries. This
    // pins the other half — that the floor still describes the image we run.
    final declared = RegExp(
      r'^CC_NATIVES_BASE_IMAGE="([^"]+)"',
      multiLine: true,
    ).firstMatch(matrix);
    expect(
      declared,
      isNotNull,
      reason: 'scripts/lib/natives.sh must declare CC_NATIVES_BASE_IMAGE',
    );
    final dockerfile = File(
      '$root/docker/cc_server/Dockerfile',
    ).readAsStringSync();
    expect(
      RegExp(
        r'^FROM\s+(\S+)',
        multiLine: true,
      ).firstMatch(dockerfile)?.group(1),
      declared!.group(1),
      reason:
          'docker/cc_server/Dockerfile runs a different base image than the '
          'ABI floor in scripts/lib/natives.sh describes. Raising the image '
          'means raising CC_NATIVES_GLIBC_MAX / CC_NATIVES_GLIBCXX_MAX with it '
          '(and lowering it means the natives may no longer load).',
    );
    for (final key in ['CC_NATIVES_GLIBC_MAX', 'CC_NATIVES_GLIBCXX_MAX']) {
      expect(
        matrix,
        contains('$key='),
        reason: 'verify_natives.sh reads $key from the matrix file',
      );
    }
  });

  test('no shell script hardcodes a native list any more', () {
    // The whole point of scripts/lib/natives.sh. cc_server_package.sh used to
    // carry a second, differently-implemented copy.
    final pkg = File(
      '$root/scripts/release/cc_server_package.sh',
    ).readAsStringSync();
    expect(
      pkg,
      isNot(contains('require_native ')),
      reason:
          'cc_server_package.sh reintroduced its own native list; it should '
          'call verify_natives.sh, which reads scripts/lib/natives.sh',
    );
  });

  group('code mode runner', () {
    // cc_codemode is an executable, not an FFI library, so it is not a row in
    // CC_NATIVES (verify_natives.sh matches library file names). It travels
    // like the media helpers instead: built into <natives>/codemode/, staged
    // as bin/codemode/ beside the server executable and checked by
    // scripts/lib/codemode.sh. The server refuses to boot without it, so
    // every path that ships media must ship the runner too.
    List<File> filesUnder(String dir, bool Function(String) keep) => [
      for (final entity in Directory('$root/$dir').listSync(recursive: true))
        if (entity is File && keep(entity.path)) entity,
    ];
    final scripts = filesUnder(
      'scripts',
      (path) =>
          path.endsWith('.sh') &&
          !path.endsWith('/scripts/lib/media.sh') &&
          !path.endsWith('/scripts/lib/codemode.sh'),
    );
    final workflows = filesUnder(
      '.github',
      (path) => path.endsWith('.yml') || path.endsWith('.yaml'),
    );

    test('every script that stages media stages the runner', () {
      final missing = <String>[];
      var mediaStagers = 0;
      for (final file in [...scripts, ...workflows]) {
        final source = file.readAsStringSync();
        final rel = file.path.substring(root.length + 1);
        if (source.contains('cc_media_stage ')) {
          mediaStagers++;
        }
        if (source.contains('cc_media_stage ') &&
            !source.contains('cc_codemode_stage ')) {
          missing.add('$rel stages media but not the code mode runner');
        }
        if (source.contains('cc_media_verify ') &&
            !source.contains('cc_codemode_verify ')) {
          missing.add('$rel verifies media but not the code mode runner');
        }
      }
      // The seven stagers named below; fewer means the scan went blind.
      expect(mediaStagers, greaterThanOrEqualTo(7));
      expect(missing, isEmpty, reason: missing.join('\n'));
    });

    test('the runner is staged at bin/codemode in every package', () {
      for (final path in const [
        'scripts/build_server.sh',
        'scripts/run_desktop.sh',
        'scripts/release/macos_package.sh',
        'scripts/release/linux_package.sh',
        'scripts/release/windows_package.sh',
        'scripts/release/cc_server_package.sh',
        'scripts/release/cc_demo_server_package.sh',
      ]) {
        expect(
          File('$root/$path').readAsStringSync(),
          matches(
            RegExp(r'cc_codemode_stage "\$NATIVES" "[^"]*/bin/codemode"'),
          ),
          reason: '$path does not stage the runner as bin/codemode/',
        );
      }
      expect(
        File('$root/docker/cc_server/Dockerfile').readAsStringSync(),
        contains('test -x /app/bin/codemode/cc_codemode'),
        reason: 'the container image no longer checks for the runner',
      );
    });

    test('every native build produces the runner', () {
      expect(
        File('$root/scripts/natives/build_natives.sh').readAsStringSync(),
        contains(r'bash "$SCRIPT_DIR/build_codemode.sh" "$DEST"'),
      );
      // macOS and Linux: remapped build paths, checked on the built file
      // (with the target directory and cargo home this build used) and
      // verified again on every installed copy.
      final unix = File(
        '$root/scripts/natives/build_codemode.sh',
      ).readAsStringSync();
      for (final snippet in const [
        r'"$CARGO_TARGET_DIR=/build/target"',
        'CARGO_ENCODED_RUSTFLAGS',
        r'cc_codemode_check_paths "$BUILT" "$CODEMODE_OS" "$CARGO_TARGET_DIR" "$CODEMODE_CARGO_HOME"',
        r'cc_codemode_verify "$d" "$CODEMODE_OS"',
      ]) {
        expect(
          unix,
          contains(snippet),
          reason: 'build_codemode.sh lost `$snippet`',
        );
      }
      // Windows builds natives in its own script, where the runner's
      // Windows-only properties are checked rather than trusted.
      final windows = File(
        '$root/scripts/release/windows_natives.sh',
      ).readAsStringSync();
      for (final snippet in const [
        // Static CRT and Control Flow Guard (runner/build.rs refuses a
        // build without them; dumpbin confirms the image).
        '-Ctarget-feature=+crt-static -Ccontrol-flow-guard',
        'CF Instrumented',
        // Imports resolve from System32 only, and only reviewed DLLs.
        "grep -Ei 'dependent load flag'",
        "grep -q '800'",
        '//imports',
        'kernel32.dll | ntdll.dll | advapi32.dll | bcryptprimitives.dll',
        // QuickJS-NG's file names trimmed at the target directory, and the
        // build fails if cl ignored the switch.
        r'/d1trimfile:$CODEMODE_TARGET_W\\',
        "if grep -q 'D9002'",
        // The path check, with the target directory among the prefixes.
        'cc_codemode_check_paths build/natives/codemode/cc_codemode.exe windows',
        r'"$CODEMODE_TARGET_W" "$(cygpath -w "$RUNNER_TEMP")"',
        // The lockdown self-test, on a pipe.
        'cc_codemode.exe --self-test 2>&1)"',
      ]) {
        expect(
          windows,
          contains(snippet),
          reason: 'windows_natives.sh lost `$snippet` from the runner block',
        );
      }
      // Verification, run by every staging step whatever built or cached
      // the runner: a full lockdown, a release build, no build paths.
      final lib = File('$root/scripts/lib/codemode.sh').readAsStringSync();
      final verify = RegExp(
        r'^cc_codemode_verify\(\) \{.*?^\}$',
        multiLine: true,
        dotAll: true,
      ).firstMatch(lib)?.group(0);
      expect(verify, isNotNull, reason: 'cc_codemode_verify is gone');
      for (final snippet in const [
        r'"$exe" --self-test 2>&1',
        '''*'"ok":true'*'"level":"full"'*''',
        '''*'"build":"release"'*)''',
        r'cc_codemode_check_paths "$exe" "$os"',
      ]) {
        expect(
          verify,
          contains(snippet),
          reason: 'cc_codemode_verify lost `$snippet`',
        );
      }
      expect(
        File('$root/scripts/release/windows_package.sh').readAsStringSync(),
        contains(r'"$OUT/cc_server/bin/codemode/cc_codemode.exe"'),
        reason: 'the Authenticode pass no longer signs the runner',
      );
    });

    test('the path check refuses a build machine path', () {
      final dir = Directory.systemTemp.createTempSync('cc_codemode_paths_');
      addTearDown(() => dir.deleteSync(recursive: true));
      // Run from a copy of the library outside the checkout, with no home
      // or cargo home, so only the generic markers can refuse.
      Directory('${dir.path}/lib').createSync();
      for (final name in const ['common.sh', 'natives.sh', 'codemode.sh']) {
        File('$root/scripts/lib/$name').copySync('${dir.path}/lib/$name');
      }
      const script =
          'set -euo pipefail; source lib/common.sh; source lib/codemode.sh; '
          'cc_codemode_check_paths "\$1" "\$2"';
      ProcessResult check(String contents, String os) {
        final exe = File('${dir.path}/runner')..writeAsStringSync(contents);
        return Process.runSync(
          'bash',
          ['-c', script, 'check', exe.path, os],
          workingDirectory: dir.path,
          environment: {'PATH': Platform.environment['PATH'] ?? ''},
          includeParentEnvironment: false,
        );
      }

      // What a remapped release build contains.
      const remapped =
          'x/build/cargo/registry/src/index.crates.io-1949/rquickjs-core/'
          'src/lib.rs y/build/home/z /build/target/release/out/quickjs.c';
      expect(check(remapped, 'linux').exitCode, 0);
      for (final (contents, os) in const [
        ('at /Users/someone/.cargo/x.rs', 'macos'),
        ('at /home/someone/src/x.rs', 'linux'),
        (r'at C:\Users\someone\x.rs', 'windows'),
        // A cargo home outside every home directory.
        ('/opt/ci/cargo/registry/src/index.crates.io-1949/x.rs', 'linux'),
        (r'D:\a\_temp\cargo\registry\src\index.crates.io-1949\x.rs', 'windows'),
      ]) {
        final result = check(contents, os);
        expect(result.exitCode, isNot(0), reason: '$contents passed');
        expect(
          '${result.stdout}${result.stderr}',
          contains("build machine's path"),
        );
      }
    }, skip: Platform.isWindows ? 'needs bash' : null);

    test('a missing runner fails verification naming the path', () {
      final dir = Directory.systemTemp.createTempSync('cc_codemode_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final os = Platform.isMacOS ? 'macos' : 'linux';
      const prelude =
          'set -euo pipefail; source scripts/lib/common.sh; '
          'source scripts/lib/codemode.sh; ';
      final result = Process.runSync('bash', [
        '-c',
        '${prelude}cc_codemode_verify "\$1" $os',
        'verify',
        '${dir.path}/codemode',
      ], workingDirectory: root);
      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('${dir.path}/codemode'));

      Directory('${dir.path}/codemode').createSync();
      final empty = Process.runSync('bash', [
        '-c',
        '${prelude}cc_codemode_stage "\$1" "\$2" $os',
        'stage',
        dir.path,
        '${dir.path}/bundle/bin/codemode',
      ], workingDirectory: root);
      expect(empty.exitCode, isNot(0));
      expect(empty.stderr, contains('${dir.path}/codemode/cc_codemode'));
      expect(
        Directory('${dir.path}/bundle').existsSync(),
        isFalse,
        reason: 'staging must fail before it touches the destination',
      );
    }, skip: Platform.isWindows ? 'needs bash' : null);
  });
}
