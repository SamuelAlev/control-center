import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:dio/dio.dart';

/// Resolves the current credential for a forge. Returns null when none is
/// configured.
typedef ForgeTokenLookup = Future<String?> Function(ForgeHost forge);

/// Builds authenticated [Dio] clients, one per forge.
///
/// Each forge gets its own base URL and its own `Authorization` scheme — they
/// genuinely differ, and getting one wrong fails as a silent 401 rather than a
/// compile error, so they live in exactly one place here:
///
/// | Forge     | Base                          | Header                          |
/// |-----------|-------------------------------|---------------------------------|
/// | GitHub    | `https://api.github.com`      | `Bearer <token>`                |
/// | GitLab    | `https://gitlab.com/api/v4`   | `Bearer <token>`                |
/// | Bitbucket | `https://api.bitbucket.org/2.0` | `Basic base64(email:token)`   |
///
/// The token is read per request through the token lookup rather than captured
/// when the client is built. A token pasted into Settings therefore applies to
/// the very next request, with no client rebuild and no server restart — and a
/// cleared token stops being sent immediately instead of lingering in a closure.
class ForgeDioFactory {
  /// Creates a [ForgeDioFactory].
  ///
  /// [bitbucketUsername] supplies the username half of Bitbucket's basic auth
  /// (its account email); it is read lazily for the same reason as the token.
  ForgeDioFactory({
    required ForgeTokenLookup tokenLookup,
    String Function()? bitbucketUsername,
    Duration timeout = const Duration(seconds: 12),
  }) : _tokenLookup = tokenLookup,
       _bitbucketUsername = bitbucketUsername ?? (() => ''),
       _timeout = timeout;

  final ForgeTokenLookup _tokenLookup;
  final String Function() _bitbucketUsername;
  final Duration _timeout;

  final Map<ForgeHost, Dio> _clients = {};

  /// The authenticated client for [forge], built once and reused.
  Dio of(ForgeHost forge) => _clients[forge] ??= _build(forge);

  Dio _build(ForgeHost forge) {
    final dio = createDio(baseUrl: forge.apiBaseUrl);
    // Cap forge calls well below the RPC client's 30s deadline so a slow or
    // unavailable forge fails server-side and the handler degrades, rather than
    // both sides racing the same timeout and the client reporting "RPC timed
    // out" for what is really one forge being down.
    dio.options
      ..connectTimeout = _timeout
      ..receiveTimeout = _timeout
      ..sendTimeout = _timeout;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenLookup(forge);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = _authHeader(forge, token);
            if (forge == ForgeHost.gitlab) {
              // GitLab accepts a personal access token either way, but
              // `PRIVATE-TOKEN` is the documented header for one while
              // `Authorization: Bearer` is documented for OAuth. Sending both
              // means an operator can paste whichever kind of token they have
              // without us having to guess which — and a token that is valid
              // for neither fails identically.
              options.headers['PRIVATE-TOKEN'] = token;
            }
          }
          for (final entry in _extraHeaders(forge).entries) {
            options.headers.putIfAbsent(entry.key, () => entry.value);
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Map transport failures to the app's typed exceptions HERE, once per
          // forge, rather than inside each adapter. The GitHub client has
          // always mapped its own; doing it in the interceptor gives GitLab and
          // Bitbucket the same typed errors without 40 methods of try/catch,
          // and keeps a raw dio failure from reaching the RPC layer as an
          // unrecognised error.
          //
          // Cancellation is deliberately passed through untouched: it is a
          // subscriber standing down, not a failure, and the PR streams check
          // for it by type to swallow it quietly.
          if (error.type == DioExceptionType.cancel) {
            handler.next(error);
            return;
          }
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: mapDioException(error),
              stackTrace: error.stackTrace,
            ),
          );
        },
      ),
    );
    return dio;
  }

  String _authHeader(ForgeHost forge, String token) => switch (forge) {
    // Bitbucket Cloud has no bearer scheme for API tokens: the token is the
    // password half of basic auth and the account email is the username.
    ForgeHost.bitbucket =>
      'Basic '
          '${base64Encode(utf8.encode('${_bitbucketUsername()}:$token'))}',
    ForgeHost.github || ForgeHost.gitlab || ForgeHost.local => 'Bearer $token',
  };

  Map<String, String> _extraHeaders(ForgeHost forge) => switch (forge) {
    ForgeHost.github => const {'X-GitHub-Api-Version': '2022-11-28'},
    _ => const {},
  };
}
