/// Whether a workspace's database takes writes.
///
/// A file's integrity is checked when it first opens in a server process, so
/// a workspace nobody has touched since boot reads [ok] until it opens; a
/// write that reaches a damaged file before then is still refused by the
/// file itself.
enum WorkspaceStorageState {
  /// Reads and writes work.
  ok('ok'),

  /// The file failed its integrity check: it serves reads and refuses every
  /// write until it is restored from a snapshot.
  readOnly('read_only');

  const WorkspaceStorageState(this.wire);

  /// The value on the wire (`storage_state`).
  final String wire;
}

/// The `data.kind` (and, for agents, the leading word of the tool error)
/// refusing a write to a [WorkspaceStorageState.readOnly] workspace. Every
/// entry point that refuses such a write uses this one value, so a client
/// localizes one kind however the write arrived.
const workspaceReadOnlyKind = 'storage.read_only';
