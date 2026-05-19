import 'dart:io';

import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart' show TerminalPanel;
import 'package:control_center/features/sandboxing/presentation/terminal_panel_web.dart' show TerminalPanel;
import 'package:flutter_pty/flutter_pty.dart';

/// Session-id prefix that keeps a terminal's sandbox session distinct from the
/// agent's sandbox session in the same conversation.
const String terminalSandboxSessionPrefix = 'term-';

/// Shared `flutter_pty` + [SandboxManager] boot logic for an interactive
/// terminal — the single home of the rules the io [TerminalPanel] and the
/// server-side `DesktopTerminalSessionPort` both rely on, so the local panel and
/// the PTY-over-RPC surface behave identically.
///
/// Desktop-only (`dart:io` + `flutter_pty`). The web terminal never imports this
/// — it drives the SERVER's [SandboxManager]-backed PTY over RPC instead.
///
/// Backend wiring:
///   * Native (macOS) → `sandbox-exec -f <profile> /bin/zsh -il` on a PTY
///   * Native (Linux/WSL2) → `bwrap <args> /bin/bash -il` on a PTY
///   * None              → `/bin/zsh -il` (or `cmd.exe`) directly on a PTY
///
/// On macOS/Linux the native sandbox can be unavailable at runtime; [onNotice]
/// (when given) receives a human-readable line to surface to the terminal, and
/// the boot transparently falls back to the host shell.
Future<Pty> startSandboxTerminalPty({
  required SandboxManager manager,
  required SandboxBackend backend,
  required String sessionId,
  required String cwd,
  required int rows,
  required int cols,
  void Function(String notice)? onNotice,
}) async {
  if (backend == SandboxBackend.none) {
    return _startHostShellPty(rows: rows, cols: cols, cwd: cwd);
  }
  return _startNativeSandboxPty(
    manager: manager,
    sessionId: sessionId,
    rows: rows,
    cols: cols,
    cwd: cwd,
    onNotice: onNotice,
  );
}

Future<Pty> _startNativeSandboxPty({
  required SandboxManager manager,
  required String sessionId,
  required int rows,
  required int cols,
  required String cwd,
  void Function(String notice)? onNotice,
}) async {
  final shell = Platform.isMacOS ? '/bin/zsh' : '/bin/bash';
  final config = terminalSandboxConfig(sessionId: sessionId, cwd: cwd);
  try {
    final wrap = await manager.wrap(
      config: config,
      argv: [shell, '-il'],
      workingDirectory: cwd,
    );
    final env = <String, String>{
      if (Platform.environment['HOME'] != null)
        'HOME': Platform.environment['HOME']!,
      if (Platform.environment['PATH'] != null)
        'PATH': Platform.environment['PATH']!,
      if (Platform.environment['TERM'] != null)
        'TERM': Platform.environment['TERM']!,
      ...wrap.environment,
    };
    return Pty.start(
      wrap.executable,
      arguments: wrap.argv,
      environment: env,
      workingDirectory: cwd,
      rows: rows,
      columns: cols,
    );
  } on UnsupportedError catch (e) {
    // Native sandbox not available on this OS — fall back transparently.
    onNotice?.call('[!] $e — running on the host without a sandbox.');
    return _startHostShellPty(rows: rows, cols: cols, cwd: cwd);
  }
}

Future<Pty> _startHostShellPty({
  required int rows,
  required int cols,
  required String cwd,
}) async {
  return Pty.start(
    Platform.isWindows ? 'cmd.exe' : '/bin/zsh',
    arguments: const ['-il'],
    workingDirectory: cwd,
    rows: rows,
    columns: cols,
  );
}

/// The sandbox profile a terminal session runs under.
///
/// The terminal is **the user's playground**, not the agent's tool — capability
/// gating only applies to the agent dispatcher. Filesystem rules: the user's
/// home is writable (so `zsh` history, `fnm`, completion caches, etc. work
/// normally), but the secret paths (`~/.ssh`, `~/.aws`, …) are still read-denied.
/// Network is unrestricted.
SandboxConfig terminalSandboxConfig({
  required String sessionId,
  required String cwd,
}) {
  final home = Platform.environment['HOME'] ?? '';
  return SandboxConfig(
    sessionId: '$terminalSandboxSessionPrefix$sessionId',
    network: const NetworkConfig(),
    filesystem: FilesystemConfig(
      denyRead: [
        if (home.isNotEmpty) ...[
          '$home/.ssh',
          '$home/.aws',
          '$home/.gnupg',
          '$home/.config/gh',
          '$home/Library/Keychains',
        ],
      ],
      allowWrite: [
        cwd,
        if (home.isNotEmpty) home,
        '/tmp',
      ],
    ),
    skipMandatoryHomeRcDenies: true,
  );
}
