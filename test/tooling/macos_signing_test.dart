import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over how the macOS **Release** build signs itself.
///
/// The release pipeline signs AFTER Xcode: `macos_package.sh` re-signs the whole
/// bundle inside-out with Developer ID, embeds the provisioning profile, applies
/// `Runner/Release.entitlements`, notarizes and staples. Xcode's signature is
/// replaced wholesale, so the Release configuration must not try to produce a
/// real one — it cannot on a CI runner and it does not need to anywhere.
///
/// Both halves of that failed a release separately:
///   * `"Apple Development"` + `DEVELOPMENT_TEAM` → Xcode looked for a Mac
///     Development provisioning profile no runner has ("No profiles for
///     'com.alev.control-center' were found").
///   * `CODE_SIGN_ENTITLEMENTS` → pulled in `keychain-access-groups`, a
///     RESTRICTED entitlement that requires a provisioning profile even under
///     manual signing ("Runner requires a provisioning profile").
///
/// Xcode rewrites project.pbxproj whenever the project is opened and edited, so
/// these settings can come back without anyone deciding they should.
void main() {
  final root = Directory.current.path;
  final pbxproj = File(
    '$root/macos/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();

  /// The SETTINGS of one `XCBuildConfiguration` block, by object id, with
  /// `/* … */` comments stripped.
  ///
  /// The comments matter: the Release block explains at length why it does NOT
  /// use `DEVELOPMENT_TEAM`, `CODE_SIGN_ENTITLEMENTS` or an "Apple Development"
  /// identity — and naming them there would satisfy a naive `contains` check
  /// for the very settings this file asserts are absent.
  String configBody(String id) {
    final start = pbxproj.indexOf('\t\t$id /*');
    expect(start, isNot(-1), reason: 'build configuration $id is gone');
    final end = pbxproj.indexOf('\n\t\t};', start);
    return pbxproj
        .substring(start, end)
        .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  }

  // Resolved from the XCConfigurationList of each target; see the ids in
  // project.pbxproj. Pinned by id rather than by name because every target has
  // a configuration called "Release".
  const runnerRelease = '33CC10FD2044A3C60003C045';
  const runnerDebug = '33CC10FC2044A3C60003C045';
  const flutterAssembleRelease = '33CC111D2044C6BA0003C045';

  group('Runner Release configuration', () {
    test('signs ad-hoc, not with a real identity', () {
      final body = configBody(runnerRelease);
      expect(
        body,
        contains('"CODE_SIGN_IDENTITY[sdk=macosx*]" = "-"'),
        reason:
            'the Release build must sign ad-hoc. A real identity makes Xcode '
            'demand a provisioning profile that CI does not have and the '
            'signature is replaced by macos_package.sh anyway.',
      );
      expect(
        body,
        isNot(contains('Apple Development')),
        reason:
            'Apple Development is a local-dev identity; Release must not use it',
      );
    });

    test('does not request automatic provisioning', () {
      final body = configBody(runnerRelease);
      expect(body, contains('CODE_SIGN_STYLE = Manual'));
      expect(
        body,
        isNot(contains('DEVELOPMENT_TEAM')),
        reason:
            'a DEVELOPMENT_TEAM on Release sends Xcode looking for a matching '
            'provisioning profile',
      );
      expect(body, isNot(contains('PROVISIONING_PROFILE')));
    });

    test('carries no entitlements — the packaging script applies them', () {
      final body = configBody(runnerRelease);
      expect(
        body,
        isNot(contains('CODE_SIGN_ENTITLEMENTS')),
        reason:
            'Release.entitlements contains keychain-access-groups, a RESTRICTED '
            'entitlement that requires a provisioning profile even under manual '
            'signing. macos_package.sh passes it to codesign instead.',
      );
    });

    test('ad-hoc, not signing-disabled', () {
      // An unsigned arm64 binary does not execute at all, so a --skip-sign dry
      // run or a local release build would produce something unlaunchable.
      final body = configBody(runnerRelease);
      expect(body, isNot(contains('CODE_SIGNING_ALLOWED = NO')));
      expect(body, isNot(contains('CODE_SIGNING_REQUIRED = NO')));
    });
  });

  test('macos_package.sh is the one applying the entitlements', () {
    // The other half of the contract above: if Xcode stops applying them and
    // the script never starts, the shipped app silently loses its keychain
    // access group and secure storage breaks at runtime.
    final script = File(
      '$root/scripts/release/macos_package.sh',
    ).readAsStringSync();
    expect(
      script,
      contains('--entitlements macos/Runner/Release.entitlements'),
      reason:
          'nothing would apply Release.entitlements to the shipped app, so the '
          'team-prefixed keychain-access-group would be missing',
    );
  });

  test('the app bundle Frameworks/ gets code and nothing else', () {
    // codesign's default rules treat an app bundle's Contents/Frameworks/ as a
    // NESTED CODE location: every file there is validated as code. One
    // tree-sitter query staged beside the grammar dylibs was enough to fail the
    // whole bundle signature with "code object is not signed at all — In
    // subcomponent: …/Contents/Frameworks/dart.scm", after every nested
    // framework had already been signed.
    //
    // The queries are not lost: GrammarManager falls back to
    // `embeddedTreeSitterQueries` (pinned to the same .scm files by
    // embedded_queries_test.dart) and the cc_server bundle under Resources/ —
    // where indexing actually runs and which is NOT a nested-code location —
    // still carries the on-disk copies.
    final script = File(
      '$root/scripts/release/macos_package.sh',
    ).readAsStringSync();
    expect(
      script,
      contains(
        r'stage_natives "$NATIVES" "$APP/Contents/Frameworks" dylib no-queries',
      ),
      reason:
          'staging the .scm queries into Contents/Frameworks/ fails codesign '
          'on the app bundle itself',
    );
  });

  group('standalone cc_server archive', () {
    // The desktop DMG and the standalone server archive are signed by two
    // different scripts and the server one shipped a REJECTED build as a
    // release asset: `cc_server_package.sh` stages the vendored code-server
    // (a whole Node runtime plus compiled *.node addons) into the bundle and
    // then signed only `Frameworks/*.dylib`, `lib/*.dylib` and the executable.
    // Notarization came back `status: Invalid`, notarytool exited 0 anyway and
    // the script archived, checksummed and reported success.
    final script = File(
      '$root/scripts/release/cc_server_package.sh',
    ).readAsStringSync();

    test('signs every Mach-O it finds, not a fixed list of directories', () {
      expect(
        script,
        contains(r'machos() { find '),
        reason:
            'the signing pass must enumerate the archive. A glob over the two '
            'directories we happen to remember stops covering it the moment '
            'anything else is staged in — which is exactly what code-server did.',
      );
      expect(
        script,
        contains(r'''sed -n 's/^CodeDirectory .*flags=[^(]*(\([^)]*\)).*/\1/p' '''),
        reason:
            'without the per-file adhoc/hardened-runtime check the only signal '
            'that something is unsigned is a bare `status: Invalid` from the '
            'notary service 15 minutes later, naming no file',
      );
    });

    test('treats `status: Invalid` as a failure', () {
      // `notarytool submit --wait` reports that the SUBMISSION completed, not
      // that it passed and exits 0 either way.
      expect(
        script,
        contains("grep -q 'status: Accepted'"),
        reason:
            'notarytool exits 0 on a rejected submission, so an unchecked '
            'submit ships an un-notarized archive with a green CI run',
      );
      expect(
        script,
        contains('xcrun notarytool log'),
        reason:
            'the notary log is the only place that names the offending binary',
      );
    });

    test('the vendored node keeps its hardened-runtime exceptions', () {
      // Signing node with the hardened runtime and no entitlements is
      // notarizable and unrunnable: V8 cannot allocate executable memory, so
      // code-server dies at startup instead of at the notary.
      const path = 'scripts/release/entitlements/code_server.entitlements';
      expect(script, contains(path));
      final entitlements = File('$root/$path').readAsStringSync();
      for (final key in const [
        'com.apple.security.cs.allow-jit',
        'com.apple.security.cs.allow-unsigned-executable-memory',
        'com.apple.security.cs.disable-library-validation',
      ]) {
        expect(entitlements, contains(key));
      }
    });
  });

  test('Debug keeps automatic signing for local development', () {
    // Contributors sign with their own (possibly free) Apple team so the
    // data-protection keychain works — see RELEASING.md, "Local development
    // signing". Release being ad-hoc must not have leaked into Debug.
    final body = configBody(runnerDebug);
    expect(
      body,
      contains('CODE_SIGN_ENTITLEMENTS = Runner/DebugProfile.entitlements'),
    );
    expect(body, contains('DEVELOPMENT_TEAM'));
  });

  test('Flutter Assemble signs manually in every configuration', () {
    // Release was the lone Automatic one, which is the other half of the
    // automatic provisioning the release build must not attempt.
    expect(
      configBody(flutterAssembleRelease),
      contains('CODE_SIGN_STYLE = Manual'),
    );
  });
}
