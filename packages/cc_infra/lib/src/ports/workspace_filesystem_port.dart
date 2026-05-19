// Re-export shim. The `WorkspaceFilesystemPort` interface moved to the
// pure-Dart `cc_domain` contract layer so the web-safe RPC adapter
// (`RpcWorkspaceFilesystemPort` in `cc_data`) can implement it without a
// package-graph back-edge onto `cc_infra` (which the `package_purity_test`
// rail forbids — `cc_data` is a closed `cc_domain + cc_rpc` allowlist).
//
// This shim keeps every existing importer of
// `package:cc_infra/src/ports/workspace_filesystem_port.dart` (cc_infra's own
// services, the `cc_mcp` tools, and the Flutter app) working unchanged.
export 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
