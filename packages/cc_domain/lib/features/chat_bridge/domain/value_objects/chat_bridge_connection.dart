import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';

/// Whose provider-side app a [ChatBridgeConnection] runs on.
enum ChatConnectionMode {
  /// The workspace's own app: an admin pasted its tokens (Slack Socket Mode
  /// `xapp-` + `xoxb-`) and the server dials the provider directly.
  own('own'),

  /// The shared app behind Control Center Connect: the server holds only a
  /// sealed refresh grant on disk, keeps the short-lived bot token in memory and
  /// receives event references through the Connect relay.
  connect('connect');

  const ChatConnectionMode(this.wire);

  /// The stable wire/storage string.
  final String wire;

  /// Parses a [ChatConnectionMode] from its [wire] string. A record that
  /// names no mode was saved by the paste flow, which is [own].
  static ChatConnectionMode fromWire(String? value) => ChatConnectionMode.values
      .firstWhere((m) => m.wire == value, orElse: () => ChatConnectionMode.own);
}

/// One Control Center workspace's connection to one chat provider.
///
/// A connection belongs to a workspace, not to the server: an admin installs the
/// provider-side app and connects it here and every member of *that* workspace
/// can then drive agents from chat once their identity is linked. Two workspaces
/// may connect two different apps (even in the same Slack team or Discord guild)
/// without interfering — a mention addresses exactly one bot user.
///
/// The secrets live in [credentials], keyed by the provider descriptor's field
/// ids (or, for a [ChatConnectionMode.connect] connection, the sealed grant
/// alone), in the workspace's own directory beside its database — so they are
/// removed with the workspace and never ride inside a `workspace.db` export.
class ChatBridgeConnection {
  /// Creates a [ChatBridgeConnection].
  ChatBridgeConnection({
    required this.provider,
    required this.workspaceId,
    required this.credentials,
    this.mode = ChatConnectionMode.own,
    this.appId = '',
    this.teamId = '',
    this.teamName = '',
    this.botUserId = '',
    this.botId = '',
    this.botName = '',
    this.enabled = true,
    required this.connectedAt,
  }) {
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'must not be empty',
      );
    }
    if (credentials.isEmpty) {
      throw ArgumentError.value(
        credentials,
        'credentials',
        'a connection needs at least one credential',
      );
    }
  }

  /// Rebuilds a connection from its stored JSON.
  factory ChatBridgeConnection.fromJson(Map<String, dynamic> json) =>
      ChatBridgeConnection(
        provider: ChatProvider.fromWire(json['provider'] as String?),
        workspaceId: json['workspaceId'] as String,
        credentials: {
          for (final entry
              in ((json['credentials'] as Map?) ?? const {}).entries)
            '${entry.key}': '${entry.value}',
        },
        mode: ChatConnectionMode.fromWire(json['mode'] as String?),
        appId: json['appId'] as String? ?? '',
        teamId: json['teamId'] as String? ?? '',
        teamName: json['teamName'] as String? ?? '',
        botUserId: json['botUserId'] as String? ?? '',
        botId: json['botId'] as String? ?? '',
        botName: json['botName'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
        connectedAt:
            DateTime.tryParse(json['connectedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  /// Which provider this connection speaks to.
  final ChatProvider provider;

  /// The Control Center workspace this connection serves.
  final String workspaceId;

  /// Provider-side secrets, keyed by the descriptor's credential field ids.
  final Map<String, String> credentials;

  /// Whose app this connection runs on.
  final ChatConnectionMode mode;

  /// Provider-side application id (Slack `A…`, Discord application id).
  final String appId;

  /// Provider-side workspace/guild id (Slack `T…`).
  final String teamId;

  /// Provider-side workspace/guild display name, for the settings surface.
  final String teamName;

  /// The bot's own user id on the provider, used to ignore its own messages.
  final String botUserId;

  /// The provider's id for the bot integration itself (Slack `B…`), distinct
  /// from [botUserId]. Recorded when the token is saved and checked against
  /// every later token so a swapped-in token for another app is refused.
  final String botId;

  /// The bot's display name — what members type after `@`.
  final String botName;

  /// Whether the bridge should run. A disabled connection keeps its credentials
  /// but opens no socket.
  final bool enabled;

  /// When the connection was established.
  final DateTime connectedAt;

  /// The stored secret for [fieldId], or null when the field was never given.
  String? credential(String fieldId) {
    final value = credentials[fieldId];
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Whether [fieldId] holds a non-empty secret.
  bool hasCredential(String fieldId) => credential(fieldId) != null;

  /// Returns a copy with the given fields replaced. [credentials] are *merged*,
  /// so rotating one secret cannot drop the others.
  ChatBridgeConnection copyWith({
    String? appId,
    String? teamId,
    String? teamName,
    String? botUserId,
    String? botId,
    String? botName,
    Map<String, String>? credentials,
    bool? enabled,
  }) => ChatBridgeConnection(
    provider: provider,
    workspaceId: workspaceId,
    credentials: {...this.credentials, ...?credentials},
    mode: mode,
    appId: appId ?? this.appId,
    teamId: teamId ?? this.teamId,
    teamName: teamName ?? this.teamName,
    botUserId: botUserId ?? this.botUserId,
    botId: botId ?? this.botId,
    botName: botName ?? this.botName,
    enabled: enabled ?? this.enabled,
    connectedAt: connectedAt,
  );

  /// Serializes to the stored JSON shape (secrets included — this map is only
  /// ever written to the workspace's own credentials file, never to a client).
  Map<String, dynamic> toJson() => {
    'provider': provider.wire,
    'workspaceId': workspaceId,
    'credentials': credentials,
    'mode': mode.wire,
    'appId': appId,
    'teamId': teamId,
    'teamName': teamName,
    'botUserId': botUserId,
    'botId': botId,
    'botName': botName,
    'enabled': enabled,
    'connectedAt': connectedAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatBridgeConnection &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          workspaceId == other.workspaceId &&
          _sameCredentials(other.credentials) &&
          mode == other.mode &&
          appId == other.appId &&
          teamId == other.teamId &&
          teamName == other.teamName &&
          botUserId == other.botUserId &&
          botId == other.botId &&
          botName == other.botName &&
          enabled == other.enabled &&
          connectedAt == other.connectedAt;

  bool _sameCredentials(Map<String, String> other) {
    if (other.length != credentials.length) {
      return false;
    }
    for (final entry in credentials.entries) {
      if (other[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    provider,
    workspaceId,
    Object.hashAllUnordered([
      for (final e in credentials.entries) Object.hash(e.key, e.value),
    ]),
    mode,
    appId,
    teamId,
    teamName,
    botUserId,
    botId,
    botName,
    enabled,
    connectedAt,
  );
}

/// Live state of a workspace's bridge to one provider, as reported to clients.
enum ChatConnectionState {
  /// No connection is stored for the workspace.
  disconnected('disconnected'),

  /// Credentials are stored and the transport is dialing / re-dialing.
  connecting('connecting'),

  /// The transport is up and receiving events.
  connected('connected'),

  /// The connection is stored but failing (bad token, revoked app, …).
  error('error');

  const ChatConnectionState(this.wire);

  /// The stable wire string.
  final String wire;

  /// Parses a [ChatConnectionState] from its [wire] string.
  static ChatConnectionState fromWire(String? value) =>
      ChatConnectionState.values.firstWhere(
        (s) => s.wire == value,
        orElse: () => ChatConnectionState.disconnected,
      );
}

/// A workspace's bridge to one provider as shown in settings — never carries
/// credentials.
class ChatConnectionStatus {
  /// Creates a [ChatConnectionStatus].
  const ChatConnectionStatus({
    required this.provider,
    required this.state,
    this.mode,
    this.teamId,
    this.teamName,
    this.appId,
    this.botUserId,
    this.botName,
    this.lastError,
    this.connectedAt,
    this.streamingAvailable,
    this.canManageApp = false,
    this.linkedMemberCount = 0,
  });

  /// Rebuilds a status from its wire map.
  factory ChatConnectionStatus.fromJson(Map<String, dynamic> json) =>
      ChatConnectionStatus(
        provider: ChatProvider.fromWire(json['provider'] as String?),
        state: ChatConnectionState.fromWire(json['state'] as String?),
        mode: json['mode'] == null
            ? null
            : ChatConnectionMode.fromWire(json['mode'] as String?),
        teamId: json['teamId'] as String?,
        teamName: json['teamName'] as String?,
        appId: json['appId'] as String?,
        botUserId: json['botUserId'] as String?,
        botName: json['botName'] as String?,
        lastError: json['lastError'] as String?,
        connectedAt: DateTime.tryParse(json['connectedAt'] as String? ?? ''),
        streamingAvailable: json['streamingAvailable'] as bool?,
        canManageApp: json['canManageApp'] as bool? ?? false,
        linkedMemberCount: json['linkedMemberCount'] as int? ?? 0,
      );

  /// The disconnected status for a workspace with no app on [provider].
  static ChatConnectionStatus none(ChatProvider provider) =>
      ChatConnectionStatus(
        provider: provider,
        state: ChatConnectionState.disconnected,
      );

  /// Which provider this status is about.
  final ChatProvider provider;

  /// Live transport state.
  final ChatConnectionState state;

  /// Whose app the stored connection runs on, or null when nothing is stored.
  final ChatConnectionMode? mode;

  /// Provider-side workspace/guild id, when connected.
  final String? teamId;

  /// Provider-side workspace/guild name, when connected.
  final String? teamName;

  /// Provider-side application id, when connected.
  final String? appId;

  /// The bot's provider-side id, when connected.
  final String? botUserId;

  /// The bot's display name, when connected.
  final String? botName;

  /// Last failure reported by the transport or a provider API call.
  final String? lastError;

  /// When the connection was established.
  final DateTime? connectedAt;

  /// Whether the provider's native response streaming has been observed to work
  /// for this app. Null until a first reply has been attempted; false means the
  /// bridge is posting whole replies.
  final bool? streamingAvailable;

  /// Whether the provider-side app can be reshaped from Control Center (i.e.
  /// the app-management credential is stored).
  final bool canManageApp;

  /// How many workspace members have linked their identity on this provider.
  final int linkedMemberCount;

  /// Whether anything is stored for this provider at all.
  bool get isConnected => state != ChatConnectionState.disconnected;

  /// Serializes to the wire map.
  Map<String, dynamic> toJson() => {
    'provider': provider.wire,
    'state': state.wire,
    if (mode != null) 'mode': mode!.wire,
    if (teamId != null) 'teamId': teamId,
    if (teamName != null) 'teamName': teamName,
    if (appId != null) 'appId': appId,
    if (botUserId != null) 'botUserId': botUserId,
    if (botName != null) 'botName': botName,
    if (lastError != null) 'lastError': lastError,
    if (connectedAt != null) 'connectedAt': connectedAt!.toIso8601String(),
    if (streamingAvailable != null) 'streamingAvailable': streamingAvailable,
    'canManageApp': canManageApp,
    'linkedMemberCount': linkedMemberCount,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatConnectionStatus &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          state == other.state &&
          mode == other.mode &&
          teamId == other.teamId &&
          teamName == other.teamName &&
          appId == other.appId &&
          botUserId == other.botUserId &&
          botName == other.botName &&
          lastError == other.lastError &&
          connectedAt == other.connectedAt &&
          streamingAvailable == other.streamingAvailable &&
          canManageApp == other.canManageApp &&
          linkedMemberCount == other.linkedMemberCount;

  @override
  int get hashCode => Object.hash(
    provider,
    state,
    mode,
    teamId,
    teamName,
    appId,
    botUserId,
    botName,
    lastError,
    connectedAt,
    streamingAvailable,
    canManageApp,
    linkedMemberCount,
  );
}
