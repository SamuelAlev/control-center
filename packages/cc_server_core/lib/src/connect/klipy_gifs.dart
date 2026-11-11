import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/features/pr_review/domain/entities/gif_result.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart' show KlipyApiClient;
import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/identity/workspace_provider_app_settings.dart';
import 'package:rhttp/rhttp.dart' show RhttpClient;

/// Where GIF search runs right now.
enum KlipyLaneSource {
  /// The workspace's own Klipy app key.
  workspaceOwn,

  /// The operator's own `KLIPY_APP_KEY`.
  own,

  /// Control Center Connect (its proxy, or the key it hands out).
  connect,

  /// Nothing configured: GIF search returns nothing.
  off;

  /// The wire spelling.
  String get wire => name;
}

/// The composer's GIF search, resolved per call and per workspace.
///
/// A workspace on its own apps uses its own Klipy key and nothing else (no
/// key saved: search is off). A workspace that inherits uses the operator's
/// own key while the server is on its own apps, else the server's Connect;
/// one on a Connect of its own uses that Connect. A Connect's Klipy lane
/// decides — `proxy` searches through Connect (the key never reaches this
/// server), `key` hands this server a rotatable key to call Klipy with. With
/// neither, the answer is empty. Every result's media URLs must be on
/// Klipy's CDN: clients load them directly, so anything else is dropped.
class KlipyGifs {
  /// Creates the resolver. [ownAppKey] is `KLIPY_APP_KEY` (empty when
  /// unset); `workspaceApps` holds workspaces' own keys (none in the
  /// `cc_server connect` CLI, which only reports the server's source);
  /// [transport] supplies the HTTP client direct calls ride on.
  KlipyGifs({
    required this._connect,
    String ownAppKey = '',
    this._workspaceApps,
    RhttpClient Function()? transport,
  }) : _ownAppKey = ownAppKey.trim(),
       _transportFactory = transport ?? KlipyApiClient.transport;

  final ConnectClient _connect;
  final String _ownAppKey;
  final WorkspaceProviderAppSettings? _workspaceApps;
  final RhttpClient Function() _transportFactory;
  RhttpClient? _transport;

  /// Which source a call from [workspaceId] would use now (the server's own
  /// choice for null).
  Future<KlipyLaneSource> source([String? workspaceId]) async {
    final route = await _connect.routeFor(workspaceId);
    if (route.workspaceOwnApps) {
      return await _workspaceApps?.klipyAppKey(workspaceId!) != null
          ? KlipyLaneSource.workspaceOwn
          : KlipyLaneSource.off;
    }
    if (_ownKeyActive(route)) {
      return KlipyLaneSource.own;
    }
    final lane = (await _connect.usableConfig(route.target))?.klipy;
    return lane == null ? KlipyLaneSource.off : KlipyLaneSource.connect;
  }

  /// GIFs matching [query], for a member of [workspaceId].
  Future<List<KlipyGif>> search(String workspaceId, String query) => _resolve(
    workspaceId,
    direct: (client) => client.search(query),
    proxy: (target) => _connect.klipySearch(target, query),
  );

  /// Klipy's trending GIFs, for a member of [workspaceId].
  Future<List<KlipyGif>> trending(String workspaceId) => _resolve(
    workspaceId,
    direct: (client) => client.trending(),
    proxy: _connect.klipyTrending,
  );

  Future<List<KlipyGif>> _resolve(
    String workspaceId, {
    required Future<List<GifResult>> Function(KlipyApiClient client) direct,
    required Future<List<KlipyGif>> Function(ConnectTarget target) proxy,
  }) async {
    final route = await _connect.routeFor(workspaceId);
    if (route.workspaceOwnApps) {
      final key = await _workspaceApps?.klipyAppKey(workspaceId);
      return key == null ? const [] : _direct(key, direct);
    }
    if (_ownKeyActive(route)) {
      return _direct(_ownAppKey, direct);
    }
    final lane = (await _connect.usableConfig(route.target))?.klipy;
    switch (lane?.mode) {
      case null:
        return const [];
      case KlipyLaneMode.key:
        return _direct(lane!.appKey, direct);
      case KlipyLaneMode.proxy:
        final List<KlipyGif> gifs;
        try {
          gifs = await proxy(route.target);
        } on ConnectException catch (e) {
          CcHostLog.warning('gif: Connect search unavailable (${e.code.wire})');
          throw const NetworkException(
            'GIF search is unavailable right now.',
            code: 'klipy_unavailable',
          );
        }
        return [
          for (final gif in gifs)
            if (isKlipyCdnUrl(gif.previewUrl) && isKlipyCdnUrl(gif.gifUrl)) gif,
        ];
    }
  }

  /// `KLIPY_APP_KEY` applies only while [route] inherits a server on its
  /// own apps (`ConnectSettings.serverOwnAppsActive`).
  bool _ownKeyActive(ConnectRoute route) =>
      _ownAppKey.isNotEmpty && route.serverOwnApps;

  Future<List<KlipyGif>> _direct(
    String appKey,
    Future<List<GifResult>> Function(KlipyApiClient client) call,
  ) async {
    final client = KlipyApiClient(
      appKey: appKey,
      httpClient: _transport ??= _transportFactory(),
    );
    return [for (final result in await call(client)) ?_fromResult(result)];
  }

  static KlipyGif? _fromResult(GifResult result) {
    if (!isKlipyCdnUrl(result.previewUrl) || !isKlipyCdnUrl(result.url)) {
      return null;
    }
    return KlipyGif(
      id: '${result.id}',
      title: result.title,
      width: result.width,
      height: result.height,
      previewUrl: result.previewUrl,
      gifUrl: result.url,
    );
  }
}
