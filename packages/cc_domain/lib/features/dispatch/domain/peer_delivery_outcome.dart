/// How a peer message reached (or failed to reach) its recipient agent.
///
/// Reports the delivery MECHANISM, never what the recipient did with the
/// message. Consumed by the `send_to_agent` tool's reply payload so the sending
/// agent can tell "the recipient is working on it now" from "it is sitting in
/// the channel until the recipient next runs".
///
/// (Formerly `IrcDeliveryOutcome`, in a `domain/irc/` directory left over from
/// the deleted in-memory IRC bus. Agent↔agent messages ride durable channels
/// now; only this vocabulary survived, so it moved out of that directory and
/// lost the misleading prefix.)
enum PeerDeliveryOutcome {
  /// A pending wait (or live session sink) consumed the message directly.
  injected,

  /// An idle recipient was given a real wake turn.
  woken,

  /// A parked recipient was revived first, then the message delivered.
  revived,

  /// Live hand-off failed; the message stays in the channel for the recipient's
  /// next turn (or the recipient is unknown / terminated / not messageable).
  failed,
}
