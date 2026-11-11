import 'package:cc_domain/core/domain/repositories/commit_signing_key_repository.dart';
import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [CommitSigningKeyRepository] over the `credentials.commitSigningKey`,
/// `credentials.createCommitSigningKey` and
/// `credentials.deleteCommitSigningKey` ops.
class RpcCommitSigningKeyRepository implements CommitSigningKeyRepository {
  /// Creates an [RpcCommitSigningKeyRepository] over [_client].
  RpcCommitSigningKeyRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<CommitSigningKey?> get() async {
    final data = await _client.call('credentials.commitSigningKey', const {});
    return CommitSigningKey.tryParse(data['key']);
  }

  @override
  Future<CommitSigningKey> create() async {
    final data = await _client.call(
      'credentials.createCommitSigningKey',
      const {},
    );
    final key = CommitSigningKey.tryParse(data['key']);
    if (key == null) {
      throw const FormatException(
        'credentials.createCommitSigningKey answered without a key',
      );
    }
    return key;
  }

  @override
  Future<bool> delete() async {
    final data = await _client.call(
      'credentials.deleteCommitSigningKey',
      const {},
    );
    return data['deleted'] == true;
  }
}
