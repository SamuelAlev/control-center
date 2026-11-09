import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_rpc/cc_rpc.dart';

/// Who runs a lane's browser sign-in on this server.
enum SignInLaneMode {
  /// The server's own OAuth app; the provider redirects to the server.
  own,

  /// Control Center Connect; the browser shows an 8-character code that the
  /// client hands back.
  connect,

  /// Neither is set up, or the own app is half-configured.
  unavailable;

  /// Parses a wire value; [unavailable] for anything unknown.
  static SignInLaneMode fromWire(Object? wire) => switch (wire) {
    'own' => own,
    'connect' => connect,
    _ => unavailable,
  };
}

/// One lane as `oauth.lanes` reports it.
class SignInLaneInfo {
  /// Creates a [SignInLaneInfo].
  const SignInLaneInfo({
    required this.lane,
    required this.mode,
    this.redirectUri = '',
    this.error = '',
  });

  /// Decodes one `oauth.lanes` entry; null when the lane is unknown.
  static SignInLaneInfo? tryParse(Map<String, dynamic> json) {
    final lane = ConnectOAuthLane.fromWire(json['lane'] as String?);
    if (lane == null) {
      return null;
    }
    return SignInLaneInfo(
      lane: lane,
      mode: SignInLaneMode.fromWire(json['mode']),
      redirectUri: json['redirect_uri'] as String? ?? '',
      error: json['error'] as String? ?? '',
    );
  }

  /// The lane.
  final ConnectOAuthLane lane;

  /// Who runs its sign-in.
  final SignInLaneMode mode;

  /// The own-mode callback URL to register with the provider, verbatim.
  /// Empty in Connect mode.
  final String redirectUri;

  /// Why the lane cannot sign anyone in, already phrased for a person.
  final String error;
}

/// Where a sign-in attempt stands.
enum SignInAttemptStatus {
  /// Waiting for the browser.
  pending,

  /// The grant is stored.
  succeeded,

  /// Over; see [SignInAttempt.error].
  failed;

  /// Parses a wire value; [failed] for anything unknown.
  static SignInAttemptStatus fromWire(Object? wire) => switch (wire) {
    'pending' => pending,
    'succeeded' => succeeded,
    _ => failed,
  };

  /// Whether the attempt is over.
  bool get isTerminal => this != pending;
}

/// Why a sign-in attempt failed. The closed set `oauth.*` reports; anything
/// else reads as [unknown].
enum SignInFailure {
  /// The attempt ran out of time.
  expired('expired'),

  /// The person declined at the provider.
  accessDenied('access_denied'),

  /// The provider granted different permissions than the lane asks for.
  scopeMismatch('scope_mismatch'),

  /// Too many wrong confirmation codes.
  invalidCode('invalid_code'),

  /// The provider or Connect is not answering.
  providerUnavailable('provider_unavailable'),

  /// The provider refused to exchange the authorization code.
  exchangeFailed('exchange_failed'),

  /// The server's own app for this provider is set up wrongly.
  misconfigured('misconfigured'),

  /// A previous grant is gone; sign in again.
  needsSignIn('needs_sign_in'),

  /// The app is not installed where it is needed.
  notInstalled('not_installed'),

  /// A GitHub organization installation is bound to another server.
  installationBoundElsewhere('installation_bound_elsewhere'),

  /// A Slack workspace is bound to another server.
  teamBoundElsewhere('team_bound_elsewhere'),

  /// Connecting a Slack workspace the first time takes one of its admins.
  notAdmin('not_admin'),

  /// The installation or account is suspended.
  suspended('suspended'),

  /// This server is not allowed on its Connect.
  installBlocked('install_blocked'),

  /// A code this client does not know.
  unknown('');

  const SignInFailure(this.wire);

  /// The wire spelling.
  final String wire;

  /// Parses a wire value; null for an empty or absent one.
  static SignInFailure? fromWire(Object? wire) {
    if (wire is! String || wire.isEmpty) {
      return null;
    }
    for (final failure in values) {
      if (failure.wire == wire) {
        return failure;
      }
    }
    return unknown;
  }
}

/// One browser sign-in attempt, as `oauth.begin` / `oauth.status` /
/// `oauth.complete` report it.
class SignInAttempt {
  /// Creates a [SignInAttempt].
  const SignInAttempt({
    required this.loginId,
    required this.lane,
    required this.mode,
    required this.url,
    required this.expiresAt,
    required this.status,
    this.account = '',
    this.error,
  });

  /// Decodes an attempt payload.
  factory SignInAttempt.fromJson(Map<String, dynamic> json) {
    final lane = ConnectOAuthLane.fromWire(json['lane'] as String?);
    if (lane == null) {
      throw FormatException('Unknown sign-in lane: ${json['lane']}');
    }
    final loginId = json['login_id'] as String? ?? '';
    if (loginId.isEmpty) {
      throw const FormatException('A sign-in attempt carries no login_id');
    }
    return SignInAttempt(
      loginId: loginId,
      lane: lane,
      mode: json['mode'] == 'connect'
          ? SignInLaneMode.connect
          : SignInLaneMode.own,
      url: json['url'] as String? ?? '',
      expiresAt:
          DateTime.tryParse(json['expires_at'] as String? ?? '')?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(minutes: 10)),
      status: SignInAttemptStatus.fromWire(json['status']),
      account: json['account'] as String? ?? '',
      error: SignInFailure.fromWire(json['error']),
    );
  }

  /// The opaque id the server minted for this attempt.
  final String loginId;

  /// The lane being signed in.
  final ConnectOAuthLane lane;

  /// Own app or Connect; never [SignInLaneMode.unavailable].
  final SignInLaneMode mode;

  /// The provider's authorization page.
  final String url;

  /// When the attempt stops being completable.
  final DateTime expiresAt;

  /// Where it stands.
  final SignInAttemptStatus status;

  /// The account that signed in, once [status] is succeeded.
  final String account;

  /// Why it failed, once [status] is failed.
  final SignInFailure? error;
}

/// Which slot a stored grant lives in.
enum SignInSlot {
  /// Bound to one workspace.
  workspace,

  /// Server-wide for the caller.
  global;

  /// Parses a wire value; [global] for anything else.
  static SignInSlot fromWire(Object? wire) =>
      wire == 'workspace' ? workspace : global;
}

/// One stored grant, as `oauth.connections` reports it.
class ProviderConnection {
  /// Creates a [ProviderConnection].
  const ProviderConnection({
    required this.lane,
    required this.connected,
    this.account = '',
    this.accountId = '',
    this.slot = SignInSlot.global,
    this.source = SignInLaneMode.own,
    this.needsSignIn = false,
  });

  /// Decodes one entry; null when the lane is unknown.
  static ProviderConnection? tryParse(Map<String, dynamic> json) {
    final lane = ConnectOAuthLane.fromWire(json['lane'] as String?);
    if (lane == null) {
      return null;
    }
    return ProviderConnection(
      lane: lane,
      connected: json['connected'] as bool? ?? false,
      account: json['account'] as String? ?? '',
      accountId: '${json['account_id'] ?? ''}',
      slot: SignInSlot.fromWire(json['slot']),
      source: json['source'] == 'connect'
          ? SignInLaneMode.connect
          : SignInLaneMode.own,
      needsSignIn: json['needs_sign_in'] as bool? ?? false,
    );
  }

  /// The lane.
  final ConnectOAuthLane lane;

  /// Whether a usable grant is stored.
  final bool connected;

  /// The login, email or name the grant belongs to.
  final String account;

  /// The provider's immutable account id.
  final String accountId;

  /// Where the grant is stored.
  final SignInSlot slot;

  /// Who minted it.
  final SignInLaneMode source;

  /// Whether the grant was refused upstream and needs a new sign-in.
  final bool needsSignIn;
}

/// The browser sign-in surface over RPC: `oauth.lanes`, `oauth.begin`,
/// `oauth.status`, `oauth.complete`, `oauth.connections` and
/// `oauth.disconnect`.
///
/// Every call passes `workspace_id` explicitly — including as `null` — so the
/// RPC client's active workspace can never retarget an attempt started for a
/// different scope (onboarding signs in before any workspace exists).
class RemoteProviderSignIn {
  /// Creates a [RemoteProviderSignIn] over [_client].
  RemoteProviderSignIn(this._client);

  final RemoteRpcClient _client;

  /// Every lane this server knows and who runs it.
  Future<List<SignInLaneInfo>> lanes({String? workspaceId}) async {
    final data = await _client.call('oauth.lanes', {
      'workspace_id': workspaceId,
    });
    return [
      for (final entry in (data['lanes'] as List? ?? const []).whereType<Map>())
        ?SignInLaneInfo.tryParse(entry.cast<String, dynamic>()),
    ];
  }

  /// Starts a browser sign-in for [lane].
  Future<SignInAttempt> begin(
    ConnectOAuthLane lane, {
    String? workspaceId,
  }) async => SignInAttempt.fromJson(
    await _client.call('oauth.begin', {
      'lane': lane.wire,
      'workspace_id': workspaceId,
    }),
  );

  /// Reads where [loginId] stands.
  Future<SignInAttempt> status(String loginId, {String? workspaceId}) async =>
      SignInAttempt.fromJson(
        await _client.call('oauth.status', {
          'login_id': loginId,
          'workspace_id': workspaceId,
        }),
      );

  /// Hands a Connect confirmation [code] for [loginId] to the server.
  ///
  /// A wrong code throws the server's refusal; the fifth wrong code fails
  /// the attempt with [SignInFailure.invalidCode].
  Future<SignInAttempt> complete({
    required String loginId,
    required String code,
    String? workspaceId,
  }) async => SignInAttempt.fromJson(
    await _client.call('oauth.complete', {
      'login_id': loginId,
      'code': code,
      'workspace_id': workspaceId,
    }),
  );

  /// The caller's own grants, plus the workspace's grants when
  /// [workspaceId] is given.
  Future<List<ProviderConnection>> connections({String? workspaceId}) async {
    final data = await _client.call('oauth.connections', {
      'workspace_id': workspaceId,
    });
    return [
      for (final entry
          in (data['connections'] as List? ?? const []).whereType<Map>())
        ?ProviderConnection.tryParse(entry.cast<String, dynamic>()),
    ];
  }

  /// Revokes [lane]'s grant upstream where possible and deletes it.
  Future<void> disconnect(ConnectOAuthLane lane, {String? workspaceId}) =>
      _client.call('oauth.disconnect', {
        'lane': lane.wire,
        'workspace_id': workspaceId,
      });
}
