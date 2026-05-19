// Web/thin-client binding for the embedding-model control surface.
//
// The web client hosts no on-device model — it asks the connected SERVER (which
// owns the model) to report status / install / uninstall over the
// `models.embedding*` RPC ops. On-device ML inference physically cannot run in a
// browser, so when the connected server doesn't expose these ops (a headless
// host that hosts no models), the status provider resolves to `null` and the
// section degrades to "managed on the server host".
library;

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RPC-backed [ModelControl]: drives the SERVER's embedding model over the
/// `models.embedding*` ops. Each mutator returns the fresh snapshot the server
/// reports, the same shape `models.embeddingStatus` returns.
class RpcEmbeddingModelControl implements ModelControl {
  /// Creates a control over the given [client].
  RpcEmbeddingModelControl(this._client);

  final RemoteRpcClient _client;

  @override
  Future<ModelStatusSnapshot> status() async {
    final data = await _client.call('models.embeddingStatus', const {});
    return ModelStatusSnapshot.fromJson(data);
  }

  @override
  Stream<ModelStatusSnapshot> watch() => _client
      .subscribe('models.watchEmbedding', const {})
      .map(ModelStatusSnapshot.fromJson);

  @override
  Future<void> install() =>
      _client.call('models.installEmbedding', const {});

  @override
  Future<void> cancel() => _client.call('models.cancelEmbedding', const {});

  @override
  Future<void> uninstall() =>
      _client.call('models.uninstallEmbedding', const {});
}

/// The embedding-model control the settings section drives. On web this is the
/// RPC-backed control talking to the connected server.
final embeddingModelControlProvider = Provider<ModelControl>(
  (ref) => RpcEmbeddingModelControl(ref.watch(rpcClientProvider)),
);

/// The current embedding-model snapshot as a LIVE stream, or `null` when the
/// connected server exposes no model control (`models.watchEmbedding` absent →
/// `opUnknown`). The section renders the "managed on the server host"
/// placeholder for the null case.
///
/// Subscribing to `models.watchEmbedding` (rather than a one-shot `status()`)
/// is what animates the progress bar while the SERVER downloads the model: the
/// server streams a fresh snapshot on every progress tick.
final embeddingModelStatusSnapshotProvider =
    StreamProvider<ModelStatusSnapshot?>((ref) async* {
      final control = ref.watch(embeddingModelControlProvider);
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
