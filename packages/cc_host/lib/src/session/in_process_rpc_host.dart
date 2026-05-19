import 'dart:async';

import 'package:cc_host/src/policy/session_capability.dart';
import 'package:cc_host/src/repo_rpc/repo_op_dispatcher.dart';
import 'package:cc_host/src/repo_rpc/watch_query.dart';
import 'package:cc_host/src/session/remote_rpc_session.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An in-process, single-session RPC host — the "be your own server" loopback.
///
/// This is the reusable composition the desktop embeds to **self-serve its own
/// data over RPC** without a socket: it wires a [RemoteRpcSession] (the exact
/// same server-side machinery the WSS / WebRTC transports use) onto one end of
/// an [InProcessRpcChannel.pair], starts it, and exposes the other end as a
/// ready [RemoteRpcClient]. No serialization round-trip over the network, no
/// authentication handshake (the peer is the app itself, in the same process),
/// no event forwarder — just the repo-RPC + subscription surface.
///
/// The server is stateless: it holds no workspace. The client carries the
/// desktop's ACTIVE workspace into every request as `workspace_id` — seed
/// [InProcessRpcHost.new]'s `initialWorkspaceId` from it and call
/// [rebindWorkspace] whenever the active workspace changes so scoped
/// reads/writes resolve to the workspace the user is looking at.
///
/// VM-only (it lives in `cc_host`, which is VM-only), but Flutter-free — the
/// embedding app owns the Riverpod/lifecycle glue.
class InProcessRpcHost {
  InProcessRpcHost._({
    required this.client,
    required RemoteRpcSession session,
    required InProcessRpcChannel serverChannel,
    required InProcessRpcChannel clientChannel,
  }) : _session = session,
       _serverChannel = serverChannel,
       _clientChannel = clientChannel;

  /// Builds a started in-process host.
  ///
  /// Mirrors `LocalRpcServer._onSocket`: wire a [RemoteRpcSession] over the
  /// server end of a fresh channel pair, start it, then start a
  /// [RemoteRpcClient] (seeded with [initialWorkspaceId] as its
  /// `activeWorkspaceId`) over the client end. The returned host's [client] is
  /// ready to `call` / `subscribe` immediately (the in-process channel opens
  /// synchronously for sends).
  ///
  /// [dispatcher] is the shared tool dispatcher (`initialize`, `tools/*`);
  /// [repoOps] / [watchQueries] are the typed repo-RPC + subscription surface the
  /// session serves; [workspaceResolver] backs `session/list_workspaces`. The
  /// [deviceId] tags the session for auditing (defaults to `in-process`).
  factory InProcessRpcHost({
    required RpcDispatcher dispatcher,
    required RemoteWorkspaceResolver workspaceResolver,
    RepoOpDispatcher? repoOps,
    WatchQueryRegistry? watchQueries,
    String? initialWorkspaceId,
    String deviceId = 'in-process',
  }) {
    final (serverChannel, clientChannel) = InProcessRpcChannel.pair();
    final session = RemoteRpcSession(
      deviceId: deviceId,
      channel: serverChannel,
      dispatcher: dispatcher,
      workspaceResolver: workspaceResolver,
      // The in-process host IS the first-party desktop app talking to itself,
      // so it carries full privilege (it may manage pairings).
      capability: SessionCapability.fullClient,
      repoOps: repoOps,
      watchQueries: watchQueries,
    );
    // Start the server session BEFORE the client so the first client frame is
    // already being listened for (the in-process channel is broadcast — a frame
    // sent with no listener is dropped).
    unawaited(session.start());
    // The server is stateless; the client carries its active workspace_id into
    // every request. Seed it with the desktop's current workspace.
    final client = RemoteRpcClient(clientChannel)
      ..activeWorkspaceId = initialWorkspaceId
      ..start();
    return InProcessRpcHost._(
      client: client,
      session: session,
      serverChannel: serverChannel,
      clientChannel: clientChannel,
    );
  }

  /// The client end — what the embedding app talks to (`call` / `subscribe`).
  /// Its `activeWorkspaceId` is the per-request workspace; keep it pointed at
  /// the desktop's active workspace via [rebindWorkspace].
  final RemoteRpcClient client;

  final RemoteRpcSession _session;
  final InProcessRpcChannel _serverChannel;
  final InProcessRpcChannel _clientChannel;

  /// Points the client at [workspaceId] so subsequent stateless requests carry
  /// it as their `workspace_id`. Call when the desktop's active workspace
  /// changes. The server holds no workspace, so this is a local client update,
  /// not a round-trip.
  void rebindWorkspace(String? workspaceId) =>
      client.activeWorkspaceId = workspaceId;

  /// Tears down the host: closes the client, stops the session, and closes both
  /// channel ends. Idempotent-friendly (the underlying closes are idempotent).
  Future<void> dispose() async {
    await client.close();
    await _session.stop();
    await _clientChannel.close();
    await _serverChannel.close();
  }
}
