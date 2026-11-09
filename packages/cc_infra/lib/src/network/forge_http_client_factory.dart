import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:rhttp/rhttp.dart';

/// Resolves the current credential for a forge. Returns null when none is
/// configured.
typedef ForgeTokenLookup = Future<String?> Function(ForgeHost forge);

/// Resolves the credential for one request, given its method and URL (which
/// may be relative to the forge's API base). Lets a client pick a
/// per-repository token per call.
///
/// Returning null sends the request without a credential. A lookup that knows
/// the request must not go out anonymously throws [ForgeCredentialUnavailable]
/// instead, and the request fails locally.
typedef ForgeRequestTokenLookup =
    Future<String?> Function(ForgeHost forge, String method, String url);

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
/// Auth schemes live here once (wrong scheme → silent 401): GitHub/GitLab
/// `Bearer` on their API bases; Bitbucket `Basic base64(email:token)` on
/// `api.bitbucket.org/2.0`. Token is read per request via the lookup — Settings
/// paste/clear applies on the next call without rebuild.
///
/// The interceptor only AUTHENTICATES. It deliberately does not map failures:
/// callers catch the status they care about (`RhttpStatusCodeException` with
/// 401/403/404) and the layer above maps the rest once, so wrapping a status
/// failure in anything else here would hide the status from every one of them.
class ForgeHttpClientFactory {
  /// Creates a [ForgeHttpClientFactory].
  ///
  /// [bitbucketUsername] supplies the username half of Bitbucket's basic auth
  /// (its account email); it is read lazily for the same reason as the token.
  ForgeHttpClientFactory({
    required this._tokenLookup,
    this._requestTokenLookup,
    this._onResponse,
    this._requestGuard,
    String Function()? bitbucketUsername,
    this._timeout = const Duration(seconds: 12),
    ForgeHttpClientBuilder? buildClient,
  }) : _bitbucketUsername = bitbucketUsername ?? (() => ''),
       _buildClient =
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
  final String Function() _bitbucketUsername;

  /// Longest a forge call may take, connection included.
  final Duration _timeout;

  final ForgeHttpClientBuilder _buildClient;

  final Map<ForgeHost, RhttpClient> _clients = {};

  /// The authenticated client for [forge], built once and reused.
  RhttpClient of(ForgeHost forge) => _clients[forge] ??= _build(forge);

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
          bitbucketUsername: _bitbucketUsername,
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
    required this.bitbucketUsername,
    this.requestTokenLookup,
  });

  /// The forge every request through this interceptor is authenticated for.
  final ForgeHost forge;

  /// Resolves the credential for [forge] on EVERY request, so a token pasted
  /// (or cleared) in Settings applies to the next call with no rebuild.
  final ForgeTokenLookup tokenLookup;

  /// Per-request credential, when the client picks one per call.
  final ForgeRequestTokenLookup? requestTokenLookup;

  /// The username half of Bitbucket's basic auth, read lazily for the same
  /// reason as [tokenLookup].
  final String Function() bitbucketUsername;

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    var headers = request.headers;
    final perRequest = requestTokenLookup;
    final String? token;
    try {
      token = perRequest != null
          ? await perRequest(forge, request.method.value, request.url)
          : await tokenLookup(forge);
    } on ForgeCredentialUnavailable catch (e) {
      // Thrown, like the rate-limit circuit's failure: there is no error route
      // out of `beforeRequest`, and nothing leaves the machine.
      throw e.asStatusFailure(request);
    }
    if (token != null && token.isNotEmpty) {
      headers = (headers ?? HttpHeaders.empty).copyWithRaw(
        name: 'Authorization',
        value: _authHeader(forge, token),
      );
      if (forge == ForgeHost.gitlab) {
        // GitLab accepts a personal access token either way, but
        // `PRIVATE-TOKEN` is the documented header for one while
        // `Authorization: Bearer` is documented for OAuth. Sending both means
        // an operator can paste whichever kind of token they have without us
        // having to guess which — and a token that is valid for neither fails
        // identically.
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

  String _authHeader(ForgeHost forge, String token) => switch (forge) {
    // Bitbucket Cloud has no bearer scheme for API tokens: the token is the
    // password half of basic auth and the account email is the username.
    ForgeHost.bitbucket =>
      'Basic '
          '${base64Encode(utf8.encode('${bitbucketUsername()}:$token'))}',
    ForgeHost.github || ForgeHost.gitlab || ForgeHost.local => 'Bearer $token',
  };

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
  const ForgeCredentialUnavailable(this.statusCode, this.message);

  /// The status the local failure carries.
  final int statusCode;

  /// Why there is no credential; becomes the failure body's `message`.
  final String message;

  /// The local status failure for [request]. Nothing was sent.
  RhttpStatusCodeException asStatusFailure(HttpRequest request) =>
      RhttpStatusCodeException(
        request: request,
        statusCode: statusCode,
        headers: const [('content-type', 'application/json')],
        body: jsonEncode({'message': message}),
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

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    final body = request.body;
    final reason = guard(
      forge,
      request.method.value,
      request.url,
      switch (body) {
        HttpBodyJson(:final json) => json,
        HttpBodyText(:final text) => _tryDecode(text),
        _ => null,
      },
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
