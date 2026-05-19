import 'dart:io';

import 'package:control_center/features/demo/demo_world.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the client-side demo deep-link constants to the server's seeder and
/// fixture sources.
///
/// The client can never import the server's demo package (the architecture
/// test forbids desktop-reachable code importing `cc_server_core`), so the
/// stable identifiers the demo tour deep-links to are MIRRORED in
/// `lib/features/demo/demo_world.dart`. A mirror nobody compares is a mirror
/// that drifts: a renamed seed space or ticket key would turn the tour's
/// "Open" buttons into dead links that fall back to list pages — the exact
/// "asks you to create a space" experience the deep-links exist to avoid.
///
/// Space IDS are exempt (the seeder mints UUIDs; the client resolves the space
/// by name at runtime), which is why the space pin below is on the NAME.
void main() {
  final root = Directory.current.path;
  final seeder = File(
    '$root/packages/cc_server_core/lib/src/demo/demo_seeder.dart',
  ).readAsStringSync();
  final serverWorld = File(
    '$root/packages/cc_server_core/lib/src/demo/demo_world.dart',
  ).readAsStringSync();
  final fixtures = File(
    '$root/packages/cc_server_core/lib/src/demo/fixtures/demo_fixtures.g.dart',
  ).readAsStringSync();

  test('the agent space name matches a seeded space', () {
    expect(seeder, contains("name: '$kDemoAgentSpaceName'"));
  });

  test('the repo full name matches the server demo world', () {
    // The server composes `owner/name` from two constants; pin both halves so
    // a change to either one is caught.
    final owner = kDemoRepoFullName.split('/').first;
    final repo = kDemoRepoFullName.split('/').last;
    expect(serverWorld, contains("kDemoRepoOwner = '$owner'"));
    expect(serverWorld, contains("kDemoRepoName = '$repo'"));
  });

  test('the project repo matches the server demo world', () {
    // The client OPENs this repo ("Star on GitHub") and the server COUNTS its
    // stars (`demo.repoStars`); if the two halves drifted, the button would
    // count one repository and open another.
    expect(
      serverWorld,
      contains("kDemoProjectRepoFullName = '$kDemoProjectRepoFullName'"),
    );
  });

  test('the review PR number matches a fixture PR', () {
    // The fixtures JSON is double-encoded; the PR's html_url appears as a
    // plain `<owner>/<repo>/pull/<number>` substring, which is stable to pin.
    expect(fixtures, contains('$kDemoRepoFullName/pull/$kDemoReviewPrNumber'));
  });

  test('the ticket id matches a seeded ticket', () {
    expect(seeder, contains("key: '$kDemoTicketId'"));
  });

  test('the demo viewer is a pending reviewer in the fixtures', () {
    // The whole point of giving the demo a viewer identity is that the seeded
    // review requests address it. A login that appears nowhere in the fixtures
    // would leave the inbox and the PR queue looking exactly as empty as
    // having no identity at all — and nothing else would fail.
    expect(
      fixtures,
      contains(kDemoViewerLogin),
      reason:
          'the demo viewer login must be a real reviewer in pull_requests.json',
    );
    expect(fixtures, contains(kDemoViewerTeamSlug));
  });
}
