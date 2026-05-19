/// Pure-Dart shared contracts for Control Center.
///
/// Exposes the JSON-RPC 2.0 wire types (`JsonRpcRequest`, `JsonRpcResponse`,
/// `JsonRpcError`, `JsonRpcNotification`) and the wire DTOs the RPC tools
/// emit. Importable by the desktop app (native) and the `cc_remote` PWA
/// (Flutter web) alike — no platform dependencies.
library;

export 'core/domain/ports/confirmation_port.dart';
export 'core/domain/ports/run_credential_gate_port.dart';
export 'core/domain/services/redaction/redactor.dart';
export 'core/domain/services/redaction/secret_scanner.dart';
export 'core/domain/value_objects/connection_descriptor.dart';
export 'core/domain/value_objects/file_search_hit.dart';
export 'src/build_info.dart';
export 'src/dtos/dtos.dart';
export 'src/errors/app_exceptions.dart';
export 'src/jsonrpc/jsonrpc.dart';
export 'src/rpc/action_determinism.dart';
export 'src/rpc/bulk_action_runner.dart';
export 'src/rpc/protocol.dart';
