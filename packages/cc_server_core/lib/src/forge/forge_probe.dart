/// The one plain GET the forge layer makes outside an API client: who a
/// token is, whether it can read a repository, what a bot token is.
library;

import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_infra/cc_infra.dart' show forgeAuthorizationHeader;

/// One forge answer. `status` is null when the forge was not reached (or
/// answered more than a probe reads); `json` is the decoded body, or null.
typedef ForgeProbeAnswer = ({
  int? status,
  Object? json,
  String body,
  String? Function(String name) header,
});

const Duration _timeout = Duration(seconds: 8);
const int _maxBodyBytes = 1024 * 1024;

/// `GET` [path] on [forge]'s API ([ForgeHost.apiBaseUrl], so every probe
/// reaches the same host), authenticated with [token] the way every request
/// to that forge is ([forgeAuthorizationHeader], plus GitLab's
/// `PRIVATE-TOKEN`). Never follows a redirect and never throws.
Future<ForgeProbeAnswer> forgeGet(
  ForgeHost forge,
  String token,
  String path,
) async {
  String? none(String _) => null;
  if (forge.apiBaseUrl.isEmpty || token.isEmpty) {
    return (status: null, json: null, body: '', header: none);
  }
  final client = HttpClient()..connectionTimeout = _timeout;
  try {
    final request = await client.getUrl(Uri.parse('${forge.apiBaseUrl}$path'));
    request.followRedirects = false;
    request.headers
      ..set(
        HttpHeaders.authorizationHeader,
        forgeAuthorizationHeader(forge, token),
      )
      ..set(HttpHeaders.userAgentHeader, 'control-center')
      ..set(HttpHeaders.acceptHeader, 'application/json');
    if (forge == ForgeHost.gitlab) {
      request.headers.set('PRIVATE-TOKEN', token);
    }
    final response = await request.close().timeout(_timeout);
    final bytes = <int>[];
    await for (final chunk in response.timeout(_timeout)) {
      bytes.addAll(chunk);
      if (bytes.length > _maxBodyBytes) {
        return (status: null, json: null, body: '', header: none);
      }
    }
    final body = utf8.decode(bytes, allowMalformed: true);
    Object? json;
    try {
      json = body.isEmpty ? null : jsonDecode(body);
    } on FormatException {
      json = null;
    }
    return (
      status: response.statusCode,
      json: json,
      body: body,
      header: response.headers.value,
    );
  } on Object {
    return (status: null, json: null, body: '', header: none);
  } finally {
    client.close(force: true);
  }
}
