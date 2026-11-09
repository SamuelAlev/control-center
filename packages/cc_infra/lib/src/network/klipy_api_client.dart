import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/features/pr_review/domain/entities/gif_result.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:rhttp/rhttp.dart';

const _kKlipyBaseUrl = 'https://api.klipy.com';
const _kPerPage = 30;

/// Server-side Klipy GIF client for one app key.
///
/// Klipy takes the app key as a path segment (`/api/v1/<key>/gifs/…`), so
/// the request URL is itself a credential. That is why this client never
/// rides the shared interceptor chain (its log lines name every URL) and
/// why a failure surfaces as a [NetworkException] carrying only the status:
/// nothing a caller can log or return holds the key.
///
/// Cheap to construct: build one per call with the key in force right then,
/// over a long-lived [transport].
class KlipyApiClient {
  /// Creates a [KlipyApiClient] for [_appKey] over [httpClient] (defaults to a
  /// fresh [transport]).
  KlipyApiClient({required this._appKey, RhttpClient? httpClient})
    : _httpClient = httpClient ?? transport();

  /// A Klipy transport with no logging, retry or dedup interceptors. Share
  /// one across [KlipyApiClient]s.
  static RhttpClient transport() => RhttpClient.createSync(
    settings: httpClientSettings(
      baseUrl: _kKlipyBaseUrl,
      settings: const ClientSettings(
        // Klipy answers or the request is not worth waiting on.
        timeoutSettings: TimeoutSettings(
          connectTimeout: Duration(seconds: 5),
          timeout: Duration(seconds: 5),
        ),
        // A redirect would carry the key-bearing path to another host.
        redirectSettings: RedirectSettings.none(),
      ),
    ),
  );

  final RhttpClient _httpClient;
  final String _appKey;

  /// Whether an app key is configured.
  bool get isConfigured => _appKey.isNotEmpty;

  /// Searches Klipy for GIFs matching [query].
  Future<List<GifResult>> search(String query) => _get('gifs/search', {
    'q': query,
    'per_page': '$_kPerPage',
    'format_filter': 'gif',
  });

  /// Fetches Klipy's trending GIFs.
  Future<List<GifResult>> trending() =>
      _get('gifs/trending', {'per_page': '$_kPerPage', 'format_filter': 'gif'});

  Future<List<GifResult>> _get(String path, Map<String, String> query) async {
    final HttpTextResponse response;
    try {
      response = await _httpClient.getText(
        '/api/v1/${Uri.encodeComponent(_appKey)}/$path',
        query: query,
        headers: const HttpHeaders.rawMap({'Accept': 'application/json'}),
      );
    } on RhttpStatusCodeException catch (e) {
      throw NetworkException(
        'Klipy answered HTTP ${e.statusCode}.',
        statusCode: e.statusCode,
        code: 'klipy_unavailable',
      );
    } on RhttpException {
      throw const NetworkException(
        'Klipy could not be reached.',
        code: 'klipy_unavailable',
      );
    }
    try {
      return _parseResponse(response);
    } on Object {
      throw const NetworkException(
        'Klipy answered with something that is not a GIF list.',
        code: 'klipy_unavailable',
      );
    }
  }

  List<GifResult> _parseResponse(HttpTextResponse response) {
    final decoded = httpJsonBody(response);
    final data = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    final outer = data?['data'] as Map<String, dynamic>?;
    final items = outer?['data'] as List<dynamic>?;
    if (items == null) {
      return const [];
    }
    return items
        .map((e) => GifResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
