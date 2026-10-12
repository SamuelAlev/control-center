import 'package:cc_domain/features/pr_review/domain/entities/gif_result.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:rhttp/rhttp.dart';

const _kKlipyBaseUrl = 'https://api.klipy.com';
const _kPerPage = 30;

/// Server-side Klipy GIF client. Lives on `cc_server` so the thin client never
/// hits Klipy directly (it holds no app key and the browser can't reach it
/// cross-origin): the client drives `gif.search` / `gif.trending` over RPC and
/// the host calls this. The Klipy app key is a server config value
/// (`CcServerConfig.klipyAppKey`), embedded in the request path as Klipy
/// expects.
class KlipyApiClient {
  /// Creates a [KlipyApiClient] for [_appKey], optionally backed by a custom
  /// [httpClient] (defaults to the shared `createHttpClient` with Klipy's base
  /// URL).
  KlipyApiClient({required this._appKey, RhttpClient? httpClient})
    : _httpClient =
          httpClient ??
          createHttpClient(
            baseUrl: _kKlipyBaseUrl,
            settings: const ClientSettings(
              // Klipy answers or the request is not worth waiting on: the old
              // client bounded both connection setup and the whole call at 5s.
              timeoutSettings: TimeoutSettings(
                connectTimeout: Duration(seconds: 5),
                timeout: Duration(seconds: 5),
              ),
            ),
          );

  final RhttpClient _httpClient;
  final String _appKey;

  /// Whether an app key is configured (the ops are absent on the host
  /// otherwise).
  bool get isConfigured => _appKey.isNotEmpty;

  /// Searches Klipy for GIFs matching [query].
  Future<List<GifResult>> search(String query) async {
    final response = await _httpClient.getText(
      '/api/v1/$_appKey/gifs/search',
      query: {'q': query, 'per_page': '$_kPerPage', 'format_filter': 'gif'},
    );
    return _parseResponse(response);
  }

  /// Fetches Klipy's trending GIFs.
  Future<List<GifResult>> trending() async {
    final response = await _httpClient.getText(
      '/api/v1/$_appKey/gifs/trending',
      query: {'per_page': '$_kPerPage', 'format_filter': 'gif'},
    );
    return _parseResponse(response);
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
