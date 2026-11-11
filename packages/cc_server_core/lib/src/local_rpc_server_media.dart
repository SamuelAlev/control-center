part of 'local_rpc_server.dart';

/// The credential the media proxy presents for [userId] viewing
/// [workspaceId] when it fetches [target], or null for an anonymous fetch.
typedef MediaCredentialResolver =
    Future<String?> Function(String userId, Uri target, String workspaceId);

extension _MediaMethods on LocalRpcServer {
  Future<void> _serveMediaProxy(HttpRequest request) async {
    final res = request.response;
    final transfer = _resourceTransfers[request];
    bool cancelled() => transfer?.isCancelled ?? false;
    final cancellation = transfer?.cancelled;
    if (!mediaProxyEnabled) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    final q = request.uri.queryParameters;
    final encoded = q['u'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (encoded == null || deviceId == null || sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    final wParam = int.tryParse(q['w'] ?? '');
    final maxWidth = wParam?.clamp(8, 2048).toInt();
    String rawUrl;
    try {
      rawUrl = utf8.decode(base64Url.decode(encoded));
    } catch (_) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(rawUrl, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final target = Uri.tryParse(rawUrl);
    if (target == null ||
        (target.scheme != 'http' && target.scheme != 'https')) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    // An early 403 for a literal or a reserved name; a hostname is judged by
    // the pinned connection every fetch goes through.
    if (isBlockedProxyTarget(target)) {
      _w('Media proxy refusing blocked target host: ${target.host}');
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final clientRange = request.headers.value(HttpHeaders.rangeHeader);
    final maxBytes = mediaProxyMaxBytes ?? 96 * 1024 * 1024;

    // `ws` (the viewer's active workspace) picks which of the viewer's own
    // sign-ins a private forge asset is fetched with: the one in effect in
    // that workspace, never a global slot. Unsigned on purpose: it only
    // chooses among the viewer's own credentials, and membership is checked.
    // Without it the fetch is anonymous.
    final userId = device?.userId;
    final workspaceId = q['ws'];
    final scoped = workspaceId != null && workspaceId.isNotEmpty;
    if (scoped && await _lacksMembershipForUser(userId, workspaceId)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    // A credential rides only https.
    final authorization = userId == null || !scoped || target.scheme != 'https'
        ? null
        : await mediaCredential?.call(userId, target, workspaceId);

    final cache = _mediaCache;
    if (cache != null &&
        (authorization == null || authorization.isEmpty) &&
        (clientRange == null || clientRange.isEmpty)) {
      try {
        final resolution = await cache.resolve(
          MediaCache.keyFor(rawUrl, maxWidth),
          ({etag, lastModified, required cancellation}) => _fetchMediaForCache(
            target,
            maxWidth: maxWidth,
            etag: etag,
            lastModified: lastModified,
            cancelled: cancellation.cancelled,
            isCancelled: () => cancellation.isCancelled,
          ),
          cancelled: cancellation,
          isCancelled: cancelled,
        );
        if (cancelled()) {
          return;
        }
        switch (resolution) {
          case MediaCacheHit(:final bodyFile, :final contentType):
            await _serveCachedMediaFile(res, contentType, bodyFile);
            return;
          case MediaCacheUncached(:final bytes, :final contentType):
            await _serveBufferedMedia(res, contentType, bytes);
            return;
          case MediaCachePassthrough(:final outcome):
            await _relayMediaStream(
              res,
              outcome.response,
              outcome.client,
              cancelled: cancellation,
              isCancelled: cancelled,
            );
            return;
          case MediaCacheFailure():
            await _closeProxy(res, HttpStatus.badGateway);
            return;
        }
      } catch (e) {
        if (cancelled()) {
          return;
        }
        _w('Media cache path failed for ${target.host}: $e');
      }
    }
    if (cancelled()) {
      return;
    }

    HttpClient? client;
    try {
      client = _mediaHttpClient();
      final outbound = client;
      _abortMediaClientOnCancellation(
        outbound,
        cancelled: cancellation,
        isCancelled: cancelled,
      );
      final opened = await _openUpstream(
        outbound,
        target,
        range: clientRange,
        authorization: authorization,
        isCancelled: cancelled,
      );
      if (cancelled()) {
        return;
      }
      switch (opened) {
        case _UpstreamError(:final statusCode):
          await _closeProxy(res, statusCode);
          return;
        case _UpstreamNotModified():
          await _closeProxy(res, HttpStatus.badGateway);
          return;
        case _UpstreamOk(:final response, :final finalUri):
          final upstream = response;
          if (upstream.statusCode >= 400 || upstream.contentLength > maxBytes) {
            await _closeProxy(res, HttpStatus.badGateway);
            return;
          }

          final isRanged =
              upstream.statusCode == HttpStatus.partialContent ||
              (clientRange != null && clientRange.isNotEmpty);

          if (!isRanged) {
            final looksLikeIcon =
                finalUri.path.toLowerCase().endsWith('.ico') ||
                _isIconContentType(upstream.headers.contentType);
            if (looksLikeIcon) {
              final bytes = await _readCapped(
                upstream,
                maxBytes,
                isCancelled: cancelled,
              );
              if (cancelled()) {
                return;
              }
              if (bytes == null) {
                await _closeProxy(res, HttpStatus.badGateway);
                return;
              }
              final png = transcodeIcoToPng(bytes);
              final source = png ?? bytes;
              final resized = maxWidth != null
                  ? await resizeRasterToWidthAsync(source, maxWidth)
                  : null;
              if (cancelled()) {
                return;
              }
              await _serveBufferedMedia(
                res,
                resized?.mimeType ??
                    (png != null
                        ? 'image/png'
                        : (upstream.headers.contentType?.toString() ??
                              'application/octet-stream')),
                resized?.bytes ?? source,
              );
              return;
            }
            if (maxWidth != null) {
              final raw = await _readCapped(
                upstream,
                maxBytes,
                isCancelled: cancelled,
              );
              if (cancelled()) {
                return;
              }
              if (raw == null) {
                await _closeProxy(res, HttpStatus.badGateway);
                return;
              }
              final resized = await resizeRasterToWidthAsync(raw, maxWidth);
              if (cancelled()) {
                return;
              }
              await _serveBufferedMedia(
                res,
                resized?.mimeType ??
                    (upstream.headers.contentType?.toString() ??
                        'application/octet-stream'),
                resized?.bytes ?? raw,
              );
              return;
            }
          }

          final relayClient = client;
          client = null;
          await _relayMediaStream(
            res,
            upstream,
            relayClient,
            cancelled: cancellation,
            isCancelled: cancelled,
          );
          return;
      }
    } catch (e) {
      if (!cancelled()) {
        _w('Media proxy fetch failed for ${target.host}: $e');
        await _closeProxy(res, HttpStatus.badGateway);
      }
    } finally {
      client?.close(force: true);
    }
  }

  Future<MediaFetchOutcome> _fetchMediaForCache(
    Uri target, {
    required int? maxWidth,
    String? etag,
    String? lastModified,
    bool alwaysBuffer = false,
    int? bufferCap,
    Future<void>? cancelled,
    bool Function()? isCancelled,
  }) async {
    final maxBytes = bufferCap ?? mediaProxyMaxBytes ?? 96 * 1024 * 1024;
    final client = _mediaHttpClient();
    _abortMediaClientOnCancellation(
      client,
      cancelled: cancelled,
      isCancelled: isCancelled,
    );
    var transferred = false;
    try {
      if (isCancelled?.call() ?? false) {
        return const MediaFetchFailed();
      }
      final opened = await _openUpstream(
        client,
        target,
        etag: etag,
        lastModified: lastModified,
        isCancelled: isCancelled,
      );
      if (isCancelled?.call() ?? false) {
        return const MediaFetchFailed();
      }
      switch (opened) {
        case _UpstreamError():
          return const MediaFetchFailed();
        case _UpstreamNotModified():
          return const MediaFetchNotModified();
        case _UpstreamOk(:final response, :final finalUri):
          final upstream = response;
          if (upstream.statusCode >= 400 || upstream.contentLength > maxBytes) {
            // Closing the client in finally also terminates bodies that never
            // finish, rather than waiting for an untrusted peer to drain.
            return const MediaFetchFailed();
          }
          final looksLikeIcon =
              finalUri.path.toLowerCase().endsWith('.ico') ||
              _isIconContentType(upstream.headers.contentType);
          final isImage =
              looksLikeIcon ||
              (upstream.headers.contentType?.mimeType.toLowerCase().startsWith(
                    'image/',
                  ) ??
                  false);
          if (!isImage && maxWidth == null && !alwaysBuffer) {
            transferred = true;
            return MediaFetchStream(upstream, client);
          }
          final raw = await _readCapped(
            upstream,
            maxBytes,
            isCancelled: isCancelled,
          );
          if (raw == null || (isCancelled?.call() ?? false)) {
            return const MediaFetchFailed();
          }
          final String contentType;
          final List<int> body;
          if (looksLikeIcon) {
            final png = transcodeIcoToPng(raw);
            final source = png ?? raw;
            final resized = maxWidth != null
                ? await resizeRasterToWidthAsync(source, maxWidth)
                : null;
            body = resized?.bytes ?? source;
            contentType =
                resized?.mimeType ??
                (png != null
                    ? 'image/png'
                    : (upstream.headers.contentType?.toString() ??
                          'application/octet-stream'));
          } else {
            final resized = maxWidth != null
                ? await resizeRasterToWidthAsync(raw, maxWidth)
                : null;
            body = resized?.bytes ?? raw;
            contentType =
                resized?.mimeType ??
                (upstream.headers.contentType?.toString() ??
                    'application/octet-stream');
          }
          if (isCancelled?.call() ?? false) {
            return const MediaFetchFailed();
          }
          final cacheControl = upstreamCacheControlValue(upstream.headers);
          return MediaFetchBuffered(
            bytes: body,
            contentType: contentType,
            etag: firstUpstreamHeaderValue(
              upstream.headers,
              HttpHeaders.etagHeader,
            ),
            lastModified: firstUpstreamHeaderValue(
              upstream.headers,
              HttpHeaders.lastModifiedHeader,
            ),
            maxAgeSeconds: _parseMaxAgeSeconds(cacheControl),
            cache: !_forbidsStoring(cacheControl),
          );
      }
    } catch (e) {
      if (!(isCancelled?.call() ?? false)) {
        _w('Media proxy fetch failed for ${target.host}: $e');
      }
      return const MediaFetchFailed();
    } finally {
      if (!transferred) {
        client.close(force: true);
      }
    }
  }

  /// A client for one upstream fetch: it connects only through
  /// [mediaConnectionFactory] (the address it judged, never a second DNS
  /// answer) and never through a proxy, which would connect by name.
  HttpClient _mediaHttpClient() => HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..userAgent = 'control-center-media-proxy'
    ..findProxy = ((_) => 'DIRECT')
    ..connectionFactory = mediaConnectionFactory;

  Future<_UpstreamOpen> _openUpstream(
    HttpClient client,
    Uri target, {
    String? range,
    String? etag,
    String? lastModified,
    String? authorization,
    bool Function()? isCancelled,
  }) async {
    var current = target;
    var sendAuth = authorization != null && authorization.isNotEmpty;
    for (var hop = 0; ; hop++) {
      if (isCancelled?.call() ?? false) {
        return const _UpstreamError(HttpStatus.badGateway);
      }
      final req = (await client.getUrl(current))
        ..followRedirects = false
        ..headers.set(HttpHeaders.acceptHeader, '*/*');
      if (sendAuth) {
        req.headers.set(HttpHeaders.authorizationHeader, authorization!);
      }
      if (range != null && range.isNotEmpty) {
        req.headers.set(HttpHeaders.rangeHeader, range);
      }
      if (etag != null && etag.isNotEmpty) {
        req.headers.set(HttpHeaders.ifNoneMatchHeader, etag);
      }
      if (lastModified != null && lastModified.isNotEmpty) {
        req.headers.set(HttpHeaders.ifModifiedSinceHeader, lastModified);
      }
      final upstream = await req.close().timeout(const Duration(seconds: 20));
      if (isCancelled?.call() ?? false) {
        return const _UpstreamError(HttpStatus.badGateway);
      }
      if (upstream.statusCode == HttpStatus.notModified &&
          (etag != null || lastModified != null)) {
        // A 304 has no useful body; do not wait on a misbehaving host.
        return const _UpstreamNotModified();
      }
      if (!upstream.isRedirect) {
        return _UpstreamOk(upstream, current);
      }
      // Redirect bodies are irrelevant. Closing the request's response is
      // handled by the client when following the next redirect or on exit.
      if (hop >= 3) {
        _w('Media proxy exceeded redirect budget for ${target.host}');
        return const _UpstreamError(HttpStatus.badGateway);
      }
      final loc = firstUpstreamHeaderValue(
        upstream.headers,
        HttpHeaders.locationHeader,
      );
      if (loc == null || loc.isEmpty) {
        return const _UpstreamError(HttpStatus.badGateway);
      }
      final next = current.resolve(loc);
      if (next.scheme != 'http' && next.scheme != 'https') {
        return const _UpstreamError(HttpStatus.badRequest);
      }
      if (isBlockedProxyTarget(next)) {
        if (isCancelled?.call() ?? false) {
          return const _UpstreamError(HttpStatus.badGateway);
        }
        _w('Media proxy refusing blocked redirect host: ${next.host}');
        return const _UpstreamError(HttpStatus.forbidden);
      }
      // The viewer's credential rides only https, and only to the host it
      // was chosen for.
      if (next.scheme != 'https' ||
          next.host.toLowerCase() != current.host.toLowerCase()) {
        sendAuth = false;
      }
      current = next;
    }
  }

  Future<void> _serveBufferedMedia(
    HttpResponse res,
    String contentType,
    List<int> bytes,
  ) async {
    _setBufferedMediaHeaders(res, contentType);
    res
      ..headers.contentLength = bytes.length
      ..add(bytes);
    await res.close();
  }

  Future<void> _serveCachedMediaFile(
    HttpResponse res,
    String contentType,
    File bodyFile,
  ) async {
    final int length;
    try {
      length = await bodyFile.length();
    } on FileSystemException {
      await _closeProxy(res, HttpStatus.badGateway);
      return;
    }
    _setBufferedMediaHeaders(res, contentType);
    res.headers.contentLength = length;
    try {
      await res.addStream(bodyFile.openRead());
      await res.close();
    } on Object {
      // Client disconnected mid-stream, or the entry was swept out from under
      // us — either way the response is already unusable.
    }
  }

  void _setBufferedMediaHeaders(HttpResponse res, String contentType) {
    ContentType parsed;
    try {
      parsed = ContentType.parse(contentType);
    } on FormatException {
      parsed = ContentType('application', 'octet-stream');
    }
    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = parsed
      ..headers.set('Cache-Control', 'private, max-age=86400')
      ..headers.set('X-Content-Type-Options', 'nosniff');
  }

  Future<void> _relayMediaStream(
    HttpResponse res,
    HttpClientResponse upstream,
    HttpClient client, {
    Future<void>? cancelled,
    bool Function()? isCancelled,
  }) async {
    final maxBytes = mediaProxyMaxBytes ?? 96 * 1024 * 1024;
    _abortMediaClientOnCancellation(
      client,
      cancelled: cancelled,
      isCancelled: isCancelled,
    );
    try {
      res
        ..statusCode = upstream.statusCode
        ..headers.contentType =
            upstream.headers.contentType ??
            ContentType('application', 'octet-stream')
        ..headers.set('Cache-Control', 'private, max-age=86400')
        ..headers.set('X-Content-Type-Options', 'nosniff')
        ..headers.set('Accept-Ranges', 'bytes');
      final contentRange = firstUpstreamHeaderValue(
        upstream.headers,
        HttpHeaders.contentRangeHeader,
      );
      if (contentRange != null) {
        res.headers.set(HttpHeaders.contentRangeHeader, contentRange);
      }
      var total = 0;
      await for (final chunk in upstream) {
        if (isCancelled?.call() ?? false) {
          return;
        }
        total += chunk.length;
        if (total > maxBytes) {
          await res.close();
          return;
        }
        res.add(chunk);
      }
      if (isCancelled?.call() ?? false) {
        return;
      }
      await res.close();
    } finally {
      client.close(force: true);
    }
  }

  int? _parseMaxAgeSeconds(String? cacheControl) {
    if (cacheControl == null) {
      return null;
    }
    final match = RegExp(
      r'(?:^|,)\s*(?:s-maxage|max-age)\s*=\s*(\d+)',
    ).firstMatch(cacheControl.toLowerCase());
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  bool _forbidsStoring(String? cacheControl) {
    if (cacheControl == null) {
      return false;
    }
    final value = cacheControl.toLowerCase();
    return value.contains('no-store') || value.contains('private');
  }

  bool _isIconContentType(ContentType? ct) {
    if (ct == null) {
      return false;
    }
    final m = ct.mimeType.toLowerCase();
    return m == 'image/x-icon' ||
        m == 'image/vnd.microsoft.icon' ||
        m == 'image/ico';
  }

  /// Bind cancellation to the actual outbound socket, not just the loopback
  /// response that consumes it. A shared cache fetch passes its flight's
  /// cancellation here; a direct fetch passes its individual request's.
  void _abortMediaClientOnCancellation(
    HttpClient client, {
    Future<void>? cancelled,
    bool Function()? isCancelled,
  }) {
    if (isCancelled?.call() ?? false) {
      client.close(force: true);
    }
    if (cancelled != null) {
      unawaited(
        cancelled.then((_) {
          if (isCancelled?.call() ?? false) {
            client.close(force: true);
          }
        }),
      );
    }
  }

  Future<List<int>?> _readCapped(
    HttpClientResponse resp,
    int cap, {
    bool Function()? isCancelled,
  }) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in resp) {
      if (isCancelled?.call() ?? false) {
        return null;
      }
      if (chunk.length > cap - builder.length) {
        return null;
      }
      builder.add(chunk);
    }
    return (isCancelled?.call() ?? false) ? null : builder.takeBytes();
  }
}
