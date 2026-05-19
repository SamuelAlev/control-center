/// The demo's fictional world: who the team is and what they are building.
///
/// Invented wholesale. Nothing here resembles a real organization, product or
/// person — a public demo that looked like a real company's data would be a
/// different kind of problem entirely.
///
/// The world is **Parced**, a real-estate closing platform: properties,
/// offers, contingencies, escrow, title and the paperwork law firms push
/// around it. The cast is Parced's engineering team; every PR, ticket,
/// meeting and memory fact is about that domain.
library;

/// A fictional teammate.
///
/// They are REAL `users` rows in the global database, not placeholder strings:
/// messaging refuses to author a message without a real user id (the old
/// `'user'` sentinel was removed), and having them as workspace members is what
/// makes attribution, mentions and the presence roster render like a team.
///
/// They are shared across every pooled workspace and are NOT reaped with a
/// visitor — they are fixtures, not sessions.
class DemoPerson {
  /// Creates a person.
  const DemoPerson({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.role,
  });

  /// Stable user id, shared by every demo workspace.
  final String id;

  /// Their handle, which doubles as their forge login in the PR fixtures.
  final String handle;

  /// Display name.
  final String displayName;

  /// What they do, used in space descriptions and ticket assignment copy.
  final String role;
}

/// The fictional product this team works on: a real-estate closing platform.
const String kDemoRepoOwner = 'parced';

/// The fictional repository name — the closing/escrow workflow service.
const String kDemoRepoName = 'closing';

/// `owner/name`, the key every PR cache row is stored under.
const String kDemoRepoFullName = '$kDemoRepoOwner/$kDemoRepoName';

/// The PROJECT's own repository (`owner/name`) — the one real thing a demo
/// points at: what `demo.repoStars` reports the stars of and what the client's
/// "Star on GitHub" button opens.
///
/// Deliberately distinct from [kDemoRepoFullName]: that repo is fictional and
/// does not exist on GitHub, so a visitor linked to it would land on a 404.
const String kDemoProjectRepoFullName = 'SamuelAlev/control-center';

/// The workspace name a visitor lands in.
const String kDemoWorkspaceName = 'Parced';

/// The forge node id of the PR the demo's AI review is attached to (#412).
///
/// Review rows key off `prExternalId`, which is the forge's node id and NOT
/// the PR number — the fixtures carry it as `detail.node_id`, so a review
/// seeded against `'412'` would write rows the review tab never looks up.
const String kDemoReviewPrExternalId = '4120001';

/// The cast, in roster order.
const List<DemoPerson> kDemoCast = [
  DemoPerson(
    id: 'demo-person-maya',
    handle: 'maya-ok',
    displayName: 'Maya Okonkwo',
    role: 'Staff engineer',
  ),
  DemoPerson(
    id: 'demo-person-diego',
    handle: 'dferrer',
    displayName: 'Diego Ferrer',
    role: 'Backend',
  ),
  DemoPerson(
    id: 'demo-person-priya',
    handle: 'priya-r',
    displayName: 'Priya Raman',
    role: 'Design engineer',
  ),
  DemoPerson(
    id: 'demo-person-tom',
    handle: 'tlindqvist',
    displayName: 'Tom Lindqvist',
    role: 'Product',
  ),
];

/// Looks a person up by handle.
DemoPerson? demoPersonByHandle(String handle) {
  for (final person in kDemoCast) {
    if (person.handle == handle) {
      return person;
    }
  }
  return null;
}

/// Whether [userId] is one of the shared cast fixtures.
///
/// The cast are members of EVERY pooled workspace and survive every reaping;
/// boot-time garbage collection uses this to avoid deleting them when it
/// cleans up guest users discovered behind an unowned workspace.
bool isDemoCastMember(String userId) =>
    kDemoCast.any((p) => p.id == userId);

/// The only pipeline templates a demo workspace keeps.
///
/// The product's own seeder installs thirteen built-ins; a demo shows two so
/// the Pipelines screen reads like a curated example rather than a catalogue.
/// `pr_review` pairs with the flagship PR review narrative and `ticket_to_pr`
/// pairs with the triage script — between them they exercise a multi-step
/// definition and an event trigger. The boot-time template reconciler is
/// pointed at this same set in demo mode, so it cannot re-add the rest.
const Set<String> kDemoPipelineTemplateIds = {'pr_review', 'ticket_to_pr'};
