import 'dart:async';
import 'dart:collection';

import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';

/// What renewing a sealed Slack grant came to.
sealed class SlackGrantRenewal {
  const SlackGrantRenewal();
}

/// Connect minted a fresh bot token; [token] carries it and the new seal.
final class SlackGrantRenewed extends SlackGrantRenewal {
  /// Creates the outcome.
  const SlackGrantRenewed(this.token);

  /// The renewed credential. Its seal replaces the stored one: the old seal's
  /// refresh token is spent.
  final ProviderToken token;
}

/// The grant can never be renewed again (revoked, uninstalled, the team was
/// connected to another server, or this server's Connect identity changed).
/// The only case that clears the stored grant.
final class SlackGrantRejected extends SlackGrantRenewal {
  /// Creates the outcome.
  const SlackGrantRejected(this.reason);

  /// A stable reason code, for the log.
  final String reason;
}

/// Connect or Slack could not be reached. The grant stays; the next call
/// tries again.
final class SlackGrantUnavailable extends SlackGrantRenewal {
  /// Creates the outcome.
  const SlackGrantUnavailable(this.reason);

  /// A stable reason code, for the log.
  final String reason;
}

/// The Connect side of the shared Slack app: renewing and revoking a sealed
/// bot grant, and attaching a team to the event relay.
abstract interface class SlackConnectGrants {
  /// Renews [sealed] for [workspaceId] (the slot it was sealed for).
  Future<SlackGrantRenewal> renew(
    ProviderToken sealed, {
    required String workspaceId,
  });

  /// Uninstalls the bot and releases the team binding. Best effort.
  Future<void> revoke(ProviderToken sealed, {required String workspaceId});

  /// Attaches a team's relayed events, for [workspaceId], to the relay of
  /// the Connect that workspace routes through.
  SlackRelayAttach attachFor(String workspaceId);
}

/// [SlackConnectGrants] over this server's [ConnectClient]: each workspace's
/// grant goes to the Connect that workspace routes through now.
class ConnectSlackGrants implements SlackConnectGrants {
  /// Creates the grants seam; [relay] defaults to one over [_connect].
  ConnectSlackGrants({required this._connect, ConnectSlackRelayHub? relay})
    : relay = relay ?? ConnectSlackRelayHub(connect: _connect);

  final ConnectClient _connect;

  /// The relay long-polls, one per Connect origin in use.
  final ConnectSlackRelayHub relay;

  @override
  SlackRelayAttach attachFor(String workspaceId) =>
      (teamId, {required onItem, required onState}) =>
          relay.attach(workspaceId, teamId, onItem: onItem, onState: onState);

  @override
  Future<SlackGrantRenewal> renew(
    ProviderToken sealed, {
    required String workspaceId,
  }) async {
    final unusable = await _unusable(sealed, workspaceId);
    if (unusable == 'connect_changed') {
      // The workspace's Connect is off or another one: the seal waits for
      // it to return.
      return const SlackGrantUnavailable('connect_changed');
    }
    if (unusable != null) {
      return SlackGrantRejected(unusable);
    }
    try {
      final grant = await _connect.refresh(
        await _connect.targetFor(workspaceId),
        ConnectProvider.slack,
        SealRequest(seal: sealed.seal, workspaceId: workspaceId),
      );
      return SlackGrantRenewed(
        sealed.copyWith(
          accessToken: grant.accessToken,
          expiresAt: grant.expiresAt,
          seal: grant.seal.isEmpty ? sealed.seal : grant.seal,
          issuedAt: DateTime.now().toUtc(),
        ),
      );
    } on ConnectException catch (e) {
      // `team_bound_elsewhere`: the team was connected to another server,
      // which Connect only allows through Slack's own admin check. This seal
      // can never refresh again.
      if (e.code.clearsGrant || e.code == ConnectErrorCode.teamBoundElsewhere) {
        return SlackGrantRejected(e.code.wire);
      }
      return SlackGrantUnavailable(e.code.wire);
    }
  }

  @override
  Future<void> revoke(
    ProviderToken sealed, {
    required String workspaceId,
  }) async {
    if (await _unusable(sealed, workspaceId) != null) {
      return;
    }
    try {
      await _connect.slackRevoke(
        await _connect.targetFor(workspaceId),
        SealRequest(seal: sealed.seal, workspaceId: workspaceId),
      );
    } on ConnectException catch (e) {
      CcHostLog.warning('Slack: revoking the shared app failed (${e.code})');
    }
  }

  /// Why [sealed] cannot be used with the Connect [workspaceId] talks to
  /// now, or null when it can. A seal is bound to the Connect that made it
  /// and to this server's install identity there.
  Future<String?> _unusable(ProviderToken sealed, String workspaceId) async {
    if (!sealed.isSealed) {
      return 'not_sealed';
    }
    return switch (await _connect.sealStanding(
      connectOrigin: sealed.connectOrigin,
      sealInstallId: sealed.sealInstallId,
      workspaceId: workspaceId,
    )) {
      SealStanding.usable => null,
      SealStanding.parked => 'connect_changed',
      SealStanding.dead => 'install_changed',
    };
  }
}

/// The relay long-polls, one per Connect origin an attached team's
/// workspace routes through.
///
/// Connect queues references per install, and the install identity is per
/// origin, so two loops on one origin would split its queue: there is exactly
/// one [ConnectSlackEventClient] per origin in use, and it runs only while a
/// team is attached to it. Each attachment resolves its workspace's target
/// when it attaches, and again on [rehome] (a server or workspace choice
/// changed), moving to that origin's loop. A workspace with no Connect is
/// told `connect_changed` and polls nothing.
class ConnectSlackRelayHub {
  /// Creates the hub over `connect`; `sleep` paces each loop's retries.
  ConnectSlackRelayHub({required this._connect, this._sleep});

  final ConnectClient _connect;
  final Future<void> Function(Duration delay)? _sleep;

  final Map<String, ConnectSlackEventClient> _loops = {};
  final Map<String, ConnectTarget> _targets = {};
  final Set<_RelayAttachment> _attachments = {};
  bool _closed = false;

  /// The origins with a loop, for diagnostics and tests.
  Iterable<String> get origins => _loops.keys;

  /// Attaches [teamId] for [workspaceId]; see [SlackRelayAttach].
  void Function() attach(
    String workspaceId,
    String teamId, {
    required void Function(SlackRelayItem item) onItem,
    required SlackTransportStateHandler onState,
  }) {
    final attachment = _RelayAttachment(workspaceId, teamId, onItem, onState);
    _attachments.add(attachment);
    unawaited(_home(attachment));
    return () {
      _attachments.remove(attachment);
      attachment.detach();
    };
  }

  /// Re-resolves every attachment of [workspaceId] (every one for null),
  /// moving it to the loop of the origin it routes through now.
  Future<void> rehome([String? workspaceId]) async {
    for (final attachment in List.of(_attachments)) {
      if (workspaceId == null || attachment.workspaceId == workspaceId) {
        await _home(attachment);
      }
    }
  }

  /// Stops every loop for good (server shutdown).
  void close() {
    _closed = true;
    _attachments.clear();
    for (final loop in _loops.values) {
      loop.close();
    }
    _loops.clear();
  }

  Future<void> _home(_RelayAttachment attachment) async {
    final generation = ++attachment.generation;
    final ConnectTarget target;
    try {
      target = await _connect.targetFor(attachment.workspaceId);
    } on Object catch (e) {
      CcHostLog.warning('Slack relay: resolving a Connect failed ($e)');
      return;
    }
    if (_closed ||
        generation != attachment.generation ||
        !_attachments.contains(attachment)) {
      return;
    }
    attachment.detach();
    if (!target.enabled) {
      attachment.onState(ChatConnectionState.connecting, 'connect_changed');
      return;
    }
    final origin = target.origin;
    // A workspace-chosen URL is polled through the guarded transport as soon
    // as any attachment on that origin needs it.
    final known = _targets[origin];
    if (known == null || (target.guarded && !known.guarded)) {
      _targets[origin] = target;
    }
    final loop = _loops.putIfAbsent(
      origin,
      () => ConnectSlackEventClient(
        poll: () => _connect.pollEvents(_targets[origin]!),
        sleep: _sleep,
      ),
    );
    attachment.inner = loop.attach(
      attachment.teamId,
      onItem: attachment.onItem,
      onState: attachment.onState,
    );
  }
}

class _RelayAttachment {
  _RelayAttachment(this.workspaceId, this.teamId, this.onItem, this.onState);

  final String workspaceId;
  final String teamId;
  final void Function(SlackRelayItem item) onItem;
  final SlackTransportStateHandler onState;
  void Function()? inner;
  int generation = 0;

  void detach() {
    inner?.call();
    inner = null;
  }
}

/// One long-poll on one Connect's relay, fanned out to the Slack teams
/// attached to it.
///
/// Connect queues references for this install, not per workspace, so there is
/// exactly one poll loop per Connect origin ([ConnectSlackRelayHub]). It runs
/// only while at least one team is
/// attached, dedupes by Slack's event id (Connect may redeliver after a
/// dropped poll) and routes each item by team id to the transport that
/// attached it. A team nobody attached is dropped: the relay cannot address a
/// workspace, only the team, and an unattached team has no grant here.
class ConnectSlackEventClient {
  /// Creates the client over `ConnectClient.pollEvents`.
  ConnectSlackEventClient({
    required this._poll,
    Future<void> Function(Duration delay)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final Future<List<Map<String, Object?>>> Function() _poll;
  final Future<void> Function(Duration delay) _sleep;

  final Map<String, _RelaySink> _sinks = {};
  final LinkedHashSet<String> _seen = LinkedHashSet<String>();
  static const int _seenLimit = 4096;

  bool _running = false;
  bool _closed = false;
  ChatConnectionState _state = ChatConnectionState.connecting;
  String? _lastError;

  /// Teams currently attached.
  Iterable<String> get attachedTeams => _sinks.keys;

  /// Attaches [teamId]; see [SlackRelayAttach].
  void Function() attach(
    String teamId, {
    required void Function(SlackRelayItem item) onItem,
    required SlackTransportStateHandler onState,
  }) {
    final sink = _RelaySink(onItem, onState);
    _sinks[teamId] = sink;
    onState(_state, _lastError);
    _ensureRunning();
    return () {
      if (identical(_sinks[teamId], sink)) {
        _sinks.remove(teamId);
      }
    };
  }

  /// Stops polling for good (server shutdown). A poll in flight finishes and
  /// is discarded.
  void close() {
    _closed = true;
    _sinks.clear();
  }

  void _ensureRunning() {
    if (_running || _closed) {
      return;
    }
    _running = true;
    unawaited(_loop());
  }

  Future<void> _loop() async {
    var failures = 0;
    try {
      while (!_closed && _sinks.isNotEmpty) {
        try {
          final items = await _poll();
          failures = 0;
          _broadcast(ChatConnectionState.connected, null);
          for (final raw in items) {
            _route(raw);
          }
        } on ConnectException catch (e) {
          failures++;
          _broadcast(ChatConnectionState.connecting, e.code.wire);
          await _sleep(_backoff(failures));
        } on Object catch (e) {
          failures++;
          CcHostLog.warning('Slack relay: poll failed ($e)');
          _broadcast(ChatConnectionState.connecting, 'relay_unavailable');
          await _sleep(_backoff(failures));
        }
      }
    } finally {
      _running = false;
    }
    // A team may have attached between the last check and `_running = false`.
    if (!_closed && _sinks.isNotEmpty) {
      _ensureRunning();
    }
  }

  static Duration _backoff(int failures) =>
      Duration(seconds: 1 << (failures - 1).clamp(0, 5));

  void _route(Map<String, Object?> raw) {
    final SlackRelayItem item;
    final String key;
    if (raw['kind'] == 'command') {
      final ref = SlackCommandRef.tryParse(raw);
      if (ref == null) {
        return;
      }
      item = SlackRelayedCommand(
        commandId: ref.commandId,
        teamId: ref.teamId,
        userId: ref.userId,
        channelId: ref.channelId,
        command: ref.command,
        text: ref.text,
        responseUrl: ref.responseUrl,
      );
      key = 'cmd:${ref.commandId}';
    } else {
      final ref = SlackEventRef.tryParse(raw);
      if (ref == null) {
        return;
      }
      item = SlackRelayedEvent(
        eventId: ref.eventId,
        teamId: ref.teamId,
        eventType: ref.eventType,
        channelId: ref.channelId,
        threadTs: ref.threadTs,
        messageTs: ref.messageTs,
      );
      key = 'ev:${ref.eventId}';
    }
    final sink = _sinks[item.teamId];
    if (sink == null || !_seen.add(key)) {
      return;
    }
    if (_seen.length > _seenLimit) {
      _seen.remove(_seen.first);
    }
    sink.onItem(item);
  }

  void _broadcast(ChatConnectionState state, String? error) {
    if (state == _state && error == _lastError) {
      return;
    }
    _state = state;
    _lastError = error;
    for (final sink in List.of(_sinks.values)) {
      sink.onState(state, error);
    }
  }
}

class _RelaySink {
  _RelaySink(this.onItem, this.onState);

  final void Function(SlackRelayItem item) onItem;
  final SlackTransportStateHandler onState;
}

/// One Connect-mode workspace's bot token: the sealed grant on disk, the
/// short-lived `xoxe.xoxb-` access token in memory only.
///
/// The token is renewed five minutes before it expires, single-flight, so a
/// burst of Slack calls costs one refresh. Every renewal is persisted before
/// anything else can fail (the previous seal's refresh token is spent) and is
/// then proven with `auth.test`: the new token must still be the team, bot
/// user and bot id the connection was saved with.
class SlackConnectSession {
  /// Creates the session for [connection], starting from [token] (which may
  /// already carry a fresh access token, right after sign-in).
  SlackConnectSession({
    required this.connection,
    required this._token,
    required this._grants,
    required this._authTest,
    required this._persist,
    required this._onRejected,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  /// The connection the token belongs to.
  final ChatBridgeConnection connection;

  final SlackConnectGrants _grants;

  /// `auth.test` with an explicit token.
  final Future<SlackAuthIdentity> Function(String token) _authTest;

  /// Persists a renewed grant (its new seal).
  final Future<void> Function(ProviderToken token) _persist;

  /// Called once when the grant is rejected for good.
  final void Function(String reason) _onRejected;

  final DateTime Function() _clock;

  /// How long before expiry a token is renewed.
  static const Duration renewMargin = Duration(minutes: 5);

  ProviderToken _token;
  Future<String>? _inflight;
  String? _rejected;

  /// The current grant (access token in memory, seal for disk).
  ProviderToken get token => _token;

  /// Why the grant was rejected, once it has been.
  String? get rejection => _rejected;

  /// The bot token for the next Slack call; see [SlackBotTokenSource].
  Future<String> botToken({bool renew = false}) {
    if (_rejected != null) {
      return Future.error(const SlackApiException('connect', 'token_revoked'));
    }
    if (!renew && _fresh) {
      return Future.value(_token.accessToken);
    }
    return _inflight ??= _renew().whenComplete(() => _inflight = null);
  }

  bool get _fresh {
    final expires = _token.expiresAt;
    return _token.accessToken.isNotEmpty &&
        expires != null &&
        _clock().isBefore(expires.subtract(renewMargin));
  }

  Future<String> _renew() async {
    final outcome = await _grants.renew(
      _token,
      workspaceId: connection.workspaceId,
    );
    switch (outcome) {
      case SlackGrantRejected(:final reason):
        _reject(reason);
        throw const SlackApiException('connect', 'token_revoked');
      case SlackGrantUnavailable(:final reason):
        throw SlackApiException('connect', reason);
      case SlackGrantRenewed(:final token):
        if (!token.accessToken.startsWith(slackRotatingBotTokenPrefix)) {
          _reject('not_a_rotating_bot_token');
          throw const SlackApiException('connect', 'token_revoked');
        }
        _token = token;
        // The old seal's refresh token is spent: store the new one first.
        await _persist(token);
        await _verify(token.accessToken);
        return token.accessToken;
    }
  }

  Future<void> _verify(String accessToken) async {
    final SlackAuthIdentity identity;
    try {
      identity = await _authTest(accessToken);
    } on SlackApiException catch (e) {
      if (e.isAuthFailure) {
        rethrow;
      }
      CcHostLog.warning(
        'Slack(${connection.workspaceId}): auth.test after renewal failed '
        '(${e.error})',
      );
      return;
    } on Object catch (e) {
      CcHostLog.warning(
        'Slack(${connection.workspaceId}): auth.test after renewal failed '
        '($e)',
      );
      return;
    }
    if (identity.teamId != connection.teamId ||
        identity.userId != connection.botUserId ||
        identity.botId != connection.botId) {
      _reject('bot_identity_mismatch');
      throw const SlackApiException('auth.test', 'bot_identity_mismatch');
    }
  }

  void _reject(String reason) {
    if (_rejected != null) {
      return;
    }
    _rejected = reason;
    CcHostLog.warning(
      'Slack(${connection.workspaceId}): the shared app grant was rejected '
      '($reason)',
    );
    _onRejected(reason);
  }
}

/// The prefix of a rotating Slack bot token, the only kind the shared app
/// issues.
const String slackRotatingBotTokenPrefix = 'xoxe.xoxb-';
