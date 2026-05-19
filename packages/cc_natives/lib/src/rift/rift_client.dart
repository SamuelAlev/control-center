import 'dart:convert';
import 'dart:isolate';

import 'package:cc_natives/src/rift/rift_exception.dart';
import 'package:cc_natives/src/rift/rift_ffi_bindings.dart';

/// Typed wrapper over the bundled rift FFI library, speaking rift's JSON
/// protocol.
///
/// The native `rift_ffi_call` is SYNCHRONOUS and a `create` recursively clones
/// every inode in the tree (fast per-byte on APFS, but O(files)), so calls run
/// on a worker isolate via [Isolate.run] to keep the UI thread responsive.
/// Only JSON strings cross the isolate boundary; the worker reloads the dylib
/// from [dylibPaths] (FFI handles can't be sent between isolates).
///
/// Every command carries the registry [databasePath] so all of Control
/// Center's managed copies share one rift registry. Throws [RiftException] on
/// `{status:"error"}` responses.
class RiftClient {
  /// Creates a [RiftClient] that loads the native lib from [dylibPaths].
  RiftClient({required this.dylibPaths, required this.databasePath});

  /// Candidate absolute paths to the rift shared library, tried in order.
  final List<String> dylibPaths;

  /// Absolute path to the rift SQLite registry file.
  final String databasePath;

  bool? _available;

  /// Whether the native library loaded (probed once on the main isolate). When
  /// false, callers must fall back (to a plain `git worktree`).
  bool get isAvailable =>
      _available ??= RiftFfiBindings.tryLoad(explicitPaths: dylibPaths) != null;

  /// Registers [at] as a rift-managed source. Idempotent.
  Future<void> init({required String at}) async {
    await _send({'command': 'init', 'at': at});
  }

  /// Creates a copy-on-write copy of [from] under [into], returning the new
  /// workspace path. Always pass [copyAll] true for a complete, ready tree.
  Future<String> create({
    required String from,
    required String into,
    String? name,
    bool copyAll = true,
    bool hooks = false,
  }) async {
    final value = await _send({
      'command': 'create',
      'from': from,
      'into': into,
      'name': ?name,
      'copyAll': copyAll,
      'hooks': hooks,
    });
    if (value is! String || value.isEmpty) {
      throw const RiftException(
        code: 'protocol',
        message: 'create did not return a path',
      );
    }
    return value;
  }

  /// Moves the managed copy at [at] (and its descendants) into rift trash.
  Future<void> remove({required String at}) async {
    await _send({'command': 'remove', 'at': at});
  }

  /// Physically deletes trashed copies and prunes missing registry entries.
  Future<List<String>> gc() async => _asPaths(await _send({'command': 'gc'}));

  /// Lists the direct managed children created from [of].
  Future<List<String>> list({required String of}) async =>
      _asPaths(await _send({'command': 'list', 'of': of}));

  Future<Object?> _send(Map<String, Object?> request) async {
    if (!isAvailable) {
      throw const RiftException(
        code: 'unavailable',
        message: 'rift native library is not loaded',
      );
    }
    final payload = jsonEncode({...request, 'database': databasePath});
    final paths = dylibPaths;
    // Run the synchronous native call on a worker isolate so a large clone
    // never blocks the UI thread.
    final raw = await Isolate.run(() => _riftFfiCall(paths, payload));

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw RiftException(
        code: 'protocol',
        message: 'unexpected rift response: $raw',
      );
    }
    if (decoded['status'] == 'ok') {
      return decoded['value'];
    }
    final error = decoded['error'];
    if (error is Map) {
      throw RiftException(
        code: (error['code'] as String?) ?? 'unknown',
        message: (error['message'] as String?) ?? 'rift error',
        path: error['path'] as String?,
      );
    }
    throw RiftException(code: 'protocol', message: 'malformed rift error: $raw');
  }

  List<String> _asPaths(Object? value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}

/// Loads the dylib in the current (worker) isolate and performs one call.
/// Returns rift's raw JSON response, or a synthetic error envelope when the
/// library can't be loaded here.
String _riftFfiCall(List<String> paths, String requestJson) {
  final bindings = RiftFfiBindings.tryLoad(explicitPaths: paths);
  if (bindings == null) {
    return '{"status":"error","error":{"code":"unavailable",'
        '"message":"rift native library failed to load in worker isolate"}}';
  }
  return bindings.call(requestJson);
}
