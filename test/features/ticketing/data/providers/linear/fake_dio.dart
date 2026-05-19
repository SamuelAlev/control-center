import 'package:dio/dio.dart';

/// Hand-written [Dio] fake for the Linear adapter tests.
///
/// The adapter talks to Linear's GraphQL endpoint through exactly one method —
/// `post('', data: …)` — so a settable responder covers every case the suite
/// needs and the whole surface is ~40 lines. It replaced a `mockito` mock whose
/// only job was to stub that same call: mockito is a real dependency with a
/// real constraint (it pins `analyzer >=13.3.0`) and the rest of this repo had
/// already moved to plain fakes under test/fakes/.
///
/// Deliberately NOT a general Dio double: every other member throws through
/// [noSuchMethod], so a test that starts exercising a new part of Dio fails
/// loudly here rather than silently receiving a null-ish default.
class FakeDio implements Dio {
  Future<Response<Map<String, dynamic>>> Function()? _responder;

  /// The paths `post` has been called with, in order. Nothing asserts on this
  /// today — the adapter always posts to `''` — but it makes a surprising call
  /// visible when a test fails.
  final List<String> postedPaths = <String>[];

  /// The request bodies `post` has been called with, in order.
  final List<Object?> postedData = <Object?>[];

  /// Make the next (and every subsequent) `post` return [response].
  void stubPost(Future<Response<Map<String, dynamic>>> Function() response) {
    _responder = response;
  }

  /// Make `post` fail with [error] — the adapter's error-mapping paths.
  void stubPostError(Object error) {
    _responder = () => Future<Response<Map<String, dynamic>>>.error(error);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    postedPaths.add(path);
    postedData.add(data);
    final responder = _responder;
    if (responder == null) {
      throw StateError(
        'FakeDio.post($path) was called with no stub. Call stubPost() or '
        'stubPostError() first.',
      );
    }
    // Every call site is `post<Map<String, dynamic>>`, which is what the
    // responder produces.
    return await responder() as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'FakeDio does not implement ${invocation.memberName}. Add it here if the '
    'adapter genuinely needs it.',
  );
}
