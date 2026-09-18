import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';

/// Logical iOS screen geometry returned by WebDriverAgent.
class WdaScreen {
  /// Creates screen geometry.
  const WdaScreen({required this.size, required this.scale});

  /// Logical simulator points used by actions.
  final RigDisplaySize size;

  /// Native pixels per logical point.
  final double scale;
}

/// Structured WebDriverAgent protocol failure.
class WdaException implements Exception {
  /// Creates a protocol failure.
  const WdaException({required this.message, this.code, this.statusCode});

  /// W3C error code, when present.
  final String? code;

  /// Operator-facing message.
  final String message;

  /// HTTP status, when the server answered.
  final int? statusCode;

  @override
  String toString() => [
    'WdaException',
    if (code != null) code,
    if (statusCode != null) 'HTTP $statusCode',
    message,
  ].join(': ');
}

/// Direct W3C/WebDriverAgent client with bounded response parsing.
class WdaClient {
  /// Creates a client for WDA's command and MJPEG loopback ports.
  WdaClient({
    required this.baseUri,
    required this.mjpegUri,
    HttpClient Function()? httpClientFactory,
    this.requestTimeout = const Duration(seconds: 20),
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  static const int _jsonLimit = 8 * 1024 * 1024;
  static const int _screenshotLimit = 32 * 1024 * 1024;
  static const int _isolateThreshold = 64 * 1024;

  /// WDA command endpoint.
  final Uri baseUri;

  /// WDA native MJPEG endpoint.
  final Uri mjpegUri;
  final HttpClient Function() _httpClientFactory;

  /// Deadline for each finite request.
  final Duration requestTimeout;

  String? _sessionId;

  /// Current W3C session id.
  String? get sessionId => _sessionId;

  /// Polls WDA readiness.
  Future<void> status() async {
    await _jsonRequest('GET', '/status', session: false);
  }

  /// Creates the single XCTest-backed W3C session.
  Future<String> createSession() async {
    if (_sessionId != null) {
      return _sessionId!;
    }
    final body = await _jsonRequest(
      'POST',
      '/session',
      session: false,
      body: const {
        'capabilities': {
          'alwaysMatch': {
            'platformName': 'iOS',
            'appium:automationName': 'XCUITest',
          },
        },
      },
    );
    final value = body['value'];
    final id = value is Map
        ? value['sessionId'] as String?
        : body['sessionId'] as String?;
    if (id == null || id.isEmpty) {
      throw const WdaException(
        code: 'invalid response',
        message: 'WebDriverAgent created no session id.',
      );
    }
    _sessionId = id;
    return id;
  }

  /// Deletes the W3C session. Idempotent locally.
  Future<void> deleteSession() async {
    final id = _sessionId;
    if (id == null) {
      return;
    }
    try {
      await _jsonRequest('DELETE', '/session/$id', session: false);
    } finally {
      _sessionId = null;
    }
  }

  /// Reads the current logical screen size and native scale.
  Future<WdaScreen> screen() async {
    final value = await _valueRequest('GET', '/wda/screen');
    if (value is! Map) {
      throw const WdaException(
        code: 'invalid response',
        message: 'WebDriverAgent returned malformed screen geometry.',
      );
    }
    final width = _positiveInt(value['width']);
    final height = _positiveInt(value['height']);
    final scale = switch (value['scale']) {
      final num number => number.toDouble(),
      final String text => double.tryParse(text),
      _ => null,
    };
    if (width == null || height == null || scale == null || scale <= 0) {
      throw const WdaException(
        code: 'invalid response',
        message: 'WebDriverAgent returned invalid screen geometry.',
      );
    }
    return WdaScreen(size: RigDisplaySize(width, height), scale: scale);
  }

  /// Performs a W3C pointer tap in logical simulator points.
  Future<void> tap(int x, int y) => _actions([
    {
      'type': 'pointer',
      'id': 'finger',
      'parameters': {'pointerType': 'touch'},
      'actions': [
        {'type': 'pointerMove', 'duration': 0, 'x': x, 'y': y},
        {'type': 'pointerDown', 'button': 0},
        {'type': 'pause', 'duration': 50},
        {'type': 'pointerUp', 'button': 0},
      ],
    },
  ]);

  /// Performs a W3C one-finger swipe in logical simulator points.
  Future<void> swipe({
    required int fromX,
    required int fromY,
    required int toX,
    required int toY,
    required Duration duration,
  }) => _actions([
    {
      'type': 'pointer',
      'id': 'finger',
      'parameters': {'pointerType': 'touch'},
      'actions': [
        {'type': 'pointerMove', 'duration': 0, 'x': fromX, 'y': fromY},
        {'type': 'pointerDown', 'button': 0},
        {
          'type': 'pointerMove',
          'duration': duration.inMilliseconds,
          'x': toX,
          'y': toY,
        },
        {'type': 'pointerUp', 'button': 0},
      ],
    },
  ]);

  /// Sends W3C key down/up actions in the supplied order.
  Future<void> key(List<String> values) async {
    final actions = <Map<String, dynamic>>[];
    for (final value in values) {
      actions.add({'type': 'keyDown', 'value': value});
    }
    for (final value in values.reversed) {
      actions.add({'type': 'keyUp', 'value': value});
    }
    await _actions([
      {'type': 'key', 'id': 'keyboard', 'actions': actions},
    ]);
  }

  /// Types literal text through WDA's focused-element route.
  Future<void> typeText(String text) async {
    await _valueRequest('POST', '/wda/keys', body: {'value': [text]});
  }

  /// Returns to the simulator home screen.
  Future<void> home() async {
    await _valueRequest('POST', '/wda/homescreen', body: const {});
  }

  /// Locks the simulator.
  Future<void> lock() async {
    await _valueRequest('POST', '/wda/lock', body: const {});
  }

  /// Unlocks the simulator.
  Future<void> unlock() async {
    await _valueRequest('POST', '/wda/unlock', body: const {});
  }

  /// Launches an installed bundle id.
  Future<void> launchApp(String bundleId) async {
    await _valueRequest(
      'POST',
      '/wda/apps/launch',
      body: {'bundleId': bundleId},
    );
  }

  /// Reads the native accessibility hierarchy as JSON.
  Future<Object?> source() async =>
      _valueRequest('GET', '/source?format=json');

  /// Captures a full-resolution PNG.
  Future<Uint8List> screenshot() async {
    final value = await _valueRequest(
      'GET',
      '/screenshot',
      responseLimit: _screenshotLimit,
    );
    if (value is! String) {
      throw const WdaException(
        code: 'invalid response',
        message: 'WebDriverAgent returned no screenshot payload.',
      );
    }
    try {
      if (value.length > _isolateThreshold) {
        return await Isolate.run(() => base64Decode(value));
      }
      return base64Decode(value);
    } on FormatException {
      throw const WdaException(
        code: 'invalid response',
        message: 'WebDriverAgent returned invalid screenshot base64.',
      );
    }
  }

  /// Reads one pasteboard type as bytes.
  Future<Uint8List> getPasteboard({required String contentType}) async {
    final value = await _valueRequest(
      'POST',
      '/wda/getPasteboard',
      body: {'contentType': contentType},
    );
    if (value is! String) {
      throw const WdaException(
        code: 'invalid response',
        message: 'WebDriverAgent returned no pasteboard payload.',
      );
    }
    return value.length > _isolateThreshold
        ? Isolate.run(() => base64Decode(value))
        : base64Decode(value);
  }

  /// Writes one pasteboard type.
  Future<void> setPasteboard({
    required String contentType,
    required List<int> bytes,
  }) async {
    final encoded = bytes.length > _isolateThreshold
        ? await Isolate.run(() => base64Encode(bytes))
        : base64Encode(bytes);
    await _valueRequest(
      'POST',
      '/wda/setPasteboard',
      body: {'contentType': contentType, 'content': encoded},
    );
  }

  /// Configures WDA's native MJPEG producer for a viewer.
  Future<void> configureMjpeg({
    required int fps,
    required int scalingFactor,
    required int quality,
  }) async {
    await _valueRequest(
      'POST',
      '/appium/settings',
      body: {
        'settings': {
          'mjpegServerFramerate': fps.clamp(1, 15),
          'mjpegScalingFactor': scalingFactor.clamp(1, 100),
          'mjpegServerScreenshotQuality': quality.clamp(1, 100),
        },
      },
    );
  }

  /// Opens WDA's dedicated native MJPEG response body.
  ///
  /// Cancelling the returned stream closes the request client, which closes
  /// the loopback socket and stops hidden tabs consuming frames.
  Stream<List<int>> openMjpeg() async* {
    final client = _httpClientFactory()..connectionTimeout = requestTimeout;
    try {
      final request = await client.getUrl(mjpegUri).timeout(requestTimeout);
      final response = await request.close().timeout(requestTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw WdaException(
          statusCode: response.statusCode,
          message: 'WebDriverAgent MJPEG stream was refused.',
        );
      }
      yield* response;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _actions(List<Map<String, dynamic>> actions) async {
    await _valueRequest('POST', '/actions', body: {'actions': actions});
  }

  Future<Object?> _valueRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    int responseLimit = _jsonLimit,
  }) async {
    final response = await _jsonRequest(
      method,
      path,
      body: body,
      responseLimit: responseLimit,
    );
    return response['value'];
  }

  Future<Map<String, dynamic>> _jsonRequest(
    String method,
    String path, {
    bool session = true,
    Map<String, dynamic>? body,
    int responseLimit = _jsonLimit,
  }) async {
    final resolvedPath = session ? _sessionPath(path) : path;
    final uri = baseUri.resolve(resolvedPath);
    final client = _httpClientFactory()..connectionTimeout = requestTimeout;
    try {
      final request = await client.openUrl(method, uri).timeout(requestTimeout);
      request.headers.contentType = ContentType.json;
      if (body != null) {
        request.add(utf8.encode(jsonEncode(body)));
      }
      final response = await request.close().timeout(requestTimeout);
      final bytes = await _readBounded(response, responseLimit, uri)
          .timeout(requestTimeout);
      final decoded = await _decodeJson(bytes);
      final value = decoded['value'];
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = value is Map ? value['error'] as String? : null;
        final message = value is Map
            ? value['message'] as String?
            : null;
        throw WdaException(
          code: error,
          statusCode: response.statusCode,
          message: message ?? 'WebDriverAgent request failed at ${uri.path}.',
        );
      }
      if (value is Map && value['error'] is String) {
        throw WdaException(
          code: value['error'] as String,
          statusCode: response.statusCode,
          message:
              value['message'] as String? ??
              'WebDriverAgent returned a protocol error.',
        );
      }
      return decoded;
    } on TimeoutException {
      throw WdaException(
        code: 'timeout',
        message: 'WebDriverAgent timed out at ${uri.path}.',
      );
    } finally {
      client.close(force: true);
    }
  }

  String _sessionPath(String path) {
    final id = _sessionId;
    if (id == null) {
      throw const WdaException(
        code: 'invalid session id',
        message: 'No WebDriverAgent session is active.',
      );
    }
    return '/session/$id$path';
  }

  static Future<Uint8List> _readBounded(
    HttpClientResponse response,
    int limit,
    Uri uri,
  ) async {
    if (response.contentLength > limit) {
      throw WdaException(
        code: 'response too large',
        statusCode: response.statusCode,
        message: 'WebDriverAgent response exceeded $limit bytes at ${uri.path}.',
      );
    }
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in response) {
      total += chunk.length;
      if (total > limit) {
        throw WdaException(
          code: 'response too large',
          statusCode: response.statusCode,
          message:
              'WebDriverAgent response exceeded $limit bytes at ${uri.path}.',
        );
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  static Future<Map<String, dynamic>> _decodeJson(Uint8List bytes) async {
    Object? decode() => jsonDecode(utf8.decode(bytes));
    final decoded = bytes.length > _isolateThreshold
        ? await Isolate.run(decode)
        : decode();
    if (decoded is! Map) {
      throw const WdaException(
        code: 'invalid response',
        message: 'WebDriverAgent returned a non-object JSON response.',
      );
    }
    return decoded.cast<String, dynamic>();
  }

  static int? _positiveInt(Object? value) {
    final integer = switch (value) {
      final int number => number,
      final double number when number.isFinite && number == number.round() =>
        number.round(),
      final String text => int.tryParse(text),
      _ => null,
    };
    return integer != null && integer > 0 ? integer : null;
  }
}
