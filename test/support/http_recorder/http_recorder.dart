import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_infra/testing/http_client.dart' show httpRequestUri;
import 'package:rhttp/rhttp.dart';

import 'cassette.dart';
import 'cassette_matcher.dart';
import 'cassette_store.dart';

export 'package:cc_domain/cc_domain.dart'
    show RequestSnapshot, ResponseSnapshot, Redactor, SecretScanner, kRedacted;

export 'cassette.dart';
export 'cassette_matcher.dart'
    show RequestMatcher, defaultRequestMatcher, requestDiff;
export 'cassette_store.dart' show CassetteStore, UnsafeCassetteError;

/// How the recorder treats traffic.
enum RecordMode {
  /// Replay if a cassette exists, record if it does not. In CI, always replay
  /// (a missing cassette fails loudly instead of silently re-recording).
  auto,

  /// Always hit upstream and append; overwrites on [HttpRecorder.save].
  record,

  /// Strict — match each request to a recorded interaction; fail if none.
  replay,

  /// Bypass the recorder entirely.
  passthrough,
}

/// Record/replay HTTP cassettes for rhttp clients.
///
/// Redact-on-write, a hard secret-scanning gate, and sequential-cursor replay
/// with request-diff diagnostics. Pass [interceptor] when creating the client.
class HttpRecorder {
  HttpRecorder._({
    required this.name,
    required this._mode,
    required this._store,
    required this._redactor,
    required this._matcher,
    required this._cassette,
    this._metadata,
  });

  final String name;
  final RecordMode _mode;
  final CassetteStore _store;
  final Redactor _redactor;
  final RequestMatcher _matcher;
  final Cassette _cassette;
  final Map<String, dynamic>? _metadata;
  int _cursor = 0;
  bool _dirty = false;

  RecordMode get mode => _mode;
  late final Interceptor interceptor = _CassetteInterceptor(this);

  /// Loads the cassette before the client's immutable interceptor list is built.
  static Future<HttpRecorder> open(
    String name, {
    RecordMode mode = RecordMode.auto,
    String? directory,
    Redactor? redactor,
    RequestMatcher? matcher,
    SecretScanner? scanner,
    Map<String, dynamic>? metadata,
    bool? isCi,
  }) async {
    final store = CassetteStore(directory: directory, scanner: scanner);
    final existing = await store.read(name);
    final ci =
        isCi ??
        (const String.fromEnvironment('CI', defaultValue: '').isNotEmpty);
    final resolved = switch (mode) {
      RecordMode.auto =>
        (existing != null || ci) ? RecordMode.replay : RecordMode.record,
      _ => mode,
    };
    return HttpRecorder._(
      name: name,
      mode: resolved,
      store: store,
      redactor: redactor ?? Redactor.defaults(),
      matcher: matcher ?? defaultRequestMatcher,
      cassette: resolved == RecordMode.record
          ? Cassette(metadata: metadata)
          : (existing ?? Cassette(metadata: metadata)),
      metadata: metadata,
    );
  }

  /// Persists recorded traffic, refusing any cassette that still contains secrets.
  Future<void> save() async {
    if (_mode != RecordMode.record || !_dirty) {
      return;
    }
    await _store.write(
      name,
      Cassette(
        version: _cassette.version,
        metadata: {'name': name, ...?_metadata},
        interactions: _cassette.interactions,
      ),
    );
  }

  RequestSnapshot _snapshotRequest(HttpRequest request) =>
      _redactor.redactRequest(
        RequestSnapshot(
          method: request.method.value,
          url: httpRequestUri(request).toString(),
          headers: {
            for (final entry
                in (request.headers?.toMapList() ?? <String, List<String>>{})
                    .entries)
              entry.key.toLowerCase(): entry.value.join(', '),
          },
          body: switch (request.body) {
            null => '',
            HttpBodyText body => body.text,
            HttpBodyJson body => jsonEncode(body.json),
            HttpBodyBytes body => base64Encode(body.bytes),
            HttpBodyForm body => Uri(queryParameters: body.form).query,
            final body => '$body',
          },
        ),
      );

  ResponseSnapshot _snapshotResponse(HttpResponse response) =>
      _redactor.redactResponse(
        ResponseSnapshot(
          status: response.statusCode,
          headers: response.headerMap,
          body: switch (response) {
            HttpTextResponse() => response.body,
            HttpBytesResponse() => base64Encode(response.body),
            HttpStreamResponse() => throw UnsupportedError(
              'Record buffered responses, not streams',
            ),
          },
          bodyEncoding: response is HttpBytesResponse ? 'base64' : 'text',
        ),
      );

  HttpResponse _buildResponse(HttpRequest request, ResponseSnapshot snapshot) {
    final headers = [
      for (final entry in snapshot.headers.entries) (entry.key, entry.value),
    ];
    if (request.expectBody == HttpExpectBody.text) {
      return HttpTextResponse(
        remoteIp: null,
        request: request,
        version: HttpVersion.http1_1,
        statusCode: snapshot.status,
        headers: headers,
        body: snapshot.bodyEncoding == 'base64'
            ? utf8.decode(base64Decode(snapshot.body))
            : snapshot.body,
      );
    }
    final Uint8List bytes = snapshot.bodyEncoding == 'base64'
        ? base64Decode(snapshot.body)
        : utf8.encode(snapshot.body);
    return request.expectBody == HttpExpectBody.bytes
        ? HttpBytesResponse(
            remoteIp: null,
            request: request,
            version: HttpVersion.http1_1,
            statusCode: snapshot.status,
            headers: headers,
            body: bytes,
          )
        : HttpStreamResponse(
            remoteIp: null,
            request: request,
            version: HttpVersion.http1_1,
            statusCode: snapshot.status,
            headers: headers,
            body: Stream.value(bytes),
          );
  }
}

class _CassetteInterceptor extends Interceptor {
  _CassetteInterceptor(this._recorder);
  final HttpRecorder _recorder;

  @override
  Future<InterceptorResult<HttpRequest>> beforeRequest(
    HttpRequest request,
  ) async {
    final recorder = _recorder;
    if (recorder._mode == RecordMode.passthrough ||
        recorder._mode == RecordMode.record) {
      return Interceptor.next();
    }
    final result = selectSequential(
      recorder._cassette.interactions,
      recorder._snapshotRequest(request),
      recorder._matcher,
      recorder._cursor,
    );
    if (result.interaction == null) {
      throw RhttpUnknownException(
        request,
        'Cassette "${recorder.name}" does not match the current request:\n${result.detail}',
      );
    }
    recorder._cursor++;
    return Interceptor.resolve(
      recorder._buildResponse(request, result.interaction!.response),
    );
  }

  @override
  Future<InterceptorResult<HttpResponse>> afterResponse(
    HttpResponse response,
  ) async {
    final recorder = _recorder;
    if (recorder._mode == RecordMode.record) {
      recorder._cassette.interactions.add(
        HttpInteraction(
          request: recorder._snapshotRequest(response.request),
          response: recorder._snapshotResponse(response),
        ),
      );
      recorder._dirty = true;
    }
    return Interceptor.next();
  }
}
