import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over the names of the files a release ships.
///
/// These names are a PUBLIC interface, not an internal detail: `cc_server
/// update` matches its download against
/// `cc_server-<ver>-<os>-<arch>.{tar.gz,zip}` (angle brackets are inside the
/// backticks, so they are literal),
/// the Sparkle appcasts embed the desktop names as SIGNED enclosure URLs and
/// SHA256SUMS.txt keys on them. Renaming one breaks already-installed clients.
///
/// scripts/lib/artifact_names.sh is the source; this test pins every other
/// place that names a shipped file against it.
void main() {
  final root = Directory.current.path;
  const version = '9.9.9';

  /// The canonical set, obtained by RUNNING the table rather than re-parsing it.
  late final List<String> names;

  setUpAll(() {
    final result = Process.runSync('bash', [
      'scripts/lib/artifact_names.sh',
      version,
    ], workingDirectory: root);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    names = (result.stdout as String)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  });

  test('the table yields the set for the platforms this release ships', () {
    // The shipped set is RELEASE_PLATFORMS in scripts/lib/artifact_names.sh.
    // This test follows that list rather than pinning a hardcoded set, so
    // adding or dropping a platform is one word in one file.
    expect(
      names,
      containsAll([
        'Control-Center-$version-arm64.dmg',
        'Control-Center-$version-x86_64.AppImage',
        'Control-Center-$version-x86_64.AppImage.zsync',
        'Control-Center-$version-linux-x64.tar.gz',
        'Control-Center-$version-x64-setup.exe',
        'Control-Center-$version-windows-x64.zip',
        'Control-Center-$version-arm64-setup.exe',
        'Control-Center-$version-windows-arm64.zip',
        'cc_server-$version-macos-arm64.tar.gz',
        'cc_server-$version-linux-x64.tar.gz',
        'cc_server-$version-windows-x64.zip',
        'cc_server-$version-windows-arm64.zip',
        'appcast.xml',
        'appcast-windows.xml',
        'appcast-windows-arm64.xml',
      ]),
    );
    expect(names.toSet().length, names.length, reason: 'duplicate asset name');
  });

  test('a disabled platform contributes nothing, anywhere', () {
    // The whole point of deriving from one list: a platform that is off must
    // not appear as an artifact, a Sparkle feed, or a release-note download.
    // Exercised by overriding RELEASE_PLATFORMS rather than by whatever the
    // default happens to be, so this holds however the list is set.
    final windows =
        Process.runSync('bash', [
              '-c',
              'RELEASE_PLATFORMS="macos linux" bash scripts/lib/artifact_names.sh $version',
            ], workingDirectory: root).stdout
            as String;
    expect(windows, isNot(contains('setup.exe')));
    expect(windows, isNot(contains('windows-x64')));
    expect(windows, isNot(contains('windows-arm64')));
    expect(windows, isNot(contains('appcast-windows')));

    // ...and re-enabling it brings everything back, so the switch is real.
    final all =
        Process.runSync('bash', [
              '-c',
              'RELEASE_PLATFORMS="macos linux windows" bash scripts/lib/artifact_names.sh $version',
            ], workingDirectory: root).stdout
            as String;
    expect(all, contains('Control-Center-$version-x64-setup.exe'));
    expect(all, contains('cc_server-$version-windows-x64.zip'));
    expect(all, contains('appcast-windows.xml'));
    // The Arm64 build is its own platform with its own switch: x64 alone
    // ships no Arm64 asset or feed.
    expect(all, isNot(contains('arm64-setup.exe')));
    expect(all, isNot(contains('windows-arm64')));

    final arm =
        Process.runSync('bash', [
              '-c',
              'RELEASE_PLATFORMS="windows-arm64" bash scripts/lib/artifact_names.sh $version',
            ], workingDirectory: root).stdout
            as String;
    expect(
      arm.split('\n').where((l) => l.isNotEmpty).toList(),
      [
        'Control-Center-$version-arm64-setup.exe',
        'Control-Center-$version-windows-arm64.zip',
        'cc_server-$version-windows-arm64.zip',
        'appcast-windows-arm64.xml',
      ],
    );
  });

  test('make_release.sh builds its manifest from the table', () {
    // The release manifest is what turns a missing artifact into a failed job
    // instead of a silently short release, so it must not drift into its own
    // hardcoded list.
    final source = File(
      '$root/scripts/release/make_release.sh',
    ).readAsStringSync();
    expect(
      source,
      contains('source "\$REPO_ROOT/scripts/lib/artifact_names.sh"'),
    );
    expect(source, contains('release_asset_names "\$VERSION"'));
    for (final literal in [
      'Control-Center-\${VERSION}',
      'cc_server-\${VERSION}',
    ]) {
      expect(
        source,
        isNot(contains(literal)),
        reason: 'make_release.sh hardcodes an artifact name; use the table',
      );
    }
  });

  test('the package scripts name their outputs from the table', () {
    const expected = {
      'scripts/release/macos_package.sh': ['dmg'],
      'scripts/release/linux_package.sh': [
        'appimage',
        'appimage-zsync',
        'linux-tarball',
      ],
      'scripts/release/windows_package.sh': [
        'win-setup',
        'win-portable',
        'win-arm64-setup',
        'win-arm64-portable',
      ],
    };
    for (final MapEntry(key: path, value: kinds) in expected.entries) {
      final source = File('$root/$path').readAsStringSync();
      expect(
        source,
        contains('artifact_names.sh'),
        reason: '$path does not source the name table',
      );
      for (final kind in kinds) {
        expect(
          source,
          contains('release_asset_name $kind'),
          reason: '$path does not derive its `$kind` name from the table',
        );
      }
    }
  });

  test('gen_appcast.sh signs the same desktop names', () {
    // A mismatch here is worse than a missing file: the feed would be signed
    // over a URL that 404s and every client would report a broken update.
    final source = File(
      '$root/scripts/release/gen_appcast.sh',
    ).readAsStringSync();
    expect(
      source,
      contains(r'Control-Center-${VERSION}-arm64.dmg'),
      reason: 'gen_appcast.sh no longer matches the artifact name table',
    );
    // The Windows enclosures come from the table itself, one feed per
    // Windows platform, each naming that platform's installer kind.
    expect(source, contains('source "\$REPO_ROOT/scripts/lib/artifact_names.sh"'));
    expect(source, contains(r'release_asset_name "$kind" "$VERSION"'));
    expect(source, contains(r'release_platform_feed "$platform"'));
    for (final row in const [
      '"windows|windows|win-setup"',
      '"windows-arm64|windows-arm64|win-arm64-setup"',
    ]) {
      expect(
        source,
        contains(row),
        reason: 'gen_appcast.sh lost the Windows feed row $row',
      );
    }
    // WinSparkle LAUNCHES the enclosure as an installer; it cannot unpack a
    // zip, so a portable zip must never become an enclosure.
    expect(
      RegExp(r'<enclosure[^>]*\.zip').hasMatch(source) ||
          source.contains('win-portable') ||
          source.contains('win-arm64-portable'),
      isFalse,
      reason: 'the Windows enclosure must be the Inno .exe, not the zip',
    );
  });

  test('both Windows architectures are built, uploaded and collected', () {
    // gen_appcast.sh reads each Windows installer from artifacts/<upload
    // name>/, so the matrix's artifact names, the release job's download
    // pattern and the feed rows must agree, and the Arm64 leg must run on an
    // Arm64 host (Flutter cannot cross-compile Windows).
    final workflow = File(
      '$root/.github/workflows/release.yml',
    ).readAsStringSync();
    for (final snippet in const [
      'runner: windows-latest',
      'runner: windows-11-arm',
      'artifact: windows\n',
      'artifact: windows-arm64\n',
      'server-artifact: cc_server-windows\n',
      'server-artifact: cc_server-windows-arm64\n',
      'arch: \${{ matrix.arch }}',
      'pattern: "{macos,windows,windows-arm64,linux,cc_server-*}"',
      r'windows_package.sh "$VERSION" "$ARCH"',
      r'cc_server_package.sh "$VERSION" windows "$ARCH"',
    ]) {
      expect(
        workflow,
        contains(snippet),
        reason: 'release.yml lost `$snippet` from the Windows build matrix',
      );
    }

    // One Inno script, two installers: the arch picks the gate, the source
    // dir and the asset name the table expects.
    final iss = File(
      '$root/windows/installer/control_center.iss',
    ).readAsStringSync();
    expect(
      iss,
      contains('OutputBaseFilename=Control-Center-{#AppVersion}-{#TargetArch}-setup'),
    );
    expect(iss, contains(r'Source: "build\windows\{#TargetArch}\runner\Release\*"'));
    expect(iss, contains('ArchitecturesAllowed=arm64'));
    expect(iss, contains('ArchitecturesAllowed=x64compatible'));
    expect(
      RegExp(r'^AppId=', multiLine: true).allMatches(iss).length,
      1,
      reason: 'both installers must share one AppId so either upgrades the other',
    );
  });

  test('RELEASING.md documents the same artifacts', () {
    // The "What gets built" table is what a human reads before a release; it
    // drifting from what CI produces is how the doc stopped being trustworthy.
    final doc = File('$root/RELEASING.md').readAsStringSync();
    for (final pattern in const [
      '-arm64.dmg',
      '-x64-setup.exe',
      '-windows-x64.zip',
      '-arm64-setup.exe',
      '-windows-arm64.zip',
      '.AppImage',
      'cc_server-',
      'appcast.xml',
      'appcast-windows.xml',
      'appcast-windows-arm64.xml',
    ]) {
      expect(
        doc,
        contains(pattern),
        reason: 'RELEASING.md never mentions $pattern',
      );
    }
  });
}
