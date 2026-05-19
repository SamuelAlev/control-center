import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:dio/dio.dart';

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

/// Record/replay HTTP cassettes for a Dio client, so integration tests exercise
/// real request shapes against deterministic, reviewable fixtures — no hand-
/// written mocks, no flakes from upstream drift.
///
/// Redact-on-write, a hard secret-scanning gate, sequential-cursor replay with rich `requestDiff` diagnostics.
///
/// ```dart
/// final recorder = await HttpRecorder.attach(dio, 'github/pr-files');
/// // ... exercise the client ...
/// await recorder.save();
/// ```
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

  /// The cassette name (`<name>.json` under the store directory).
  final String name;

  final RecordMode _mode;
  final CassetteStore _store;
  final Redactor _redactor;
  final RequestMatcher _matcher;
  final Cassette _cassette;
  final Map<String, dynamic>? _metadata;
  int _cursor = 0;
  bool _dirty = false;

  /// The effective mode after `auto` resolution.
  RecordMode get mode => _mode;

  /// Attaches a recorder to [dio] and returns it. Loads the cassette (for
  /// replay) up front and resolves `auto` mode based on whether it exists and
  /// whether we are in CI.
  static Future<HttpRecorder> attach(
    Dio dio,
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
    final cassette = resolved == RecordMode.record
        ? Cassette(metadata: metadata)
        : (existing ?? Cassette(metadata: metadata));
    final recorder = HttpRecorder._(
      name: name,
      mode: resolved,
      store: store,
      redactor: redactor ?? Redactor.defaults(),
      matcher: matcher ?? defaultRequestMatcher,
      cassette: cassette,
      metadata: metadata,
    );
    dio.interceptors.add(_CassetteInterceptor(recorder));
    return recorder;
  }

  /// Persists the recorded cassette to disk (record mode only). Throws
  /// [UnsafeCassetteError] if it contains anything that looks like a secret.
  Future<void> save() async {
    if (_mode != RecordMode.record || !_dirty) {
      return;
    }
    final withMeta = Cassette(
      version: _cassette.version,
      metadata: {'name': name, ...?_metadata},
      interactions: _cassette.interactions,
    );
    await _store.write(name, withMeta);
  }

  // ---- interceptor hooks -------------------------------------------------

  RequestSnapshot _snapshotRequest(RequestOptions options) {
    final headers = <String, String>{
      for (final entry in options.headers.entries)
        entry.key.toLowerCase(): '${entry.value}',
    };
    return _redactor.redactRequest(
      RequestSnapshot(
        method: options.method.toUpperCase(),
        url: options.uri.toString(),
        headers: headers,
        body: _encodeRequestBody(options.data),
      ),
    );
  }

  ResponseSnapshot _snapshotResponse(Response<dynamic> response) {
    final headers = <String, String>{
      for (final entry in response.headers.map.entries)
        entry.key.toLowerCase(): entry.value.join(', '),
    };
    final data = response.data;
    if (data is List<int>) {
      return _redactor.redactResponse(
        ResponseSnapshot(
          status: response.statusCode ?? 0,
          headers: headers,
          body: base64Encode(data),
          bodyEncoding: 'base64',
        ),
      );
    }
    return _redactor.redactResponse(
      ResponseSnapshot(
        status: response.statusCode ?? 0,
        headers: headers,
        body: data is String ? data : jsonEncode(data),
      ),
    );
  }

  static String _encodeRequestBody(Object? data) {
    if (data == null) {
      return '';
    }
    if (data is String) {
      return data;
    }
    if (data is Map || data is List) {
      return jsonEncode(data);
    }
    return '$data';
  }

  Response<dynamic> _buildResponse(RequestOptions options, ResponseSnapshot s) {
    final dynamic data;
    if (s.bodyEncoding == 'base64') {
      data = base64Decode(s.body);
    } else if (options.responseType == ResponseType.json &&
        _looksJson(s.headers['content-type'], s.body)) {
      data = s.body.isEmpty ? null : jsonDecode(s.body);
    } else {
      data = s.body;
    }
    return Response<dynamic>(
      requestOptions: options,
      statusCode: s.status,
      headers: Headers.fromMap({
        for (final entry in s.headers.entries) entry.key: [entry.value],
      }),
      data: data,
    );
  }

  static bool _looksJson(String? contentType, String body) {
    if (contentType != null && contentType.toLowerCase().contains('json')) {
      return true;
    }
    final trimmed = body.trimLeft();
    return trimmed.startsWith('{') || trimmed.startsWith('[');
  }
}

class _CassetteInterceptor extends Interceptor {
  _CassetteInterceptor(this._recorder);

  final HttpRecorder _recorder;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final r = _recorder;
    if (r._mode == RecordMode.passthrough || r._mode == RecordMode.record) {
      handler.next(options);
      return;
    }
    // Replay: match the next interaction in record order.
    final incoming = r._snapshotRequest(options);
    final result = selectSequential(
      r._cassette.interactions,
      incoming,
      r._matcher,
      r._cursor,
    );
    if (result.interaction == null) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error:
              'Cassette "${r.name}" does not match the current request:\n'
              '${result.detail}',
        ),
      );
      return;
    }
    r._cursor++;
    handler.resolve(r._buildResponse(options, result.interaction!.response));
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final r = _recorder;
    if (r._mode == RecordMode.record) {
      r._cassette.interactions.add(
        HttpInteraction(
          request: r._snapshotRequest(response.requestOptions),
          response: r._snapshotResponse(response),
        ),
      );
      r._dirty = true;
    }
    handler.next(response);
  }
}
