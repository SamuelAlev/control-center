import 'package:control_center/core/config/env_config.dart';
import 'package:control_center/features/pr_review/domain/entities/gif_result.dart';
import 'package:dio/dio.dart';

const _kKlipyBaseUrl = 'https://api.klipy.com';
const _kPerPage = 30;

/// Klipy api client.
class KlipyApiClient {
  /// Creates a new [Klipy api client].
  KlipyApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _kKlipyBaseUrl,
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 5),
              ),
            );

  final Dio _dio;

  String get _appKey => EnvConfig.klipyAppKey;

  /// checkAppKey.
  void checkAppKey() {
    final appKey = _appKey;
    if (appKey.isEmpty) {
      throw StateError(
        'KLIPY_APP_KEY not set. Pass via --dart-define=KLIPY_APP_KEY=...',
      );
    }
  }

  /// search.
  Future<List<GifResult>> search(String query) async {
    checkAppKey();
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

  /// trending.
  Future<List<GifResult>> trending() async {
    checkAppKey();
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
      return [];
    }
    return items
        .map((e) => GifResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

