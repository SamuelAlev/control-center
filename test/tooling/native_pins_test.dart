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
/// scripts/lib/native_pins.env is now the only home for a pinned ref and
/// renovate.json's custom managers target it alone.
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
}
