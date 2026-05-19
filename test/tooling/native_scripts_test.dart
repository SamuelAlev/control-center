import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards for the native build scripts, where a merely-wrong guard clause reads
/// exactly like a build failure: `set -euo pipefail` turns any non-zero exit
/// into a stop, so a bad check aborts the build with no useful signal.
///
/// The `build_inference.sh` cases additionally pin the two properties that make
/// statically linking sherpa-onnx + ONNX Runtime safe: the archive is verified
/// before it is linked and none of its symbols escape the dylib.
void main() {
  final root = Directory.current.path;

  group('build_inference.sh', () {
    final source =
        File('$root/scripts/natives/build_inference.sh').readAsStringSync();

    test('pins the sherpa-onnx archive by checksum before linking it', () {
      // The crate's own build script downloads this archive itself, unverified,
      // at build time. We pre-fetch and verify instead: the archive is linked
      // STATICALLY into a shipped artifact, so an unchecked download would be
      // an unaudited third-party binary inside our release.
      expect(
        source,
        contains('sha256_of'),
        reason: 'the pinned-checksum verification was dropped',
      );
      expect(
        source,
        contains('SHERPA_ONNX_LIB_DIR'),
        reason:
            'without this the crate build script downloads its own archive, '
            'defeating the pin',
      );
    });

    test('asserts the statically linked symbols do not leak', () {
      // On Linux the loader resolves symbols globally, first-loaded-wins, so an
      // exported OrtGetApiBase/SherpaOnnx* could interpose on (or be interposed
      // by) another ONNX Runtime in the process. Removing that two-runtimes-one-
      // namespace hazard is the point of this native, so the export restriction
      // in build.rs is verified rather than trusted.
      expect(
        source,
        contains('OrtGetApiBase|SherpaOnnx'),
        reason: 'the symbol-leak assertion was removed from the build script',
      );
      expect(source, contains('cc_embedder_run'), reason: 'ABI check weakened');
      expect(source, contains('cc_asr_transcribe'), reason: 'ABI check weakened');
    });
  });

  group('macos_package.sh', () {
    final source =
        File('$root/scripts/release/macos_package.sh').readAsStringSync();

    test('an absent signing identity reaches the actionable error', () {
      // `security find-identity | grep "Developer ID Application"` exits 1 when
      // there is no match and under `pipefail` that killed the script with NO
      // output — swallowing the carefully written message on the very next
      // line, which names the two ways to fix it. The failure looked like a
      // crash rather than a missing certificate.
      final lookups = RegExp(
        r'IDENTITY="\$\(security find-identity[^\n]*\)"',
      ).allMatches(source);
      expect(
        lookups,
        hasLength(2),
        reason: 'expected the CI (imported keychain) and local lookups',
      );
      for (final match in lookups) {
        expect(
          match.group(0),
          contains('|| true'),
          reason:
              'an identity lookup without `|| true` aborts silently under '
              'pipefail instead of reaching the error message below it:\n'
              '${match.group(0)}',
        );
      }
    });

    test('the unsigned escape hatch cannot be used in CI', () {
      // ALLOW_UNSIGNED exists so `dry_run.sh --skip-sign` can package locally
      // without a Developer ID. It must never be a release path: signing and
      // notarization are required, with no unsigned fallback.
      expect(source, contains(r'ALLOW_UNSIGNED'));
      expect(
        source,
        contains(r'[ -z "${GITHUB_ACTIONS:-}" ]'),
        reason:
            'ALLOW_UNSIGNED lost its CI refusal, so a release could ship an '
            'unsigned, un-notarized DMG',
      );
    });

    test('code nested INSIDE a framework is signed before the framework', () {
      // Signing a framework does not reach the code it contains. Sparkle 2
      // ships four payloads inside Sparkle.framework/Versions/B — Autoupdate,
      // Updater.app and two XPC services — and the CocoaPods build leaves every
      // one AD-HOC signed. Nothing local objects: `codesign --verify --deep
      // --strict` accepts an ad-hoc signature, so the bundle verified, the DMG
      // built and the notary service rejected the submission 15 minutes later
      // as a bare `status: Invalid` naming no file at all.
      expect(
        source,
        contains('sign_nested_code'),
        reason:
            'nested framework code (Sparkle Autoupdate / Updater.app / '
            'XPCServices) would keep its ad-hoc signature and fail notarization',
      );
      final loop = RegExp(
        r'for fw in "\$APP/Contents/Frameworks/"\*\.framework; do\n(.*?)\ndone',
        dotAll: true,
      ).firstMatch(source);
      expect(loop, isNotNull, reason: 'the framework signing loop is gone');
      final body = loop!.group(1)!;
      expect(
        body.indexOf('sign_nested_code'),
        lessThan(body.indexOf(r'sign "$fw"')),
        reason:
            'the framework must be signed LAST — sealing it before its nested '
            'code is signed invalidates the seal',
      );
    });

    test('an ad-hoc or un-hardened Mach-O fails before notarization', () {
      // The check that actually matches what the notary service enforces and
      // the only one that names the offending file. Without it the same class
      // of failure costs a full release run to discover and reports nothing
      // useful when it does.
      expect(
        source,
        contains('adhoc'),
        reason:
            'the pre-notarization sweep for ad-hoc nested code was removed; '
            '`codesign --verify --deep --strict` does NOT catch it',
      );
    });

    test('notarization failure is detected and explained', () {
      // `notarytool submit --wait` EXITS 0 on `status: Invalid` — it reports
      // that the submission finished, not that it passed. Unchecked, the script
      // walked on to `stapler staple`, which failed with
      //   CloudKit query for … failed due to "Record not found"
      // for a DMG that had simply been rejected — a message that sends you
      // debugging stapling instead of signing.
      expect(
        source,
        contains('status: Accepted'),
        reason:
            'nothing checks the notarization verdict, so a rejected DMG only '
            'surfaces as a confusing stapler error',
      );
      expect(
        source,
        contains('xcrun notarytool log'),
        reason:
            'the notary log is the ONLY place that names the offending binary '
            'and the reason it was rejected',
      );
    });

    test('the embedded cc_server is signed with its dart-aot entitlements', () {
      // The Dart AOT runtime maps the snapshot embedded in bin/cc_server as
      // executable memory; the hardened runtime forbids that without
      // allow-unsigned-executable-memory and the kernel SIGKILLs the server
      // at spawn (CODESIGNING: Invalid Page) — after the binary passed strict
      // verification AND notarization. v0.0.1 shipped exactly that: a Dock
      // icon with no window, waiting on a server that could never start.
      expect(
        source,
        contains(
          '--entitlements scripts/release/entitlements/cc_server.entitlements',
        ),
        reason: 'a bare-signed cc_server notarizes and then dies on launch',
      );
    });
  });

  group('cc_server_package.sh', () {
    final source = File(
      '$root/scripts/release/cc_server_package.sh',
    ).readAsStringSync();

    test('the standalone cc_server is signed with its dart-aot entitlements',
        () {
      // Same failure mode as the embedded copy (see the macos_package.sh
      // group): bare hardened signing notarizes and then SIGKILLs on launch.
      expect(
        source,
        contains(r'sign_entitled "$CC_ENTITLEMENTS" "$DIST/bin/cc_server"'),
        reason: 'a bare-signed cc_server notarizes and then dies on launch '
            '(CODESIGNING: Invalid Page)',
      );
    });
  });

  group('entitlements', () {
    test('no entitlements file contains a double hyphen', () {
      // XML forbids `--` inside comments. plutil -lint tolerates it, but the
      // AMFI parser inside codesign does not — the sign step dies with
      // "Failed to parse entitlements: AMFIUnserializeXML: syntax error",
      // 15 CI minutes after the comment was written. Write codesign flags in
      // these comments with a single dash.
      final dir = Directory('$root/scripts/release/entitlements');
      for (final f in dir.listSync().whereType<File>()) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final stripped =
              lines[i].replaceAll('<!--', '').replaceAll('-->', '');
          expect(
            stripped.contains('--'),
            isFalse,
            reason:
                '${f.path}:${i + 1} contains "--", which AMFI rejects inside '
                'an entitlements plist',
          );
        }
      }
    });

    test('cc_server.entitlements carries the dart-aot exception', () {
      final ent = File(
        '$root/scripts/release/entitlements/cc_server.entitlements',
      ).readAsStringSync();
      expect(
        ent,
        contains('com.apple.security.cs.allow-unsigned-executable-memory'),
        reason:
            'without this exception the Dart AOT snapshot mapping is killed '
            'by the hardened runtime',
      );
    });
  });

  group('windows_natives.sh', () {
    final source =
        File('$root/scripts/release/windows_natives.sh').readAsStringSync();

    test('no archive is handed to tar as an -f argument', () {
      // GNU tar reads an -f value containing a colon as a REMOTE archive
      // (`host:path`). Every path Git Bash gets on the runner is rooted at
      // RUNNER_TEMP=`D:\a\_temp`, so `tar xjf "$cache/$archive"` went looking
      // for a machine called `D`:
      //   tar (child): Cannot connect to D: resolve failed
      // and bzip2 then declared the (perfectly good) archive corrupt. Reading
      // from stdin leaves no -f value to misparse.
      // Comments are stripped: the block above documents the broken form
      // verbatim so the next reader knows what it looked like.
      final code = source
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('#'))
          .join('\n');
      expect(
        RegExp(r'tar [a-z]*f\b').hasMatch(code),
        isFalse,
        reason:
            'a Windows path with a drive letter passed as tar -f is read as '
            'host:path. Redirect the archive on stdin instead.',
      );
      expect(
        source,
        contains(r'tar xj -C "$(cygpath -u "$cache")" <"$cache/$archive"'),
        reason:
            'the same tar also refuses the Windows-style directory as its -C '
            r'value ($RUNNER_TEMP is D:\a\_temp): "Cannot open: No such file '
            'or directory". Convert it with cygpath -u so tar only ever sees '
            'a POSIX path.',
      );
    });

    test('MSVC //OUT and //Fo values are backslash (cygpath -w) paths', () {
      // Git Bash rewrites a `//opt` argument to `/opt` only when the remainder
      // contains no forward slash. `//OUT:build/natives/ccpty.dll` reads as a
      // UNC path instead, reaches link.exe verbatim and is IGNORED:
      //   LINK : warning LNK4044: unrecognized option '//OUT:build/natives/ccpty.dll'
      // so the DLL landed in the CWD under the first .obj's name and the
      // export sanity check failed on a file that was never written. The same
      // rule silently breaks a //Fo whose value keeps a forward slash.
      final code = source
          .split('\n')
          .where((l) => !l.trimLeft().startsWith('#'))
          .join('\n');
      expect(
        RegExp(r'//(?:OUT:|Fo)(?!"\$\(cygpath -w )').allMatches(code),
        isEmpty,
        reason:
            'every //OUT: and //Fo value must go through cygpath -w so the '
            'MSVC tool receives an all-backslash path',
      );
    });

    test('webrtc-audio-processing builds as C++20 under MSVC', () {
      // MSVC only accepts the designated initializers WebRTC's agc2 code uses
      // under /std:c++20 (input_volume_stats_reporter.cc: error C7555);
      // GCC/Clang take them as a C++17 extension, so only the Windows build
      // trips it. The abseil-cpp fallback subproject is pinned to the same
      // std so the statically linked archives agree on the standard level.
      expect(
        source,
        contains('-Dcpp_std=c++20 -Dabseil-cpp:cpp_std=c++20'),
        reason:
            'the aec meson setup lost the C++20 std override MSVC needs to '
            'compile WebRTC (designated initializers, error C7555)',
      );
    });

    test('the APM archive is found under its meson name (libfoo.a, not .lib)', () {
      // meson names static libraries libfoo.a even under MSVC — they are
      // ordinary COFF archives link.exe accepts by path — so waiting for an
      // MSVC-flavoured webrtc-audio-processing-2.lib found nothing after a
      // fully successful 440-target build.
      expect(
        source,
        contains(
          r'$SRC/build/webrtc/modules/audio_processing/'
          'libwebrtc-audio-processing-2.a',
        ),
        reason: 'the aec block must look for the .a the meson build emits, '
            'at the same fixed path build_aec.sh uses',
      );
      expect(
        source.contains("-name '*.lib'"),
        isFalse,
        reason: 'dependency archives are .a under meson-on-MSVC too',
      );
    });

    test('webrtc archives and the aec shim agree on the static CRT', () {
      // meson's release default compiles /MD; the shim — like every other
      // Windows native here — is /MT because the standalone cc_server zip
      // ships no VC++ runtime. Mixing them fails the aec_ffi.dll link with
      // LNK2038 "RuntimeLibrary: MD_DynamicRelease doesn't match
      // MT_StaticRelease" for every object in the archive.
      expect(
        source,
        contains('-Db_vscrt=mt'),
        reason: 'the aec meson setup lost the static-CRT override',
      );
    });

    test('the lame link pulls in the split-off HIP decoder archive', () {
      // vcpkg's static mp3lame splits the HIP/mpglib decoder into its own
      // libmpghip-static.lib; libmp3lame-static.lib(mpglib_interface.obj)
      // references its InitMP3/decodeMP3/tabsel_123/… symbols, so linking
      // only *mp3lame*.lib dies with 6 unresolved externals (LNK2019).
      expect(
        source,
        contains('mpghip'),
        reason: 'the lame block lost the libmpghip-static.lib discovery/link',
      );
    });

    test('the aec link pulls in winmm for timeGetTime', () {
      // rtc::SystemTimeNanos calls timeGetTime, which lives in winmm.dll —
      // the one system symbol the whole-archived APM objects reach outside
      // the default lib set. Without winmm.lib the aec_ffi.dll link dies
      // with LNK2019 __imp_timeGetTime.
      expect(
        source,
        contains('winmm.lib'),
        reason: 'the aec link line lost winmm.lib',
      );
    });

    test('each native block reports the command that actually failed', () {
      // `( … ) || { echo ERROR; exit 1; }` reads like a guard but disables
      // errexit for the WHOLE subshell — bash ignores -e inside any command
      // whose status is being tested, even if the subshell sets -e itself. So
      // the block ran on past the first failure and reported whatever broke
      // last: a tar that could not open its archive surfaced three minutes
      // later as a sherpa-onnx-sys panic about a missing SHERPA_ONNX_LIB_DIR,
      // which reads like a bad pin and is not.
      expect(
        RegExp(r'\)\s*\|\|\s*\{\s*echo "ERROR').hasMatch(source),
        isFalse,
        reason:
            'this guard shape suppresses errexit inside the subshell. Use a '
            'plain subshell with an EXIT trap for the human-facing message.',
      );
      // Every required native still names itself when its block fails.
      for (final native in const [
        'fff_c.dll',
        'cc_watcher.dll',
        'cc_saml.dll',
        'cc_inference.dll',
        'ccpty.dll',
        'tree-sitter.dll',
        'aec_ffi.dll',
        'lame_ffi.dll',
      ]) {
        expect(
          RegExp(r'trap .*\$\? -eq 0 .*' + RegExp.escape(native)).hasMatch(source),
          isTrue,
          reason: '$native lost the EXIT trap that names it on failure',
        );
      }
    });

    test("MSVC's link.exe wins over Git's coreutils `link`", () {
      // Git for Windows ships /usr/bin/link.exe (the coreutils hardlink tool)
      // and Git Bash puts /usr/bin ahead of everything vcvarsall prepended.
      // rustc and the bare `link //DLL` calls resolve the linker BY NAME, so
      // every link in the script picked up coreutils and the build died on the
      // first crate with "/usr/bin/link: extra operand '…rcgu.o'" — under a
      // rustc note suggesting the MSVC install needs repairing, which it did
      // not. cl.exe is unique to MSVC and link.exe sits beside it.
      expect(
        source,
        contains(r'MSVC_BIN="$(dirname "$(command -v cl)")"'),
        reason: 'the MSVC bin directory is no longer resolved from cl.exe',
      );
      expect(
        source,
        contains(r'export PATH="$MSVC_BIN:$PATH"'),
        reason:
            'without MSVC ahead of /usr/bin, `link` is Git\'s hardlink tool '
            'and every native link fails',
      );
      expect(
        source,
        contains(r'[ "$LINK_DIR" = "$MSVC_BIN" ]'),
        reason:
            'the assertion is what keeps a future PATH change from quietly '
            'reintroducing a 4-minute-to-fail build',
      );
    });
  });

  group('windows_package.sh', () {
    final source = File(
      '$root/scripts/release/windows_package.sh',
    ).readAsStringSync();

    test('the ISCC define uses the // escape Git Bash cannot path-mangle', () {
      // A single-slash "/DAppVersion=…" is POSIX-path-converted by Git Bash
      // into "C:/Program Files/Git/DAppVersion=…", which ISCC reads as a
      // SECOND script filename: "You may not specify more than one script
      // filename." The // escape collapses to one slash because the
      // remainder is slash-free.
      expect(
        source,
        contains(r'"//DAppVersion=$VERSION"'),
        reason: 'the ISCC version define lost its // escape',
      );
    });
  });

  group('natives_common.sh', () {
    final source = File(
      '$root/scripts/natives/lib/natives_common.sh',
    ).readAsStringSync();

    test('pinned clones retry transient fetch failures', () {
      // gitlab.freedesktop.org (webrtc-audio-processing) answers a fraction
      // of clones with "remote: GitLab is not responding" / HTTP 502. Every
      // native is boot-required, so one flaky fetch used to abort a
      // 20-minute release run on the spot instead of waiting out the blip.
      expect(
        source,
        contains('for attempt in 1 2 3'),
        reason: 'git_clone_pinned lost its fetch retry loop',
      );
    });
  });
}
