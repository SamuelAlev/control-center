import 'package:cc_data/src/repositories/remote_fonts_repository.dart';
import 'package:cc_domain/features/fonts/fonts.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [FontCatalogRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `fonts.list` op, mapping the
/// `FontFamilyDto` wire shape back to [FontFamilyInfo]. An unreachable host is
/// an empty catalogue rather than an error: the picker still offers the bundled
/// and system fonts, which need no network at all.
class RpcFontCatalogRepository implements FontCatalogRepository {
  /// Creates an [RpcFontCatalogRepository] over [client].
  RpcFontCatalogRepository(RemoteRpcClient client)
    : _remote = RemoteFontsRepository(client);

  final RemoteFontsRepository _remote;

  @override
  Future<List<FontFamilyInfo>> catalog() async {
    try {
      final dtos = await _remote.list();
      return [for (final dto in dtos) dto.toEntity()];
    } catch (_) {
      return const [];
    }
  }
}
