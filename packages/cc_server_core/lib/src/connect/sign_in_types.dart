part of 'sign_in_service.dart';

/// How one lane signs in for a workspace right now.
final class SignInLaneState {
  /// A lane that signs in through [mode].
  const SignInLaneState(this.mode) : reason = null, error = '';

  /// A lane that cannot sign in, and why.
  const SignInLaneState.unavailable(
    SignInUnavailableReason this.reason, {
    this.error = '',
  }) : mode = SignInLaneMode.unavailable;

  /// Own app, Connect, or unavailable.
  final SignInLaneMode mode;

  /// Why [mode] is [SignInLaneMode.unavailable]; null otherwise.
  final SignInUnavailableReason? reason;

  /// The setup error for [SignInUnavailableReason.misconfigured], phrased
  /// for a person; empty otherwise.
  final String error;
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
    this.target = ConnectTarget.none,
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

  /// The Connect a sealed grant came from ([ConnectTarget.none] for an own
  /// app), where it is revoked when this server does not keep it.
  final ConnectTarget target;
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
  /// A workspace on its own apps never does.
  Future<bool> allowsConnect(String? workspaceId);

  /// The credential slot a sign-in from [workspaceId] lands in: the
  /// workspace id, or null for the person's global slot.
  Future<String?> slotFor(String? workspaceId);

  /// Resolves who an access token belongs to.
  Future<SignInIdentity> identify(String accessToken);

  /// The server users who hold a grant for the provider account [accountId]
  /// in this lane, in any slot. A provider account acts for one person on
  /// this server only; workspace lanes, whose account is the workspace's,
  /// answer none.
  Future<Set<String>> accountHolders(String accountId);

  /// Stores a finished sign-in.
  Future<void> store(SignInResult result);

  /// Revokes, best effort, an own-app grant this server obtained but will
  /// not keep (in [slot]): only with the app that issued it
  /// ([ProviderToken.appId]), never another one. Sealed grants are revoked
  /// at their Connect by the sign-in service.
  Future<void> revokeOwnGrant(ProviderToken token, String? slot);

  /// [userId]'s grant in this lane as seen from [workspaceId], or null when
  /// there is none. Workspace-level lanes (`linear_app`, `slack`) answer for
  /// the workspace and ignore [userId].
  Future<LaneConnection?> connection(String userId, String? workspaceId);

  /// Deletes the grant [connection] reports, revoking it upstream where the
  /// provider allows.
  Future<void> disconnect(String userId, String? workspaceId);

  /// Revokes upstream (best effort) and deletes every credential this lane
  /// keeps for a person who left: [userId]'s in [workspaceId]'s own slot,
  /// [userId]'s in every slot (the global one too) when [workspaceId] is
  /// null, or everyone's in [workspaceId] (the workspace's own grant too)
  /// when [userId] is null. Returns how many were deleted.
  Future<int> offboard({String? userId, String? workspaceId});

  /// Every grant this lane keeps that the Connect at [connectOrigin]
  /// sealed: the seal and the slot it is held in ([globalWorkspaceScope]
  /// for the server-wide one), looking in the global slot and each of
  /// [workspaceIds]. Empty when the lane keeps no sealed grant. Read by an
  /// install-key rotation, which revokes them and retires the old key with
  /// one of them.
  Future<List<SealRequest>> connectSeals(
    String connectOrigin,
    List<String> workspaceIds,
  );
}

/// One lane's current grant, as reported to clients. Never carries a token.
final class LaneConnection {
  /// Creates the report.
  const LaneConnection({
    required this.lane,
    required this.status,
    this.account = '',
    this.accountId = '',
    this.workspaceSlot = false,
    this.source = SignInLaneMode.own,
  });

  /// Which lane.
  final ConnectOAuthLane lane;

  /// Where the grant stands; only [ForgeConnectionStatus.connected] is
  /// usable.
  final ForgeConnectionStatus status;

  /// Login, email or display name (the last known one while the grant needs
  /// a new sign-in).
  final String account;

  /// The provider's immutable account id.
  final String accountId;

  /// True when the grant lives in (or a sign-in from here would land in)
  /// the workspace slot.
  final bool workspaceSlot;

  /// Own app or Connect.
  final SignInLaneMode source;

  /// The wire shape.
  Map<String, Object?> toJson() => {
    'lane': lane.wire,
    'status': status.wire,
    'account': account,
    'account_id': accountId,
    'slot': workspaceSlot ? 'workspace' : 'global',
    'source': source.name,
  };
}
