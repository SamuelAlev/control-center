import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_connect/src/pages.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// The browser cookie that ties `/done` to the login whose callback this
/// browser completed on HTTPS (`__Host-`: Secure, Path=/, no Domain).
const String connectCookieName = '__Host-cc_connect';

/// The plain-HTTP loopback counterpart (`__Host-` and `Secure` are rejected by
/// WebKit/Safari over `http://127.0.0.1` and `http://localhost`).
const String loopbackConnectCookieName = 'cc_connect';

/// Picks the `/done` cookie name for [baseOrLocation] (`https` uses `__Host-`,
/// loopback `http` uses the plain name).
String connectCookieNameFor(String baseOrLocation) =>
    baseOrLocation.startsWith('https://')
    ? connectCookieName
    : loopbackConnectCookieName;

/// The single value of header [name], or null when absent or repeated.
String? singleHeader(HttpRequest request, String name) {
  final values = request.headers[name];
  if (values == null || values.length != 1) {
    return null;
  }
  return values.single;
}

/// The client closed the connection before its request body arrived in full.
/// Nobody is left to answer; logged at warn, never reported.
final class ConnectClientAborted implements Exception {
  /// Creates the exception.
  const ConnectClientAborted();

  @override
  String toString() => 'ConnectClientAborted';
}

/// Reads the body up to [cap] bytes; null when it is larger (the rest is
/// not read). Throws [ConnectClientAborted] when the client hangs up first.
Future<List<int>?> readCappedBody(HttpRequest request, int cap) async {
  if (request.contentLength > cap) {
    return null;
  }
  final out = BytesBuilder(copy: false);
  try {
    await for (final chunk in request) {
      if (out.length + chunk.length > cap) {
        return null;
      }
      out.add(chunk);
    }
  } on HttpException {
    // "Connection closed while receiving data": a truncated upload.
    throw const ConnectClientAborted();
  }
  return out.takeBytes();
}

/// Decodes a JSON object body; throws [ConnectException]
/// (`invalid_request`).
Map<String, Object?> decodeJsonObject(List<int> body) {
  try {
    final decoded = jsonDecode(utf8.decode(body));
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
  } on FormatException {
    // Fall through.
  }
  throw const ConnectException(ConnectErrorCode.invalidRequest);
}

/// Headers every Connect response carries. Deliberately no CORS header of
/// any kind: no browser origin may read a Connect answer. [https] adds HSTS
/// (an https public URL).
void applyBaseHeaders(HttpResponse response, {required bool https}) {
  response.headers
    ..removeAll('access-control-allow-origin')
    ..set('cache-control', 'no-store')
    ..set('x-content-type-options', 'nosniff')
    ..set('referrer-policy', 'no-referrer');
  if (https) {
    response.headers.set('strict-transport-security', 'max-age=31536000');
  }
}

/// Writes a JSON answer and closes the response.
Future<void> sendJson(HttpResponse response, int status, Object? body) async {
  final bytes = utf8.encode(jsonEncode(body));
  response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..contentLength = bytes.length
    ..add(bytes);
  await response.close();
}

/// Writes `{"error": code}` with the code's status.
Future<void> sendError(HttpResponse response, ConnectErrorCode code) =>
    sendJson(response, code.httpStatus, {'error': code.wire});

/// Writes a hardened HTML page; [form] allows its form to post to Connect.
///
/// The form page alone replaces the base `no-referrer` policy with
/// `same-origin`: under `no-referrer` a browser sends `Origin: null` with the
/// page's own form post, which names no origin to check. `same-origin` makes
/// it send Connect's origin on that post and still sends nothing to any other
/// origin.
Future<void> sendPage(
  HttpResponse response,
  int status,
  String html, {
  bool form = false,
}) async {
  final bytes = utf8.encode(html);
  if (form) {
    response.headers.set('referrer-policy', 'same-origin');
  }
  response
    ..statusCode = status
    ..headers.contentType = ContentType.html
    ..headers.set(
      'content-security-policy',
      form ? formPageContentSecurityPolicy : pageContentSecurityPolicy,
    )
    ..headers.set('x-frame-options', 'DENY')
    ..headers.set('cross-origin-opener-policy', 'same-origin')
    ..headers.set('cross-origin-resource-policy', 'same-origin')
    ..contentLength = bytes.length
    ..add(bytes);
  await response.close();
}

/// Writes a static message page.
Future<void> sendStaticPage(HttpResponse response, StaticPage page) =>
    sendPage(response, page.status, renderStaticPage(page));

/// A `303 See Other` to [location], optionally setting the login cookie.
Future<void> sendSeeOther(
  HttpResponse response,
  Uri location, {
  String? cookieValue,
  Duration cookieMaxAge = const Duration(minutes: 10),
}) async {
  response
    ..statusCode = HttpStatus.seeOther
    ..headers.set('location', location.toString())
    ..contentLength = 0;
  if (cookieValue != null) {
    final secure = location.scheme == 'https';
    final name = secure ? connectCookieName : loopbackConnectCookieName;
    response.headers.add(
      'set-cookie',
      '$name=$cookieValue; Max-Age=${cookieMaxAge.inSeconds}; '
          'Path=/;${secure ? ' Secure;' : ''} HttpOnly; SameSite=Lax',
    );
  }
  await response.close();
}

/// The value of [name] in the request's `Cookie` header(s), or null.
String? requestCookie(HttpRequest request, String name) {
  final headers = request.headers['cookie'];
  if (headers == null) {
    return null;
  }
  for (final header in headers) {
    for (final part in header.split(';')) {
      final eq = part.indexOf('=');
      if (eq <= 0) {
        continue;
      }
      if (part.substring(0, eq).trim() == name) {
        return part.substring(eq + 1).trim();
      }
    }
  }
  return null;
}
