import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// A request body that went past the endpoint's cap.
class _RequestTooLarge implements Exception {
  const _RequestTooLarge();
}

/// One rig's registration with the credential service.
class _RigCredentialGrant {
  _RigCredentialGrant({
    required this.rigId,
    required this.workspaceId,
    required this.conversationId,
    required this.secret,
    required this.capabilities,
    required this.allowedHosts,
    this.repoOwner,
    this.repoName,
  });

  final String rigId;
  final String workspaceId;
  final String conversationId;
  final String secret;
  final AgentCapabilities capabilities;
  final Set<String> allowedHosts;
  final String? repoOwner;
  final String? repoName;

  /// Handles for every grant minted for this rig, so all of them can be
  /// revoked when it closes.
  final List<String> mintedHandles = [];

  int mintsInWindow = 0;
  DateTime windowStart = DateTime.now();
}

/// A host-side endpoint that mints short-lived forge credentials for code
/// running inside a rig.
///
/// This is what makes `git push` work from an in-VM terminal without ever
/// putting a durable credential inside the enclosure. The guest ships a git
/// credential helper that asks this service per operation; the service mints
/// through [CredentialBrokerPort], hands over just the username/password pair
/// git needs, and revokes everything when the rig closes.
///
/// Why a per-VM secret is not a contradiction of "no credentials inside
/// enclosures": the secret is not a credential to anything outside. It is a
/// capability to ASK this host for a scoped token, it is minted at boot and
/// dies with the machine, it only reaches the host's own loopback, every use
/// is audited and rate-limited, and the answer is bounded by the rig's own
/// allowlist. A real forge token sitting in `~/.git-credentials` inside the
/// guest would be none of those things.
class GuestCredentialService {
  /// Creates a [GuestCredentialService] over [broker].
  GuestCredentialService({required CredentialBrokerPort broker})
    : _broker = broker;

  final CredentialBrokerPort _broker;
  final Map<String, _RigCredentialGrant> _grants = {};
  HttpServer? _server;

  /// Requests allowed per rig per minute. Generous for real use (a push is one
  /// request) and tight enough that a guest cannot farm tokens in a loop.
  static const int _mintsPerMinute = 30;

  /// The host loopback port the service listens on, or null when not started.
  int? get port => _server?.port;

  /// Whether the service is listening.
  bool get isRunning => _server != null;

  /// Starts the listener on an OS-assigned loopback port. Idempotent.
  Future<int> start() async {
    final existing = _server;
    if (existing != null) {
      return existing.port;
    }
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    unawaited(_serve(server));
    CcInfraLog.info(
      'rig/credentials: broker endpoint listening on 127.0.0.1:${server.port}',
    );
    return server.port;
  }

  /// Registers [rigId] with its per-VM [secret] and the forge hosts it may ask
  /// about.
  ///
  /// [allowedHosts] is normally the forge host of the rig's worktree. A rig
  /// with an empty set can hold a secret and still get nothing back, which is
  /// the right default for a machine with no repo in it.
  void registerRig({
    required String rigId,
    required String workspaceId,
    required String conversationId,
    required String secret,
    required Set<String> allowedHosts,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
  }) {
    _grants[rigId] = _RigCredentialGrant(
      rigId: rigId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      secret: secret,
      capabilities: capabilities,
      allowedHosts: {for (final h in allowedHosts) h.toLowerCase()},
      repoOwner: repoOwner,
      repoName: repoName,
    );
  }

  /// Revokes every token minted for [rigId] and forgets its secret.
  ///
  /// Called on close AND on failure: a rig that died mid-push must not leave a
  /// live token behind, and the point of minting short-lived tokens is lost if
  /// nothing revokes them early.
  Future<void> unregisterRig(String rigId) async {
    final grant = _grants.remove(rigId);
    if (grant == null) {
      return;
    }
    for (final handle in grant.mintedHandles) {
      try {
        await _broker.revoke(handle);
      } on Object catch (e) {
        CcInfraLog.warning(
          'rig/credentials: could not revoke $handle for rig $rigId: $e',
        );
      }
    }
  }

  /// Stops the listener and revokes every outstanding token.
  Future<void> stop() async {
    final server = _server;
    _server = null;
    for (final rigId in _grants.keys.toList()) {
      await unregisterRig(rigId);
    }
    await server?.close(force: true);
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      try {
        await _handle(request);
      } on Object catch (e, st) {
        CcInfraLog.error('rig/credentials: request failed: $e', e, st);
        try {
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
        } on Object {
          // Client already gone.
        }
      }
    }
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    if (request.uri.path != '/credential' || request.method != 'POST') {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    // Bounded BEFORE anything is read, and again while reading.
    //
    // Every policy check below — the secret compare, the host allowlist, the
    // rate limit — runs only after the body is fully buffered, and this
    // endpoint is reachable by every local process AND by every exec guest
    // through the reverse tunnel. An unbounded `join()` therefore let an
    // unauthenticated caller allocate as much of the server's heap as it cared
    // to send, without ever getting past the first check. A real request is
    // three short strings.
    final declared = request.headers.contentLength;
    if (declared > _maxRequestBytes) {
      response.statusCode = HttpStatus.requestEntityTooLarge;
      await response.close();
      return;
    }
    final String body;
    try {
      body = await _readBounded(request);
    } on _RequestTooLarge {
      CcInfraLog.warning(
        'rig/credentials: refused an oversized request body '
        '(> $_maxRequestBytes bytes)',
      );
      response.statusCode = HttpStatus.requestEntityTooLarge;
      await response.close();
      return;
    } on TimeoutException {
      response.statusCode = HttpStatus.requestTimeout;
      await response.close();
      return;
    }
    Map<String, dynamic> payload;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('not an object');
      }
      payload = decoded;
    } on FormatException {
      response.statusCode = HttpStatus.badRequest;
      await response.close();
      return;
    }

    final rigId = payload['rig_id'];
    final secret = payload['secret'];
    final host = payload['host'];
    if (rigId is! String || secret is! String || host is! String) {
      response.statusCode = HttpStatus.badRequest;
      await response.close();
      return;
    }

    final grant = _grants[rigId];
    // An unknown rig and a wrong secret must be indistinguishable, so a caller
    // on this machine cannot enumerate live rig ids by probing. The compare is
    // constant-time: this endpoint is reachable by any local process, and a
    // secret that leaks byte-by-byte through timing is not a secret.
    if (grant == null || !_secureEquals(grant.secret, secret)) {
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }

    final normalizedHost = host.toLowerCase();
    if (!grant.allowedHosts.contains(normalizedHost)) {
      // The rig's egress allowlist and this list are one policy seen from two
      // sides: a host the guest cannot reach must never be one we hand it a
      // token for.
      CcInfraLog.warning(
        'rig/credentials: rig $rigId asked for "$normalizedHost", which is not '
        'in its allowlist',
      );
      response.statusCode = HttpStatus.forbidden;
      await response.close();
      return;
    }

    if (!_withinRateLimit(grant)) {
      CcInfraLog.warning(
        'rig/credentials: rig $rigId exceeded its mint rate limit',
      );
      response.statusCode = HttpStatus.tooManyRequests;
      await response.close();
      return;
    }

    final ScopedCredentials credentials;
    try {
      credentials = await _broker.mint(
        conversationId: grant.conversationId,
        capabilities: grant.capabilities,
        repoOwner: grant.repoOwner,
        repoName: grant.repoName,
      );
    } on Object catch (e) {
      CcInfraLog.warning('rig/credentials: mint failed for rig $rigId: $e');
      response.statusCode = HttpStatus.serviceUnavailable;
      await response.close();
      return;
    }
    grant.mintedHandles.add(credentials.handle);

    final resolved = _forgeCredentialFor(normalizedHost, credentials);
    if (resolved == null) {
      // The broker had nothing for this forge. Answering with an empty
      // password would make git prompt for one against a terminal nobody is
      // watching, so say no clearly instead.
      CcInfraLog.warning(
        'rig/credentials: no credential available for "$normalizedHost" '
        '(rig $rigId)',
      );
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..write(
        jsonEncode({
          'username': resolved.$1,
          'password': resolved.$2,
          'expires_at': credentials.expiresAt?.toIso8601String(),
        }),
      );
    await response.close();
  }

  /// Reads [request]'s body, refusing anything past [_maxRequestBytes] and
  /// anything that takes longer than [_bodyTimeout] to arrive.
  ///
  /// A `Content-Length` header is a claim, not a fact — a chunked body carries
  /// none at all — so the running total is what actually enforces the cap.
  Future<String> _readBounded(HttpRequest request) async {
    final bytes = <int>[];
    await for (final chunk in request.timeout(_bodyTimeout)) {
      if (bytes.length + chunk.length > _maxRequestBytes) {
        throw const _RequestTooLarge();
      }
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// The largest body this endpoint will read. A real request is
  /// `{"rig_id":…,"secret":…,"host":…}` — three short strings.
  static const int _maxRequestBytes = 8 * 1024;

  /// How long a body has to arrive. A guest that opens a connection and then
  /// sends nothing must not hold a server slot indefinitely.
  static const Duration _bodyTimeout = Duration(seconds: 10);

  /// Maps a forge host to the `(username, password)` pair git expects.
  ///
  /// The username half is not cosmetic — each forge treats a different literal
  /// as significant (`x-access-token`, `oauth2`, the account's own name), so a
  /// shared placeholder authenticates on exactly one of the three.
  (String, String)? _forgeCredentialFor(
    String host,
    ScopedCredentials credentials,
  ) {
    final forge = _forgeForHost(host);
    if (forge == null) {
      return null;
    }
    final envKey = switch (forge) {
      ForgeHost.github => 'GITHUB_TOKEN',
      ForgeHost.gitlab => 'GITLAB_TOKEN',
      ForgeHost.bitbucket => 'BITBUCKET_API_TOKEN',
      ForgeHost.local => null,
    };
    final token = envKey == null ? null : credentials.environment[envKey];
    if (token == null || token.isEmpty) {
      return null;
    }
    final username = switch (forge) {
      ForgeHost.github => 'x-access-token',
      ForgeHost.gitlab => 'oauth2',
      ForgeHost.bitbucket =>
        credentials.environment['BITBUCKET_EMAIL'] ?? 'x-token-auth',
      ForgeHost.local => 'git',
    };
    return (username, token);
  }

  static ForgeHost? _forgeForHost(String host) {
    for (final forge in ForgeHost.values) {
      final gitHost = forge.gitHost;
      if (gitHost.isNotEmpty && gitHost.toLowerCase() == host) {
        return forge;
      }
    }
    return null;
  }

  /// Constant-time string equality.
  static bool _secureEquals(String a, String b) {
    final aUnits = a.codeUnits;
    final bUnits = b.codeUnits;
    if (aUnits.length != bUnits.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < aUnits.length; i++) {
      diff |= aUnits[i] ^ bUnits[i];
    }
    return diff == 0;
  }

  bool _withinRateLimit(_RigCredentialGrant grant) {
    final now = DateTime.now();
    if (now.difference(grant.windowStart) > const Duration(minutes: 1)) {
      grant.windowStart = now;
      grant.mintsInWindow = 0;
    }
    grant.mintsInWindow++;
    return grant.mintsInWindow <= _mintsPerMinute;
  }
}
