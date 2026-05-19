import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_clipboard.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_display.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The guest agent did not answer, or answered badly.
class GuestAgentException implements Exception {
  /// Creates a [GuestAgentException].
  const GuestAgentException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'GuestAgentException: $message';
}

/// What the in-guest agent says it is.
///
/// The forward-compatibility seam: a host that can ask an image what protocol
/// it speaks can refuse (or adapt to) one it does not, instead of failing
/// somewhere further in with a mystery. Nothing enforces [protocol] yet.
class GuestAgentVersion {
  /// Creates a [GuestAgentVersion].
  const GuestAgentVersion({required this.protocol, required this.agent});

  /// Parses a `/version` reply, defaulting a missing/garbled protocol to 0 —
  /// "older than the first one that announced itself", never a throw.
  factory GuestAgentVersion.fromJson(Map<String, dynamic> json) {
    final protocol = json['protocol'];
    return GuestAgentVersion(
      protocol: protocol is int ? protocol : 0,
      agent: json['agent'] is String ? json['agent'] as String : 'unknown',
    );
  }

  /// The protocol revision the guest agent speaks.
  final int protocol;

  /// A build identifier for the agent itself (diagnostics, not a contract).
  final String agent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuestAgentVersion &&
          other.protocol == protocol &&
          other.agent == agent;

  @override
  int get hashCode => Object.hash(protocol, agent);

  @override
  String toString() => 'GuestAgentVersion($agent, protocol $protocol)';
}

/// The guest image is older than the endpoint that was asked for.
///
/// Distinct from [GuestAgentException] because the fix is different and the
/// caller can say so: a 404 from a rig means the image on disk predates this
/// feature and needs rebuilding, while every other failure is a machine that
/// is not well. Reporting the first as the second sends whoever reads it
/// looking for a fault in a VM that is working exactly as its image says.
class GuestAgentTooOld implements Exception {
  /// Creates a [GuestAgentTooOld].
  const GuestAgentTooOld(this.endpoint);

  /// The endpoint the image does not serve.
  final String endpoint;

  @override
  String toString() =>
      'GuestAgentTooOld: this rig image does not serve $endpoint';
}

/// Host-side client for the small daemon inside a rig's guest image.
///
/// The agent is deliberately tiny and UNPRIVILEGED. It can capture the screen,
/// change the display mode, move the clipboard and report health — nothing
/// else. Input injection is NOT its job: that goes through the hypervisor
/// (QMP), so the guest never hosts a privileged process that can synthesize
/// input, and compromising the guest's own software does not hand an attacker
/// a keyboard. The clipboard does not weaken that: owning an X selection is
/// what every ordinary client does, and it carries data, never events.
///
/// The transport is plain HTTP over a port forwarded from the guest to host
/// loopback. It is not encrypted because it never leaves the host's loopback
/// interface, and it carries a per-VM bearer token so another process on the
/// same machine cannot drive someone else's rig by guessing a port.
class GuestAgentClient {
  /// Creates a client for the agent reachable on host loopback [port].
  GuestAgentClient({
    required this.port,
    required this.token,
    String host = '127.0.0.1',
    HttpClient? httpClient,
  }) : _host = host,
       _client = httpClient ?? (HttpClient()..idleTimeout = _idleTimeout);

  /// The host-side forwarded port.
  final int port;

  /// Per-VM bearer token, minted at boot and destroyed with the machine.
  final String token;

  final String _host;
  final HttpClient _client;

  static const Duration _idleTimeout = Duration(seconds: 30);

  /// Waits until the agent answers, or throws after [timeout].
  ///
  /// The whole boot gate: a rig is "ready" exactly when this returns, because
  /// nothing before it can be observed or driven.
  Future<RigDisplaySize> awaitReady({
    Duration timeout = const Duration(seconds: 120),
    void Function(String step)? onProgress,
  }) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    var reported = false;
    while (DateTime.now().isBefore(deadline)) {
      try {
        return await health();
      } on Object catch (e) {
        lastError = e;
        if (!reported) {
          reported = true;
          onProgress?.call('Waiting for the guest to come up');
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw GuestAgentException(
      'The guest agent did not answer within ${timeout.inSeconds}s '
      '(last error: $lastError). The VM booted but its agent is not '
      'reachable — the image may be wrong for this surface.',
    );
  }

  /// The guest's current display mode.
  Future<RigDisplaySize> health() async {
    final body = await _getJson('/health');
    final display = body['display'];
    if (display is Map) {
      return RigDisplaySize.fromJson(display.cast<String, dynamic>());
    }
    return RigDisplaySize.defaultDesktop;
  }

  /// What the guest agent reports it is, or null when the image predates
  /// `/version`.
  ///
  /// A 404 is an OLD image, not a broken one, and the two need different
  /// answers: every image built before this endpoint existed is still a
  /// perfectly good rig, so treating "no such endpoint" as a failure would
  /// break machines that work. Any OTHER non-200 is a real fault and throws.
  Future<GuestAgentVersion?> version() async {
    final response = await _get('/version');
    // Drain unconditionally: an unread body holds the connection open in the
    // client's pool, and the 404 path is the one most likely to be hit.
    final text = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_requestTimeout);
    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }
    if (response.statusCode != 200) {
      throw GuestAgentException(
        'Guest agent /version returned HTTP ${response.statusCode}: $text',
      );
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return GuestAgentVersion.fromJson(decoded);
      }
    } on FormatException {
      CcInfraLog.warning('rig/guest-agent: unparseable reply from /version');
    }
    throw const GuestAgentException(
      'Guest agent /version returned a malformed reply',
    );
  }

  /// Captures one still, scaled to at most [size].
  ///
  /// The AGENT lane. Scaling happens in the guest, so a 2560x1600 desktop does
  /// not ship 4 MB across the wire to be thrown away on the host.
  Future<Uint8List> capture({
    required RigDisplaySize size,
    int quality = 80,
  }) async {
    final response = await _get(
      '/frame?w=${size.width}&h=${size.height}&q=${quality.clamp(1, 100)}',
    );
    if (response.statusCode != 200) {
      throw GuestAgentException(
        'Capture failed with HTTP ${response.statusCode}',
      );
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
      if (builder.length > _maxCaptureBytes) {
        // Everything a guest produces is untrusted, including how MUCH of it
        // there is. An unbounded accumulator is a guest-controlled allocation
        // in the server's heap.
        throw const GuestAgentException(
          'Capture exceeded ${_maxCaptureBytes ~/ (1024 * 1024)} MB — the '
          'guest is not answering with a screenshot.',
        );
      }
    }
    final bytes = builder.takeBytes();
    if (bytes.isEmpty) {
      throw const GuestAgentException('Capture returned no bytes');
    }
    return bytes;
  }

  /// Opens the human watch lane: an MJPEG stream at the negotiated settings.
  ///
  /// The returned bytes are relayed to the viewer verbatim. Nothing on the
  /// host decodes them — the server is a pipe, and putting a JPEG decoder in
  /// the request path is how you get a server that cannot answer RPCs while
  /// someone watches a VM.
  Future<Stream<List<int>>> openStream(RigWatchRequest request) async {
    // No deadline: this lane's success condition IS a body that never ends.
    final response = await _get(
      '/stream?w=${request.size.width}&h=${request.size.height}'
      '&fps=${request.fps}&q=${request.quality}',
      timeout: null,
    );
    if (response.statusCode != 200) {
      throw GuestAgentException(
        'Stream failed with HTTP ${response.statusCode}',
      );
    }
    return response;
  }

  /// Opens the guest's audio lane: whatever plays into its null sink,
  /// encoded to MP3 in-guest and relayed as bytes.
  Future<Stream<List<int>>> openAudio({int bitrateKbps = 128}) async {
    final response = await _get('/audio?kbps=$bitrateKbps', timeout: null);
    if (response.statusCode != 200) {
      throw GuestAgentException(
        'Audio stream failed with HTTP ${response.statusCode}',
      );
    }
    return response;
  }

  /// Asks the guest to change its display mode.
  ///
  /// Returns what the guest actually settled on: a guest can refuse a mode its
  /// virtual GPU has no timing for, and a caller that assumed success would
  /// map every later click through the wrong coordinate space.
  Future<RigDisplaySize> setDisplay(RigDisplaySize size) async {
    final body = await _postJson('/display', {
      'width': size.width,
      'height': size.height,
    });
    final display = body['display'];
    if (display is Map) {
      return RigDisplaySize.fromJson(
        display.cast<String, dynamic>(),
        fallback: size,
      );
    }
    return size;
  }

  /// Reads [selection] off the guest's clipboard.
  ///
  /// Throws [GuestAgentTooOld] when the image predates protocol 2 — the
  /// clipboard is the first capability an existing rig image can be missing,
  /// and "rebuild the image" is a different instruction from "the VM is
  /// broken".
  Future<RigClipboardData> readClipboard(
    RigClipboardSelection selection,
  ) async {
    final body = await _getJson(
      '/clipboard?sel=${selection.wire}',
      // Longer than the guest's own 4s selection timeout plus a round trip:
      // a read that gives up BEFORE the guest does turns a slow clipboard
      // owner into "the rig is not responding".
      timeout: const Duration(seconds: 12),
    );
    final image = body['image'];
    final imageBytes = image is String ? image.length * 3 ~/ 4 : 0;
    final tooBig = imageBytes > RigClipboardData.maxImageBytes;
    return RigClipboardData(
      text: body['text'] is String ? body['text'] as String : null,
      // Dropped rather than truncated: half a PNG is not a smaller PNG, it is
      // a corrupt one, and pasting it would look like a guest bug.
      imageBase64: tooBig ? null : (image is String ? image : null),
      imageMediaType: tooBig
          ? null
          : (body['image_media_type'] is String
                ? body['image_media_type'] as String
                : (image is String ? 'image/png' : null)),
      imageSkippedBytes: tooBig ? imageBytes : null,
      files: [
        for (final f in (body['files'] as List? ?? const []))
          if (f is Map) ?RigGuestFile.fromJson(f.cast<String, dynamic>()),
      ],
    );
  }

  /// Puts [data] on the guest's `CLIPBOARD` selection.
  ///
  /// One flavour lands, and the guest picks it in the order image → files →
  /// text: X selection ownership is exclusive, so a second claim on the same
  /// selection evicts the first. Callers that want a specific flavour send
  /// only that one.
  Future<void> writeClipboard(RigClipboardData data) async {
    await _postJson('/clipboard', {
      if (data.text != null) 'text': data.text,
      if (data.imageBase64 != null) ...{
        'image': data.imageBase64,
        'image_media_type': data.imageMediaType ?? 'image/png',
      },
      if (data.files.isNotEmpty)
        'files': [for (final f in data.files) f.guestPath],
    }, timeout: const Duration(seconds: 12));
  }

  /// Closes the underlying HTTP client.
  void close() => _client.close(force: true);

  /// One request/response round trip, bounded.
  ///
  /// [timeout] is null ONLY for the two streaming lanes (`/stream`, `/audio`),
  /// whose whole job is to stay open. Everything else is a small JSON reply or
  /// one JPEG, and a guest that accepts the connection and then stops talking
  /// would otherwise hang the caller forever: the boot gate would never reach
  /// its own 120 s deadline, and a `computer_use` capture would hold its tool
  /// call open indefinitely.
  Future<HttpClientResponse> _get(
    String path, {
    Duration? timeout = _requestTimeout,
  }) async {
    final request = await _client.getUrl(Uri.parse('http://$_host:$port$path'));
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    final future = request.close();
    return timeout == null ? future : future.timeout(timeout);
  }

  /// The deadline for a non-streaming guest-agent request.
  static const Duration _requestTimeout = Duration(seconds: 20);

  /// The most a single capture may be: a scaled JPEG of one screen. The guest
  /// scales before it encodes, so a real frame is tens of kilobytes; this is
  /// the ceiling on what a HOSTILE guest can make the host hold in memory by
  /// answering `/frame` with an endless body.
  static const int _maxCaptureBytes = 32 * 1024 * 1024;

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Duration timeout = _requestTimeout,
  }) async {
    final response = await _get(path, timeout: timeout);
    return _decode(response, path, timeout: timeout);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = _requestTimeout,
  }) async {
    final request = await _client.postUrl(
      Uri.parse('http://$_host:$port$path'),
    );
    final bytes = utf8.encode(jsonEncode(body));
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
      ..contentType = ContentType.json;
    // An explicit Content-Length, never chunked: without it dart:io sends a
    // chunked body, the agent's stdlib HTTP handler reads "length 0" and
    // parses an EMPTY request — so /display "successfully" re-applied its
    // own defaults and every resize through this client was a silent no-op.
    request.contentLength = bytes.length;
    request.add(bytes);
    final response = await request.close().timeout(timeout);
    return _decode(response, path, timeout: timeout);
  }

  Future<Map<String, dynamic>> _decode(
    HttpClientResponse response,
    String path, {
    Duration timeout = _requestTimeout,
  }) async {
    final text = await response.transform(utf8.decoder).join().timeout(timeout);
    if (response.statusCode == HttpStatus.notFound) {
      // An endpoint this image never had. Every agent serves /health and
      // /frame, so a 404 is always "this image is older than the caller",
      // never "the machine is broken" — and only the first is fixed by
      // rebuilding an image.
      throw GuestAgentTooOld(path.split('?').first);
    }
    if (response.statusCode != 200) {
      throw GuestAgentException(
        'Guest agent $path returned HTTP ${response.statusCode}: $text',
      );
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on FormatException {
      CcInfraLog.warning('rig/guest-agent: unparseable reply from $path');
    }
    throw GuestAgentException('Guest agent $path returned a malformed reply');
  }
}
