import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads the selectable font catalogue over the RPC client.
///
/// Mirrors the `fonts.list` op in the host catalog. Not workspace-scoped: a font
/// choice is a display preference and the catalogue is the same everywhere. The
/// host owns the upstream fetch, its disk cache and the font bytes themselves
/// (served over `/proxy/font`) — a client never dials a font CDN, because it
/// could not get a Skia-decodable format from one if it tried.
class RemoteFontsRepository {
  /// Creates a [RemoteFontsRepository] over [_client].
  RemoteFontsRepository(this._client);

  final RemoteRpcClient _client;

  /// Every selectable family, sorted by display name. Empty when the host has
  /// never reached the catalogue (offline first run) — never an error.
  Future<List<FontFamilyDto>> list() async {
    final data = await _client.call('fonts.list', const {});
    final fonts = data['fonts'];
    if (fonts is! List) {
      return const [];
    }
    return [
      for (final row in fonts)
        if (row is Map) FontFamilyDto.fromJson(row.cast<String, dynamic>()),
    ];
  }
}
