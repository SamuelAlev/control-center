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
  /// [spaceId] scopes the working dir to a conversation; [backend] pins the
  /// sandbox backend (a `SandboxBackend` name); [rows]/[cols] are the initial
  /// PTY size.
  Future<String> spawn({
    required int rows,
    required int cols,
    String? spaceId,
    String? cwd,
    String? backend,
  }) async => (await spawnSession(
    rows: rows,
    cols: cols,
    spaceId: spaceId,
    cwd: cwd,
    backend: backend,
  )).sessionId;

  /// Spawns a shell and reports which backend it ACTUALLY runs under.
  ///
  /// The distinction matters for the badge: an unspecified default can step
  /// down when a host has no rig service, and a terminal labelled "enclosed
  /// VM" while running on the host would be the worst possible lie to tell.
  /// `backend` is null when the server does not report one.
  Future<({String sessionId, String? backend})> spawnSession({
    required int rows,
    required int cols,
    String? spaceId,
    String? cwd,
    String? backend,
  }) async {
    final data = await _client.call(
      'terminal.spawn',
      {
        'rows': rows,
        'cols': cols,
        'space_id': ?spaceId,
        'cwd': ?cwd,
        'backend': ?backend,
      },
      // Far beyond the client-wide 30s: a `microvm` spawn legitimately boots
      // a VM and syncs a worktree first (the server bounds it at ~150s), and
      // a spawn that times out client-side while succeeding server-side
      // leaks a machine the panel never attaches to.
      timeout: const Duration(seconds: 180),
    );
    return (
      sessionId: data['session_id'] as String,
      backend: data['backend'] as String?,
    );
  }

  /// The session's output: first whether this person may drive it
  /// ([TerminalDriveRight], from the subscription's opening `{can_drive}`
  /// frame), then live PTY bytes ([TerminalBytes], from `{chunk: <base64>}`
  /// frames), never replaceable snapshots. Each listener starts live;
  /// replaying a previous chunk corrupts the screen. A frame carrying
  /// neither is dropped, never turned into an empty chunk.
  Stream<TerminalOutputFrame> output(String sessionId) => _client
      .subscribeEvents('terminal.output', {'session_id': sessionId})
      .expand<TerminalOutputFrame>((data) {
        final chunk = data['chunk'];
        if (chunk is String) {
          return [TerminalBytes(base64Decode(chunk))];
        }
        final canDrive = data['can_drive'];
        if (canDrive is bool) {
          return [TerminalDriveRight(canDrive: canDrive)];
        }
        return const [];
      });

  /// The session's foreground-process title stream (`{title: <string>}`
  /// pushes; `''` when the shell sits at its prompt). The server polls the
  /// PTY's foreground process group, so the tab can title itself after a
  /// long-running command even when the shell never emits OSC 0/2. A server
  /// without the op errors the stream with `RpcErrorCodes.opUnknown` —
  /// callers should tolerate that and simply keep the OSC-only behaviour.
  Stream<String> titles(String sessionId) => _client
      .subscribe('terminal.titles', {'session_id': sessionId})
      .map((data) => (data['title'] as String?) ?? '');

  /// Writes [data] (raw bytes) to the session's PTY stdin (base64-framed).
  Future<void> write(String sessionId, List<int> data) => _client.call(
    'terminal.write',
    {'session_id': sessionId, 'data': base64Encode(data)},
  );

  /// Resizes the session's PTY to [rows]×[cols].
  Future<void> resize(String sessionId, int rows, int cols) => _client.call(
    'terminal.resize',
    {'session_id': sessionId, 'rows': rows, 'cols': cols},
  );

  /// Kills the session's shell and releases its sandbox resources.
  Future<void> kill(String sessionId) =>
      _client.call('terminal.kill', {'session_id': sessionId});
}

/// One frame of a terminal's `terminal.output` subscription.
sealed class TerminalOutputFrame {
  const TerminalOutputFrame();
}

/// Whether this person may drive the terminal: type into it, resize it and
/// close or stop it. False is a read-only view of someone else's terminal; a
/// person's own terminal is always true. Sent once, before any bytes.
final class TerminalDriveRight extends TerminalOutputFrame {
  /// Creates the right.
  const TerminalDriveRight({required this.canDrive});

  /// Whether this person may drive the terminal.
  final bool canDrive;
}

/// Live bytes the PTY wrote.
final class TerminalBytes extends TerminalOutputFrame {
  /// Wraps [bytes].
  const TerminalBytes(this.bytes);

  /// The raw bytes, possibly splitting a UTF-8 sequence.
  final List<int> bytes;
}
