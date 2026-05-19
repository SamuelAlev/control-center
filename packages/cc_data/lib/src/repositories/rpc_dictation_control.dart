import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/dictation/domain/dictation_control_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [DictationControlPort] backed by the RPC client — the thin-client
/// dictation path (PRD 25 §2). Maps each call onto the host's `dictation.start`
/// / `dictation.ingestAudio` / `dictation.stop` ops and the
/// `dictation.watchPartials` subscription.
///
/// It is the composer sibling of `RpcMeetingRecordingControl`: PCM16 frames
/// travel base64-encoded in the JSON-RPC envelope (the transport has no
/// raw-binary frame), the host runs the rolling-window transcriber and it
/// pushes each finalized window back over [watchPartials]. The owning workspace
/// is injected by the client transport per session — never a parameter — so no
/// `workspace_id` appears here.
class RpcDictationControl implements DictationControlPort {
  /// Creates an [RpcDictationControl] over the given client.
  RpcDictationControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<String> start() async {
    final res = await _client.call('dictation.start', const {});
    return res['dictation_id'] as String;
  }

  @override
  Future<void> ingestAudio({
    required String dictationId,
    required int seq,
    required Uint8List pcm,
  }) async {
    // The host op takes only `{dictation_id, pcm}`; [seq] is a client-side gap
    // diagnostic the server does not read, so it is not sent.
    await _client.call('dictation.ingestAudio', {
      'dictation_id': dictationId,
      'pcm': base64Encode(pcm),
    });
  }

  @override
  Future<void> stop({required String dictationId}) async {
    await _client.call('dictation.stop', {'dictation_id': dictationId});
  }

  @override
  Stream<DictationPartial> watchPartials(String dictationId) => _client
      .subscribe('dictation.watchPartials', {'dictation_id': dictationId})
      .map(
        (m) => DictationPartial(
          text: m['text'] as String? ?? '',
          isFinal: m['is_final'] as bool? ?? false,
        ),
      );
}
