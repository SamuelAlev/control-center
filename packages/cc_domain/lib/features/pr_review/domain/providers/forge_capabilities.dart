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

/// One thing a forge integration can do. The enum name is the wire key and
/// the name [ForgeUnsupportedError] reports.
enum ForgeCapability {
  /// Review comments can be drafted server-side and submitted as one batch.
  ///
  /// GitHub pending reviews and GitLab draft notes both do this. Bitbucket has
  /// no equivalent, so a multi-comment review is posted comment-by-comment and
  /// reviewers see them arrive individually.
  pendingReviewBatching,

  /// A review can carry an explicit "changes requested" verdict.
  requestChanges,

  /// Per-file "viewed" state is stored on the forge and syncs across devices.
  ///
  /// When false the app still tracks viewed state, but locally only.
  viewedStateSync,

  /// Emoji reactions on comments and on the PR itself.
  reactions,

  /// Inline comment threads carry a resolved/unresolved conversation state
  /// that can be read and toggled.
  ///
  /// When false a thread's resolved state is local to this app: nothing is
  /// read from the forge and nothing is written back, so "resolved" means
  /// "hidden here" rather than "settled for everyone on the PR".
  commentThreadResolution,

  /// Reviews can be requested from a team/group, not just individual users.
  teamReviewers,

  /// The forge suggests reviewers for a PR.
  suggestedReviewers,

  /// CI results are exposed per commit (checks, pipelines, build statuses).
  ciChecks,

  /// An individual CI job's steps and logs can be drilled into from the PR.
  ciJobDetail,

  /// Stacked pull requests as a first-class forge concept.
  stacks,

  /// PR description templates stored in the repository.
  prTemplates,

  /// A notification feed that can be polled for review requests and mentions.
  notifications,

  /// User profiles carry enough detail (bio, contributions, organizations) to
  /// fill the profile screen rather than a bare name-and-avatar card.
  richUserProfiles,

  /// The forge publishes a fetchable ref for a PR's head commit
  /// (`refs/pull/N/head`, `refs/merge-requests/N/head`).
  ///
  /// When false, checking out a PR means fetching its source branch by name,
  /// which only works while that branch still exists on the remote.
  serverSidePrHeadRef,

  /// A pull request can be moved between draft and ready-for-review after it
  /// has been opened.
  ///
  /// When false the draft state is fixed at creation time (or the forge has
  /// no draft concept at all), so the "Ready for review" / "Convert to draft"
  /// affordances are not rendered.
  draftToggle,

  /// Pull requests carry a set of labels that can be listed, added and
  /// removed.
  ///
  /// When false the sidebar still shows whatever the payload already carried,
  /// and the add/remove controls are not rendered.
  labels,

  /// Every pull request ever opened from a branch can be listed exhaustively
  /// (the client implements `ForgeBranchPrHistoryClient`).
  branchHistory,

  /// Targeted reads behind the author notifications — the forge's own
  /// mergeability verdict, the latest approver, the first failing check (the
  /// client implements `ForgeMergeSignalsClient`).
  mergeSignals,

  /// A merge conflict can be read and resolved from a PR space (GitHub-only:
  /// the conflict seam reads GitHub's mergeability and pushes through its
  /// App lane).
  mergeConflictResolution,

  /// The account's activity feed (review requests, mentions) can be read for
  /// the viewer-activity poller.
  viewerActivity,

  /// The open list can be read page by page past the first ("load more";
  /// the client implements `ForgeOpenPrPagingClient`).
  openListPaging,

  /// Reviewers who already submitted a review can be asked to review again.
  ///
  /// GitHub supports this via `POST .../requested_reviewers`, whereas GitLab's
  /// REST `reviewer_ids` write and Bitbucket's `reviewers` write are no-ops
  /// for existing reviewers.
  reRequestReview;

  /// The capability named [name] on the wire, or null for one this build
  /// does not know.
  static ForgeCapability? tryParse(String name) {
    for (final c in values) {
      if (c.name == name) {
        return c;
      }
    }
    return null;
  }
}

/// What one forge can actually do: a set of [ForgeCapability].
///
/// **Static, not probed.** These are properties of *our integration* with a
/// forge's API, known at compile time — not something we discover at runtime.
/// Probing them would be a lie dressed as a measurement, the same distinction
/// `AdapterEnforcement` draws for agent CLIs. When we add support for something,
/// we edit [kForgeCapabilities].
///
/// The UI reads these to decide what to render: a Bitbucket PR must not show a
/// "Files viewed" toggle that silently does nothing, and a GitLab MR must not
/// show a stacks panel. Hiding beats a disabled control here — an affordance
/// that a forge structurally cannot have is not "temporarily unavailable".
class ForgeCapabilities {
  /// Creates a [ForgeCapabilities] descriptor holding [supported].
  const ForgeCapabilities({required this.forge, required this.supported});

  /// Reads a descriptor back off the wire (one bool per capability name).
  /// Absent or unknown keys read as unsupported rather than failing.
  factory ForgeCapabilities.fromJson(Map<String, dynamic> json) =>
      ForgeCapabilities(
        forge: ForgeHost.fromWire(json['forge'] as String?),
        supported: {
          for (final c in ForgeCapability.values)
            if (json[c.name] == true) c,
        },
      );

  /// The forge this describes.
  final ForgeHost forge;

  /// Everything this forge's integration supports.
  final Set<ForgeCapability> supported;

  /// Whether [capability] is supported.
  bool has(ForgeCapability capability) => supported.contains(capability);

  /// See [ForgeCapability.pendingReviewBatching].
  bool get pendingReviewBatching => has(ForgeCapability.pendingReviewBatching);

  /// See [ForgeCapability.requestChanges].
  bool get requestChanges => has(ForgeCapability.requestChanges);

  /// See [ForgeCapability.viewedStateSync].
  bool get viewedStateSync => has(ForgeCapability.viewedStateSync);

  /// See [ForgeCapability.reactions].
  bool get reactions => has(ForgeCapability.reactions);

  /// See [ForgeCapability.commentThreadResolution].
  bool get commentThreadResolution =>
      has(ForgeCapability.commentThreadResolution);

  /// See [ForgeCapability.teamReviewers].
  bool get teamReviewers => has(ForgeCapability.teamReviewers);

  /// See [ForgeCapability.suggestedReviewers].
  bool get suggestedReviewers => has(ForgeCapability.suggestedReviewers);

  /// See [ForgeCapability.ciChecks].
  bool get ciChecks => has(ForgeCapability.ciChecks);

  /// See [ForgeCapability.ciJobDetail].
  bool get ciJobDetail => has(ForgeCapability.ciJobDetail);

  /// See [ForgeCapability.stacks].
  bool get stacks => has(ForgeCapability.stacks);

  /// See [ForgeCapability.prTemplates].
  bool get prTemplates => has(ForgeCapability.prTemplates);

  /// See [ForgeCapability.notifications].
  bool get notifications => has(ForgeCapability.notifications);

  /// See [ForgeCapability.richUserProfiles].
  bool get richUserProfiles => has(ForgeCapability.richUserProfiles);

  /// See [ForgeCapability.serverSidePrHeadRef].
  bool get serverSidePrHeadRef => has(ForgeCapability.serverSidePrHeadRef);

  /// See [ForgeCapability.draftToggle].
  bool get draftToggle => has(ForgeCapability.draftToggle);

  /// See [ForgeCapability.labels].
  bool get labels => has(ForgeCapability.labels);

  /// See [ForgeCapability.reRequestReview].
  bool get reRequestReview => has(ForgeCapability.reRequestReview);

  /// Looks up a capability by its wire name, so the ratchet test can assert
  /// every declared capability is reachable.
  bool byName(String name) {
    final capability = ForgeCapability.tryParse(name);
    if (capability == null) {
      throw ArgumentError.value(name, 'name', 'Unknown forge capability');
    }
    return has(capability);
  }

  /// Every capability name, in declaration order. The settings "what works
  /// where" matrix and the ratchet test both iterate this.
  static List<String> get allNames => [
    for (final c in ForgeCapability.values) c.name,
  ];

  /// Serializes to the wire (one bool per capability plus the forge).
  Map<String, dynamic> toJson() => {
    'forge': forge.wire,
    for (final c in ForgeCapability.values) c.name: has(c),
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
    supported: {
      ForgeCapability.pendingReviewBatching,
      ForgeCapability.requestChanges,
      ForgeCapability.viewedStateSync,
      ForgeCapability.reactions,
      ForgeCapability.commentThreadResolution,
      ForgeCapability.teamReviewers,
      ForgeCapability.suggestedReviewers,
      ForgeCapability.ciChecks,
      ForgeCapability.ciJobDetail,
      ForgeCapability.stacks,
      ForgeCapability.prTemplates,
      ForgeCapability.notifications,
      ForgeCapability.richUserProfiles,
      ForgeCapability.serverSidePrHeadRef,
      ForgeCapability.draftToggle,
      ForgeCapability.labels,
      ForgeCapability.branchHistory,
      ForgeCapability.mergeSignals,
      ForgeCapability.mergeConflictResolution,
      ForgeCapability.viewerActivity,
      ForgeCapability.openListPaging,
      ForgeCapability.reRequestReview,
    },
  ),
  // GitLab: draft notes give real batching, approvals + "changes requested"
  // reviewer state give a verdict, pipelines give checks and job detail.
  // No stacks (no forge-level concept), no viewed-state API. The `Draft: `
  // title prefix *is* GitLab's draft flag, so toggling it is a title write
  // rather than a dedicated endpoint — but it is a real toggle.
  ForgeHost.gitlab: ForgeCapabilities(
    forge: ForgeHost.gitlab,
    supported: {
      ForgeCapability.pendingReviewBatching,
      ForgeCapability.requestChanges,
      ForgeCapability.reactions,
      ForgeCapability.teamReviewers,
      ForgeCapability.ciChecks,
      ForgeCapability.ciJobDetail,
      ForgeCapability.prTemplates,
      ForgeCapability.richUserProfiles,
      ForgeCapability.serverSidePrHeadRef,
      ForgeCapability.draftToggle,
      ForgeCapability.labels,
      ForgeCapability.branchHistory,
      ForgeCapability.openListPaging,
    },
  ),
  // Bitbucket Cloud is the thinnest surface of the three: comments post
  // individually (no draft/pending state), build statuses carry a result and a
  // link but no step-level detail, and there is no viewed state, no reaction
  // API, no notification feed, no label field and no PR head ref — a checkout
  // fetches the source branch by name.
  ForgeHost.bitbucket: ForgeCapabilities(
    forge: ForgeHost.bitbucket,
    supported: {
      ForgeCapability.requestChanges,
      ForgeCapability.suggestedReviewers,
      ForgeCapability.ciChecks,
      ForgeCapability.branchHistory,
    },
  ),
  ForgeHost.local: ForgeCapabilities(forge: ForgeHost.local, supported: {}),
};

/// The capabilities of [forge]. Total — every enum value has an entry.
ForgeCapabilities capabilitiesOf(ForgeHost forge) =>
    kForgeCapabilities[forge] ?? kForgeCapabilities[ForgeHost.local]!;
