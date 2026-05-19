// The embedding-model control surface the settings section reads.
//
// The desktop and web are both thin clients: neither hosts an on-device
// embedding model, so both drive the connected `cc_server`'s model over the
// `models.embedding*` RPC ops. When the connected server exposes no model
// control, the status provider resolves to `null` and the section renders an
// honest "managed on the server host" placeholder.
library;

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/infrastructure/model_status_stream.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// RPC-backed [ModelControl]: drives the SERVER's embedding model over the
/// `models.embedding*` ops. Each mutator returns the fresh snapshot the server
/// reports, the same shape `models.embeddingStatus` returns.
class RpcEmbeddingModelControl implements ModelControl {
  /// Creates a control over the given client.
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
  Future<void> install() => _client.call('models.installEmbedding', const {});

  @override
  Future<void> cancel() => _client.call('models.cancelEmbedding', const {});

  @override
  Future<void> uninstall() =>
      _client.call('models.uninstallEmbedding', const {});
}

/// The embedding-model control the settings section drives — the RPC-backed
/// control talking to the connected server.
final embeddingModelControlProvider = Provider<ModelControl>(
  (ref) => RpcEmbeddingModelControl(ref.watch(rpcClientProvider)),
);

/// The current embedding-model snapshot as a LIVE stream, or `null` when the
/// connected server exposes no model control (`models.embeddingStatus` /
/// `models.watchEmbedding` absent → `opUnknown`). The section renders the
/// "managed on the server host" placeholder for the null case.
final embeddingModelStatusSnapshotProvider =
    StreamProvider<ModelStatusSnapshot?>(
      (ref) => modelStatusStream(ref.watch(embeddingModelControlProvider)),
    );
