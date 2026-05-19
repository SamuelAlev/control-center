/// Pure-Dart app-server composition for Control Center.
///
/// The repo-RPC catalog (tickets / messaging / newsfeed), the WebSocket RPC
/// server (`LocalRpcServer`), live event forwarding, and the paired-device
/// secrets port. Depends only on cc_host + cc_persistence + cc_domain + cc_rpc
/// (no Flutter), so it links into the `dart build cli` headless server; the
/// desktop also uses it for its in-process server until Fork A spawns cc_server.
library;

export 'src/activity_log_persister.dart';
export 'src/backfill_embeddings_use_case.dart';
export 'src/cached_pr_review_repository.dart';
export 'src/cc_server_config.dart';
export 'src/cc_server_runtime.dart';
export 'src/dao_activity_log_reader.dart';
export 'src/dao_code_graph_repository.dart';
export 'src/dao_newsfeed_repository.dart';
export 'src/dao_pr_lifecycle_repository.dart';
export 'src/file_secrets_store.dart';
export 'src/google_calendar_server.dart';
export 'src/local_rpc_server.dart';
export 'src/pair_device.dart';
export 'src/paired_device_secrets_port.dart';
export 'src/pairing_qr.dart';
export 'src/remote_event_forwarder.dart';
export 'src/remote_rpc_catalog.dart';
export 'src/rpc_exception_mapper.dart';
export 'src/server_mcp_client_control.dart';
export 'src/server_mcp_control.dart';
export 'src/snapshot_aggregator.dart';
