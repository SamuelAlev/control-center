import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';

/// Each person's editor layouts, per workspace.
///
/// A layout is the caller's own arrangement and roams with them across
/// devices. It is state: nothing prunes it, and a space's layouts go with the
/// space.
abstract interface class EditorLayoutRepository {
  /// [userId]'s stored layout of [target] on [surface], or null.
  Future<String?> read(
    String workspaceId, {
    required String userId,
    required EditorLayoutSurface surface,
    required String target,
  });

  /// Stores [layout] (the client's encoded JSON) as [userId]'s layout of
  /// [target] on [surface].
  Future<void> write(
    String workspaceId, {
    required String userId,
    required EditorLayoutSurface surface,
    required String target,
    required String layout,
  });
}
