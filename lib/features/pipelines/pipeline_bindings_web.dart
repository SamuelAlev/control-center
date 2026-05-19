// Web binding for the pipeline engine declared in `pipeline_providers.dart`.
//
// The pipeline EXECUTOR runs on the SERVER (it drives the dispatch stack:
// cc_natives indexer, agent dispatch, the messaging service — none of which
// exist on a web thin client). So on web `buildPipelineEngine` returns an
// `RpcPipelineEnginePort`: start / cancel / retry a run and kill a step all
// forward to the host's `pipeline.*` ops and execute server-side, with live
// run/step state streaming back over the existing `pipeline_run.watch*`
// subscriptions. Against a host that owns the engine (the desktop in-process
// host) this works end-to-end; against a HEADLESS server (which omits the
// `pipeline.*` ops) the actions fail loudly and the web client degrades to an
// honest "pipelines run on the server host" state.
library;

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web pipeline executor over RPC: drives the server's live `PipelineEngine`.
PipelineEnginePort buildPipelineEngine(Ref ref) =>
    RpcPipelineEnginePort(ref.watch(rpcClientProvider));
