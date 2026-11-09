part of 'sign_in_service.dart';

/// Where a lane's sign-in runs right now.
enum SignInMode {
  /// The server's own app: the browser comes back to this server.
  own,

  /// Control Center Connect: the browser comes back to Connect, which shows
  /// a confirmation code.
  connect,

  /// Nothing configured.
  unavailable;

  /// The wire spelling.
  String get wire => name;
}

/// An own-app OAuth client for one lane. The token and authorize endpoints
/// are the provider's fixed ones; only the client credentials vary.
final class OwnOAuthApp {
  /// Creates the client description.
  const OwnOAuthApp({
    required this.authorize,
    required this.token,
    required this.clientId,
    required this.scopes,
    this.clientSecret = '',
    this.scopeSeparator = ' ',
    this.extraAuthorizeParams = const {},
  });

  /// The provider's authorize endpoint.
  final Uri authorize;

  /// The provider's token endpoint.
  final Uri token;

  /// The operator's client id.
  final String clientId;

  /// The operator's client secret; empty for a public PKCE client.
  final String clientSecret;

  /// The fixed scope set for the lane; empty when the provider takes none.
  final List<String> scopes;

  /// How the provider joins scopes in the authorize URL.
  final String scopeSeparator;

  /// Fixed extra authorize parameters (`prompt`, `actor`, `access_type`).
  final Map<String, String> extraAuthorizeParams;
}

/// Thrown when a lane is configured halfway: partial own credentials never
/// mix with Connect, so the honest answer is a setup error.
final class SignInMisconfigured implements Exception {
  /// Creates the error.
  const SignInMisconfigured(this.message);

  /// What the operator has to fix.
  final String message;

  @override
  String toString() => message;
}

/// The identity behind a freshly minted own-app token.
typedef SignInIdentity = ({String id, String login});

/// A finished sign-in, handed to the lane to store.
final class SignInResult {
  /// Creates the result.
  const SignInResult({
    required this.lane,
    required this.userId,
    required this.workspaceId,
    required this.slot,
    required this.token,
    this.grant,
  });

  /// Which lane.
  final ConnectOAuthLane lane;

  /// The person who signed in (from the authenticated session, never a
  /// client argument).
  final String userId;

  /// The workspace the sign-in was started from, if any.
  final String? workspaceId;

  /// The credential slot: a workspace id, or null for the person's global
  /// slot.
  final String? slot;

  /// The credential. Sealed for a Connect lane (access token for memory
  /// only); a plain token for an own app or a Linear exchange.
  final ProviderToken token;

  /// The raw Connect grant, for lanes that need its extra fields (Slack's
  /// team and bot ids).
  final SealedGrant? grant;
}

/// One lane's server-side half: what app it uses and where its credential
/// lives. The sign-in service owns the browser round-trip and the exchange.
abstract interface class SignInLaneBinding {
  /// The lane.
  ConnectOAuthLane get lane;

  /// The own app for [workspaceId], or null to route through Connect.
  /// Throws [SignInMisconfigured] for partial own credentials.
  Future<OwnOAuthApp?> ownApp(String? workspaceId);

  /// Whether this lane may route through Connect for [workspaceId] at all.
  /// A workspace on its own GitHub App never does.
  Future<bool> allowsConnect(String? workspaceId);

  /// The credential slot a sign-in from [workspaceId] lands in: the
  /// workspace id, or null for the person's global slot.
  Future<String?> slotFor(String? workspaceId);

  /// Resolves who an own-app access token belongs to.
  Future<SignInIdentity> identify(String accessToken);

  /// Stores a finished sign-in.
  Future<void> store(SignInResult result);

  /// [userId]'s grant in this lane as seen from [workspaceId], or null when
  /// there is none. Workspace-level lanes (`linear_app`, `slack`) answer for
  /// the workspace and ignore [userId].
  Future<LaneConnection?> connection(String userId, String? workspaceId);

  /// Deletes the grant [connection] reports, revoking it upstream where the
  /// provider allows.
  Future<void> disconnect(String userId, String? workspaceId);
}

/// One lane's current grant, as reported to clients. Never carries a token.
final class LaneConnection {
  /// Creates the report.
  const LaneConnection({
    required this.lane,
    required this.connected,
    this.account = '',
    this.accountId = '',
    this.workspaceSlot = false,
    this.source = SignInMode.own,
    this.needsSignIn = false,
  });

  /// Which lane.
  final ConnectOAuthLane lane;

  /// Whether a usable grant is stored.
  final bool connected;

  /// Login, email or display name.
  final String account;

  /// The provider's immutable account id.
  final String accountId;

  /// True when the grant lives in the workspace slot.
  final bool workspaceSlot;

  /// Own app or Connect.
  final SignInMode source;

  /// True when a grant exists but must be renewed by signing in again.
  final bool needsSignIn;

  /// The wire shape.
  Map<String, Object?> toJson() => {
    'lane': lane.wire,
    'connected': connected,
    'account': account,
    'account_id': accountId,
    'slot': workspaceSlot ? 'workspace' : 'global',
    'source': source.wire,
    'needs_sign_in': needsSignIn,
  };
}

/// The lifecycle of one started sign-in.
enum SignInStatus {
  /// Waiting for the browser (own) or the confirmation code (Connect).
  pending,

  /// Stored.
  succeeded,

  /// Refused, expired or failed; [SignInAttempt.error] says why.
  failed;

  /// The wire spelling.
  String get wire => name;
}

/// A started sign-in, as reported to the client that started it.
final class SignInAttempt {
  SignInAttempt._({
    required this.loginId,
    required this.lane,
    required this.mode,
    required this.userId,
    required this.workspaceId,
    required this.slot,
    required this.verifier,
    required this.expiresAt,
    required this.url,
    this.state = '',
    this.redirectUri,
    this.clientId = '',
  });

  /// Opaque handle; for Connect it is Connect's login id (the deep link
  /// carries it back), for an own app a fresh random id.
  final String loginId;

  /// Which lane.
  final ConnectOAuthLane lane;

  /// Own app or Connect.
  final SignInMode mode;

  /// The person.
  final String userId;

  /// The workspace it started from.
  final String? workspaceId;

  /// The credential slot.
  final String? slot;

  /// The PKCE verifier. Never leaves this process.
  final String verifier;

  /// When it stops being completable.
  final DateTime expiresAt;

  /// Where to send the browser.
  final Uri url;

  /// Own-app `state`.
  final String state;

  /// Own-app redirect URI, reused verbatim for the exchange.
  final Uri? redirectUri;

  /// The client id the exchange must use (own app, or Connect's Linear
  /// client for the Linear code exchange).
  final String clientId;

  /// Current status.
  SignInStatus status = SignInStatus.pending;

  /// The connected account, when it succeeded.
  String account = '';

  /// Why it failed, once [status] is failed.
  SignInFailure? error;

  /// Why the last confirmation code was not accepted, while the attempt
  /// stays open for another ([SignInFailure.codeMismatch]); cleared by the
  /// next code.
  SignInFailure? codeError;

  int _wrongCodes = 0;

  void _fail(SignInFailure failure) {
    status = SignInStatus.failed;
    error = failure;
    codeError = null;
  }

  /// The wire shape for the client.
  Map<String, Object?> toJson() => {
    'login_id': loginId,
    'lane': lane.wire,
    'mode': mode.wire,
    'url': url.toString(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
    'status': status.wire,
    if (account.isNotEmpty) 'account': account,
    'error': ?error?.wire,
    'code_error': ?codeError?.wire,
  };
}
