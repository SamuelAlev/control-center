import 'package:cc_domain/core/domain/entities/directory_listing.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [DirectoryBrowserPort] backed by the RPC client — the thin-client data path
/// for browsing the SERVER's filesystem when adding a repo.
///
/// The browser has no local filesystem, so the web add-repo form forwards every
/// navigation to the host's `fs.browseDirectory` op and renders the returned
/// [DirectoryListing]. Paths are the server's own absolute paths; the client
/// treats them as opaque tokens it hands straight back (to navigate deeper, or
/// to `repos.addFromPath`). Browsing is constrained to the host's configured
/// roots, enforced server-side. Throws [RemoteRpcException] with
/// `RpcErrorCodes.validation` when a path is outside those roots or unreadable.
class RpcDirectoryBrowserPort implements DirectoryBrowserPort {
  /// Creates an [RpcDirectoryBrowserPort] over [_client].
  RpcDirectoryBrowserPort(this._client);

  final RemoteRpcClient _client;

  @override
  Future<DirectoryListing> browse({String? path}) async {
    final data = await _client.call('fs.browseDirectory', {'path': ?path});
    return _listing(data);
  }

  DirectoryListing _listing(Map<String, dynamic> data) => DirectoryListing(
        path: data['path'] as String,
        parent: data['parent'] as String?,
        isGitRepo: data['is_git_repo'] as bool? ?? false,
        roots: ((data['roots'] as List?) ?? const [])
            .whereType<String>()
            .toList(),
        entries: ((data['entries'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => _entry(e.cast<String, dynamic>()))
            .toList(),
      );

  DirectoryEntry _entry(Map<String, dynamic> e) => DirectoryEntry(
        name: e['name'] as String,
        path: e['path'] as String,
        isGitRepo: e['is_git_repo'] as bool? ?? false,
      );
}
