import 'dart:async';

import 'package:cc_connect/src/upstream_http.dart';

/// The Cloud Run / GCE metadata endpoint that hands the runtime service
/// account's OAuth access token to the instance.
final Uri gcpMetadataTokenUrl = Uri.parse(
  'http://metadata.google.internal/computeMetadata/v1/instance/'
  'service-accounts/default/token',
);

/// A source of Google Cloud bearer tokens (KMS, Firestore).
abstract interface class GcpTokenSource {
  /// A token valid for at least a minute.
  Future<String> token();
}

/// Reads the runtime service account's token from the metadata server and
/// caches it until a minute before it expires. Concurrent callers share one
/// fetch.
final class GcpMetadataTokenSource implements GcpTokenSource {
  /// Creates the source.
  GcpMetadataTokenSource(this._http, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final UpstreamHttp _http;
  final DateTime Function() _clock;
  String _token = '';
  DateTime _expiresAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<String>? _inflight;

  @override
  Future<String> token() {
    if (_token.isNotEmpty &&
        _clock().isBefore(_expiresAt.subtract(const Duration(minutes: 1)))) {
      return Future.value(_token);
    }
    return _inflight ??= _fetch().whenComplete(() => _inflight = null);
  }

  Future<String> _fetch() async {
    final response = await _http.send(
      UpstreamRequest(
        'GET',
        gcpMetadataTokenUrl,
        headers: const {'metadata-flavor': 'Google'},
      ),
    );
    final json = response.jsonObject;
    final token = json?['access_token'];
    final expiresIn = json?['expires_in'];
    if (!response.ok ||
        token is! String ||
        token.isEmpty ||
        expiresIn is! int) {
      throw const UpstreamUnavailable('metadata token');
    }
    _token = token;
    _expiresAt = _clock().add(Duration(seconds: expiresIn));
    return token;
  }
}
