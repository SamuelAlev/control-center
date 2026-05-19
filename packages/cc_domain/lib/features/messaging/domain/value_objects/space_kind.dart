/// How a messaging space came to exist (PRD 22 §1, §5).
///
/// The discriminator lets agent↔agent spaces be sectioned separately in the
/// sidebar, muted-by-default (agent chatter never touches human unread counts /
/// notifications) and GC'd by their own retention policy.
enum SpaceKind {
  /// A human-created space (the default).
  topic('topic'),

  /// An agent↔agent peer space (sectioned, muted-by-default, own retention).
  agentPeer('agentPeer'),

  /// A system space (pipeline-managed, provisioning, etc.).
  system('system'),

  /// A PR space, created idempotently by `pr.ensureSpace` the moment a PR
  /// surface (chat/terminal/files) needs a worktree anchor. Hidden from the
  /// sidebar until it has messages, so merely opening a PR never clutters the
  /// space list.
  pr('pr'),

  /// A space created by the chat bridge for a Slack thread or bot DM. It is
  /// an ordinary human-facing conversation — sectioned and notified like
  /// [topic] — but the kind lets a surface show where it is mirrored to.
  ///
  /// One value per bridged product, so a surface can badge the source without
  /// joining the link table; behavioral checks go through [isExternalChat] so
  /// adding a provider is one value here and nothing else.
  slack('slack');

  const SpaceKind(this.wire);

  /// The stable wire/storage string.
  final String wire;

  /// Parses a [SpaceKind] from its [wire] string, defaulting to [topic].
  static SpaceKind fromWire(String? value) => SpaceKind.values.firstWhere(
    (o) => o.wire == value,
    orElse: () => SpaceKind.topic,
  );

  /// Whether this is an agent↔agent peer space (muted-by-default, sectioned).
  bool get isAgentPeer => this == SpaceKind.agentPeer;

  /// Whether this is a PR space (sidebar-hidden until messaged).
  bool get isPr => this == SpaceKind.pr;

  /// Whether this space is bridged from an external chat product.
  ///
  /// The check every behavior uses — mirroring, badging, retention — so a new
  /// provider is one enum value and no new branches.
  bool get isExternalChat => this == SpaceKind.slack;
}
