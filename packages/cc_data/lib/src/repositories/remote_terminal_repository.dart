import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';

/// Drives a server-hosted interactive terminal (a PTY running a shell inside the
/// agent sandbox) over the RPC client.
///
/// Mirrors the `terminal.*` ops + the `terminal.output` subscription. The PTY
/// lives on the SERVER's machine; this is the thin-client handle the web /
/// remote terminal panel uses. Bytes travel base64-framed both ways: [write]
/// encodes outgoing bytes and [output] decodes incoming chunks. Carries no
/// `workspace_id` — the host binds the authoritative workspace per session and
/// validates session ownership server-side, so a client can never touch another
/// workspace's terminal.
///
/// When the connected server does NOT host these ops (a pure-Dart headless
/// server that links no PTY), [spawn] throws a [RemoteRpcException] with code
/// `RpcErrorCodes.opUnknown`; the panel catches it and renders an honest
/// "terminal runs on the server host" placeholder.
class RemoteTerminalRepository {
  /// Creates a [RemoteTerminalRepository] over [_client].
  RemoteTerminalRepository(this._client);

  final RemoteRpcClient _client;

  /// Spawns a sandboxed shell PTY on the server and returns its session id.
  /// [channelId] scopes the working dir to a conversation; [backend] pins the
  /// sandbox backend (a `SandboxBackend` name); [rows]/[cols] are the initial
  /// PTY size.
  Future<String> spawn({
    required int rows,
    required int cols,
    String? channelId,
    String? cwd,
    String? backend,
  }) async {
    final data = await _client.call('terminal.spawn', {
      'rows': rows,
      'cols': cols,
      'channel_id': ?channelId,
      'cwd': ?cwd,
      'backend': ?backend,
    });
    return data['session_id'] as String;
  }

  /// The session's live PTY output, decoded from the base64-framed snapshots
  /// (`{chunk: <base64>}`) the server pushes per PTY emission.
  Stream<List<int>> output(String sessionId) => _client
      .subscribe('terminal.output', {'session_id': sessionId})
      .map((data) {
        final chunk = data['chunk'] as String?;
        return chunk == null ? const <int>[] : base64Decode(chunk);
      });

  /// Writes [data] (raw bytes) to the session's PTY stdin (base64-framed).
  Future<void> write(String sessionId, List<int> data) =>
      _client.call('terminal.write', {
        'session_id': sessionId,
        'data': base64Encode(data),
      });

  /// Resizes the session's PTY to [rows]×[cols].
  Future<void> resize(String sessionId, int rows, int cols) =>
      _client.call('terminal.resize', {
        'session_id': sessionId,
        'rows': rows,
        'cols': cols,
      });

  /// Kills the session's shell and releases its sandbox resources.
  Future<void> kill(String sessionId) =>
      _client.call('terminal.kill', {'session_id': sessionId});
}
