/// How a chat identity came to be linked to a Control Center user.
///
/// Provenance, not permission: no method grants access on its own — the linked
/// user must still be a member of the workspace when the bridge runs.
enum ChatLinkMethod {
  /// The provider's verified account email matched a Control Center user's.
  email('email'),

  /// The user redeemed a one-time code from Control Center via `/cc link`.
  code('code'),

  /// An owner/admin linked the pair by hand from workspace settings.
  manual('manual');

  const ChatLinkMethod(this.wire);

  /// The stable wire/storage string.
  final String wire;

  /// Parses a [ChatLinkMethod] from its [wire] string, defaulting to [code].
  static ChatLinkMethod fromWire(String? value) => ChatLinkMethod.values
      .firstWhere((m) => m.wire == value, orElse: () => ChatLinkMethod.code);
}
