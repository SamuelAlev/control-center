/// The client-side mirror of the demo world's stable identifiers.
///
/// The authoritative definitions live in the SERVER's demo package
/// (`packages/cc_server_core/lib/src/demo/`), which this app can never import
/// (the architecture test forbids desktop-reachable code importing
/// `cc_server_core`). The tour's deep-links need a few of those identifiers,
/// so they are mirrored here — and
/// `test/features/demo/demo_deep_link_pins_test.dart` pins every one of them
/// against the seeder/fixtures sources so the two halves cannot drift apart
/// silently.
///
/// Space IDS are deliberately absent from this file: the seeder mints a UUID
/// per space at seed time, so the client resolves the seeded space by NAME at
/// runtime (`kDemoAgentSpaceName`) instead of encoding an id that could never
/// be stable.
library;

/// The space "Talk to an agent" opens: the `escrow-review` conversation, which
/// pairs the visitor with Ravi (the reviewer agent) and carries the #412
/// thread. Seeded by `DemoSeeder._seedSpaces`.
const String kDemoAgentSpaceName = 'escrow-review';

/// The repo the demo's PR world lives in (`owner/name`), mirrored from
/// `kDemoRepoFullName` in the server's `demo_world.dart`.
const String kDemoRepoFullName = 'parced/closing';

/// The project's OWN repository (`owner/name`), mirrored from
/// `kDemoProjectRepoFullName` in the server's `demo_world.dart`.
///
/// Deliberately NOT [kDemoRepoFullName]: that repo is the invented one the
/// seeded PR world lives in and does not exist on GitHub, so a visitor linked
/// there would land on a 404. This is the demo's one link to something real —
/// what the tour's "Star on GitHub" button opens, and the repo the server's
/// `demo.repoStars` op reports the count of.
const String kDemoProjectRepoFullName = 'SamuelAlev/control-center';

/// What the tour's "Star on GitHub" button opens in the OS browser.
const String kDemoProjectRepoUrl =
    'https://github.com/$kDemoProjectRepoFullName';

/// The pull request "Review a pull request" opens — the open review the whole
/// demo narrative revolves around. From `kDemoPullRequestsJson`.
const int kDemoReviewPrNumber = 412;

/// The ticket "Follow the work" opens — the in-progress upload bug, assigned
/// to Juno. Its id IS its key (`PD-118`) in `DemoSeeder._seedTickets`.
const String kDemoTicketId = 'PD-118';

/// The forge account a demo visitor reviews AS.
///
/// A demo server holds no credential, so `forge.listConnections` is absent and
/// the viewer login resolves to the empty string — which silently empties every
/// surface keyed on "is this mine?": the inbox's review queue, "requested from
/// you", the merge-readiness column and the PR list's own-authorship grouping.
/// A furnished demo whose inbox is blank is a worse demo than no inbox.
///
/// So the client answers the viewer question locally with the identity the
/// FIXTURES already cast as the human reviewer — the visitor sits in Maya's
/// seat, which is what makes the seeded review requests address them. This is
/// a display identity only: it authenticates nothing and no write leaves the
/// demo, because every forge mutation is absent from the op registry.
const String kDemoViewerLogin = 'maya-ok';

/// The org and team the demo viewer belongs to, so a review request addressed
/// to a TEAM (`parced/closing-eng` on PR #414) also reaches their queue.
const String kDemoViewerOrg = 'parced';

/// The team slug of [kDemoViewerOrg] the demo viewer belongs to.
const String kDemoViewerTeamSlug = 'closing-eng';
