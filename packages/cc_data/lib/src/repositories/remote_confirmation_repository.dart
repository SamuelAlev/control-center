import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads + resolves pending agent-action confirmations over the RPC client.
///
/// Backs the `cc_remote` phone's approve/decline surface. `watchPending` is the
/// live snapshot stream of destructive actions awaiting a human decision
/// (`confirmation.watchPending`, host-global); `respond` resolves one
/// (`confirmation.respond`). The agent run blocks server-side until a response
/// arrives or the host's registry times out (→ deny).
class RemoteConfirmationRepository {
  /// Creates a [RemoteConfirmationRepository] over [_client].
  RemoteConfirmationRepository(this._client);

  final RemoteRpcClient _client;

  /// Live pending approvals — a fresh snapshot on every change.
  ///
  /// Host-global by default (the desktop's approval overlay wants every
  /// space). Pass [spaceId] to have the SERVER narrow the stream: a
  /// surface that renders one thread should not receive — and a phone should
  /// not be sent — the command text of approvals from every other workspace
  /// it happens to be a member of.
  Stream<List<ConfirmationRequestDto>> watchPending({String? spaceId}) =>
      _client
          .subscribe('confirmation.watchPending', <String, dynamic>{
            'space_id': ?spaceId,
          })
          .map(_pending);

  /// Resolves [id] with [approved]. Returns true if [id] was still pending.
  ///
  /// [rememberForSeconds] turns an approval into a STANDING one: the server
  /// writes a narrow, argument-scoped, expiring policy rule so the same action
  /// stops asking for that window. It is bounded server-side (scope by the
  /// responder's role, duration by a hard ceiling) — a click cannot become
  /// permanent policy, which is an admin-only act in the guardrail editor.
  Future<bool> respond(
    String id, {
    required bool approved,
    int? rememberForSeconds,
    String rememberScope = 'space',
  }) async {
    final data = await _client.call('confirmation.respond', <String, dynamic>{
      'id': id,
      'approved': approved,
      if (rememberForSeconds != null)
        'remember': <String, dynamic>{
          'scope': rememberScope,
          'ttl_seconds': rememberForSeconds,
        },
    });
    return data['ok'] == true;
  }

  static List<ConfirmationRequestDto> _pending(Map<String, dynamic> data) =>
      ((data['pending'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (m) => ConfirmationRequestDto.fromJson(m.cast<String, dynamic>()),
          )
          .toList();
}
