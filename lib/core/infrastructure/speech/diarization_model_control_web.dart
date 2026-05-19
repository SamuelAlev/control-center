// Web/thin-client binding for the diarization-model control surface.
//
// The web client hosts no on-device model — it asks the connected SERVER (which
// owns the model) to report status / install / uninstall over the
// `models.diarization*` RPC ops. On-device ML inference physically cannot run in
// a browser, so when the connected server doesn't expose these ops (a headless
// host that hosts no models), the status provider resolves to `null` and the
// section degrades to "managed on the server host".
library;

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RPC-backed [ModelControl]: drives the SERVER's diarization model over the
/// `models.diarization*` ops. Each mutator returns the fresh snapshot the server
/// reports, the same shape `models.diarizationStatus` returns.
class RpcDiarizationModelControl implements ModelControl {
  /// Creates a control over the given [client].
  RpcDiarizationModelControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<ModelStatusSnapshot> status() async {
    final data = await _client.call('models.diarizationStatus', const {});
    return ModelStatusSnapshot.fromJson(data);
  }

  @override
  Stream<ModelStatusSnapshot> watch() => _client
      .subscribe('models.watchDiarization', const {})
      .map(ModelStatusSnapshot.fromJson);

  @override
  Future<void> install() =>
      _client.call('models.installDiarization', const {});

  @override
  Future<void> cancel() => _client.call('models.cancelDiarization', const {});

  @override
  Future<void> uninstall() =>
      _client.call('models.uninstallDiarization', const {});
}

/// The diarization-model control the settings section drives. On web this is the
/// RPC-backed control talking to the connected server.
final diarizationModelControlProvider = Provider<ModelControl>(
  (ref) => RpcDiarizationModelControl(ref.watch(rpcClientProvider)),
);

/// The current diarization-model snapshot as a LIVE stream, or `null` when the
/// connected server exposes no model control (`models.watchDiarization` absent →
/// `opUnknown`). The section renders the "managed on the server host"
/// placeholder for the null case.
///
/// Subscribing to `models.watchDiarization` (rather than a one-shot `status()`)
/// is what animates the progress bar while the SERVER downloads + unpacks the
/// models: the server streams a fresh snapshot on every progress tick.
final diarizationModelStatusSnapshotProvider =
    StreamProvider<ModelStatusSnapshot?>((ref) async* {
      final control = ref.watch(diarizationModelControlProvider);
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
