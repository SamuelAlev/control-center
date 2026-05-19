import 'dart:async';
import 'package:control_center/core/utils/app_log.dart';

import 'package:dio/dio.dart';

/// A Dio interceptor that retries failed requests with exponential backoff.
class RetryInterceptor extends Interceptor {
  /// Creates a [RetryInterceptor] with the given [Dio] instance.
  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
  }) : _dio = dio;

  final Dio _dio;
  /// The maximum number of retry attempts.
  final int maxRetries;
  /// The base delay between retries, doubled on each attempt.
  final Duration baseDelay;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final remaining = response.headers.value('x-ratelimit-remaining');
    if (remaining != null) {
      final count = int.tryParse(remaining);
      if (count != null && count == 0) {
        final retryAfter = response.headers.value('retry-after');
        final backoff = retryAfter != null
            ? Duration(seconds: int.tryParse(retryAfter) ?? 60)
            : const Duration(seconds: 60);
        AppLog.w(
          'RetryInterceptor',
          'Rate limit approaching ($remaining remaining). '
          'Preemptive backoff ${backoff.inSeconds}s',
        );
        Future<void>.delayed(backoff).then((_) => handler.next(response));
        return;
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!_shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    final retryAfter = err.response?.headers.value('retry-after');
    Duration delay;
    if (retryAfter != null) {
      delay = Duration(seconds: int.tryParse(retryAfter) ?? baseDelay.inSeconds);
    } else {
      delay = baseDelay * (1 << retryCount);
    }
    await Future<void>.delayed(delay);

    final options = err.requestOptions.copyWith(
      extra: {...err.requestOptions.extra, 'retryCount': retryCount + 1},
    );

    try {
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    final status = err.response?.statusCode;
    return status == 429 || (status != null && status >= 500 && status < 600);
  }
}
