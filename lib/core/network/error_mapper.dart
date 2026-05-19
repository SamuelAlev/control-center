import 'package:control_center/core/errors/app_exceptions.dart';
import 'package:dio/dio.dart';

/// Map dio exception.
NetworkException mapDioException(DioException e) {
  final statusCode = e.response?.statusCode;

  if (statusCode == 400) {
    return NetworkException(
      e.message ?? 'Bad request',
      statusCode: 400,
      responseBody: _responseString(e.response?.data),
      code: 'bad_request',
    );
  }

  if (statusCode == 401 || statusCode == 403) {
    return NetworkException(
      e.message ?? 'Authentication failed',
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: 'auth_error',
    );
  }

  if (statusCode == 404) {
    return NetworkException(
      e.message ?? 'Resource not found',
      statusCode: 404,
      responseBody: _responseString(e.response?.data),
      code: 'not_found',
    );
  }

  if (statusCode == 409) {
    return NetworkException(
      e.message ?? 'Conflict',
      statusCode: 409,
      responseBody: _responseString(e.response?.data),
      code: 'conflict',
    );
  }

  if (statusCode == 422) {
    return NetworkException(
      e.message ?? 'Unprocessable entity',
      statusCode: 422,
      responseBody: _responseString(e.response?.data),
      code: 'unprocessable_entity',
    );
  }

  if (statusCode == 429) {
    final retryAfter = e.response?.headers.value('retry-after');
    final message = retryAfter != null
        ? 'Rate limited — retry after $retryAfter second(s)'
        : (e.message ?? 'Rate limited');
    return NetworkException(
      message,
      statusCode: 429,
      responseBody: _responseString(e.response?.data),
      code: 'rate_limited',
    );
  }

  if (statusCode != null && statusCode >= 500) {
    return NetworkException(
      e.message ?? 'Server error',
      statusCode: statusCode,
      responseBody: _responseString(e.response?.data),
      code: 'server_error',
    );
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return NetworkException(
      e.message ?? 'Network timeout',
      statusCode: statusCode,
      code: 'timeout',
    );
  }

  if (e.type == DioExceptionType.connectionError) {
    return NetworkException(
      e.message ?? 'Connection error',
      statusCode: statusCode,
      code: 'connection_error',
    );
  }

  return NetworkException(
    e.message ?? 'Network error',
    statusCode: statusCode,
    responseBody: _responseString(e.response?.data),
    code: 'network_error',
  );
}

String? _responseString(Object? data) {
  if (data == null) {
    return null;
  }

  return data is String ? data : data.toString();
}

