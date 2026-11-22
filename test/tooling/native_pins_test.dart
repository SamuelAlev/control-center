import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over the pinned third-party native sources.
///
/// Every `*_REF` used to exist twice — a `${X_REF:-<sha>}` default in the build
/// script AND an `env:` entry in release.yml so the Windows job saw the same
/// value. `WAP_REF` managed three copies, while RELEASING.md described "both
/// copies". A half-applied bump builds one platform from one commit and the
/// other from another, which is the kind of difference that shows up as a
/// mysterious per-platform crash rather than a build failure.
///
/// scripts/lib/native_pins.env is now the only home for a pinned native ref.
/// renovate.json's custom managers target it for those refs.
void main() {
  final root = Directory.current.path;
  final pinsFile = File('$root/scripts/lib/native_pins.env');
  final pins = pinsFile.readAsLinesSync();

  /// KEY -> value, parsed exactly the way load_native_pins does (strip the
  /// trailing ` # vX.Y.Z`, then trim).
  final values = <String, String>{
    for (final line in pins)
      if (line.trim().isNotEmpty && !line.trimLeft().startsWith('#'))
        line.split('=').first.trim(): line
            .substring(line.indexOf('=') + 1)
            .split('#')
            .first
            .trim(),
  };

  group('FFmpeg release pin', () {
    final release = values['FFMPEG_MEDIA_BTBN_RELEASE']!;

    test('reaches the October 31 baseline by November 1 UTC', () {
      expect(
        _ffmpegMeetsBaseline(release, DateTime.now().toUtc()),
        isTrue,
        reason:
            'From 2026-11-01 00:00 UTC, FFmpeg must use the 2026-10-31 '
            'BtbN build or a newer month-end build. Update the release, build, '
            'publisher checksums and recipe/source commits together; '
            'do not extend the deadline. Current pin: $release',
      );
    });

    test('uses a retained month-end build', () {
      expect(
        _ffmpegUsesMonthEndBuild(release, DateTime.now().toUtc()),
        isTrue,
        reason:
            'BtbN retains month-end builds for two years. Only '
            '$_temporaryFfmpegRelease is allowed as a daily workaround, '
            'and only through 2026-10-31 UTC. Current pin: $release',
      );
    });

    test('expires the daily workaround at the UTC deadline', () {
      final before = DateTime.utc(2026, 10, 31, 23, 59, 59, 999, 999);
      final deadline = DateTime.utc(2026, 11, 1);
      expect(_ffmpegMeetsBaseline(_temporaryFfmpegRelease, before), isTrue);
      expect(_ffmpegUsesMonthEndBuild(_temporaryFfmpegRelease, before), isTrue);
      expect(_ffmpegMeetsBaseline(_temporaryFfmpegRelease, deadline), isFalse);
      expect(
        _ffmpegUsesMonthEndBuild(_temporaryFfmpegRelease, deadline),
        isFalse,
      );
      const retainedRelease = 'autobuild-2026-10-31-13-03';
      expect(_ffmpegMeetsBaseline(retainedRelease, deadline), isTrue);
      expect(_ffmpegUsesMonthEndBuild(retainedRelease, deadline), isTrue);
    });

    test('rejects an older month-end baseline after the deadline', () {
      expect(
        _ffmpegMeetsBaseline(
          'autobuild-2026-09-30-13-08',
          DateTime.utc(2026, 11, 1),
        ),
        isFalse,
      );
    });

    test('recognizes calendar month ends including leap years', () {
      final now = DateTime.utc(2026, 11, 1);
      for (final (release, retained) in [
        ('autobuild-2026-11-30-13-03', true),
        ('autobuild-2026-12-31-13-03', true),
        ('autobuild-2027-02-28-13-03', true),
        ('autobuild-2028-02-29-13-03', true),
        ('autobuild-2026-10-30-13-03', false),
        ('autobuild-2026-11-29-13-03', false),
        ('autobuild-2028-02-28-13-03', false),
      ]) {
        expect(
          _ffmpegUsesMonthEndBuild(release, now),
          retained,
          reason: release,
        );
      }
    });

    test('does not extend the exception to another daily build', () {
      expect(
        _ffmpegUsesMonthEndBuild(
          'autobuild-2026-10-16-13-03',
          DateTime.utc(2026, 10, 16),
        ),
        isFalse,
      );
    });
  });

  test('the pin file parses into plain KEY=value pairs', () {
    // The format is deliberately dumb so bash can source it and Renovate can
    // regex it. A quoted value or a shell expansion would break one or both.
    expect(values, isNotEmpty);
    for (final MapEntry(key: k, value: v) in values.entries) {
      expect(
        k,
        matches(RegExp(r'^[A-Z][A-Z0-9_]*$')),
        reason: '$k is not a plain env key',
      );
      expect(v, isNot(contains('"')), reason: '$k must not be quoted');
      expect(v, isNot(contains(r'$')), reason: '$k must not use expansion');
    }
  });

  test('every ref carries the version comment Renovate compares against', () {
    // Renovate matches `<KEY> … <40-hex digest> … <vX.Y.Z>` on ONE line: the
    // digest is what it rewrites, the version is the currentValue it compares
    // to upstream tags. Move the comment to its own line and the manager
    // silently stops matching — the pin then never updates again, with no error.
    for (final line in pins) {
      final match = RegExp(r'^([A-Z][A-Z0-9_]*_REF)=').firstMatch(line);
      if (match == null) {
        continue;
      }
      expect(
        line,
        matches(RegExp(r'_REF=[0-9a-f]{40} # v[0-9]')),
        reason:
            '${match.group(1)} has no inline `# vX.Y.Z` comment, so its '
            'renovate.json custom manager will not match it',
      );
    }
  });

  test('every pinned ref is a full 40-char commit SHA', () {
    final refs = values.entries.where((e) => e.key.endsWith('_REF'));
    expect(refs, isNotEmpty);
    for (final MapEntry(key: k, value: v) in refs) {
      expect(
        v,
        matches(RegExp(r'^[0-9a-f]{40}$')),
        reason: '$k is not a full commit SHA — a tag or short SHA is mutable',
      );
    }
  });

  test('no other build file hardcodes a native ref or checksum', () {
    // The GitHub Actions `uses:` pins are 40-hex too and are legitimately
    // Renovate-managed in place, so only the native-pin NAMES are searched.
    final names = values.keys.where((k) => k.endsWith('_REF')).toList();
    final searched = [
      'scripts/natives/build_rift.sh',
      'scripts/natives/build_fff.sh',
      'scripts/natives/build_tree_sitter.sh',
      'scripts/natives/build_aec.sh',
      'scripts/natives/build_lame.sh',
      'scripts/release/windows_natives.sh',
      'scripts/release/linux_package.sh',
      '.github/workflows/release.yml',
      '.github/workflows/natives.yml',
    ];
    for (final path in searched) {
      final source = File('$root/$path').readAsStringSync();
      for (final name in names) {
        // `NAME=<40 hex>` or `NAME: <40 hex>` — an assignment, not a mention.
        expect(
          RegExp('$name\\s*[:=]\\s*[0-9a-f]{40}').hasMatch(source),
          isFalse,
          reason:
              '$path assigns $name directly. Pins live in '
              'scripts/lib/native_pins.env so a Renovate bump lands everywhere '
              'at once; read them with load_native_pins.',
        );
      }
    }
  });

  test('the AppImage tool is pinned to a tagged release, not `continuous`', () {
    // `continuous` is rebuilt in place, so it was both unverifiable and able to
    // change under a release with no commit in this repo — in a pipeline where
    // the LAME tarball is SHA256-verified and every git source is commit-pinned.
    expect(values['APPIMAGETOOL_URL'], isNotNull);
    expect(
      values['APPIMAGETOOL_URL'],
      isNot(contains('/continuous/')),
      reason: 'appimagetool must come from an immutable tagged release',
    );
    expect(
      values['APPIMAGETOOL_SHA256'],
      matches(RegExp(r'^[0-9a-f]{64}$')),
      reason: 'appimagetool needs a SHA-256 to verify the download against',
    );
    expect(
      File('$root/scripts/release/linux_package.sh').readAsStringSync(),
      contains(r'fetch_pinned "$APPIMAGETOOL_URL" "$APPIMAGETOOL_SHA256"'),
      reason: 'linux_package.sh must verify the download, not just fetch it',
    );
  });

  test('the AppImage runtime is pinned too, and handed to appimagetool', () {
    // appimagetool 1.9.1 fetches the runtime (the ELF stub every AppImage
    // starts with) from type2-runtime's `continuous` release on each run
    // unless it is given --runtime-file, so pinning the tool alone left the
    // artifact's first megabyte unpinned.
    final url = values['APPIMAGE_RUNTIME_URL'];
    expect(url, isNotNull);
    expect(url, isNot(contains('/continuous/')));
    final tag = RegExp(r'/releases/download/([^/]+)/').firstMatch(url!);
    expect(tag, isNotNull, reason: 'APPIMAGE_RUNTIME_URL names no release tag');
    expect(
      values['APPIMAGE_RUNTIME_SHA256'],
      matches(RegExp(r'^[0-9a-f]{64}$')),
    );
    final pkg = File(
      '$root/scripts/release/linux_package.sh',
    ).readAsStringSync();
    expect(
      pkg,
      contains(
        r'fetch_pinned "$APPIMAGE_RUNTIME_URL" "$APPIMAGE_RUNTIME_SHA256"',
      ),
    );
    expect(pkg, contains(r'--runtime-file "$RUNTIME"'));
    // The license table names the version that actually ships.
    expect(
      File('$root/scripts/lib/third_party.sh').readAsStringSync(),
      contains('"AppImage runtime|${tag!.group(1)}|'),
    );
    expect(
      File('$root/renovate.json').readAsStringSync(),
      contains('APPIMAGE_RUNTIME_URL'),
      reason: 'the runtime pin has no renovate.json custom manager',
    );
  });

  test('every ref has a renovate custom manager pointed at the pin file', () {
    // Without this, a retargeted or deleted manager means the pin silently
    // stops updating — the most invisible kind of supply-chain rot.
    final renovate = File('$root/renovate.json').readAsStringSync();
    // The path is a regex inside JSON, so the dot arrives escaped.
    expect(
      renovate,
      contains(r'native_pins\\.env'),
      reason:
          'no renovate.json manager targets scripts/lib/native_pins.env, so '
          'the native pins would silently stop being updated',
    );
    for (final name in values.keys.where((k) => k.endsWith('_REF'))) {
      expect(
        renovate,
        contains(name),
        reason: '$name has no renovate.json custom manager',
      );
    }
  });

  test('the Windows ARM64 sqlite-vector build matches the pub package', () {
    // Every other target loads the prebuilt the sqlite_vector package ships;
    // Windows ARM64 loads one compiled from SQLITE_VECTOR_REF. Bumping either
    // without the other would ship two different extensions behind one API.
    final lock = File('$root/pubspec.lock').readAsStringSync();
    final locked = RegExp(
      r'\n  sqlite_vector:\n(?:    .*\n)*?    version: "([^"]+)"',
    ).firstMatch(lock);
    expect(locked, isNotNull, reason: 'sqlite_vector is not in pubspec.lock');
    final pinned = RegExp(
      r'^SQLITE_VECTOR_REF=[0-9a-f]{40} # v(\S+)',
      multiLine: true,
    ).firstMatch(pins.join('\n'));
    expect(pinned, isNotNull, reason: 'SQLITE_VECTOR_REF is not pinned');
    expect(
      pinned!.group(1),
      locked!.group(1),
      reason:
          'bump SQLITE_VECTOR_REF to the sqlite-vector release tagged '
          '${locked.group(1)} (and the sqlite_vector patch, if its hook moved)',
    );
  });

  test('the rhttp native pin matches the pub package and its patch', () {
    // rhttp is the only native built from a PUB package rather than a git
    // checkout, so ONE version is described in three places: this pin file
    // (what scripts/natives/build_rhttp.sh compiles), pubspec.lock (what the
    // Dart bindings resolve to) and patches/rhttp@<version>.patch (the headless
    // patchwork patch, which only applies to that exact version). Let any of
    // them drift and either the patch stops applying or the compiled wire code
    // no longer matches the Dart bindings — a mismatch that surfaces on the
    // first HTTP request, not at build time.
    final lock = File('$root/pubspec.lock').readAsStringSync();
    final locked = RegExp(
      r'\n  rhttp:\n(?:    .*\n)*?    version: "([^"]+)"',
    ).firstMatch(lock);
    expect(locked, isNotNull, reason: 'rhttp is not in pubspec.lock');
    expect(
      values['RHTTP_VERSION'],
      locked!.group(1),
      reason: 'RHTTP_VERSION and the resolved rhttp package disagree',
    );

    expect(
      values['RHTTP_URL'],
      endsWith('rhttp-${values['RHTTP_VERSION']}.tar.gz'),
      reason: 'the pinned URL must name the pinned version',
    );
    expect(
      File('$root/patches/rhttp@${values['RHTTP_VERSION']}.patch').existsSync(),
      isTrue,
      reason:
          'patchwork matches patches/rhttp@<version>.patch by EXACT version: '
          'bump the pin and the patch together',
    );
  });

  group('code mode runner', () {
    // cc_codemode is built from source with `cargo --locked`, so Cargo.lock is
    // what ships. The pin file repeats the engine versions for the two
    // consumers that cannot read Cargo.lock: the licence notices and
    // scripts/lib/codemode.sh, which holds `cc_codemode --version` to the
    // QuickJS-NG pin at packaging time. These tests keep the copies together.
    const crate = 'packages/cc_natives/native/codemode';
    final locked = _cargoLockPackages(
      File('$root/$crate/Cargo.lock').readAsStringSync(),
    );

    test('the rquickjs pin matches Cargo.lock and the manifest', () {
      final pin = values['CODEMODE_RQUICKJS_VERSION'];
      expect(pin, isNotNull, reason: 'CODEMODE_RQUICKJS_VERSION is not pinned');
      for (final name in const ['rquickjs', 'rquickjs-core', 'rquickjs-sys']) {
        expect(
          locked[name],
          pin,
          reason:
              '$crate/Cargo.lock locks $name ${locked[name]}, but '
              'native_pins.env pins CODEMODE_RQUICKJS_VERSION=$pin',
        );
      }
      expect(
        File('$root/$crate/runner/Cargo.toml').readAsStringSync(),
        contains('rquickjs = { version = "=$pin"'),
        reason: 'the runner manifest must pin rquickjs exactly (=$pin)',
      );
    });

    test('the QuickJS-NG pin matches the recorded provenance', () {
      // rquickjs-sys vendors the C sources, so the engine version is only
      // visible in PROVENANCE.md (read from the crate at the locked version)
      // and in the built binary's --version, which codemode.sh checks.
      final pin = values['CODEMODE_QUICKJS_NG_VERSION'];
      expect(
        pin,
        isNotNull,
        reason: 'CODEMODE_QUICKJS_NG_VERSION is not pinned',
      );
      final provenance = File('$root/$crate/PROVENANCE.md').readAsStringSync();
      expect(
        RegExp(
          r'^\| QuickJS-NG [^|]*\| ' + RegExp.escape(pin!) + r' \|',
          multiLine: true,
        ).hasMatch(provenance),
        isTrue,
        reason:
            'PROVENANCE.md does not record QuickJS-NG $pin; a rquickjs bump '
            'that moves the vendored engine updates both',
      );
      expect(
        File('$root/scripts/lib/codemode.sh').readAsStringSync(),
        contains(r'quickjs-ng $CODEMODE_QUICKJS_NG_VERSION protocol'),
        reason: 'packaging no longer checks the built engine against the pin',
      );
    });

    test('every crate compiled into the runner is attributed', () {
      // A crate added to Cargo.lock ships inside bin/codemode/cc_codemode. It
      // needs a row in scripts/lib/third_party.sh at its locked version, or
      // a stated reason it is not redistributed.
      const notShipped = <String, String>{
        'cc_codemode': 'first party',
        'cc_codemode_lockdown': 'first party',
        'cc': 'build only',
        'find-msvc-tools': 'build only',
        'shlex': 'build only',
        // serde_json declares these behind cfg(any()); never compiled.
        'serde': 'never compiled',
        'serde_derive': 'never compiled',
        'proc-macro2': 'never compiled',
        'quote': 'never compiled',
        'syn': 'never compiled',
        'unicode-ident': 'never compiled',
        // rquickjs-core's optional module loader, not enabled.
        'relative-path': 'never compiled',
      };
      const coveredBy = <String, String>{
        'rquickjs-core': 'rquickjs',
        'rquickjs-sys': 'rquickjs',
        'windows-link': 'windows-sys',
      };
      final table = File('$root/scripts/lib/third_party.sh').readAsStringSync();
      final rows = <String, String>{
        for (final m in RegExp(
          r'^\s*"([^ |]+) \(Rust crate\)\|([^|]+)\|',
          multiLine: true,
        ).allMatches(table))
          m.group(1)!: m.group(2)!,
      };
      expect(
        table,
        contains('"rquickjs (code mode runner)|@CODEMODE_RQUICKJS_VERSION|'),
      );
      expect(
        table,
        contains(
          '"QuickJS-NG (code mode runner)|@CODEMODE_QUICKJS_NG_VERSION|',
        ),
      );
      final problems = <String>[];
      for (final MapEntry(key: name, value: version) in locked.entries) {
        if (notShipped.containsKey(name) || name == 'rquickjs') {
          continue;
        }
        final row = coveredBy[name] ?? name;
        if (row == 'rquickjs') {
          continue;
        }
        if (!rows.containsKey(row)) {
          problems.add('$name $version has no "$row (Rust crate)" row');
        } else if (coveredBy[name] == null && rows[row] != version) {
          problems.add(
            '$name is locked at $version but attributed at ${rows[row]}',
          );
        }
      }
      for (final name in rows.keys) {
        if (!locked.containsKey(name)) {
          problems.add('"$name (Rust crate)" is not in $crate/Cargo.lock');
        }
      }
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  });
}

/// `name → version` for every `[[package]]` in a Cargo.lock.
Map<String, String> _cargoLockPackages(String lock) => {
  for (final m in RegExp(
    r'^\[\[package\]\]\nname = "([^"]+)"\nversion = "([^"]+)"',
    multiLine: true,
  ).allMatches(lock))
    m.group(1)!: m.group(2)!,
};

const _temporaryFfmpegRelease = 'autobuild-2026-10-15-13-03';
final _ffmpegBaseline = DateTime.utc(2026, 10, 31);
final _ffmpegDailyDeadline = DateTime.utc(2026, 11, 1);

bool _ffmpegMeetsBaseline(String release, DateTime now) =>
    now.toUtc().isBefore(_ffmpegDailyDeadline) ||
    !_btbnReleaseDate(release).isBefore(_ffmpegBaseline);

bool _ffmpegUsesMonthEndBuild(String release, DateTime now) {
  final date = _btbnReleaseDate(release);
  return date.day == DateTime.utc(date.year, date.month + 1, 0).day ||
      (release == _temporaryFfmpegRelease &&
          now.toUtc().isBefore(_ffmpegDailyDeadline));
}

DateTime _btbnReleaseDate(String release) {
  final match = RegExp(
    r'^autobuild-(\d{4})-(\d{2})-(\d{2})-\d{2}-\d{2}$',
  ).firstMatch(release);
  if (match == null) {
    throw FormatException('Expected autobuild-YYYY-MM-DD-HH-MM', release);
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw FormatException('Invalid BtbN release date', release);
  }
  return date;
}
