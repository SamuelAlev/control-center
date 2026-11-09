import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInFailure, SignInLaneMode;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';

export 'package:cc_connect_core/cc_connect_core.dart'
    show SignInFailure, SignInLaneMode;

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
    this.codeError,
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
      codeError: SignInFailure.fromWire(json['code_error']),
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

  /// Why the last confirmation code was refused while the attempt stays
  /// open ([SignInFailure.codeMismatch]); null otherwise.
  final SignInFailure? codeError;
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
  /// A wrong code comes back pending with [SignInAttempt.codeError] set; the
  /// fifth fails the attempt with [SignInFailure.invalidCode].
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

/// The sign-in failure an `oauth.*` call that threw amounts to: a sign-in the
/// server no longer knows reads as [SignInFailure.staleRequest], a server
/// that could not be reached (or answered something else) as
/// [SignInFailure.providerUnavailable].
SignInFailure signInFailureOfRpcError(Object error) {
  if (error is! RemoteRpcException) {
    return SignInFailure.providerUnavailable;
  }
  return switch (error.code) {
    RpcErrorCodes.unauthorized ||
    RpcErrorCodes.notFound => SignInFailure.staleRequest,
    RpcErrorCodes.invalidParams ||
    RpcErrorCodes.validation => SignInFailure.invalidRequest,
    RpcErrorCodes.rateLimited => SignInFailure.rateLimited,
    _ => SignInFailure.providerUnavailable,
  };
}
