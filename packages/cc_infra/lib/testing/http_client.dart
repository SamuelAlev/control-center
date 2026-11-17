import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:rhttp/rhttp.dart';

/// A canned transport for adapter tests, without a native library or sockets.
///
/// Interceptors, cancellation, and native streaming must be exercised against a
/// real client. This double records requests and supplies protocol responses.
class TestHttpClient implements RhttpClient {
  /// Creates a transport whose [handler] supplies each protocol response.
  TestHttpClient({
    required this.handler,
    this.settings = const ClientSettings(),
  });

  /// Produces responses or transport errors for captured requests.
  FutureOr<HttpResponse> Function(HttpRequest request) handler;

  /// Requests sent through this client, in dispatch order.
  final List<HttpRequest> requests = [];

  /// The size of the pieces a streamed response arrives in.
  int streamChunkSize = 16 * 1024;

  /// How many pieces of streamed responses were handed to their listeners.
  int streamedChunks = 0;
  bool _disposed = false;

  @override
  final ClientSettings settings;

  @override
  Interceptor? get interceptor => null;

  @override
  void dispose({bool cancelRunningRequests = false}) => _disposed = true;

  @override
  Future<HttpResponse> send(BaseHttpRequest request) async {
    final outgoing = HttpRequest.from(request: request, settings: settings);
    if (_disposed) {
      throw RhttpClientDisposedException(outgoing);
    }
    requests.add(outgoing);
    final handled = await handler(outgoing);
    final response = outgoing.expectBody == HttpExpectBody.stream
        ? _asStream(handled)
        : handled;
    if (settings.throwOnStatusCode && response.statusCode >= 400) {
      throw RhttpStatusCodeException(
        request: outgoing,
        statusCode: response.statusCode,
        headers: response.headers,
        body: switch (response) {
          HttpTextResponse() => response.body,
          HttpBytesResponse() => response.body,
          HttpStreamResponse() => null,
        },
      );
    }
    return response;
  }

  /// A handler describes the response; the request decides its shape. A
  /// caller that asked for a stream gets the handler's text or bytes in
  /// [streamChunkSize] pieces, and counts in [streamedChunks] how many of
  /// them it took before it stopped listening.
  HttpResponse _asStream(HttpResponse response) {
    final Uint8List bytes;
    switch (response) {
      case HttpStreamResponse():
        return response;
      case HttpTextResponse():
        bytes = utf8.encode(response.body);
      case HttpBytesResponse():
        bytes = response.body;
    }
    Stream<Uint8List> chunks() async* {
      for (var at = 0; at < bytes.length; at += streamChunkSize) {
        final end = at + streamChunkSize;
        streamedChunks++;
        yield Uint8List.sublistView(
          bytes,
          at,
          end < bytes.length ? end : bytes.length,
        );
      }
    }

    return HttpStreamResponse(
      remoteIp: response.remoteIp,
      request: response.request,
      version: response.version,
      statusCode: response.statusCode,
      headers: response.headers,
      body: chunks(),
    );
  }

  @override
  Future<HttpResponse> request({
    required HttpMethod method,
    required String url,
    Map<String, String>? query,
    List<(String, String)>? queryRaw,
    HttpHeaders? headers,
    HttpBody? body,
    required HttpExpectBody expectBody,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) => send(
    BaseHttpRequest(
      method: method,
      url: url,
      query: query,
      queryRaw: queryRaw,
      headers: headers,
      body: body,
      expectBody: expectBody,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    ),
  );

  // Route the convenience methods through the same captured request. Native
  // handles are deliberately not faked: accessing `ref` remains an error.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (!invocation.isMethod) {
      return super.noSuchMethod(invocation);
    }
    final name = invocation.memberName;
    final named = invocation.namedArguments;
    final method = switch (name) {
      #get || #getText || #getBytes || #getStream => HttpMethod.get,
      #post => HttpMethod.post,
      #put => HttpMethod.put,
      #delete => HttpMethod.delete,
      #head => HttpMethod.head,
      #patch => HttpMethod.patch,
      #options => HttpMethod.options,
      #trace => HttpMethod.trace,
      #requestText ||
      #requestBytes ||
      #requestStream => named[#method] as HttpMethod,
      _ => null,
    };
    if (method == null) {
      return super.noSuchMethod(invocation);
    }
    final expectBody = switch (name) {
      #getBytes || #requestBytes => HttpExpectBody.bytes,
      #getStream || #requestStream => HttpExpectBody.stream,
      _ => HttpExpectBody.text,
    };
    final response = request(
      method: method,
      url: invocation.positionalArguments.isEmpty
          ? named[#url] as String
          : invocation.positionalArguments.single as String,
      query: named[#query] as Map<String, String>?,
      queryRaw: named[#queryRaw] as List<(String, String)>?,
      headers: named[#headers] as HttpHeaders?,
      body: named[#body] as HttpBody?,
      expectBody: expectBody,
      cancelToken: named[#cancelToken] as CancelToken?,
      onSendProgress: named[#onSendProgress] as ProgressCallback?,
      onReceiveProgress: named[#onReceiveProgress] as ProgressCallback?,
    );
    return switch (expectBody) {
      HttpExpectBody.text => response.then((r) => r as HttpTextResponse),
      HttpExpectBody.bytes => response.then((r) => r as HttpBytesResponse),
      HttpExpectBody.stream => response.then((r) => r as HttpStreamResponse),
    };
  }
}

/// Creates a text response, JSON-encoding non-string protocol bodies.
HttpTextResponse httpTextResponse(
  HttpRequest request,
  Object? body, {
  int statusCode = 200,
  Map<String, String> headers = const {},
}) => HttpTextResponse(
  remoteIp: null,
  request: request,
  version: HttpVersion.http1_1,
  statusCode: statusCode,
  headers: [
    if (body is! String &&
        !headers.keys.any((key) => key.toLowerCase() == 'content-type'))
      ('content-type', 'application/json'),
    for (final entry in headers.entries) (entry.key, entry.value),
  ],
  body: body is String ? body : jsonEncode(body),
);

/// Creates a binary response without copying an existing [Uint8List].
HttpBytesResponse httpBytesResponse(
  HttpRequest request,
  List<int> bytes, {
  int statusCode = 200,
  Map<String, String> headers = const {},
}) => HttpBytesResponse(
  remoteIp: null,
  request: request,
  version: HttpVersion.http1_1,
  statusCode: statusCode,
  headers: [for (final entry in headers.entries) (entry.key, entry.value)],
  body: bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
);

/// Resolves the URI represented by a captured rhttp request.
Uri httpRequestUri(HttpRequest request) {
  final uri = Uri.parse('${request.settings?.baseUrl ?? ''}${request.url}');
  // An empty query adds no `?`, matching what the native client sends.
  if (request.queryRaw case final query? when query.isNotEmpty) {
    return uri.replace(
      query: [
        for (final (key, value) in query)
          '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      ].join('&'),
    );
  }
  final params = request.query;
  return params == null || params.isEmpty
      ? uri
      : uri.replace(queryParameters: params);
}
