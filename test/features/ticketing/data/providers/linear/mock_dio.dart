import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';

/// Mock for [Dio] that handles generic [post] properly.
class MockDio extends Mock implements Dio {
  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) =>
      super.noSuchMethod(
        Invocation.method(#post, [path], {
          #data: data,
          #queryParameters: queryParameters,
          #options: options,
          #cancelToken: cancelToken,
          #onSendProgress: onSendProgress,
          #onReceiveProgress: onReceiveProgress,
        }),
        returnValue:
            Future.value(Response<T>(requestOptions: RequestOptions(path: ''))),
      ) as Future<Response<T>>;
}
