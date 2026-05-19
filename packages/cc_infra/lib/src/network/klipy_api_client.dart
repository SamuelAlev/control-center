import 'package:cc_domain/features/pr_review/domain/entities/gif_result.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:dio/dio.dart';

const _kKlipyBaseUrl = 'https://api.klipy.com';
const _kPerPage = 30;

/// Server-side Klipy GIF client. Lives on `cc_server` so the thin client never
/// hits Klipy directly (it holds no app key, and the browser can't reach it
/// cross-origin): the client drives `gif.search` / `gif.trending` over RPC and
/// the host calls this. The Klipy app key is a server config value
/// (`CcServerConfig.klipyAppKey`), embedded in the request path as Klipy
/// expects.
class KlipyApiClient {
  /// Creates a [KlipyApiClient] for [appKey], optionally backed by a custom
  /// [dio] (defaults to the shared `createDio` with Klipy's base URL).
  KlipyApiClient({required String appKey, Dio? dio})
    : _appKey = appKey,
      _dio =
          dio ??
          (createDio(baseUrl: _kKlipyBaseUrl)
            ..options.connectTimeout = const Duration(seconds: 5)
            ..options.receiveTimeout = const Duration(seconds: 5));

  final Dio _dio;
  final String _appKey;

  /// Whether an app key is configured (the ops are absent on the host
  /// otherwise).
  bool get isConfigured => _appKey.isNotEmpty;

  /// Searches Klipy for GIFs matching [query].
  Future<List<GifResult>> search(String query) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/$_appKey/gifs/search',
      queryParameters: {
        'q': query,
        'per_page': _kPerPage,
        'format_filter': 'gif',
      },
    );
    return _parseResponse(response.data);
  }

  /// Fetches Klipy's trending GIFs.
  Future<List<GifResult>> trending() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/$_appKey/gifs/trending',
      queryParameters: {'per_page': _kPerPage, 'format_filter': 'gif'},
    );
    return _parseResponse(response.data);
  }

  List<GifResult> _parseResponse(Map<String, dynamic>? data) {
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
