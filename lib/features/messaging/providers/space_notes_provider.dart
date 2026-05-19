import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The shared per-space handoff doc (PRD 16 §11): both humans and agents
/// read/write it, so a handoff carries state instead of re-explaining.
/// Authoritative last-write-wins — no CRDT (see the PRD's design decision).
class SpaceNote {
  /// Creates a [SpaceNote].
  const SpaceNote({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.content,
    required this.updatedBy,
    required this.updatedAt,
    required this.version,
  });

  /// Parses a `notes.get`/`notes.update`/`notes.watchForSpace` `note` map.
  factory SpaceNote.fromWire(Map<String, dynamic> wire) => SpaceNote(
    id: wire['id'] as String? ?? '',
    workspaceId: wire['workspace_id'] as String? ?? '',
    spaceId: wire['space_id'] as String? ?? '',
    content: wire['content'] as String? ?? '',
    updatedBy: wire['updated_by'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(wire['updated_at'] as String? ?? '') ??
        DateTime.now(),
    version: (wire['version'] as num?)?.toInt() ?? 0,
  );

  /// The note row id.
  final String id;

  /// The owning workspace.
  final String workspaceId;

  /// The space this note belongs to.
  final String spaceId;

  /// The note's markdown content.
  final String content;

  /// The principal (user or agent) id that last wrote it.
  final String updatedBy;

  /// When it was last written.
  final DateTime updatedAt;

  /// LWW version — bumped by the server on every write.
  final int version;
}

/// Live per-space note, or null when the space has never had one written.
final spaceNoteProvider = StreamProvider.autoDispose.family<SpaceNote?, String>(
  (ref, spaceId) {
    final client = ref.watch(rpcClientProvider);
    return client.subscribe('notes.watchForSpace', {'space_id': spaceId}).map((
      data,
    ) {
      final raw = data['note'];
      if (raw is! Map) {
        return null;
      }
      return SpaceNote.fromWire(raw.cast<String, dynamic>());
    });
  },
);

/// Writes [content] as the current note for [spaceId] via `notes.update`
/// (last-write-wins — the server stamps `updated_by`/`updated_at`/`version`).
Future<void> updateSpaceNote(
  RemoteRpcClient rpcClient, {
  required String spaceId,
  required String content,
}) {
  return rpcClient.call('notes.update', {
    'space_id': spaceId,
    'content': content,
  });
}
