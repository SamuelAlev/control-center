import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_server_core/src/cc_server_config.dart';

/// The startup line that states how far this server can be reached and who
/// operates it, so an operator sees it without reading the configuration.
///
/// - `bind`: `loopback` (this machine only) or `network` (every interface).
/// - `tls`: `on` when the server terminates TLS itself; on a network bind
///   without it the operator chose `--insecure` and a TLS proxy must front it.
/// - `relay` / `tunnel`: the other ways a paired device reaches it.
/// - `owner`: whether a server owner is recorded, and who.
/// - `sandbox`: `native` (agents run in the OS sandbox), `off` (the owner
///   turned it off, so members' agents run unconfined on this host) or
///   `unavailable` (no backend, so only the owner's runs start).
String describeServerExposure(
  CcServerConfig config, {
  required String? ownerUserId,
  required HostExecutionPosture hostExecution,
}) {
  final bind = config.bindAny ? 'network' : 'loopback';
  final tls = config.tlsConfigured
      ? 'on'
      : config.bindAny
      ? 'off (plaintext; a TLS proxy must front it)'
      : 'off';
  final relay = config.signalingUrl.isEmpty ? 'off' : config.signalingUrl;
  final owner = ownerUserId == null || ownerUserId.isEmpty
      ? 'none'
      : 'recorded ($ownerUserId)';
  final sandbox = switch (hostExecution) {
    HostExecutionPosture.sandboxed => hostExecution.wire,
    HostExecutionPosture.offByOwner =>
      "${hostExecution.wire} (members' agents run unconfined on this host)",
    HostExecutionPosture.unavailable =>
      "${hostExecution.wire} (only the owner's agent runs start)",
  };
  return 'cc_server exposure: bind=$bind (${config.bindHost}) tls=$tls '
      'relay=$relay tunnel=${config.tunnelProvider} owner=$owner '
      'sandbox=$sandbox';
}
