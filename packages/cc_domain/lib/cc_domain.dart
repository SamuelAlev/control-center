/// Pure-Dart shared contracts for Control Center.
///
/// Exposes the JSON-RPC 2.0 wire types (`JsonRpcRequest`, `JsonRpcResponse`,
/// `JsonRpcError`, `JsonRpcNotification`) and the wire DTOs the RPC tools
/// emit. Importable by the desktop app (native) and the `cc_remote` PWA
/// (Flutter web) alike — no platform dependencies.
library;

export 'core/domain/ports/confirmation_port.dart';
export 'core/domain/value_objects/file_search_hit.dart';
export 'src/dtos/dtos.dart';
export 'src/errors/app_exceptions.dart';
export 'src/jsonrpc/jsonrpc.dart';
export 'src/rpc/protocol.dart';
