import 'package:cc_connect/src/provider_support.dart';
import 'package:cc_connect/src/service_config.dart';
import 'package:cc_connect/src/upstream_http.dart';
import 'package:cc_connect_core/cc_connect_core.dart';

/// Klipy search and trending through Connect, so the app key never leaves
/// it. Answers are normalised to [KlipyGif]; any item whose media is off
/// Klipy's CDN is dropped, and an answer that contains the key anywhere is
/// refused outright.
final class KlipyApi {
  /// Creates the client.
  KlipyApi(this._http, this._creds);

  final UpstreamHttp _http;
  final KlipyCredentials _creds;

  /// Searches ([KlipyQuery.query] non-empty) or lists trending GIFs.
  Future<List<KlipyGif>> gifs(KlipyQuery query) async {
    final keys = _creds.appKey.values;
    if (keys.isEmpty) {
      throw const ConnectException(ConnectErrorCode.providerUnavailable);
    }
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final response = await sendUpstream(
        _http,
        UpstreamRequest(
          'GET',
          Uri.https(
            klipyApiHost,
            '/api/v1/$key/gifs/${query.query.isEmpty ? 'trending' : 'search'}',
            {
              if (query.query.isNotEmpty) 'q': query.query,
              'page': '${query.page}',
              'per_page': '${query.perPage}',
              if (query.locale.isNotEmpty) 'locale': query.locale,
              'format_filter': 'gif',
            },
          ),
          headers: const {'accept': 'application/json'},
        ),
      );
      if ((response.status == 401 || response.status == 403) &&
          i + 1 < keys.length) {
        continue; // Rotation in flight: try the previous key once.
      }
      final text = response.text;
      for (final k in keys) {
        if (text.contains(k)) {
          throw const ConnectException(ConnectErrorCode.providerUnavailable);
        }
      }
      if (!response.ok) {
        throw const ConnectException(ConnectErrorCode.providerUnavailable);
      }
      return normaliseKlipyResponse(response.jsonObject);
    }
    throw const ConnectException(ConnectErrorCode.providerUnavailable);
  }
}

Map<String, Object?>? _map(Object? value) =>
    value is Map<String, Object?> ? value : null;

/// Maps Klipy's `{data: {data: [...]}}` answer to [KlipyGif]s: the full GIF
/// from `file.hd.gif` (falling back to `sm.gif`, `sm.webp`), the preview
/// from `file.sm.gif` / `sm.webp`.
List<KlipyGif> normaliseKlipyResponse(Map<String, Object?>? json) {
  final items = _map(json?['data'])?['data'];
  if (items is! List) {
    return const [];
  }
  final out = <KlipyGif>[];
  for (final item in items) {
    final map = _map(item);
    final file = _map(map?['file']);
    if (map == null || file == null) {
      continue;
    }
    final hd = _map(file['hd']);
    final sm = _map(file['sm']);
    final gif = _map(hd?['gif']) ?? _map(sm?['gif']) ?? _map(sm?['webp']);
    final preview = _map(sm?['gif']) ?? _map(sm?['webp']) ?? gif;
    final id = map['id'];
    final title = map['title'];
    final candidate = KlipyGif.tryParse({
      'id': id is int ? '$id' : id,
      'title': title is String ? title : '',
      'width': intField(gif?['width']),
      'height': intField(gif?['height']),
      'preview_url': preview?['url'],
      'gif_url': gif?['url'],
    });
    if (candidate != null) {
      out.add(candidate);
    }
  }
  return out;
}
