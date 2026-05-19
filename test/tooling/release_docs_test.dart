import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ratchet over RELEASING.md's description of the pipeline.
///
/// The docs had drifted in every direction at once: the Scripts table omitted
/// four scripts the release actually runs, the "Local dry run" recipe skipped
/// a native staging step (so it failed at the native-verify gate the package
/// scripts call internally), and the hardening section described a
/// harden-runner policy the workflow does not use.
///
/// Prose cannot be made correct once; it has to be held correct. This pins the
/// claims that are cheap to check mechanically.
void main() {
  final root = Directory.current.path;
  final doc = File('$root/RELEASING.md').readAsStringSync();

  test('every release script is documented', () {
    // A script nobody documents is a script nobody knows to run locally — which
    // is how the Windows path ended up restated as prose instead of pointed at.
    final scripts =
        Directory('$root/scripts/release')
            .listSync()
            .whereType<File>()
            .map((f) => f.uri.pathSegments.last)
            .where((n) => n.endsWith('.sh'))
            .toList()
          ..sort();
    expect(scripts, isNotEmpty);
    for (final name in scripts) {
      expect(
        doc,
        contains(name),
        reason:
            'RELEASING.md never mentions scripts/release/$name. Add it to the '
            'Scripts table so it is discoverable and runnable by hand.',
      );
    }
  });

  test('the shared libraries are documented', () {
    for (final name in const [
      'scripts/lib/common.sh',
      'scripts/lib/natives.sh',
      'scripts/lib/native_pins.env',
      'scripts/lib/artifact_names.sh',
    ]) {
      expect(doc, contains(name), reason: 'RELEASING.md never mentions $name');
    }
  });

  test('the local dry run points at the script, not a prose recipe', () {
    // The old recipe was a sequence of commands that did not work: it omitted
    // the native staging steps and gen_build_info.dart. dry_run.sh IS the
    // procedure, so it cannot drift from itself.
    expect(doc, contains('scripts/release/dry_run.sh'));
  });

  test('every script carries a usage line', () {
    // The scripts have no --help framework (~20 files of surface for no
    // consumer). The header comment IS the interface, so require one.
    for (final dir in const [
      'scripts/release',
      'scripts/natives',
      'scripts/lib',
    ]) {
      for (final file in Directory('$root/$dir').listSync().whereType<File>()) {
        final name = file.uri.pathSegments.last;
        if (!name.endsWith('.sh')) {
          continue;
        }
        final head = file.readAsLinesSync().take(60).join('\n');
        expect(
          head.toLowerCase(),
          anyOf(contains('usage:'), contains('source it')),
          reason:
              '$dir/$name has no `Usage:` line (or, for a sourced library, a '
              '"Source it" note) in its header comment',
        );
      }
    }
  });

  test('the harden-runner claim matches the workflow', () {
    // The doc used to claim "egress audit on the Linux build + release jobs"
    // while the workflow blocks on three jobs, audits on one, and omits it
    // entirely from the two that hold the signing certificates.
    final release = File(
      '$root/.github/workflows/release.yml',
    ).readAsStringSync();
    final blocks = 'egress-policy: block'.allMatches(release).length;
    final audits = 'egress-policy: audit'.allMatches(release).length;
    expect(
      blocks + audits,
      greaterThanOrEqualTo(4),
      reason: 'release.yml lost a harden-runner step',
    );
    // If the doc names a policy, it must name both — the split is the point.
    if (doc.contains('harden-runner')) {
      expect(
        doc,
        contains('block'),
        reason:
            'RELEASING.md describes harden-runner without mentioning the '
            '`block` policy the Linux jobs actually use',
      );
    }
  });
}
