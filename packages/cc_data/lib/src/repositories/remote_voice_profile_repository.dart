import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates voice profiles over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one.
/// Mirrors the `voice_profile.*` ops + the `voice_profile.watchForWorkspace`
/// subscription in the host catalog.
class RemoteVoiceProfileRepository {
  /// Creates a [RemoteVoiceProfileRepository] over [_client].
  RemoteVoiceProfileRepository(this._client);

  final RemoteRpcClient _client;

  /// All voice profiles in the bound workspace (ordered by name).
  Future<List<VoiceProfileDto>> getByWorkspace() async {
    final data = await _client.call('voice_profile.getByWorkspace', const {});
    return _profiles(data);
  }

  /// The profile named [displayName] in the bound workspace, or null.
  Future<VoiceProfileDto?> getByName(String displayName) async {
    final data = await _client.call('voice_profile.getByName', {
      'display_name': displayName,
    });
    final profile = data['profile'];
    return profile is Map
        ? VoiceProfileDto.fromJson(profile.cast<String, dynamic>())
        : null;
  }

  /// Inserts or updates [profile] (the host owns persistence).
  Future<void> upsert(VoiceProfileDto profile) =>
      _client.call('voice_profile.upsert', {'profile': profile.toJson()});

  /// Enrolls a [sampleEmbedding] for [displayName] in the bound workspace,
  /// blending it into the running centroid (or creating a new profile).
  Future<void> enroll({
    required String displayName,
    required List<double> sampleEmbedding,
  }) => _client.call('voice_profile.enroll', {
    'display_name': displayName,
    'sample_embedding': sampleEmbedding,
  });

  /// Removes a previously-enrolled [sampleEmbedding] for [displayName] in the
  /// bound workspace (the inverse of [enroll]).
  Future<void> unenroll({
    required String displayName,
    required List<double> sampleEmbedding,
  }) => _client.call('voice_profile.unenroll', {
    'display_name': displayName,
    'sample_embedding': sampleEmbedding,
  });

  /// Renames the profile [id] in the bound workspace.
  Future<void> rename({
    required String id,
    required String displayName,
  }) => _client.call('voice_profile.rename', {
    'id': id,
    'display_name': displayName,
  });

  /// Deletes the profile [id] in the bound workspace.
  Future<void> delete(String id) =>
      _client.call('voice_profile.delete', {'id': id});

  /// Live voice profiles in the bound workspace — a fresh snapshot on every
  /// change.
  Stream<List<VoiceProfileDto>> watch() =>
      _client.subscribe('voice_profile.watchForWorkspace', const {}).map(
        _profiles,
      );

  List<VoiceProfileDto> _profiles(Map<String, dynamic> data) =>
      ((data['profiles'] as List?) ?? const [])
          .whereType<Map>()
          .map((p) => VoiceProfileDto.fromJson(p.cast<String, dynamic>()))
          .toList();
}
