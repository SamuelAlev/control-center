import 'package:cc_data/src/repositories/remote_voice_profile_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [VoiceProfileRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `voice_profile.*` ops + the
/// `voice_profile.watchForWorkspace` subscription, mapping the
/// [VoiceProfileDto] wire shape back to [VoiceProfile]. The host owns
/// persistence (including the centroid-blending math of [enroll]/[unenroll]);
/// this client never touches a database. Reads, the watch, the direct upsert,
/// enroll/unenroll, rename, and delete are all served.
class RpcVoiceProfileRepository implements VoiceProfileRepository {
  /// Creates an [RpcVoiceProfileRepository] over [client].
  RpcVoiceProfileRepository(RemoteRpcClient client)
    : _remote = RemoteVoiceProfileRepository(client);

  final RemoteVoiceProfileRepository _remote;

  /// Rebuilds a [VoiceProfile] from its wire DTO. A missing `createdAt` /
  /// `updatedAt` falls back to the epoch so the entity stays valid.
  static VoiceProfile _fromDto(VoiceProfileDto d) => VoiceProfile(
    id: d.id,
    workspaceId: d.workspaceId,
    displayName: d.displayName,
    embedding: d.embedding,
    sampleCount: d.sampleCount,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
    updatedAt: d.updatedAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.updatedAt!),
  );

  static VoiceProfileDto _toDto(VoiceProfile p) => VoiceProfileDto(
    id: p.id,
    workspaceId: p.workspaceId,
    displayName: p.displayName,
    embedding: p.embedding,
    sampleCount: p.sampleCount,
    createdAt: p.createdAt.toIso8601String(),
    updatedAt: p.updatedAt.toIso8601String(),
  );

  @override
  Stream<List<VoiceProfile>> watchByWorkspace(String workspaceId) =>
      _remote.watch().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<List<VoiceProfile>> getByWorkspace(String workspaceId) async {
    final dtos = await _remote.getByWorkspace();
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<VoiceProfile?> getByName(String workspaceId, String displayName) async {
    final dto = await _remote.getByName(displayName);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<void> upsert(VoiceProfile profile) => _remote.upsert(_toDto(profile));

  @override
  Future<void> enroll({
    required String workspaceId,
    required String displayName,
    required List<double> sampleEmbedding,
  }) => _remote.enroll(
    displayName: displayName,
    sampleEmbedding: sampleEmbedding,
  );

  @override
  Future<void> unenroll({
    required String workspaceId,
    required String displayName,
    required List<double> sampleEmbedding,
  }) => _remote.unenroll(
    displayName: displayName,
    sampleEmbedding: sampleEmbedding,
  );

  @override
  Future<void> rename({
    required String workspaceId,
    required String id,
    required String displayName,
  }) => _remote.rename(id: id, displayName: displayName);

  @override
  Future<void> delete(String workspaceId, String id) => _remote.delete(id);
}
