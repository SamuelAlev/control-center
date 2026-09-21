import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter/widgets.dart';

/// Signed-media origin plus pairing credential for this device.
///
/// Phone never fetches remote media directly — all via cc_server
/// (`/workspace/logo`, `/proxy/media`), PSK-signed
/// ([RemoteControlCrypto.signProxyTarget]) then membership-checked. Origin is
/// live `probeUri` (failover). Broker relay has no HTTP origin — callers fall
/// back to initials/monograms.
@immutable
class RemoteMediaEndpoint {
  /// Creates a [RemoteMediaEndpoint].
  const RemoteMediaEndpoint({
    required this.httpBase,
    required this.deviceId,
    required this.psk,
  });

  /// `http(s)://host:port` of the server hosting the media endpoints.
  final Uri httpBase;

  /// The paired device id, echoed back so the host picks the verifying PSK.
  final String deviceId;

  /// The connection pre-shared key. Signs each URL's canonical target.
  final String psk;

  /// The `/workspace/logo` URL for [workspaceId].
  String workspaceLogoUrl(String workspaceId) => httpBase
      .replace(
        path: '/workspace/logo',
        queryParameters: {
          'w': workspaceId,
          'd': deviceId,
          's': RemoteControlCrypto.signProxyTarget(
            'workspace-logo:$workspaceId',
            psk,
          ),
        },
      )
      .toString();

  /// Rewrites [rawUrl] to a same-pairing `/proxy/media` URL, or returns it
  /// unchanged when it is not an absolute `http(s)` URL (a `data:` avatar, an
  /// asset, a relative path — all of which the client loads directly).
  ///
  /// [maxWidth] (device pixels) asks the proxy to downscale the raster it
  /// serves. It sits OUTSIDE the signature deliberately: the signed `u` pins
  /// the exact upstream the proxy fetches, so `w` can only shrink output the
  /// host already authorised — it cannot redirect the fetch. Widths are
  /// bucketed so nearby display sizes share one server cache entry instead of
  /// minting one per size.
  String resolve(String rawUrl, {int? maxWidth}) {
    if (rawUrl.isEmpty) {
      return rawUrl;
    }
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return rawUrl;
    }
    final bucketed = maxWidth == null ? null : _bucketWidth(maxWidth);
    return httpBase
        .replace(
          path: '/proxy/media',
          queryParameters: {
            'u': base64Url.encode(utf8.encode(rawUrl)),
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(rawUrl, psk),
            if (bucketed != null) 'w': '$bucketed',
          },
        )
        .toString();
  }

  /// The `/blob` URL serving the bytes behind [ref], or an empty string when
  /// [ref] is not a well-formed `blob:sha256:<hex>` reference.
  ///
  /// This is how a screenshot on a message reaches the phone: the row carries
  /// a content hash, never bytes. The hash is checked here because it becomes a
  /// filename on the server — anything that is not 64 lowercase hex characters
  /// is refused rather than signed.
  String blobUrl({required String workspaceId, required String ref}) {
    const prefix = 'blob:sha256:';
    if (!ref.startsWith(prefix)) {
      return '';
    }
    final hash = ref.substring(prefix.length);
    if (hash.length != 64 || !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      return '';
    }
    return httpBase
        .replace(
          path: '/blob',
          queryParameters: {
            'w': workspaceId,
            'h': hash,
            'd': deviceId,
            's': RemoteControlCrypto.signProxyTarget(
              'blob:$workspaceId:$hash',
              psk,
            ),
          },
        )
        .toString();
  }

  /// The `POST /blob` URL an attachment's bytes are uploaded to.
  ///
  /// The signed target is `blob-put:<workspaceId>` rather than a hash, because
  /// the hash is what the call PRODUCES — a client cannot sign for bytes the
  /// server has not stored yet. Membership is still checked server-side, so the
  /// signature only ever buys a write into a workspace this device's user
  /// belongs to.
  String blobUploadUrl({required String workspaceId}) => httpBase
      .replace(
        path: '/blob',
        queryParameters: {
          'w': workspaceId,
          'd': deviceId,
          's': RemoteControlCrypto.signProxyTarget(
            'blob-put:$workspaceId',
            psk,
          ),
        },
      )
      .toString();

  /// The width ladder every proxied raster is bucketed UP to. Kept small and
  /// avatar-weighted: the phone's only proxied images are marks and avatars.
  static const List<int> _ladder = [32, 48, 64, 96, 128, 192, 256, 384, 512];

  static int _bucketWidth(int width) {
    for (final step in _ladder) {
      if (width <= step) {
        return step;
      }
    }
    return _ladder.last;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteMediaEndpoint &&
          httpBase == other.httpBase &&
          deviceId == other.deviceId &&
          psk == other.psk;

  @override
  int get hashCode => Object.hash(httpBase, deviceId, psk);
}
