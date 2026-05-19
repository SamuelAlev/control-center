/// Error surfaced by the bundled `rift` FFI library (`{status:"error",error:{…}}`).
///
/// The `code` strings come from `crates/ffi/src/lib.rs` in the rift project and
/// are the contract callers branch on (e.g. [isCowUnavailable] decides whether
/// to fall back to a plain `git worktree`).
class RiftException implements Exception {
  /// Creates a [RiftException].
  const RiftException({required this.code, required this.message, this.path});

  /// Stable error identifier (e.g. `cow_unavailable`, `unsafe_git`).
  final String code;

  /// Human-readable message from rift (safe to surface to the agent/user).
  final String message;

  /// Optional path the error refers to.
  final String? path;

  /// Copy-on-write is not available on this filesystem (non-APFS / non-reflink,
  /// or source and destination on different volumes). Signal to fall back to a
  /// plain `git worktree`.
  bool get isCowUnavailable => code == 'cow_unavailable';

  /// The source repo is mid-operation (merge/rebase/cherry-pick/bisect) or has a
  /// stale lock / inconsistent index, or is itself a linked worktree. Do NOT
  /// fall back to `git worktree` (it would fail too) — surface the message.
  bool get isUnsafeGit => code == 'unsafe_git';

  /// The source was never `rift init`-ed. The adapter runs `init` then retries.
  bool get isInitRequired =>
      code == 'workspace_not_initialized' ||
      code == 'initialization_required' ||
      code == 'not_managed' ||
      code == 'missing_rift';

  /// The managed copy is already gone from disk / registry. GC can treat this as
  /// success and prune via `gc`.
  bool get isMissing =>
      code == 'missing_marker' ||
      code == 'missing_rift' ||
      code == 'not_managed' ||
      code == 'unknown_marker';

  @override
  String toString() =>
      'RiftException($code): $message${path != null ? ' [$path]' : ''}';
}

/// Thrown when `rift_ffi_call` returns a null pointer (should not happen).
class RiftFfiNullResponse implements Exception {
  /// Creates a [RiftFfiNullResponse].
  const RiftFfiNullResponse();

  @override
  String toString() => 'rift_ffi_call returned a null response pointer';
}
