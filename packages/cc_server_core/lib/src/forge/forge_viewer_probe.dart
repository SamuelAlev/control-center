import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';

/// Asks [forge] who the bearer of [token] is. Null when the token is refused
/// or the forge is unreachable.
Future<String?> probeForgeViewer(ForgeHost forge, String token) async {
  final (url, header, field) = switch (forge) {
    ForgeHost.github => (
      'https://api.github.com/user',
      'Bearer $token',
      'login',
    ),
    ForgeHost.gitlab => (
      'https://gitlab.com/api/v4/user',
      'Bearer $token',
      'username',
    ),
    ForgeHost.bitbucket || ForgeHost.local => ('', '', ''),
  };
  if (url.isEmpty) {
    return null;
  }
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.followRedirects = false;
    request.headers
      ..set(HttpHeaders.authorizationHeader, header)
      ..set(HttpHeaders.userAgentHeader, 'control-center')
      ..set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 8));
    final body = await utf8.decodeStream(
      response.timeout(const Duration(seconds: 8)),
    );
    if (response.statusCode != 200) {
      return null;
    }
    final json = jsonDecode(body);
    final value = json is Map ? json[field] : null;
    return value is String && value.isNotEmpty ? value : null;
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}
