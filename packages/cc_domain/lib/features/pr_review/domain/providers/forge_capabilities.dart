import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Thrown by a forge adapter when a caller reaches a surface that forge does
/// not have.
///
/// This is defense in depth, not the primary mechanism: the UI reads
/// [ForgeCapabilities] and does not render the affordance at all. An adapter
/// throwing this means something bypassed that check, so the message names the
/// forge and the capability rather than failing as a generic API error.
class ForgeUnsupportedError implements Exception {
  /// Creates a [ForgeUnsupportedError] for [capability] on [forge].
  const ForgeUnsupportedError(this.forge, this.capability);

  /// The forge that lacks the capability.
  final ForgeHost forge;

  /// A short name for what was attempted (`stacks`, `reactions`, …).
  final String capability;

  @override
  String toString() => '${forge.displayName} does not support $capability.';
}

/// What one forge can actually do.
///
/// **Static, not probed.** These are properties of *our integration* with a
/// forge's API, known at compile time — not something we discover at runtime.
/// Probing them would be a lie dressed as a measurement, the same distinction
/// `AdapterEnforcement` draws for agent CLIs. When we add support for something,
/// we edit this table.
///
/// The UI reads these to decide what to render: a Bitbucket PR must not show a
/// "Files viewed" toggle that silently does nothing, and a GitLab MR must not
/// show a stacks panel. Hiding beats a disabled control here — an affordance
/// that a forge structurally cannot have is not "temporarily unavailable".
class ForgeCapabilities {
  /// Creates a [ForgeCapabilities] descriptor.
  const ForgeCapabilities({
    required this.forge,
    required this.pendingReviewBatching,
    required this.requestChanges,
    required this.viewedStateSync,
    required this.reactions,
    required this.commentThreadResolution,
    required this.teamReviewers,
    required this.suggestedReviewers,
    required this.ciChecks,
    required this.ciJobDetail,
    required this.stacks,
    required this.prTemplates,
    required this.notifications,
    required this.richUserProfiles,
    required this.serverSidePrHeadRef,
    required this.draftToggle,
  });

  /// Reads a descriptor back off the wire. Absent keys read as `false`, so an
  /// older server simply reports fewer capabilities rather than failing.
  factory ForgeCapabilities.fromJson(Map<String, dynamic> json) {
    bool flag(String key) => json[key] as bool? ?? false;
    return ForgeCapabilities(
      forge: ForgeHost.fromWire(json['forge'] as String?),
      pendingReviewBatching: flag('pendingReviewBatching'),
      requestChanges: flag('requestChanges'),
      viewedStateSync: flag('viewedStateSync'),
      reactions: flag('reactions'),
      commentThreadResolution: flag('commentThreadResolution'),
      teamReviewers: flag('teamReviewers'),
      suggestedReviewers: flag('suggestedReviewers'),
      ciChecks: flag('ciChecks'),
      ciJobDetail: flag('ciJobDetail'),
      stacks: flag('stacks'),
      prTemplates: flag('prTemplates'),
      notifications: flag('notifications'),
      richUserProfiles: flag('richUserProfiles'),
      serverSidePrHeadRef: flag('serverSidePrHeadRef'),
      draftToggle: flag('draftToggle'),
    );
  }

  /// The forge this describes.
  final ForgeHost forge;

  /// Review comments can be drafted server-side and submitted as one batch.
  ///
  /// GitHub pending reviews and GitLab draft notes both do this. Bitbucket has
  /// no equivalent, so a multi-comment review is posted comment-by-comment and
  /// reviewers see them arrive individually.
  final bool pendingReviewBatching;

  /// A review can carry an explicit "changes requested" verdict.
  final bool requestChanges;

  /// Per-file "viewed" state is stored on the forge and syncs across devices.
  ///
  /// When false the app still tracks viewed state, but locally only.
  final bool viewedStateSync;

  /// Emoji reactions on comments and on the PR itself.
  final bool reactions;

  /// Inline comment threads carry a resolved/unresolved conversation state that
  /// can be read and toggled.
  ///
  /// When false a thread's resolved state is local to this app: nothing is read
  /// from the forge and nothing is written back, so "resolved" means "hidden
  /// here" rather than "settled for everyone on the PR".
  final bool commentThreadResolution;

  /// Reviews can be requested from a team/group, not just individual users.
  final bool teamReviewers;

  /// The forge suggests reviewers for a PR.
  final bool suggestedReviewers;

  /// CI results are exposed per commit (checks, pipelines, build statuses).
  final bool ciChecks;

  /// An individual CI job's steps and logs can be drilled into from the PR.
  final bool ciJobDetail;

  /// Stacked pull requests as a first-class forge concept.
  final bool stacks;

  /// PR description templates stored in the repository.
  final bool prTemplates;

  /// A notification feed that can be polled for review requests and mentions.
  final bool notifications;

  /// User profiles carry enough detail (bio, contributions, organizations) to
  /// fill the profile screen rather than a bare name-and-avatar card.
  final bool richUserProfiles;

  /// The forge publishes a fetchable ref for a PR's head commit
  /// (`refs/pull/N/head`, `refs/merge-requests/N/head`).
  ///
  /// When false, checking out a PR means fetching its source branch by name,
  /// which only works while that branch still exists on the remote.
  final bool serverSidePrHeadRef;

  /// A pull request can be moved between draft and ready-for-review after it
  /// has been opened.
  ///
  /// When false the draft state is fixed at creation time (or the forge has no
  /// draft concept at all), so the "Ready for review" / "Convert to draft"
  /// affordances are not rendered.
  final bool draftToggle;

  /// Looks up a capability by the name [ForgeUnsupportedError] uses, so the
  /// ratchet test can assert every declared capability is reachable.
  bool byName(String name) => switch (name) {
    'pendingReviewBatching' => pendingReviewBatching,
    'requestChanges' => requestChanges,
    'viewedStateSync' => viewedStateSync,
    'reactions' => reactions,
    'commentThreadResolution' => commentThreadResolution,
    'teamReviewers' => teamReviewers,
    'suggestedReviewers' => suggestedReviewers,
    'ciChecks' => ciChecks,
    'ciJobDetail' => ciJobDetail,
    'stacks' => stacks,
    'prTemplates' => prTemplates,
    'notifications' => notifications,
    'richUserProfiles' => richUserProfiles,
    'serverSidePrHeadRef' => serverSidePrHeadRef,
    'draftToggle' => draftToggle,
    _ => throw ArgumentError.value(name, 'name', 'Unknown forge capability'),
  };

  /// Every capability name, in declaration order. The settings "what works
  /// where" matrix and the ratchet test both iterate this.
  static const List<String> allNames = [
    'pendingReviewBatching',
    'requestChanges',
    'viewedStateSync',
    'reactions',
    'commentThreadResolution',
    'teamReviewers',
    'suggestedReviewers',
    'ciChecks',
    'ciJobDetail',
    'stacks',
    'prTemplates',
    'notifications',
    'richUserProfiles',
    'serverSidePrHeadRef',
    'draftToggle',
  ];

  /// Serializes to the wire (one bool per capability plus the forge).
  Map<String, dynamic> toJson() => {
    'forge': forge.wire,
    for (final name in allNames) name: byName(name),
  };
}

/// The capability matrix, one entry per forge.
///
/// This is the single source of truth the server serves to every client — no
/// client hardcodes a forge's abilities (the `harnessProviderMetas` convention
/// for LLM providers, applied to forges).
const Map<ForgeHost, ForgeCapabilities> kForgeCapabilities = {
  ForgeHost.github: ForgeCapabilities(
    forge: ForgeHost.github,
    pendingReviewBatching: true,
    requestChanges: true,
    viewedStateSync: true,
    reactions: true,
    commentThreadResolution: true,
    teamReviewers: true,
    suggestedReviewers: true,
    ciChecks: true,
    ciJobDetail: true,
    stacks: true,
    prTemplates: true,
    notifications: true,
    richUserProfiles: true,
    serverSidePrHeadRef: true,
    draftToggle: true,
  ),
  // GitLab: draft notes give real batching, approvals + "changes requested"
  // reviewer state give a verdict, pipelines give checks and job detail.
  // No stacks (no forge-level concept), no emoji-award parity on every
  // surface we use, and no viewed-state API.
  ForgeHost.gitlab: ForgeCapabilities(
    forge: ForgeHost.gitlab,
    pendingReviewBatching: true,
    requestChanges: true,
    viewedStateSync: false,
    reactions: true,
    commentThreadResolution: false,
    teamReviewers: true,
    suggestedReviewers: false,
    ciChecks: true,
    ciJobDetail: true,
    stacks: false,
    prTemplates: true,
    notifications: false,
    richUserProfiles: true,
    serverSidePrHeadRef: true,
    // The `Draft: ` title prefix *is* GitLab's draft flag, so toggling it is a
    // title write rather than a dedicated endpoint — but it is a real toggle.
    draftToggle: true,
  ),
  // Bitbucket Cloud is the thinnest surface of the three: comments post
  // individually (no draft/pending state), build statuses carry a result and a
  // link but no step-level detail, and there is no viewed state, no reaction
  // API, no notification feed and no PR head ref — a checkout fetches the
  // source branch by name.
  ForgeHost.bitbucket: ForgeCapabilities(
    forge: ForgeHost.bitbucket,
    pendingReviewBatching: false,
    requestChanges: true,
    viewedStateSync: false,
    reactions: false,
    commentThreadResolution: false,
    teamReviewers: false,
    suggestedReviewers: true,
    ciChecks: true,
    ciJobDetail: false,
    stacks: false,
    prTemplates: false,
    notifications: false,
    richUserProfiles: false,
    serverSidePrHeadRef: false,
    draftToggle: false,
  ),
  ForgeHost.local: ForgeCapabilities(
    forge: ForgeHost.local,
    pendingReviewBatching: false,
    requestChanges: false,
    viewedStateSync: false,
    reactions: false,
    commentThreadResolution: false,
    teamReviewers: false,
    suggestedReviewers: false,
    ciChecks: false,
    ciJobDetail: false,
    stacks: false,
    prTemplates: false,
    notifications: false,
    richUserProfiles: false,
    serverSidePrHeadRef: false,
    draftToggle: false,
  ),
};

/// The capabilities of [forge]. Total — every enum value has an entry.
ForgeCapabilities capabilitiesOf(ForgeHost forge) =>
    kForgeCapabilities[forge] ?? kForgeCapabilities[ForgeHost.local]!;
