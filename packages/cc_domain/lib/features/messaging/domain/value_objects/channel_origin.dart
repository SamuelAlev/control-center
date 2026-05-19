/// How a messaging channel came to exist (PRD 22 §1, §5).
///
/// The discriminator lets agent↔agent channels be sectioned separately in the
/// sidebar, muted-by-default (agent chatter never touches human unread counts /
/// notifications), and GC'd by their own retention policy.
enum ChannelOrigin {
  /// A human-facing conversation (the default; every legacy row).
  user('user'),

  /// An agent↔agent peer channel (sectioned, muted-by-default, own retention).
  agentDm('agentDm'),

  /// A system channel (pipeline-managed, provisioning, etc.).
  system('system'),

  /// A PR-workbench channel, created idempotently by `pr.ensureChannel` the
  /// moment a PR surface (chat/terminal/files) needs a worktree anchor.
  /// Hidden from the sidebar until it has messages, so merely opening a PR
  /// never clutters the channel list.
  prWorkbench('prWorkbench'),

  /// A channel created by the chat bridge for a Slack thread or bot DM. It is
  /// an ordinary human-facing conversation — sectioned and notified like
  /// [user] — but the origin lets a surface show where it is mirrored to.
  ///
  /// One value per bridged product, so a surface can badge the source without
  /// joining the link table; behavioral checks go through [isExternalChat] so
  /// adding a provider is one value here and nothing else.
  slack('slack');

  const ChannelOrigin(this.wire);

  /// The stable wire/storage string.
  final String wire;

  /// Parses a [ChannelOrigin] from its [wire] string, defaulting to [user].
  static ChannelOrigin fromWire(String? value) => ChannelOrigin.values
      .firstWhere((o) => o.wire == value, orElse: () => ChannelOrigin.user);

  /// Whether this is an agent-DM channel (muted-by-default, sectioned).
  bool get isAgentDm => this == ChannelOrigin.agentDm;

  /// Whether this is a PR-workbench channel (sidebar-hidden until messaged).
  bool get isPrWorkbench => this == ChannelOrigin.prWorkbench;

  /// Whether this channel is bridged from an external chat product.
  ///
  /// The check every behavior uses — mirroring, badging, retention — so a new
  /// provider is one enum value and no new branches.
  bool get isExternalChat => this == ChannelOrigin.slack;
}
