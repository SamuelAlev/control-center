/// The demo's fictional world: who the team is and what they are building.
///
/// Invented wholesale. Nothing here resembles a real organization, product or
/// person — a public demo that looked like a real company's data would be a
/// different kind of problem entirely.
///
/// The world is **Helix**, an applied LLM / data-science lab: evaluation
/// harnesses, retrieval pipelines, a feature store and fine-tuning. The cast
/// is Helix's engineering team; every PR, ticket, meeting and memory fact is
/// about that domain.
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

/// A fictional repository the demo workspace is linked to.
///
/// Four of these furnish the PR list and the inbox (needs-your-review, drafts,
/// returned, approved, …). The path is inert — demo mode never touches git —
/// but the `(owner, name)` pair is required: `resolvePrReviewRepository`
/// looks the linked repo up by those fields.
class DemoRepoSpec {
  /// Creates a repo spec.
  const DemoRepoSpec({
    required this.id,
    required this.name,
    required this.summary,
  });

  /// Stable repo id, shared by every demo workspace.
  final String id;

  /// Repository name (the last path segment). The org is [kDemoRepoOwner].
  final String name;

  /// One-line what-this-is, used in comments and seed copy.
  final String summary;

  /// `owner/name`.
  String get fullName => '$kDemoRepoOwner/$name';
}

/// The fictional org this team works in.
const String kDemoRepoOwner = 'helix';

/// The flagship repository — the LLM evaluation harness the tour PR lives in.
const String kDemoRepoName = 'evalkit';

/// `owner/name` of the flagship repo, the key the tour PR is stored under.
const String kDemoRepoFullName = '$kDemoRepoOwner/$kDemoRepoName';

/// The four linked repos a visitor sees. Order is the order they appear in
/// Settings → Repositories.
const List<DemoRepoSpec> kDemoRepos = [
  DemoRepoSpec(
    id: 'demo-repo-evalkit',
    name: 'evalkit',
    summary: 'LLM evaluation harness: budgets, graders, run groups',
  ),
  DemoRepoSpec(
    id: 'demo-repo-retriever',
    name: 'retriever',
    summary: 'Hybrid BM25 + embedding retrieval pipeline',
  ),
  DemoRepoSpec(
    id: 'demo-repo-features',
    name: 'features',
    summary: 'Online feature store and lineage',
  ),
  DemoRepoSpec(
    id: 'demo-repo-finetune',
    name: 'finetune',
    summary: 'LoRA / QLoRA adapter training',
  ),
];

/// The PROJECT's own repository (`owner/name`) — the one real thing a demo
/// points at: what `demo.repoStars` reports the stars of and what the client's
/// "Star on GitHub" button opens.
///
/// Deliberately distinct from [kDemoRepoFullName]: that repo is fictional and
/// does not exist on GitHub, so a visitor linked to it would land on a 404.
const String kDemoProjectRepoFullName = 'SamuelAlev/control-center';

/// The workspace name a visitor lands in.
const String kDemoWorkspaceName = 'Helix';

/// Display name of the in-product agent team that slug maps onto.
const String kDemoTeamName = 'ML eng';

/// The space Wren's HX-129 plan was authored in.
const String kDemoPlanSpaceName = 'eval-reports';

/// Display name a visitor is seated as in messaging and the roster.
///
/// Their *handle* stays `guest-*` so isolation tests (and the reaper) can
/// tell a session from the shared Maya fixture. The name is Maya's so the
/// GitHub seat (`maya-ok`) and the chat identity agree.
const String kDemoVisitorDisplayName = 'Maya Okonkwo';

/// The pull request "Review a pull request" opens — the open review the whole
/// demo narrative revolves around.
const int kDemoReviewPrNumber = 412;

/// The forge node id of the PR the demo's AI review is attached to (#412).
///
/// Review rows key off `prExternalId`, which is the forge's node id and NOT
/// the PR number — the fixtures carry it as `detail.id`, so a review seeded
/// against `'412'` would write rows the review tab never looks up.
const String kDemoReviewPrExternalId = '4120001';

/// The space "Talk to an agent" opens.
const String kDemoAgentSpaceName = 'eval-review';

/// The ticket "Follow the work" opens.
const String kDemoTicketId = 'HX-118';

/// The cast, in roster order.
const List<DemoPerson> kDemoCast = [
  DemoPerson(
    id: 'demo-person-maya',
    handle: 'maya-ok',
    displayName: 'Maya Okonkwo',
    role: 'Staff ML engineer',
  ),
  DemoPerson(
    id: 'demo-person-diego',
    handle: 'dferrer',
    displayName: 'Diego Ferrer',
    role: 'Eval infrastructure',
  ),
  DemoPerson(
    id: 'demo-person-priya',
    handle: 'priya-r',
    displayName: 'Priya Raman',
    role: 'Retrieval',
  ),
  DemoPerson(
    id: 'demo-person-tom',
    handle: 'tlindqvist',
    displayName: 'Tom Lindqvist',
    role: 'Product',
  ),
];

/// Whether [userId] is one of the shared cast fixtures.
///
/// The cast are members of EVERY pooled workspace and survive every reaping;
/// boot-time garbage collection uses this to avoid deleting them when it
/// cleans up guest users discovered behind an unowned workspace.
bool isDemoCastMember(String userId) => kDemoCast.any((p) => p.id == userId);

/// The only pipeline templates a demo workspace keeps.
///
/// The product's own seeder installs thirteen built-ins; a demo shows two so
/// the Pipelines screen reads like a curated example rather than a catalogue.
/// `pr_review` pairs with the flagship PR review narrative and `ticket_to_pr`
/// pairs with the triage script — between them they exercise a multi-step
/// definition and an event trigger. The boot-time template reconciler is
/// pointed at this same set in demo mode, so it cannot re-add the rest.
const Set<String> kDemoPipelineTemplateIds = {'pr_review', 'ticket_to_pr'};
