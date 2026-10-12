import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:rhttp/rhttp.dart';

/// Resolves the current credential for a forge. Returns null when none is
/// configured.
typedef ForgeTokenLookup = Future<String?> Function(ForgeHost forge);

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
    String Function()? bitbucketUsername,
    this._timeout = const Duration(seconds: 12),
    ForgeHttpClientBuilder? buildClient,
  }) : _bitbucketUsername = bitbucketUsername ?? (() => ''),
       _buildClient = buildClient ?? _createHttpClient;

  final ForgeTokenLookup _tokenLookup;
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
        ForgeAuthInterceptor(
          forge: forge,
          tokenLookup: _tokenLookup,
          bitbucketUsername: _bitbucketUsername,
        ),
      ],
    );
  }
}

RhttpClient _createHttpClient(
  String? baseUrl,
  ClientSettings settings,
  List<Interceptor> interceptors,
) => createHttpClient(
  baseUrl: baseUrl,
  settings: settings,
  interceptors: interceptors,
);

/// Attaches [forge]'s credential (and its API version header) to every request.
class ForgeAuthInterceptor extends Interceptor {
  /// Creates the auth interceptor for [forge].
  ForgeAuthInterceptor({
    required this.forge,
    required this.tokenLookup,
    required this.bitbucketUsername,
  });

  /// The forge every request through this interceptor is authenticated for.
  final ForgeHost forge;

  /// Resolves the credential for [forge] on EVERY request, so a token pasted
  /// (or cleared) in Settings applies to the next call with no rebuild.
  final ForgeTokenLookup tokenLookup;

  /// The username half of Bitbucket's basic auth, read lazily for the same
  /// reason as [tokenLookup].
  final String Function() bitbucketUsername;

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    var headers = request.headers;
    final token = await tokenLookup(forge);
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
    ForgeHost.github => const {'X-GitHub-Api-Version': '2022-11-28'},
    _ => const {},
  };
}

/// Whether [headers] carries [name], case-insensitively.
bool _hasHeader(HttpHeaders? headers, String name) {
  if (headers == null) {
    return false;
  }
  final lower = name.toLowerCase();
  return headers.toMapList().keys.any((key) => key.toLowerCase() == lower);
}
