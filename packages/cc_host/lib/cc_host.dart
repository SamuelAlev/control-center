/// Server-side RPC kernel for Control Center.
///
/// The reusable host machinery an app (desktop "be your own server") or a
/// headless `cc-server` embeds to serve first-party clients (desktop-remote,
/// web, the `cc_remote` PWA): one `RemoteRpcSession` per connection, the
/// `RepoOpDispatcher` (`repo/call`) + `WatchQueryRegistry`/`SubscriptionManager`
/// (`sub/*`), the `RemoteRateLimiter`, the `RemoteToolPolicy` allow-list, and
/// the `WsRemoteTransport` WSS server channel.
///
/// VM-only — it uses `dart:io`. The web-safe client half (the client, channel
/// abstraction, transports) is `cc_rpc`; the passive wire types are `cc_domain`.
///
/// Two seams keep this package free of the Flutter app: `CcHostLog` (install a
/// `CcHostLogSink` to route logs) and `RpcExceptionMapper` (the app maps its own
/// domain exceptions to `RpcErrorMapping`s the dispatcher returns).
library;

export 'src/confirmation/pending_confirmation_registry.dart';
export 'src/errors/rpc_error_mapping.dart';
export 'src/log/cc_host_log.dart';
export 'src/policy/remote_tool_policy.dart';
export 'src/policy/session_capability.dart';
export 'src/repo_rpc/repo_op.dart';
export 'src/repo_rpc/repo_op_dispatcher.dart';
export 'src/repo_rpc/subscription_manager.dart';
export 'src/repo_rpc/watch_query.dart';
export 'src/session/in_process_rpc_host.dart';
export 'src/session/remote_rate_limiter.dart';
export 'src/session/remote_rpc_session.dart';
export 'src/transport/ws_remote_transport.dart';
