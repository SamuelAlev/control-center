import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/forge_git_auth.dart';
import 'package:rhttp/rhttp.dart';

/// Resolves the current credential for a forge. Returns null when none is
/// configured.
typedef ForgeTokenLookup = Future<String?> Function(ForgeHost forge);

/// Resolves the credential for one request, given its method, URL (which
/// may be relative to the forge's API base) and decoded JSON body (null when
/// it has none). Lets a client pick a per-repository token per call, and a
/// GraphQL query's scope apart from a mutation's.
///
/// Returning null sends the request without a credential. A lookup that knows
/// the request must not go out anonymously throws [ForgeCredentialUnavailable]
/// instead, and the request fails locally.
typedef ForgeRequestTokenLookup =
    Future<String?> Function(
      ForgeHost forge,
      String method,
      String url,
      Object? jsonBody,
    );

/// Observes the status and headers of every response (and status failure) a
/// forge client receives, e.g. to track `x-ratelimit-*` budgets. Must not
/// throw; it cannot change the response.
typedef ForgeResponseObserver =
    void Function(ForgeHost forge, int statusCode, Map<String, String> headers);

/// Inspects one outgoing request (method, URL, decoded JSON body) and returns
/// why it must not be sent, or null to let it through. A refusal fails the
/// call with [ForgeRequestRefused] before any credential is looked up.
typedef ForgeRequestGuard =
    String? Function(
      ForgeHost forge,
      String method,
      String url,
      Object? jsonBody,
    );

/// Builds the client for one forge. Defaults to [createHttpClient]; injectable
/// so tests can exercise authentication without a native transport.
typedef ForgeHttpClientBuilder =
    RhttpClient Function(
      String? baseUrl,
      ClientSettings settings,
      List<Interceptor> interceptors,
    );

/// Builds authenticated [RhttpClient]s, one per forge.
///
/// Auth schemes live in [forgeAuthorizationHeader] (wrong scheme → silent
/// 401): GitHub/GitLab `Bearer` on their API bases; Bitbucket on
/// `api.bitbucket.org/2.0` takes a person's API token as `email:token`
/// (`Basic`) and an access token as `Bearer` ([BitbucketCredential]). Token is
/// read per request via the lookup — Settings paste/clear applies on the next
/// call without rebuild.
///
/// The interceptor only AUTHENTICATES. It deliberately does not map failures:
/// callers catch the status they care about (`RhttpStatusCodeException` with
/// 401/403/404) and the layer above maps the rest once, so wrapping a status
/// failure in anything else here would hide the status from every one of them.
class ForgeHttpClientFactory {
  /// Creates a [ForgeHttpClientFactory].
  ForgeHttpClientFactory({
    required this._tokenLookup,
    this._requestTokenLookup,
    this._onResponse,
    this._requestGuard,
    this._timeout = const Duration(seconds: 12),
    ForgeHttpClientBuilder? buildClient,
  }) : _buildClient =
           buildClient ??
           ((baseUrl, settings, interceptors) => createHttpClient(
             baseUrl: baseUrl,
             settings: settings,
             interceptors: interceptors,
           ));

  final ForgeTokenLookup _tokenLookup;

  /// When set, wins over the per-forge lookup.
  final ForgeRequestTokenLookup? _requestTokenLookup;

  /// Sees every response's status and headers, when set.
  final ForgeResponseObserver? _onResponse;

  /// Refuses requests this client must never send, when set.
  final ForgeRequestGuard? _requestGuard;

  /// Longest a forge call may take, connection included.
  final Duration _timeout;

  final ForgeHttpClientBuilder _buildClient;

  final Map<ForgeHost, RhttpClient> _clients = {};

  /// The authenticated client for [forge], built once and reused.
  RhttpClient of(ForgeHost forge) => _clients[forge] ??= _build(forge);

  /// Releases every client built here. The factory must not be used after.
  void dispose() {
    for (final client in _clients.values) {
      client.dispose();
    }
    _clients.clear();
  }

  RhttpClient _build(ForgeHost forge) {
    // Cap forge calls well below the RPC client's 30s deadline so a slow or
    // unavailable forge fails server-side and the handler degrades, rather than
    // both sides racing the same timeout and the client reporting "RPC timed
    // out" for what is really one forge being down.
    return _buildClient(
      forge.apiBaseUrl,
      ClientSettings(
        timeoutSettings: TimeoutSettings(
          connectTimeout: _timeout,
          timeout: _timeout,
        ),
      ),
      [
        // The guard runs first so a refused request never mints a token.
        if (_requestGuard case final guard?)
          ForgeRequestGuardInterceptor(forge: forge, guard: guard),
        ForgeAuthInterceptor(
          forge: forge,
          tokenLookup: _tokenLookup,
          requestTokenLookup: _requestTokenLookup,
        ),
        if (_onResponse case final observer?)
          ForgeResponseObserverInterceptor(forge: forge, observer: observer),
      ],
    );
  }
}

/// Attaches [forge]'s credential (and its API version header) to every request.
class ForgeAuthInterceptor extends Interceptor {
  /// Creates the auth interceptor for [forge].
  ForgeAuthInterceptor({
    required this.forge,
    required this.tokenLookup,
    this.requestTokenLookup,
  });

  /// The forge every request through this interceptor is authenticated for.
  final ForgeHost forge;

  /// Resolves the credential for [forge] on EVERY request, so a token pasted
  /// (or cleared) in Settings applies to the next call with no rebuild.
  final ForgeTokenLookup tokenLookup;

  /// Per-request credential, when the client picks one per call.
  final ForgeRequestTokenLookup? requestTokenLookup;

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    var headers = request.headers;
    final perRequest = requestTokenLookup;
    final String? token;
    try {
      token = perRequest != null
          ? await perRequest(
              forge,
              request.method.value,
              request.url,
              ForgeRequestGuardInterceptor.jsonBodyOf(request),
            )
          : await tokenLookup(forge);
    } on ForgeCredentialUnavailable catch (e) {
      // Thrown, like the rate-limit circuit's failure: there is no error route
      // out of `beforeRequest`, and nothing leaves the machine.
      throw e.asStatusFailure(request);
    }
    if (token != null && token.isNotEmpty) {
      headers = (headers ?? HttpHeaders.empty).copyWithRaw(
        name: 'Authorization',
        value: forgeAuthorizationHeader(forge, token),
      );
      if (forge == ForgeHost.gitlab) {
        // GitLab accepts a personal access token either way, but
        // `PRIVATE-TOKEN` is the documented header for one while
        // `Authorization: Bearer` is documented for OAuth and access tokens.
        // Sending both means a person's token and an automation token work
        // without guessing which kind is stored — and a token that is valid
        // for neither fails identically.
        headers = headers.copyWithRaw(name: 'PRIVATE-TOKEN', value: token);
      }
    }
    for (final entry in _extraHeaders(forge).entries) {
      if (!_hasHeader(headers, entry.key)) {
        headers = (headers ?? HttpHeaders.empty).copyWithRaw(
          name: entry.key,
          value: entry.value,
        );
      }
    }
    if (identical(headers, request.headers)) {
      return Interceptor.next();
    }
    return Interceptor.next(request.copyWith(headers: headers));
  }

  Map<String, String> _extraHeaders(ForgeHost forge) => switch (forge) {
    ForgeHost.github => const {'X-GitHub-Api-Version': gitHubRestApiVersion},
    _ => const {},
  };
}

/// Thrown by a [ForgeRequestTokenLookup] when no credential may be used for a
/// request and it must not be sent anonymously either.
///
/// An anonymous request would draw on the forge's shared per-IP budget (60 an
/// hour on GitHub) and could still read public data the workspace was never
/// granted. [ForgeAuthInterceptor] fails the call locally as a status failure
/// with [statusCode] and [message], so callers that switch on 401/403/404
/// degrade exactly as they would for the forge's own answer.
class ForgeCredentialUnavailable implements Exception {
  /// Creates the refusal.
  const ForgeCredentialUnavailable(
    this.statusCode,
    this.message, {
    this.signInLane,
  }) : automationTokenMissing = false,
       replacedOn = null;

  /// A person acting with no sign-in of their own on the forge: the local
  /// 401 names [lane] (`gitlab`, `bitbucket`, …) so the caller can offer that
  /// sign-in (`NeedsSignInException`) instead of reporting a failure.
  const ForgeCredentialUnavailable.needsSignIn(String lane, this.message)
    : statusCode = 401,
      signInLane = lane,
      automationTokenMissing = false,
      replacedOn = null;

  /// Automation with no person behind it on a token-only forge (GitLab,
  /// Bitbucket) and no automation token for the repository: the local 401
  /// says so ([automationTokenMissingKey]) so the caller pauses that
  /// repository instead of reporting an access denial.
  const ForgeCredentialUnavailable.automationTokenMissing(this.message)
    : statusCode = 401,
      signInLane = null,
      automationTokenMissing = true,
      replacedOn = null;

  /// The repository at a linked path is another one than the one linked
  /// there (the forge's durable id for the path changed): the local 409
  /// names [forge] ([repoReplacedKey]) so the caller reports `repo_replaced`
  /// and an admin relinks.
  const ForgeCredentialUnavailable.repoReplaced(ForgeHost forge, this.message)
    : statusCode = 409,
      signInLane = null,
      automationTokenMissing = false,
      replacedOn = forge;

  /// The body key that carries [signInLane] on the local failure.
  static const String signInLaneKey = 'needs_sign_in';

  /// The body key that marks an [ForgeCredentialUnavailable.automationTokenMissing]
  /// refusal.
  static const String automationTokenMissingKey = 'automation_token_missing';

  /// The body key that carries [replacedOn]'s wire on a
  /// [ForgeCredentialUnavailable.repoReplaced] refusal.
  static const String repoReplacedKey = 'repo_replaced';

  /// The forge of a [ForgeCredentialUnavailable.repoReplaced] refusal, else
  /// null.
  final ForgeHost? replacedOn;

  /// Whether this is an [ForgeCredentialUnavailable.automationTokenMissing]
  /// refusal.
  final bool automationTokenMissing;

  /// The status the local failure carries.
  final int statusCode;

  /// Why there is no credential; becomes the failure body's `message`.
  final String message;

  /// The sign-in the acting person lacks, or null when the refusal is not
  /// about a missing sign-in.
  final String? signInLane;

  /// The local status failure for [request]. Nothing was sent.
  RhttpStatusCodeException asStatusFailure(HttpRequest request) =>
      RhttpStatusCodeException(
        request: request,
        statusCode: statusCode,
        headers: const [('content-type', 'application/json')],
        body: jsonEncode({
          'message': message,
          signInLaneKey: ?signInLane,
          if (automationTokenMissing) automationTokenMissingKey: true,
          repoReplacedKey: ?replacedOn?.wire,
        }),
      );

  @override
  String toString() => 'ForgeCredentialUnavailable($statusCode): $message';
}

/// Why a [ForgeRequestGuard] refused a request. Thrown from the interceptor
/// chain before the request is sent.
class ForgeRequestRefused extends RhttpException {
  /// Creates the refusal for [request].
  const ForgeRequestRefused(super.request, this.reason);

  /// What the guard said.
  final String reason;

  @override
  String toString() => 'ForgeRequestRefused: $reason (${request.url})';
}

/// Fails requests a [ForgeRequestGuard] refuses.
class ForgeRequestGuardInterceptor extends Interceptor {
  /// Creates the guard interceptor for [forge].
  ForgeRequestGuardInterceptor({required this.forge, required this.guard});

  /// The forge the guarded client talks to.
  final ForgeHost forge;

  /// Decides per request.
  final ForgeRequestGuard guard;

  /// [request]'s decoded JSON body, or null when it has none.
  static Object? jsonBodyOf(HttpRequest request) => switch (request.body) {
    HttpBodyJson(:final json) => json,
    HttpBodyText(:final text) => _tryDecode(text),
    _ => null,
  };

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    final reason = guard(
      forge,
      request.method.value,
      request.url,
      jsonBodyOf(request),
    );
    if (reason != null) {
      throw ForgeRequestRefused(request, reason);
    }
    return Interceptor.next();
  }

  static Object? _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }
}

/// Reports every response's status and headers, success or status failure,
/// to a [ForgeResponseObserver]. Never alters the outcome.
class ForgeResponseObserverInterceptor extends Interceptor {
  /// Creates the observer interceptor for [forge].
  ForgeResponseObserverInterceptor({
    required this.forge,
    required this.observer,
  });

  /// The forge the observed client talks to.
  final ForgeHost forge;

  /// Receives each response.
  final ForgeResponseObserver observer;

  @override
  Future<InterceptorResult<HttpResponse>> afterResponse(
    HttpResponse response,
  ) async {
    _report(response.statusCode, response.headerMap);
    return Interceptor.next();
  }

  @override
  Future<InterceptorResult<RhttpException>> onError(
    RhttpException exception,
  ) async {
    if (exception is RhttpStatusCodeException) {
      _report(exception.statusCode, exception.headerMap);
    }
    return Interceptor.next();
  }

  void _report(int status, Map<String, String> headers) {
    try {
      observer(forge, status, headers);
    } on Object {
      // Observation is advisory; a broken observer must not fail the call.
    }
  }
}

/// Whether [headers] carries [name], case-insensitively.
bool _hasHeader(HttpHeaders? headers, String name) {
  if (headers == null) {
    return false;
  }
  final lower = name.toLowerCase();
  return headers.toMapList().keys.any((key) => key.toLowerCase() == lower);
}
