import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Where a forge's credential came from.
///
/// Every source is a person's own credential. GitHub is only ever [oauth] or
/// [connect]: automation reaches it through one-repository scoped tokens that
/// are never reported as a connection.
enum ForgeCredentialSource {
  /// Minted by signing in to the forge through this server's own app (OAuth),
  /// held for that user.
  oauth,

  /// Minted by signing in through Control Center Connect. The server holds
  /// only a seal bound to its install id; the access token lives in memory.
  connect,

  /// A token the user pasted, held for that user. Never GitHub: GitHub is
  /// sign-in only.
  settings,

  /// No credential available.
  none;

  /// The wire spelling.
  String get wire => name;

  /// Parses a wire value, defaulting to [none].
  static ForgeCredentialSource fromWire(String? wire) {
    for (final s in ForgeCredentialSource.values) {
      if (s.wire == wire) {
        return s;
      }
    }
    return ForgeCredentialSource.none;
  }
}

/// Where a person's sign-in to one forge stands, as reported to clients.
///
/// [connected] is the only usable state: every "am I signed in?" question
/// asks [ForgeConnection.isUsable], one definition everywhere.
enum ForgeConnectionStatus {
  /// A usable credential is in effect.
  connected('connected'),

  /// No credential in effect.
  notConnected('not_connected'),

  /// The grant was refused or expired upstream (revoked, a rotated Connect
  /// key, a replaced own app): the person has to sign in again.
  needsSignIn('needs_sign_in'),

  /// A sealed grant is parked: the workspace's sign-in service changed since
  /// it was made. Not the person's fault; it works again when the service
  /// comes back, or after signing in through the new one.
  paused('paused'),

  /// The grant is kept, but renewing it failed for now (the provider or
  /// Connect is down). The next call tries again.
  unreachable('unreachable');

  const ForgeConnectionStatus(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses a wire value; [notConnected] for anything unknown, so an
  /// unexpected value never reads as usable.
  static ForgeConnectionStatus fromWire(String? wire) {
    for (final s in values) {
      if (s.wire == wire) {
        return s;
      }
    }
    return notConnected;
  }
}

/// Where the credential in effect lives.
enum ForgeCredentialScope {
  /// A GitHub sign-in kept for one workspace only, because that workspace's
  /// sign-in target (its own App or its own Connect) differs from the
  /// server's. A pasted GitLab or Bitbucket token is never this.
  workspace,

  /// The person's server-wide credential, shared by every workspace that
  /// uses the same sign-in target.
  global;

  /// The wire spelling.
  String get wire => name;

  /// Parses a wire value; [global] for anything else.
  static ForgeCredentialScope fromWire(String? wire) =>
      wire == 'workspace' ? workspace : global;
}

/// The state of one forge's connection, as reported to clients.
///
/// Deliberately carries **no token**. Connection status crosses the RPC
/// boundary to every client, including remote ones; the credential itself never
/// leaves the server.
class ForgeConnection {
  /// Creates a [ForgeConnection].
  const ForgeConnection({
    required this.forge,
    required this.status,
    this.scope = ForgeCredentialScope.global,
    this.username = '',
    this.accountId = '',
    this.source = ForgeCredentialSource.none,
    this.error = '',
    this.expiresAt,
  });

  /// A connection with nothing in effect for [forge].
  factory ForgeConnection.disconnected(ForgeHost forge, {String error = ''}) =>
      ForgeConnection(
        forge: forge,
        status: ForgeConnectionStatus.notConnected,
        error: error,
      );

  /// Reads a [ForgeConnection] off the wire.
  factory ForgeConnection.fromJson(Map<String, dynamic> json) =>
      ForgeConnection(
        forge: ForgeHost.fromWire(json['forge'] as String?),
        status: ForgeConnectionStatus.fromWire(json['status'] as String?),
        scope: ForgeCredentialScope.fromWire(json['scope'] as String?),
        username: json['username'] as String? ?? '',
        accountId: json['account_id'] as String? ?? '',
        source: ForgeCredentialSource.fromWire(json['source'] as String?),
        error: json['error'] as String? ?? '',
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      );

  /// The forge.
  final ForgeHost forge;

  /// Where the sign-in stands.
  final ForgeConnectionStatus status;

  /// Where the credential in effect lives (or, with nothing in effect, the
  /// slot a sign-in from here would land in).
  final ForgeCredentialScope scope;

  /// The account the credential belongs to, when known. This is the viewer
  /// identity for this forge — "is this PR mine?" resolves against it, and it
  /// differs per forge for the same human. Kept while [status] is
  /// [ForgeConnectionStatus.needsSignIn], [ForgeConnectionStatus.paused] or
  /// [ForgeConnectionStatus.unreachable] when the last account is known, so
  /// the UI can say "sign in again as X".
  final String username;

  /// The forge's own id for that account (GitHub and GitLab user id,
  /// Bitbucket account id), kept the same way as [username]. Empty when the
  /// forge has not reported one for the stored credential.
  final String accountId;

  /// Where the credential came from.
  final ForgeCredentialSource source;

  /// Why the connection is unusable, when it is. Empty when fine.
  final String error;

  /// When the credential in effect lapses and has to be replaced (a pasted
  /// token's expiry), so a client can warn before it does. Null when it
  /// does not lapse, renews itself, or the forge does not say.
  final DateTime? expiresAt;

  /// Whether a usable credential is in effect.
  bool get isUsable => status == ForgeConnectionStatus.connected;

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'forge': forge.wire,
    'status': status.wire,
    'scope': scope.wire,
    'username': username,
    if (accountId.isNotEmpty) 'account_id': accountId,
    'source': source.wire,
    if (error.isNotEmpty) 'error': error,
    if (expiresAt case final at?) 'expires_at': at.toUtc().toIso8601String(),
  };

  /// Copy with.
  ForgeConnection copyWith({
    ForgeConnectionStatus? status,
    ForgeCredentialScope? scope,
    String? username,
    String? accountId,
    ForgeCredentialSource? source,
    String? error,
  }) => ForgeConnection(
    forge: forge,
    status: status ?? this.status,
    scope: scope ?? this.scope,
    username: username ?? this.username,
    accountId: accountId ?? this.accountId,
    source: source ?? this.source,
    error: error ?? this.error,
    expiresAt: expiresAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgeConnection &&
          runtimeType == other.runtimeType &&
          forge == other.forge &&
          status == other.status &&
          scope == other.scope &&
          username == other.username &&
          accountId == other.accountId &&
          source == other.source &&
          error == other.error &&
          expiresAt == other.expiresAt;

  @override
  int get hashCode => Object.hash(
    forge,
    status,
    scope,
    username,
    accountId,
    source,
    error,
    expiresAt,
  );
}
