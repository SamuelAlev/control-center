// The voice-model control surface the settings section reads.
//
// The desktop and web are both thin clients: neither hosts an on-device
// speech-to-text model — the connected `cc_server` runs ASR for meeting
// recording (`meeting.startRecording`/`ingestAudio`). Both drive the server's
// model over the `models.voice*` RPC ops, including the ASR model SELECTION
// (the catalog + `selectVoice`). When the connected server exposes no model
// control, the status provider resolves to `null` and the section renders an
// honest "managed on the server host" placeholder.
library;

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/infrastructure/model_status_stream.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RPC-backed [SelectableModelControl]: drives the SERVER's voice model over
/// the `models.voice*` ops, including the ASR model SELECTION (the catalog +
/// `selectVoice`). Each mutator returns the fresh snapshot the server reports,
/// the same shape `models.voiceStatus` returns.
class RpcVoiceModelControl implements SelectableModelControl {
  /// Creates a control over the given client.
  RpcVoiceModelControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<ModelStatusSnapshot> status() async {
    final data = await _client.call('models.voiceStatus', const {});
    return ModelStatusSnapshot.fromJson(data);
  }

  @override
  Stream<ModelStatusSnapshot> watch() => _client
      .subscribe('models.watchVoice', const {})
      .map(ModelStatusSnapshot.fromJson);

  @override
  Future<void> install() => _client.call('models.installVoice', const {});

  @override
  Future<void> cancel() => _client.call('models.cancelVoice', const {});

  @override
  Future<void> uninstall() => _client.call('models.uninstallVoice', const {});

  @override
  Future<ModelCatalog> catalog() async {
    final data = await _client.call('models.voiceCatalog', const {});
    return ModelCatalog.fromJson(data);
  }

  @override
  Future<ModelStatusSnapshot> select(String modelId) async {
    final data = await _client.call('models.selectVoice', {
      'model_id': modelId,
    });
    return ModelStatusSnapshot.fromJson(data);
  }
}

/// The voice-model control the settings section drives — the RPC-backed
/// control talking to the connected server.
final voiceModelControlProvider = Provider<ModelControl>(
  (ref) => RpcVoiceModelControl(ref.watch(rpcClientProvider)),
);

/// The connected server's voice-model catalog (the installable ASR models +
/// which one is active), or `null` when the server exposes no SELECTABLE voice
/// control (`models.voiceCatalog` absent → `opUnknown`). Drives the ASR model
/// picker, which hides itself for the null case.
final voiceModelCatalogProvider = FutureProvider<ModelCatalog?>((ref) async {
  final client = ref.watch(rpcClientProvider);
  try {
    final data = await client.call('models.voiceCatalog', const {});
    return ModelCatalog.fromJson(data);
  } on RemoteRpcException catch (e) {
    if (e.code == RpcErrorCodes.opUnknown) {
      return null;
    }
    rethrow;
  }
});

/// The current voice-model snapshot as a LIVE stream, or `null` when the
/// connected server exposes no model control (`models.voiceStatus` /
/// `models.watchVoice` absent → `opUnknown`). The section renders the
/// "managed on the server host" placeholder for the null case.
final voiceModelStatusSnapshotProvider = StreamProvider<ModelStatusSnapshot?>(
  (ref) => modelStatusStream(ref.watch(voiceModelControlProvider)),
);
