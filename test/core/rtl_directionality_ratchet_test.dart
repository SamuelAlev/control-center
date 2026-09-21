import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/source_files.dart';

/// RTL ratchet: physical-edge geometry must not grow (shrinking allowlist).
/// Files need logical geometry or an `// RTL carve-out:` comment. Fixing means
/// removing from the allowlist. Regen:
/// `CC_REGEN_RTL_ALLOWLIST=1 fvm flutter test test/core/rtl_directionality_ratchet_test.dart --concurrency=1`
void main() {
  test('physical-edge geometry does not grow (RTL ratchet)', () {
    final allowlistFile = File(_allowlistPath);
    final allow = _readAllowlist(allowlistFile);
    final stale = <String>{...allow};
    final offenders = <String>[];
    final current = <String>[];

    for (final file in dartSourceFiles(roots: _scanRoots)) {
      final rel = file.path.replaceAll(r'\', '/');
      if (rel.endsWith('.g.dart') || rel.endsWith('.freezed.dart')) {
        continue;
      }
      final content = file.readAsStringSync();
      if (content.contains(_carveOutMarker)) {
        // A deliberate LTR surface; physical geometry is the point there.
        continue;
      }
      if (!_bannedPatterns.any((pattern) => pattern.hasMatch(content))) {
        continue;
      }
      current.add(rel);
      stale.remove(rel);
      if (!allow.contains(rel)) {
        offenders.add(rel);
      }
    }

    if (Platform.environment['CC_REGEN_RTL_ALLOWLIST'] == '1') {
      current.sort();
      allowlistFile.writeAsStringSync(
        '$_allowlistHeader${current.join('\n')}\n',
      );
      return;
    }

    offenders.sort();
    final staleList = stale.toList()..sort();
    expect(
      offenders,
      isEmpty,
      reason:
          'New physical-edge geometry outside the RTL allowlist '
          '($_allowlistPath). Use EdgeInsetsDirectional / AlignmentDirectional '
          '/ TextAlign.start|end so the surface mirrors under RTL, or mark a '
          'deliberate LTR surface with "$_carveOutMarker <reason>" (see "RTL & '
          'directionality" in AGENTS.md):\n${offenders.join('\n')}',
    );
    expect(
      staleList,
      isEmpty,
      reason:
          'Stale RTL allowlist entries (no longer use physical-edge geometry — '
          'remove from $_allowlistPath):\n${staleList.join('\n')}',
    );
  });
}

/// The UI production trees the ratchet polices. Server-side packages hold no
/// widgets and the gallery's use-cases are previews, not product surfaces.
const _scanRoots = [
  'lib',
  'packages/cc_ui/lib',
  'packages/cc_markdown/lib',
  'apps/cc_remote/lib',
];

/// Marker comment exempting a file as a deliberate LTR carve-out.
const _carveOutMarker = '// RTL carve-out:';

const _allowlistPath =
    'test/core/migration_allowlists/rtl_physical_geometry.txt';

const _allowlistHeader =
    '# Enforced by rtl_directionality_ratchet_test.dart. Shrinking allowlist:\n'
    '# files still using physical-edge geometry (EdgeInsets.only(left/right:),\n'
    '# Alignment.*Left/Right, TextAlign.left/right) that should mirror under\n'
    '# RTL. Migrate to the Directional counterparts and REMOVE the entry, or\n'
    '# mark a deliberate LTR surface with an "// RTL carve-out:" comment.\n'
    '# One repo-relative path per line; blank lines and # comments ignored.\n';

/// The banned physical-geometry patterns.
///
/// `EdgeInsets.only` is matched across line breaks up to the first closing
/// paren — argument lists here are simple enough in practice that a nested
/// call before `left:`/`right:` is rare, and the ratchet is a net, not a
/// proof. Symmetric `EdgeInsets.fromLTRB` is legal (it does not encode a
/// side), so `fromLTRB` is deliberately not matched.
final _bannedPatterns = [
  RegExp(r'EdgeInsets\.only\([^)]*\b(?:left|right)\s*:', dotAll: true),
  RegExp(r'\bAlignment\.(?:center|top|bottom)(?:Left|Right)\b'),
  RegExp(r'\bTextAlign\.(?:left|right)\b'),
];

Set<String> _readAllowlist(File file) {
  if (!file.existsSync()) {
    return const {};
  }
  return file
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .toSet();
}
