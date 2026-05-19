// Web/thin-client binding for the voice-model control surface.
//
// The web client hosts no on-device model — it asks the connected SERVER (which
// owns the model) to report status / install / uninstall over the
// `models.voice*` RPC ops. On-device ML inference physically cannot run in a
// browser, so when the connected server doesn't expose these ops (a headless
// host that hosts no models), the status provider resolves to `null` and the
// section degrades to "managed on the server host".
library;

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RPC-backed [SelectableModelControl]: drives the SERVER's voice model over
/// the `models.voice*` ops, including the ASR model SELECTION (the catalog +
/// `selectVoice`) that the desktop drives in-process. Each mutator returns the
/// fresh snapshot the server reports, the same shape `models.voiceStatus`
/// returns.
class RpcVoiceModelControl implements SelectableModelControl {
  /// Creates a control over the given [client].
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
    final data =
        await _client.call('models.selectVoice', {'model_id': modelId});
    return ModelStatusSnapshot.fromJson(data);
  }
}

/// The voice-model control the settings section drives. On web this is the
/// RPC-backed control talking to the connected server.
final voiceModelControlProvider = Provider<ModelControl>(
  (ref) => RpcVoiceModelControl(ref.watch(rpcClientProvider)),
);

/// The connected server's voice-model catalog (the installable ASR models +
/// which one is active), or `null` when the server exposes no SELECTABLE voice
/// control (`models.voiceCatalog` absent → `opUnknown`). Drives the web ASR
/// model picker, which hides itself for the null case (an older/headless server
/// that hosts a fixed voice model with no selection surface).
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
/// connected server exposes no model control (`models.watchVoice` absent →
/// `opUnknown`). The section renders the "managed on the server host"
/// placeholder for the null case.
///
/// Subscribing to `models.watchVoice` (rather than a one-shot `status()`) is
/// what animates the progress bar while the SERVER downloads + unpacks the
/// model: the server streams a fresh snapshot on every progress tick.
final voiceModelStatusSnapshotProvider =
    StreamProvider<ModelStatusSnapshot?>((ref) async* {
      final control = ref.watch(voiceModelControlProvider);
      try {
        yield* control.watch();
      } on RemoteRpcException catch (e) {
        if (e.code == RpcErrorCodes.opUnknown) {
          yield null;
          return;
        }
        rethrow;
      }
    });
