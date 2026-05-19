// Desktop (thin-client) binding for the pipeline engine declared in
// `pipeline_providers.dart`.
//
// The desktop opens no local database — pipeline execution (run-state
// persistence, template loading, the dispatch stack) runs inside the connected
// `cc_server`. So the UI drives it over RPC via `RpcPipelineEnginePort`, exactly
// like the web client.
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pipeline executor over RPC.
PipelineEnginePort buildPipelineEngine(Ref ref) =>
    RpcPipelineEnginePort(ref.watch(rpcClientProvider));
