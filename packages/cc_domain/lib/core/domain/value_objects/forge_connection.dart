import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Where a forge's credential came from.
///
/// Ordered by precedence, most specific first: a token the user minted by
/// signing in beats one they pasted, which beats the server's own app identity,
/// which beats an ambient environment variable.
enum ForgeCredentialSource {
  /// Minted by signing in to the forge (OAuth), held for that user.
  oauth,

  /// A token the user pasted, held for that user.
  settings,

  /// The server's own app identity (a GitHub App installation token, a Linear
  /// app key). Answers work no human asked for — webhooks, polling, sync.
  app,

  /// Read from the server process environment.
  environment,

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

/// The state of one forge's connection, as reported to clients.
///
/// Deliberately carries **no token**. Connection status crosses the RPC
/// boundary to every client, including remote ones; the credential itself never
/// leaves the server.
class ForgeConnection {
  /// Creates a [ForgeConnection].
  const ForgeConnection({
    required this.forge,
    required this.authenticated,
    this.username = '',
    this.source = ForgeCredentialSource.none,
    this.error = '',
  });

  /// A disconnected connection for [forge].
  factory ForgeConnection.disconnected(ForgeHost forge, {String error = ''}) =>
      ForgeConnection(forge: forge, authenticated: false, error: error);

  /// Reads a [ForgeConnection] off the wire.
  factory ForgeConnection.fromJson(Map<String, dynamic> json) =>
      ForgeConnection(
        forge: ForgeHost.fromWire(json['forge'] as String?),
        authenticated: json['authenticated'] as bool? ?? false,
        username: json['username'] as String? ?? '',
        source: ForgeCredentialSource.fromWire(json['source'] as String?),
        error: json['error'] as String? ?? '',
      );

  /// The forge.
  final ForgeHost forge;

  /// Whether a usable credential is present.
  final bool authenticated;

  /// The account the credential belongs to, when known. This is the viewer
  /// identity for this forge — "is this PR mine?" resolves against it, and it
  /// differs per forge for the same human.
  final String username;

  /// Where the credential came from.
  final ForgeCredentialSource source;

  /// Why the connection is unusable, when it is. Empty when fine.
  final String error;

  /// Wire form.
  Map<String, dynamic> toJson() => {
    'forge': forge.wire,
    'authenticated': authenticated,
    'username': username,
    'source': source.wire,
    if (error.isNotEmpty) 'error': error,
  };

  /// Copy with.
  ForgeConnection copyWith({
    bool? authenticated,
    String? username,
    ForgeCredentialSource? source,
    String? error,
  }) => ForgeConnection(
    forge: forge,
    authenticated: authenticated ?? this.authenticated,
    username: username ?? this.username,
    source: source ?? this.source,
    error: error ?? this.error,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForgeConnection &&
          runtimeType == other.runtimeType &&
          forge == other.forge &&
          authenticated == other.authenticated &&
          username == other.username &&
          source == other.source &&
          error == other.error;

  @override
  int get hashCode =>
      Object.hash(forge, authenticated, username, source, error);
}
