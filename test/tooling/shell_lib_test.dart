import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contract tests for the shared shell library, `scripts/lib/common.sh`.
///
/// These run the functions for real in bash rather than grepping the source,
/// because the bug that motivated them was invisible in the text: a helper that
/// RETURNS a value on stdout also logged to stdout, so the caller captured the
/// log line prepended to the value. It only appears when the logging branch is
/// actually taken.
void main() {
  final root = Directory.current.path;

  /// Runs a bash snippet with the library sourced and returns (stdout, stderr).
  (String, String) run(String script) {
    final program =
        'set -euo pipefail\nREPO_ROOT="$root"\ncd "\$REPO_ROOT"\n'
        'source scripts/lib/common.sh\n$script';
    final result = Process.runSync('bash', [
      '-c',
      program,
    ], workingDirectory: root);
    return (result.stdout as String, result.stderr as String);
  }

  group('ensure_cc_server_bundle', () {
    test('returns ONLY the bundle path when the bundle already exists', () {
      final tmp = Directory.systemTemp.createTempSync('cc_bundle_fast');
      addTearDown(() => tmp.deleteSync(recursive: true));
      // Pre-create the bundle so the build branch is skipped.
      final bundle = Directory(
        '${tmp.path}/apps/cc_server/build/cli/macos_arm64/bundle/bin',
      )..createSync(recursive: true);
      File('${bundle.path}/cc_server').writeAsStringSync('#!/bin/sh\n');

      final (out, _) = run(
        'cd "${tmp.path}"\n'
        'ensure_cc_server_bundle macos',
      );
      expect(
        out.trim(),
        'apps/cc_server/build/cli/macos_arm64/bundle',
        reason: 'stdout must be the path and nothing else',
      );
    });

    test('keeps its build logging OFF stdout when it has to build', () {
      // THE regression. A fake `dart` stands in for the real toolchain: it
      // creates the bundle exactly like `dart build cli` would, so the logging
      // branch runs. Before the fix stdout was:
      //   ==> building cc_server cli bundle (macos)
      //   apps/cc_server/build/cli/macos_arm64/bundle
      // and the caller's `cp -R "$CC_SERVER_BUNDLE/."` failed with
      //   cp: ==> building cc_server cli bundle (macos) ...: No such file or directory
      final tmp = Directory.systemTemp.createTempSync('cc_bundle_build');
      addTearDown(() => tmp.deleteSync(recursive: true));
      Directory('${tmp.path}/apps/cc_server').createSync(recursive: true);
      // resolve_dart prefers \$REPO_ROOT/.fvm/flutter_sdk/bin/dart, so planting
      // the stand-in there exercises the real resolution path.
      Directory('${tmp.path}/.fvm/flutter_sdk/bin').createSync(recursive: true);
      File('${tmp.path}/.fvm/flutter_sdk/bin/dart').writeAsStringSync(
        '#!/bin/sh\n'
        '# stands in for `dart build cli`, run from apps/cc_server\n'
        'mkdir -p build/cli/macos_arm64/bundle/bin\n'
        'printf "#!/bin/sh\\n" > build/cli/macos_arm64/bundle/bin/cc_server\n'
        'chmod +x build/cli/macos_arm64/bundle/bin/cc_server\n'
        'echo "chatter on stdout from the build itself"\n',
      );
      Process.runSync('chmod', ['+x', '${tmp.path}/.fvm/flutter_sdk/bin/dart']);

      final (out, err) = run(
        'cd "${tmp.path}"\n'
        'REPO_ROOT="${tmp.path}"\n'
        'ensure_cc_server_bundle macos',
      );
      // The build really ran (so the logging branch was taken)...
      expect(
        File(
          '${tmp.path}/apps/cc_server/build/cli/macos_arm64/bundle/bin/cc_server',
        ).existsSync(),
        isTrue,
        reason: 'the stand-in build did not run, so this proves nothing',
      );
      // ...and both it and the log line went to stderr.
      expect(err, contains('building cc_server cli bundle'));
      expect(err, contains('chatter on stdout from the build itself'));
      expect(
        out.trim(),
        'apps/cc_server/build/cli/macos_arm64/bundle',
        reason:
            'stdout is this function\'s return value; the build log and the '
            'build tool\'s own output both belong on stderr',
      );
    });
  });

  group('scratch_dir', () {
    test('the directory survives in the CALLER shell', () {
      // It shipped as `secrets="$(scratch_dir)"`, which self-destructs:
      // command substitution runs in a SUBSHELL, so the `trap … EXIT`
      // registered inside it fires the instant that subshell exits and removes
      // the directory before the caller writes anything. One line later:
      //   macos_package.sh: line 98: /var/folders/…/tmp.XXXX/cert.p12:
      //   No such file or directory
      final (out, _) = run(r"""
        scratch_dir
        d="$SCRATCH_DIR"
        [ -d "$d" ] || { echo "GONE"; exit 1; }
        printf 'secret' > "$d/cert.p12"
        printf 'ok:%s\n' "$(cat "$d/cert.p12")"
      """);
      expect(out.trim(), 'ok:secret');
    });

    test('it is removed when the shell exits', () {
      // The other half of the contract — decoded certificates and private keys
      // must not survive the script on a developer's machine.
      final (out, _) = run(r"""
        d="$(bash -c 'set -euo pipefail
          REPO_ROOT="$PWD"
          source scripts/lib/common.sh
          scratch_dir
          printf "%s" "$SCRATCH_DIR"')"
        [ -d "$d" ] && echo "LEAKED" || echo "cleaned"
      """);
      expect(out.trim(), 'cleaned');
    });

    test('no caller captures it with command substitution', () {
      // The broken form is easy to reintroduce because it reads naturally.
      for (final path in const [
        'scripts/release/macos_package.sh',
        'scripts/release/cc_server_package.sh',
        'scripts/release/windows_package.sh',
      ]) {
        expect(
          File('$root/$path').readAsStringSync(),
          isNot(contains(r'$(scratch_dir)')),
          reason:
              '$path captures scratch_dir in a subshell, so the directory is '
              'deleted before it is used. Call it, then read \$SCRATCH_DIR.',
        );
      }
    });
  });

  test('every value-returning helper keeps stdout clean', () {
    // The same contract for the rest of the library. Each of these is captured
    // with $(...) somewhere in the release scripts.
    final (out, _) = run('''
      p="\$(cc_platform)"
      d="\$(cc_cli_dir linux)"
      e="\$(cc_lib_ext windows)"
      printf '%s|%s|%s\\n' "\$p" "\$d" "\$e"
    ''');
    expect(
      out.trim(),
      matches(RegExp(r'^(macos|linux|windows)\|linux_x64\|dll$')),
    );
  });

  test('sha256_of returns a bare digest for a path containing a backslash', () {
    // THE Windows release break. Both `sha256sum` and `shasum` ESCAPE a
    // filename that contains a backslash or newline: they prefix the whole
    // output line with `\` and double the backslashes. `… | awk '{print $1}'`
    // therefore returned `\<digest>`, which matches no pin.
    //
    // Every path Git Bash is handed on the Windows runner is rooted at
    // `RUNNER_TEMP=D:\a\_temp`, so the v0.0.1 release failed on its own
    // checksum with the digest RIGHT THERE in the message:
    //   ERROR: sherpa-onnx archive sha256 mismatch: got \b7080b6f470bac96…
    //   ERROR: cc_inference.dll not built — cc_server REFUSES TO BOOT without it
    // Feeding the file on stdin keeps the filename out of the output entirely.
    final tmp = Directory.systemTemp.createTempSync('cc_sha_escape');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final file = File('${tmp.path}/we\\ird\\name.bin')
      ..writeAsStringSync('hello');

    final (out, _) = run('sha256_of "${file.path.replaceAll(r'\', r'\\')}"');
    expect(
      out.trim(),
      // sha256("hello")
      '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824',
      reason:
          'sha256_of must return the digest and nothing else. A leading `\\` '
          'means the filename is being passed as an argument again, which '
          'breaks every pinned download on the Windows runner.',
    );
  });

  test('load_native_pins survives a CRLF checkout', () {
    // The Windows release runner checks the tree out with CRLF endings. Git
    // Bash ignores a trailing CR when it PARSES a script, so every .sh still
    // ran and this looked safe — but `read` hands the CR straight through as
    // DATA, so each blank line here arrived as the variable name CR and
    // `${!key}` aborted the whole Windows build with a bare
    // ": invalid variable name" naming neither the file nor the key.
    final tmp = Directory.systemTemp.createTempSync('cc_pins_crlf');
    addTearDown(() => tmp.deleteSync(recursive: true));
    Directory('${tmp.path}/scripts/lib').createSync(recursive: true);
    File('${tmp.path}/scripts/lib/native_pins.env').writeAsStringSync(
      File('$root/scripts/lib/native_pins.env')
          .readAsStringSync()
          .replaceAll('\n', '\r\n'),
    );

    final (out, err) = run(
      'REPO_ROOT="${tmp.path}"\n'
      'load_native_pins\n'
      r"printf '%s|%s\n' "
      r'"$FFF_REF" "$LAME_VERSION"',
    );
    expect(err, isNot(contains('invalid variable name')));
    // The value must come through CR-free too: a ref with a trailing CR clones
    // nothing and a version with one builds a URL that 404s.
    expect(out.trim(), matches(RegExp(r'^[0-9a-f]{40}\|[0-9.]+$')));
  });

  test('everything bash reads is pinned to LF', () {
    // The other half of the fix above: keep the CRs out of the checkout in the
    // first place. Without these, a Windows tree gets CRLF for every text file
    // and only the data files (which `read` does not sanitise) misbehave.
    final attrs = File('$root/.gitattributes').readAsStringSync();
    for (final glob in const ['*.sh', '*.env', '*.scm']) {
      expect(
        attrs,
        matches(RegExp('^${RegExp.escape(glob)}\\s+.*eol=lf', multiLine: true)),
        reason:
            '.gitattributes no longer pins $glob to LF, so a Windows checkout '
            'can hand bash CRs in data it reads.',
      );
    }
  });

  test('load_native_pins strips the inline version comment', () {
    // Renovate needs `KEY=<sha> # vX.Y.Z` on one line; the loader must not put
    // the comment into the value, or every clone URL/ref would carry it.
    final (out, _) = run(r'''
      load_native_pins
      printf '%s\n' "$FFF_REF"
    ''');
    expect(out.trim(), matches(RegExp(r'^[0-9a-f]{40}$')));
  });
}
