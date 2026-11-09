import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_infra/src/slack/slack_socket_mode_client.dart';

/// How Slack events reach a workspace's adapter.
///
/// Two implementations, one per connection mode: [SlackSocketModeClient]
/// dials Slack directly with an own app's `xapp-` token, and
/// `SlackRelayTransport` receives body-stripped references from the Connect
/// relay and re-reads each message from Slack. The adapter above sees the same
/// [SlackEnvelope]s either way.
abstract interface class SlackTransport {
  /// Live transport state, as the settings surface shows it.
  ChatConnectionState get state;

  /// The last failure, or null when healthy.
  String? get lastError;

  /// Starts delivering envelopes. Returns once the first attempt settled.
  Future<void> start();

  /// Stops for good. Safe to call twice.
  Future<void> stop();
}

/// Reports a transport state change to the adapter.
typedef SlackTransportStateHandler =
    void Function(ChatConnectionState state, String? error);

/// Builds the transport for one adapter, wired to its envelope and state
/// handlers. The adapter calls it once, from its constructor.
typedef SlackTransportFactory =
    SlackTransport Function({
      required SlackEnvelopeHandler onEnvelope,
      required SlackTransportStateHandler onStateChanged,
    });
