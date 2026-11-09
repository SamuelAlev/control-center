import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/slack_api_client.dart';
import 'package:cc_infra/src/slack/slack_socket_mode_client.dart';
import 'package:cc_infra/src/slack/slack_transport.dart';

/// One item the Connect relay delivered for a Slack team.
sealed class SlackRelayItem {
  const SlackRelayItem({required this.teamId});

  /// The Slack team the item belongs to.
  final String teamId;
}

/// A body-stripped Slack event reference: ids and timestamps, never text.
final class SlackRelayedEvent extends SlackRelayItem {
  /// Creates the reference.
  const SlackRelayedEvent({
    required this.eventId,
    required super.teamId,
    required this.eventType,
    this.channelId = '',
    this.threadTs = '',
    this.messageTs = '',
  });

  /// Slack's event id.
  final String eventId;

  /// `app_mention`, `message.<channel_type>`, `assistant_thread_started`, …
  final String eventType;

  /// The channel.
  final String channelId;

  /// The thread root, when in a thread.
  final String threadTs;

  /// The message timestamp.
  final String messageTs;
}

/// A relayed slash command. Slack cannot re-read a command, so its bounded
/// argument text travels with it.
final class SlackRelayedCommand extends SlackRelayItem {
  /// Creates the command.
  const SlackRelayedCommand({
    required this.commandId,
    required super.teamId,
    required this.userId,
    required this.channelId,
    required this.command,
    required this.text,
    required this.responseUrl,
  });

  /// Unique id the relay assigned.
  final String commandId;

  /// Who ran it.
  final String userId;

  /// Where.
  final String channelId;

  /// The command (`/cc`).
  final String command;

  /// Its argument text.
  final String text;

  /// Slack's response URL.
  final String responseUrl;
}

/// Attaches a sink for one Slack team to the server's relay and returns the
/// function that detaches it. Attaching the same team again replaces the
/// previous sink.
typedef SlackRelayAttach =
    void Function() Function(
      String teamId, {
      required void Function(SlackRelayItem item) onItem,
      required SlackTransportStateHandler onState,
    });

/// [SlackTransport] for a workspace on the shared Connect Slack app.
///
/// The relay hands over references only; this transport turns each one into
/// the same [SlackEnvelope] Socket Mode would have delivered by re-reading the
/// message from Slack with the workspace's own bot token. Two rules hold on
/// that re-read, because the reference itself proves nothing about content:
///
///  * **The message is what Slack says now**, not what any relay claimed.
///  * **Edits by anyone but the author are dropped.** A message edited by an
///    admin or an integration would otherwise reach an agent attributed to the
///    person who wrote the original.
class SlackRelayTransport implements SlackTransport {
  /// Creates a relay transport for [teamId] in [workspaceId].
  SlackRelayTransport({
    required this.workspaceId,
    required this.teamId,
    required this._api,
    required this._attach,
    required this._onEnvelope,
    this._onStateChanged,
  });

  /// The Control Center workspace this transport serves.
  final String workspaceId;

  /// The one Slack team this workspace's grant is bound to.
  final String teamId;

  final SlackApiClient _api;
  final SlackRelayAttach _attach;
  final SlackEnvelopeHandler _onEnvelope;
  final SlackTransportStateHandler? _onStateChanged;

  void Function()? _detach;
  ChatConnectionState _state = ChatConnectionState.disconnected;
  String? _lastError;

  /// Items are handled one after another: the re-reads are rate-limited by
  /// Slack and the order a person wrote in is the order agents should see.
  Future<void> _tail = Future<void>.value();

  /// Message keys already turned into envelopes, newest last. A mention
  /// arrives as both `app_mention` and `message.*`, so the key includes the
  /// kind; the adapter drops the plain copy itself.
  final LinkedHashSet<String> _seen = LinkedHashSet<String>();
  static const int _seenLimit = 1024;

  @override
  ChatConnectionState get state => _state;

  @override
  String? get lastError => _lastError;

  @override
  Future<void> start() async {
    if (_detach != null) {
      return;
    }
    _setState(ChatConnectionState.connecting, null);
    _detach = _attach(
      teamId,
      onItem: (item) => _tail = _tail.then((_) => _handle(item)),
      onState: _setState,
    );
  }

  @override
  Future<void> stop() async {
    final detach = _detach;
    _detach = null;
    detach?.call();
    await _tail;
    _setState(ChatConnectionState.disconnected, null);
  }

  /// Handles one relayed item. Public so the re-read rules can be tested
  /// without a relay.
  Future<void> handle(SlackRelayItem item) => _handle(item);

  Future<void> _handle(SlackRelayItem item) async {
    if (item.teamId != teamId) {
      return;
    }
    try {
      final envelope = switch (item) {
        SlackRelayedEvent() => await _eventEnvelope(item),
        SlackRelayedCommand() => _commandEnvelope(item),
      };
      if (envelope != null) {
        await _onEnvelope(envelope);
      }
    } on Object catch (e) {
      CcInfraLog.warning(
        'SlackRelay($workspaceId): dropping ${item.runtimeType}: $e',
      );
    }
  }

  Future<SlackEnvelope?> _eventEnvelope(SlackRelayedEvent ref) async {
    final (kind, channelType) = _kindOf(ref);
    if (kind == null || ref.channelId.isEmpty || ref.messageTs.isEmpty) {
      return null;
    }
    if (!_remember('${ref.channelId}:${ref.messageTs}:$kind')) {
      return null;
    }
    final message = await _api.readMessage(
      channel: ref.channelId,
      ts: ref.messageTs,
      threadTs: ref.threadTs.isEmpty ? null : ref.threadTs,
    );
    if (message == null) {
      return null;
    }
    final author = message['user'];
    final edited = message['edited'];
    if (edited is Map && edited['user'] != author) {
      return null;
    }
    return SlackEnvelope(
      type: 'events_api',
      payload: {
        'team_id': teamId,
        'event_id': ref.eventId,
        'event': {
          ...message,
          'type': kind,
          'channel': ref.channelId,
          'channel_type': ?channelType,
          'team': message['team'] ?? teamId,
        },
      },
    );
  }

  SlackEnvelope? _commandEnvelope(SlackRelayedCommand command) {
    if (command.userId.isEmpty || !_remember('cmd:${command.commandId}')) {
      return null;
    }
    return SlackEnvelope(
      type: 'slash_commands',
      payload: {
        'team_id': teamId,
        'trigger_id': command.commandId,
        'user_id': command.userId,
        'channel_id': command.channelId,
        'command': command.command,
        'text': command.text,
        // The adapter honours only `https://hooks.slack.com/`; anything else
        // is dropped there, so it is passed through untouched.
        'response_url': command.responseUrl,
      },
    );
  }

  /// The Events API type and channel type a reference stands for, or null for
  /// a kind the bridge does not serve. Multi-person DMs are dropped: the
  /// shared app holds no `mpim:history` scope to re-read them.
  static (String?, String?) _kindOf(SlackRelayedEvent ref) {
    if (ref.eventType == 'app_mention') {
      return ('app_mention', null);
    }
    if (!ref.eventType.startsWith('message.')) {
      return (null, null);
    }
    final channelType = ref.eventType.substring('message.'.length);
    return switch (channelType) {
      'im' || 'channel' || 'group' => ('message', channelType),
      _ => (null, null),
    };
  }

  bool _remember(String key) {
    if (!_seen.add(key)) {
      return false;
    }
    if (_seen.length > _seenLimit) {
      _seen.remove(_seen.first);
    }
    return true;
  }

  void _setState(ChatConnectionState state, String? error) {
    _state = state;
    _lastError = error;
    _onStateChanged?.call(state, error);
  }
}
