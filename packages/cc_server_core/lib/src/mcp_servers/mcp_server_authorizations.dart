import 'package:cc_connect_core/cc_connect_core.dart'
    show b64url, newConfirmCode, newLoginId, normaliseConfirmCode, randomBytes;
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/features/mcp/domain/ports/workspace_mcp_server_control.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';

/// One started browser sign-in to an MCP server.
class McpServerAuthorizationAttempt {
  McpServerAuthorizationAttempt._({
    required this.attemptId,
    required this.state,
    required this.workspaceId,
    required this.userId,
    required this.scope,
    required this.serverId,
    required this.serverUrl,
    required this.provider,
    required this.pending,
    required this.expiresAt,
  });

  /// The opaque handle the client holds.
  final String attemptId;

  /// The `state` the provider echoes to the callback. Never sent to a client
  /// except inside the authorization URL.
  final String state;

  /// The workspace the server belongs to.
  final String workspaceId;

  /// The person who began it, the only one who may finish it.
  final String userId;

  /// Whose server it is.
  final McpServerScope scope;

  /// The server signed in to.
  final String serverId;

  /// The server's URL when the attempt began: a sign-in is never stored for
  /// a server that was since pointed elsewhere.
  final String serverUrl;

  /// The provider that began it and will exchange the code.
  final McpOAuthProvider provider;

  /// What the exchange needs. Never leaves this process.
  final McpOAuthPending pending;

  /// When it stops being completable.
  final DateTime expiresAt;

  /// The provider's one-time code, kept from the callback until the person
  /// who began the attempt confirms it. Never leaves this process.
  String providerCode = '';

  /// The confirmation code the callback page showed.
  String confirmCode = '';

  /// Wrong confirmation codes so far.
  int wrongCodes = 0;

  /// Where it stands.
  McpServerAuthorizationStatus status = McpServerAuthorizationStatus.pending;

  /// What the client that began it is told.
  McpServerAuthorization get view => McpServerAuthorization(
    attemptId: attemptId,
    url: pending.authorizationUrl.toString(),
    status: status,
    triesLeft: status == McpServerAuthorizationStatus.failed
        ? 0
        : McpServerAuthorizations.maxWrongCodes - wrongCodes,
  );
}

/// The browser sign-ins to MCP servers in flight, held in memory.
///
/// The flow is the one every browser sign-in on this server follows: the
/// browser comes back to `<public origin>/oauth/mcp/callback` with a
/// single-use, TTL-bounded `state`; that unauthenticated request stores
/// nothing, keeps the provider's one-time code and shows a confirmation
/// code; only the person who began the attempt, presenting that code,
/// exchanges and stores the sign-in. A link someone else was sent therefore
/// signs nobody in: the code appears in their browser, not the starter's.
class McpServerAuthorizations {
  /// Creates the store.
  McpServerAuthorizations({DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  /// How long a started sign-in stays completable.
  static const Duration ttl = Duration(minutes: 10);

  /// Wrong confirmation codes an attempt accepts before it fails.
  static const int maxWrongCodes = 5;

  /// Attempts kept at once; the oldest goes first.
  static const int maxAttempts = 64;

  /// The lane segment of the callback path (`/oauth/mcp/callback`).
  static const String lane = 'mcp';

  /// This server's callback URL under its HTTP [origin].
  static String redirectUri(String origin) => '$origin/oauth/$lane/callback';

  final DateTime Function() _now;
  final Map<String, McpServerAuthorizationAttempt> _byId = {};
  final Map<String, String> _idByState = {};

  /// Begins a sign-in for [userId] to the server [provider] serves.
  ///
  /// [origin] is this server's advertised HTTP origin. [httpsOnly] refuses an
  /// authorization endpoint that is not `https` (a server confined to public
  /// addresses). Throws [AuthException] with a fixed message.
  Future<McpServerAuthorizationAttempt> begin({
    required String workspaceId,
    required String userId,
    required McpServerScope scope,
    required String serverId,
    required String serverUrl,
    required McpOAuthProvider provider,
    required String origin,
    required bool httpsOnly,
  }) async {
    if (origin.isEmpty) {
      throw const AuthException(
        'This server does not advertise a reachable URL, so a sign-in has '
        'nowhere to come back to.',
      );
    }
    _sweep();
    final state = b64url(randomBytes(32));
    final McpOAuthPending pending;
    try {
      pending = await provider.begin(
        redirectUri: redirectUri(origin),
        state: state,
      );
    } on OAuthException catch (e) {
      // Written by this package, never a provider body.
      throw AuthException(
        'This server offers no browser sign-in (${e.message}).',
      );
    }
    final url = pending.authorizationUrl;
    if (!url.hasAuthority ||
        url.userInfo.isNotEmpty ||
        !(url.scheme == 'https' || (!httpsOnly && url.scheme == 'http'))) {
      throw const AuthException(
        'This server names a sign-in page that cannot be opened safely.',
      );
    }
    final attempt = McpServerAuthorizationAttempt._(
      attemptId: newLoginId(),
      state: state,
      workspaceId: workspaceId,
      userId: userId,
      scope: scope,
      serverId: serverId,
      serverUrl: serverUrl,
      provider: provider,
      pending: pending,
      expiresAt: _now().add(ttl),
    );
    while (_byId.length >= maxAttempts) {
      _drop(_byId.keys.first);
    }
    _byId[attempt.attemptId] = attempt;
    _idByState[state] = attempt.attemptId;
    return attempt;
  }

  /// The attempt [attemptId] when [userId] began it in [workspaceId], else
  /// null: someone else's attempt is as absent as an unknown one.
  McpServerAuthorizationAttempt? lookup({
    required String attemptId,
    required String workspaceId,
    required String userId,
  }) {
    final attempt = _byId[attemptId];
    return attempt == null ||
            attempt.workspaceId != workspaceId ||
            attempt.userId != userId
        ? null
        : attempt;
  }

  /// Records the provider's redirect and returns the confirmation code the
  /// page shows. Nothing is exchanged or stored: the request is
  /// unauthenticated.
  ///
  /// Throws [AuthException] with a fixed message (never anything from the
  /// request).
  String handleCallback(Uri requestUri) {
    final query = requestUri.queryParameters;
    final state = query['state'];
    // Single use: a replayed callback finds nothing.
    final id = state == null || state.length > 128
        ? null
        : _idByState.remove(state);
    final attempt = id == null ? null : _byId[id];
    // A code typed too early leaves the attempt open (`wrongCode`); only a
    // finished one refuses the browser.
    if (attempt == null ||
        attempt.status == McpServerAuthorizationStatus.done ||
        attempt.status == McpServerAuthorizationStatus.failed ||
        attempt.providerCode.isNotEmpty) {
      throw const AuthException('This sign-in link is no longer valid.');
    }
    if (!_now().isBefore(attempt.expiresAt)) {
      attempt.status = McpServerAuthorizationStatus.failed;
      throw const AuthException('This sign-in took too long. Try again.');
    }
    final code = query['code'];
    if (query['error'] != null || code == null || code.isEmpty) {
      attempt.status = McpServerAuthorizationStatus.failed;
      throw const AuthException('The sign-in was cancelled or refused.');
    }
    if (code.length > 2048) {
      attempt.status = McpServerAuthorizationStatus.failed;
      throw const AuthException('This sign-in link is no longer valid.');
    }
    attempt
      ..providerCode = code
      ..confirmCode = newConfirmCode();
    return attempt.confirmCode;
  }

  /// Checks the confirmation code [typed] against [attempt]. True when it is
  /// the one the browser showed; otherwise the attempt counts a wrong code
  /// (a code typed before the browser came back counts too) and fails once
  /// they run out.
  bool confirm(McpServerAuthorizationAttempt attempt, String typed) {
    if (!_now().isBefore(attempt.expiresAt)) {
      attempt.status = McpServerAuthorizationStatus.failed;
      return false;
    }
    final code = normaliseConfirmCode(typed);
    if (code != null &&
        attempt.confirmCode.isNotEmpty &&
        _sameCode(code, attempt.confirmCode)) {
      return true;
    }
    attempt.wrongCodes++;
    attempt.status = attempt.wrongCodes >= maxWrongCodes
        ? McpServerAuthorizationStatus.failed
        : McpServerAuthorizationStatus.wrongCode;
    return false;
  }

  /// Forgets every attempt on server [serverId] of [workspaceId].
  void forgetServer(String workspaceId, String serverId) {
    for (final attempt in _byId.values.toList()) {
      if (attempt.workspaceId == workspaceId && attempt.serverId == serverId) {
        _drop(attempt.attemptId);
      }
    }
  }

  void _sweep() {
    final now = _now();
    for (final attempt in _byId.values.toList()) {
      if (!now.isBefore(attempt.expiresAt.add(ttl))) {
        _drop(attempt.attemptId);
      }
    }
  }

  void _drop(String attemptId) {
    final attempt = _byId.remove(attemptId);
    if (attempt != null) {
      _idByState.remove(attempt.state);
    }
  }

  static bool _sameCode(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
