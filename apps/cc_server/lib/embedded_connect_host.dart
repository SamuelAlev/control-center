import 'dart:io';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_server_core/cc_server_core.dart'
    show EmbeddedConnect, embeddedConnectEnvironmentKey;

/// Builds the `/connect` mount when `CC_SERVER_CONNECT_HOST=on`.
///
/// Only `CONNECT_*` variables reach the service, so it can never borrow this
/// server's own provider credentials. `CONNECT_PUBLIC_URL` defaults to this
/// server's public URL plus `/connect`; it must be HTTPS unless it is
/// loopback, and `CONNECT_ALLOWED_INSTALLS` is required (the service refuses
/// to start without it).
Future<EmbeddedConnect?> buildEmbeddedConnect({
  required Map<String, String> environment,
  required String publicUrl,
}) async {
  final flag = environment[embeddedConnectEnvironmentKey]?.trim().toLowerCase();
  if (flag == null || flag.isEmpty || flag == 'off') {
    return null;
  }
  if (flag != 'on') {
    throw StateError('$embeddedConnectEnvironmentKey must be on or off.');
  }
  final env = <String, String>{
    for (final entry in environment.entries)
      if (entry.key.startsWith('CONNECT_')) entry.key: entry.value,
  };
  final configured = env['CONNECT_PUBLIC_URL']?.trim() ?? '';
  final String base;
  if (configured.isNotEmpty) {
    base = configured;
  } else {
    final origin = _httpOrigin(publicUrl);
    if (origin.isEmpty) {
      throw StateError(
        'The embedded Connect needs a public URL; set CONNECT_PUBLIC_URL or '
        'CC_SERVER_PUBLIC_URL.',
      );
    }
    base = '$origin/connect';
  }
  env['CONNECT_PUBLIC_URL'] = base;
  // `ConnectServiceConfig` is the one check of the URL (absolute, HTTPS
  // unless loopback, no query); only the mount point is this host's rule.
  final config = ConnectServiceConfig.fromEnvironment(env);
  final canonical = config.publicBaseUrl;
  if (config.basePath != '/connect') {
    throw StateError('The embedded Connect is served under /connect.');
  }
  final service = await ConnectService.start(config);
  stdout.writeln('cc_server: embedded Connect at $canonical');
  return _Mount(service);
}

String _httpOrigin(String url) {
  if (url.trim().isEmpty) {
    return '';
  }
  final uri = Uri.tryParse(url.trim());
  if (uri == null || uri.host.isEmpty) {
    return '';
  }
  final scheme = uri.scheme == 'wss' || uri.scheme == 'https'
      ? 'https'
      : 'http';
  return Uri(
    scheme: scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
  ).toString();
}

final class _Mount implements EmbeddedConnect {
  _Mount(this._service);

  final ConnectService _service;

  @override
  bool ownsPath(String path) =>
      (path == '/connect' || path.startsWith('/connect/')) &&
      _service.ownsPath(path);

  @override
  Future<void> handle(HttpRequest request) => _service.handle(request);

  @override
  Future<void> close() => _service.close();
}
