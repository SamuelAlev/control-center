import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads + resolves the runs parked on a credential, over the RPC client.
///
/// The server parks a dispatch whenever the credential it needs cannot serve it
/// — a Claude Code account with no plan headroom or no sign-in, a harness
/// provider with no key — and publishes it to every connected client over
/// `credential_gate.watchBlocked`. The run stays parked until the credential
/// starts working (the server re-probes on its own), until a client resolves it
/// here, or until the host's deadline passes, at which point the turn fails with
/// the message it would have failed with anyway.
///
/// The stream is SEEDED server-side, so a client that connects while a run is
/// already parked is told about it rather than waiting for the next change.
class RemoteCredentialGateRepository {
  /// Creates a [RemoteCredentialGateRepository] over [_client].
  RemoteCredentialGateRepository(this._client);

  final RemoteRpcClient _client;

  /// Live parked runs — a fresh snapshot on every change.
  ///
  /// Host-global by default, which is what the desktop's always-mounted gate
  /// overlay wants. Pass [spaceId] to have the SERVER narrow the stream to one
  /// thread.
  Stream<List<RunCredentialBlockDto>> watchBlocked({String? spaceId}) => _client
      .subscribe('credential_gate.watchBlocked', <String, dynamic>{
        'space_id': ?spaceId,
      })
      .map(_blocked);

  /// Re-probes [id]'s credential right now — "I have just fixed it".
  ///
  /// A probe that still finds the credential unusable leaves the run parked;
  /// this is not a question with a wrong answer, so there is nothing to undo.
  Future<bool> retry(String id) => _resolve(id, 'retry');

  /// Gives up on [id]: the run fails with the message it was parked on.
  Future<bool> cancel(String id) => _resolve(id, 'cancel');

  Future<bool> _resolve(String id, String action) async {
    final data = await _client.call('credential_gate.resolve', {
      'id': id,
      'action': action,
    });
    return data['ok'] == true;
  }

  static List<RunCredentialBlockDto> _blocked(Map<String, dynamic> data) =>
      ((data['blocked'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => RunCredentialBlockDto.fromJson(m.cast<String, dynamic>()))
          .toList();
}
