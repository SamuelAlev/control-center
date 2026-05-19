// The diarization-model control surface the settings section reads.
//
// The desktop and web are both thin clients: neither hosts an on-device
// diarization model — the connected `cc_server` owns the models and runs
// diarization as part of the `meeting_summary` pipeline. Both drive the
// server's model over the `models.diarization*` RPC ops. When the connected
// server exposes no model control, the status provider resolves to `null` and
// the section renders an honest "managed on the server host" placeholder.
library;

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RPC-backed [ModelControl]: drives the SERVER's diarization model over the
/// `models.diarization*` ops. Each mutator returns the fresh snapshot the
/// server reports, the same shape `models.diarizationStatus` returns.
class RpcDiarizationModelControl implements ModelControl {
  /// Creates a control over the given client.
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
  Future<void> install() => _client.call('models.installDiarization', const {});

  @override
  Future<void> cancel() => _client.call('models.cancelDiarization', const {});

  @override
  Future<void> uninstall() =>
      _client.call('models.uninstallDiarization', const {});
}

/// The diarization-model control the settings section drives — the RPC-backed
/// control talking to the connected server.
final diarizationModelControlProvider = Provider<ModelControl>(
  (ref) => RpcDiarizationModelControl(ref.watch(rpcClientProvider)),
);

/// The current diarization-model snapshot as a LIVE stream, or `null` when the
/// connected server exposes no model control (`models.watchDiarization` absent
/// → `opUnknown`). The section renders the "managed on the server host"
/// placeholder for the null case.
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
