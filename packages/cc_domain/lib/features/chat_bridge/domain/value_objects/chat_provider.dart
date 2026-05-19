import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';

/// A third-party chat product Control Center can bridge a workspace to.
///
/// The discriminator every link row, credential file, RPC op and settings card
/// carries, so a workspace can be bridged to more than one product at once and
/// a Slack thread can never resolve a Discord conversation's space.
///
/// Adding a provider is one value here plus one adapter — nothing else in the
/// bridge, the schema, the RPC surface or the UI is provider-shaped.
enum ChatProvider {
  /// Slack, over Socket Mode (outbound WSS, no public endpoint needed).
  slack('slack', 'Slack');

  const ChatProvider(this.wire, this.displayName);

  /// The stable wire/storage string. Never derived from [name] — a rename of
  /// the Dart identifier must not silently orphan stored rows.
  final String wire;

  /// The product's name as it writes it, for user-facing copy.
  final String displayName;

  /// Parses a [ChatProvider] from its [wire] string, or null when this build
  /// does not know it (a row written by a newer version).
  static ChatProvider? tryFromWire(String? value) {
    for (final provider in ChatProvider.values) {
      if (provider.wire == value) {
        return provider;
      }
    }
    return null;
  }

  /// Parses a [ChatProvider] from its [wire] string, throwing when unknown.
  ///
  /// Used where a caller supplied the value (an RPC argument): an unknown
  /// provider is a request to reject, not a row to skip.
  static ChatProvider fromWire(String? value) =>
      tryFromWire(value) ??
      (throw ArgumentError.value(value, 'value', 'unknown chat provider'));

  /// The origin a space bridged from this provider is created with.
  ///
  /// Exhaustive on purpose: a new provider does not compile until it has an
  /// origin, which is what keeps a bridged space from looking like an ordinary
  /// one to mirroring, badging and retention.
  SpaceKind get spaceKind => switch (this) {
    ChatProvider.slack => SpaceKind.slack,
  };
}
