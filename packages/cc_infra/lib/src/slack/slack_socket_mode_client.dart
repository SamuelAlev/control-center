import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/slack_api_client.dart';
import 'package:cc_infra/src/slack/slack_socket.dart';

/// One inbound Socket Mode envelope.
///
/// Slack wraps every event in an envelope so the client can acknowledge it:
/// unacknowledged envelopes are redelivered (with `retryAttempt` set), which is
/// why the bridge dedupes on the event id rather than trusting single delivery.
class SlackEnvelope {
  /// Creates a [SlackEnvelope].
  const SlackEnvelope({
    required this.type,
    required this.payload,
    this.envelopeId,
    this.acceptsResponsePayload = false,
    this.retryAttempt = 0,
    this.retryReason,
  });

  /// Parses an envelope from a decoded Socket Mode frame.
  factory SlackEnvelope.fromJson(Map<String, dynamic> json) => SlackEnvelope(
    type: json['type'] as String? ?? '',
    payload: json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : const <String, dynamic>{},
    envelopeId: json['envelope_id'] as String?,
    acceptsResponsePayload: json['accepts_response_payload'] as bool? ?? false,
    retryAttempt: json['retry_attempt'] as int? ?? 0,
    retryReason: json['retry_reason'] as String?,
  );

  /// Envelope kind: `events_api`, `slash_commands`, `interactive`.
  final String type;

  /// The wrapped Slack payload (an Events API envelope, a command, …).
  final Map<String, dynamic> payload;

  /// Ack key. Absent on `hello` / `disconnect` control frames.
  final String? envelopeId;

  /// Whether the ack may carry a response body (slash commands do).
  final bool acceptsResponsePayload;

  /// Redelivery counter — non-zero means Slack did not see our ack in time.
  final int retryAttempt;

  /// Why Slack redelivered (`timeout`, `http_error`, …).
  final String? retryReason;

  /// The inner `event` object of an Events API envelope, when present.
  Map<String, dynamic>? get event {
    final raw = payload['event'];
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  /// The Slack team this envelope came from.
  ///
  /// Events API and slash-command payloads carry `team_id`; interactive
  /// payloads carry a `team` object instead.
  String? get teamId => switch ((payload['team_id'], payload['team'])) {
    (final String id, _) => id,
    (_, final String id) => id,
    (_, final Map team) => team['id'] as String?,
    _ => null,
  };

  /// A stable id for deduplicating redeliveries: the Events API event id, the
  /// slash command's one-shot trigger id, else the envelope id. All three are
  /// stable across a redelivery of the *same* user action, which is exactly
  /// what dedupe must key on.
  String get dedupeKey =>
      (payload['event_id'] as String?) ??
      (payload['trigger_id'] as String?) ??
      envelopeId ??
      '${payload.hashCode}';
}

/// Handles one inbound envelope. Runs *after* the ack, so it may take as long
/// as it needs (an agent dispatch takes minutes).
typedef SlackEnvelopeHandler = Future<void> Function(SlackEnvelope envelope);

/// A long-lived Socket Mode connection for ONE Control Center workspace.
///
/// Socket Mode is what makes a Slack app work from a server with no public
/// endpoint: instead of Slack POSTing to a webhook, `cc_server` dials *out* over
/// WSS and Slack pushes events down that connection. One client per connected
/// workspace, each born knowing its [workspaceId] — so an inbound event never
/// has to be mapped back to a workspace by scanning.
///
/// Three protocol details are load-bearing:
///
///  * **Ack within 3 seconds, before processing.** Slack redelivers an envelope
///    it has not seen acknowledged, so the ack is sent the moment the frame is
///    parsed and the handler runs afterwards. Acking after the work would turn
///    every slow agent dispatch into a duplicate delivery.
///  * **`disconnect` is routine, not an error.** Slack rotates connections
///    (typically hourly and before maintenance) by sending
///    `type: disconnect, reason: refresh_requested`. That reconnects promptly
///    and does NOT escalate the backoff; only real failures do.
///  * **A rejected token is terminal.** `invalid_auth` / `token_revoked` cannot
///    be fixed by retrying, so the client stops and reports [lastError] for the
///    settings surface instead of hammering Slack forever.
class SlackSocketModeClient {
  /// Creates a [SlackSocketModeClient].
  SlackSocketModeClient({
    required this.workspaceId,
    required this.appToken,
    required SlackApiClient api,
    required SlackEnvelopeHandler onEnvelope,
    SlackSocketConnector? connector,
    void Function(ChatConnectionState state, String? error)? onStateChanged,
    bool debugReconnects = false,
  }) : _api = api,
       _onEnvelope = onEnvelope,
       _connector = connector ?? connectSlackSocket,
       _onStateChanged = onStateChanged,
       _debugReconnects = debugReconnects;

  /// The Control Center workspace this connection serves.
  final String workspaceId;

  /// App-level token (`xapp-…`) used to mint a fresh WebSocket URL.
  final String appToken;

  final SlackApiClient _api;
  final SlackEnvelopeHandler _onEnvelope;
  final SlackSocketConnector _connector;
  final void Function(ChatConnectionState state, String? error)?
  _onStateChanged;
  final bool _debugReconnects;

  SlackSocket? _socket;

  /// Cancelled in [_teardown] on every drop, refresh and [stop].
  // ignore: cancel_subscriptions
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  bool _stopped = false;
  bool _connecting = false;
  int _backoffStep = 0;

  ChatConnectionState _state = ChatConnectionState.disconnected;
  String? _lastError;

  /// Live connection state, as the settings surface shows it.
  ChatConnectionState get state => _state;

  /// The last failure, or null when healthy.
  String? get lastError => _lastError;

  /// Whether the socket is currently up.
  bool get isConnected => _state == ChatConnectionState.connected;

  /// Opens the connection and keeps it open until [stop].
  Future<void> start() async {
    _stopped = false;
    await _connect();
  }

  /// Closes the connection for good. Safe to call twice.
  Future<void> stop() async {
    _stopped = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _teardown();
    _setState(ChatConnectionState.disconnected, null);
  }

  Future<void> _connect() async {
    if (_stopped || _connecting) {
      return;
    }
    _connecting = true;
    _setState(ChatConnectionState.connecting, _lastError);
    try {
      final url = await _api.openConnection(
        appToken: appToken,
        debugReconnects: _debugReconnects,
      );
      final socket = await _connector(url);
      _socket = socket;
      _sub = socket.messages.listen(
        _onFrame,
        onError: (Object error) {
          CcInfraLog.warning(
            'SlackSocketModeClient($workspaceId): socket error: $error',
          );
          _handleDrop('$error');
        },
        onDone: () => _handleDrop(null),
        cancelOnError: false,
      );
      _backoffStep = 0;
      _setState(ChatConnectionState.connected, null);
      CcInfraLog.info('SlackSocketModeClient($workspaceId): connected');
    } on SlackApiException catch (e) {
      // A rejected app-level token, or Socket Mode turned off in app config:
      // retrying cannot fix either and a retry loop would bury the real
      // problem in log noise. Stop and surface it.
      if (e.isAuthFailure || e.isMissingScope) {
        _stopped = true;
        _setState(ChatConnectionState.error, e.error);
        CcInfraLog.error(
          'SlackSocketModeClient($workspaceId): refusing to reconnect: '
          '${e.error}',
        );
      } else {
        _setState(ChatConnectionState.error, e.error);
        _scheduleReconnect();
      }
    } on Object catch (e) {
      _setState(ChatConnectionState.error, '$e');
      CcInfraLog.warning(
        'SlackSocketModeClient($workspaceId): connect failed: $e',
      );
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onFrame(dynamic frame) {
    if (frame is! String) {
      return;
    }
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(frame);
      if (decoded is! Map) {
        return;
      }
      json = Map<String, dynamic>.from(decoded);
    } on FormatException catch (e) {
      CcInfraLog.warning(
        'SlackSocketModeClient($workspaceId): undecodable frame: $e',
      );
      return;
    }

    switch (json['type'] as String?) {
      case 'hello':
        CcInfraLog.debug(
          'SlackSocketModeClient($workspaceId): hello '
          '(${json['num_connections']} connection(s))',
        );
        _setState(ChatConnectionState.connected, null);
      case 'disconnect':
        final reason = json['reason'] as String? ?? 'unspecified';
        if (reason == 'link_disabled') {
          // Socket Mode was switched off for the app: reconnecting is refused
          // by Slack, so this is terminal until the owner re-enables it.
          _stopped = true;
          _setState(ChatConnectionState.error, 'link_disabled');
          unawaited(_teardown());
          return;
        }
        CcInfraLog.info(
          'SlackSocketModeClient($workspaceId): disconnect ($reason), '
          'reconnecting',
        );
        // Expected rotation: reconnect promptly without escalating backoff.
        _backoffStep = 0;
        unawaited(_reconnectNow());
      default:
        final envelope = SlackEnvelope.fromJson(json);
        if (envelope.envelopeId == null) {
          return;
        }
        _ack(envelope.envelopeId!);
        unawaited(_dispatch(envelope));
    }
  }

  /// Acks [envelopeId] immediately. A failed send is not fatal: Slack will
  /// redeliver and the handler's dedupe absorbs it.
  void _ack(String envelopeId) {
    final socket = _socket;
    if (socket == null || !socket.isOpen) {
      return;
    }
    try {
      socket.send(jsonEncode({'envelope_id': envelopeId}));
    } on Object catch (e) {
      CcInfraLog.warning('SlackSocketModeClient($workspaceId): ack failed: $e');
    }
  }

  Future<void> _dispatch(SlackEnvelope envelope) async {
    try {
      await _onEnvelope(envelope);
    } on Object catch (e, s) {
      // One malformed event must never take the bridge down; the connection
      // keeps serving every other conversation.
      CcInfraLog.error(
        'SlackSocketModeClient($workspaceId): handler failed for '
        '${envelope.type}',
        e,
        s,
      );
    }
  }

  void _handleDrop(String? error) {
    if (_stopped) {
      return;
    }
    _setState(ChatConnectionState.connecting, error ?? _lastError);
    unawaited(_teardown());
    _scheduleReconnect();
  }

  Future<void> _reconnectNow() async {
    await _teardown();
    if (!_stopped) {
      await _connect();
    }
  }

  Future<void> _teardown() async {
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
    final socket = _socket;
    _socket = null;
    await socket?.close();
  }

  /// Exponential backoff with jitter, capped at 30s — the same shape as the
  /// relay host's reconnect, so N workspaces reconnecting after a network blip
  /// do not arrive in lockstep.
  void _scheduleReconnect() {
    if (_stopped || _reconnectTimer != null) {
      return;
    }
    final base = (1 << _backoffStep.clamp(0, 5)) * 500;
    _backoffStep++;
    final jitter = Random().nextInt(400);
    final delay = Duration(milliseconds: base.clamp(500, 30000) + jitter);
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_stopped) {
        unawaited(_connect());
      }
    });
  }

  void _setState(ChatConnectionState state, String? error) {
    if (_state == state && _lastError == error) {
      return;
    }
    _state = state;
    _lastError = error;
    _onStateChanged?.call(state, error);
  }
}
