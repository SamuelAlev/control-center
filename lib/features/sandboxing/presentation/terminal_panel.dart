import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart'
    show workspaceFilesystemPortProvider;
import 'package:control_center/features/sandboxing/domain/sandbox_config.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/extensions/sandbox_backend_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pty/flutter_pty.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:xterm/xterm.dart';

/// Bundle of metadata identifying which conversation's terminal we're
/// rendering and which on-disk directory should be writable inside the
/// sandbox.
class TerminalSession {
  /// Creates a [TerminalSession].
  const TerminalSession({
    required this.sessionId,
    required this.agentDirHostPath,
    required this.workspaceId,
    this.agentId = '',
  });

  /// Stable id — usually the channel or conversation id.
  final String sessionId;

  /// Host directory that becomes the terminal's writable workspace.
  final String agentDirHostPath;

  /// Workspace id (for diagnostic purposes).
  final String workspaceId;

  /// Bound agent id, if any.
  final String agentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalSession &&
          sessionId == other.sessionId &&
          agentDirHostPath == other.agentDirHostPath &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId;

  @override
  int get hashCode =>
      Object.hash(sessionId, agentDirHostPath, workspaceId, agentId);
}

/// Interactive xterm-rendered terminal drawer attached via PTY to the
/// channel's sandbox session.
///
/// Backend wiring:
///   * Native (macOS) → `sandbox-exec -f <profile> /bin/zsh -il` on a PTY
///   * Native (Linux/WSL2) → `bwrap <args> /bin/bash -il` on a PTY
///   * None              → `/bin/zsh -il` (or `cmd.exe`) directly on a PTY
///
/// The widget owns one [Terminal] + one [Pty] for the lifetime of the
/// session. "Restart shell" tears both down and spawns a fresh pair.
class TerminalPanel extends ConsumerStatefulWidget {
  /// Creates a [TerminalPanel].
  const TerminalPanel({required this.session, this.onShellExit, super.key});

  /// Channel + mount metadata.
  final TerminalSession session;

  /// Called when the PTY shell process exits.
  final VoidCallback? onShellExit;

  @override
  ConsumerState<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends ConsumerState<TerminalPanel> {
  late final Terminal _terminal = Terminal(maxLines: 10000);
  final TerminalController _termCtl = TerminalController();
  Pty? _pty;
  StreamSubscription<List<int>>? _ptyOut;

  bool _booting = false;
  String? _error;

  /// Session-id prefix that keeps the terminal's sandbox session separate
  /// from the agent's sandbox session in the same channel.
  static const String _terminalSessionPrefix = 'term-';

  @override
  void initState() {
    super.initState();
    _terminal.onOutput = (data) {
      final pty = _pty;
      if (pty == null) {
        return;
      }
      pty.write(Uint8List.fromList(utf8.encode(data)));
    };
    _terminal.onResize = (cols, rows, _, _) {
      _pty?.resize(rows, cols);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    if (_booting) {
      return;
    }
    setState(() {
      _booting = true;
      _error = null;
    });
    try {
      final backend = ref.read(activeSandboxBackendProvider);
      final pty = await _startPtyFor(backend);
      if (!mounted) {
        unawaited(_killPty(pty));
        return;
      }
      _attach(pty);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _booting = false);
      }
    }
  }

  Future<Pty> _startPtyFor(SandboxBackend backend) async {
    const cols = 100;
    const rows = 40;
    final cwd = await _conversationDir();
    if (backend == SandboxBackend.none) {
      return _startHostShellPty(rows: rows, cols: cols, cwd: cwd);
    }
    return _startNativeSandboxPty(rows: rows, cols: cols, cwd: cwd);
  }

  Future<Pty> _startNativeSandboxPty({
    required int rows,
    required int cols,
    required String cwd,
  }) async {
    final manager = ref.read(sandboxManagerProvider);
    final shell = Platform.isMacOS ? '/bin/zsh' : '/bin/bash';
    final config = _terminalConfig(cwd);
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
      _terminal.write('[!] $e — running on the host without a sandbox.\r\n');
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

  Future<String> _conversationDir() async {
    final fs = ref.read(workspaceFilesystemPortProvider);
    final dir = await fs.ensureConversationDir(
      widget.session.workspaceId,
      widget.session.sessionId,
    );
    return dir.path;
  }

  /// The terminal is **the user's playground**, not the agent's tool —
  /// capability gating only applies to the agent dispatcher. Filesystem
  /// rules: the user's home is writable (so `zsh` history, `fnm`,
  /// completion caches, etc. work normally), but the secret paths
  /// (`~/.ssh`, `~/.aws`, …) are still read-denied. Network is unrestricted.
  SandboxConfig _terminalConfig(String cwd) {
    final home = Platform.environment['HOME'] ?? '';
    return SandboxConfig(
      sessionId: '$_terminalSessionPrefix${widget.session.sessionId}',
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

  void _attach(Pty pty) {
    _pty = pty;
    _ptyOut?.cancel();
    _ptyOut = pty.output.listen(
      (bytes) => _terminal.write(utf8.decode(bytes, allowMalformed: true)),
      onDone: () {
        if (!mounted) {
          return;
        }
        _terminal.write('\r\n[shell exited]\r\n');
        widget.onShellExit?.call();
      },
    );
  }

  Future<void> _killPty(Pty? pty) async {
    if (pty == null) {
      return;
    }
    try {
      pty.kill();
    } catch (_) {}
  }

  Future<void> _reset() async {
    await _ptyOut?.cancel();
    _ptyOut = null;
    await _killPty(_pty);
    _pty = null;

    // Drop any per-session bridge files / Seatbelt profiles from the manager
    // so the next boot is a genuinely fresh sandbox session.
    try {
      await ref
          .read(sandboxManagerProvider)
          .disposeSession('$_terminalSessionPrefix${widget.session.sessionId}');
    } catch (_) {}

    _terminal.buffer.clear();
    _terminal.buffer.setCursor(0, 0);
    await _boot();
  }

  @override
  void dispose() {
    _ptyOut?.cancel();
    _ptyOut = null;
    final pty = _pty;
    _pty = null;
    if (pty != null) {
      try {
        pty.kill();
      } catch (_) {}
    }
    _termCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final backend = ref.watch(activeSandboxBackendProvider);
    final codeFont = ref.watch(codeFontFamilyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = tokens?.bgPrimaryAlt ?? theme.colorScheme.surface;
    final termTheme = isDark ? _darkTerminalTheme : _lightTerminalTheme;

    return Container(
      decoration: BoxDecoration(color: bg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            backend: backend,
            booting: _booting,
            error: _error,
            onReset: _reset,
          ),
          const Divider(height: 1),
          Expanded(
            child: _booting
                ? _BootingBody(error: _error)
                : _error != null
                    ? _ErrorBody(message: _error!, onRetry: _boot)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: TerminalView(
                          _terminal,
                          controller: _termCtl,
                          autofocus: true,
                          theme: termTheme,
                          backgroundOpacity: 0,
                          textStyle: TerminalStyle(
                            fontSize: 13,
                            fontFamily: codeFont,
                            height: 1.35,
                          ),
                          padding: const EdgeInsets.all(2),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ANSI terminal colors are a sanctioned domain palette (like the diff viewer):
// blue must render blue, cyan cyan — so they use the chromatically-correct
// indigo/sky scales, NOT the orange brand. The selection highlight carries the
// system accent.
const _lightTerminalTheme = TerminalTheme(
  cursor: DesignSystemPalette.gray600,
  selection: Color(0x33FA520F),
  foreground: DesignSystemPalette.gray900,
  background: DesignSystemPalette.white,
  black: DesignSystemPalette.gray900,
  red: DesignSystemPalette.red600,
  green: DesignSystemPalette.green600,
  yellow: DesignSystemPalette.yellow600,
  blue: DesignSystemPalette.indigo600,
  magenta: DesignSystemPalette.purple600,
  cyan: DesignSystemPalette.sky500,
  white: DesignSystemPalette.gray50,
  brightBlack: DesignSystemPalette.gray500,
  brightRed: DesignSystemPalette.red500,
  brightGreen: DesignSystemPalette.green500,
  brightYellow: DesignSystemPalette.yellow500,
  brightBlue: DesignSystemPalette.indigo500,
  brightMagenta: DesignSystemPalette.purple500,
  brightCyan: DesignSystemPalette.sky400,
  brightWhite: DesignSystemPalette.white,
  searchHitBackground: Color(0xFFFFFF2B),
  searchHitBackgroundCurrent: Color(0xFF31FF26),
  searchHitForeground: DesignSystemPalette.gray900,
);

const _darkTerminalTheme = TerminalTheme(
  cursor: DesignSystemPalette.gray300,
  selection: Color(0x40FB6424),
  foreground: DesignSystemPalette.gray50,
  background: DesignSystemPalette.gray950,
  black: DesignSystemPalette.gray950,
  red: DesignSystemPalette.red400,
  green: DesignSystemPalette.green400,
  yellow: DesignSystemPalette.yellow400,
  blue: DesignSystemPalette.indigo400,
  magenta: DesignSystemPalette.purple400,
  cyan: DesignSystemPalette.sky400,
  white: DesignSystemPalette.gray100,
  brightBlack: DesignSystemPalette.gray400,
  brightRed: DesignSystemPalette.red300,
  brightGreen: DesignSystemPalette.green300,
  brightYellow: DesignSystemPalette.yellow300,
  brightBlue: DesignSystemPalette.indigo300,
  brightMagenta: DesignSystemPalette.purple300,
  brightCyan: DesignSystemPalette.sky300,
  brightWhite: DesignSystemPalette.gray50,
  searchHitBackground: Color(0xFFFFFF2B),
  searchHitBackgroundCurrent: Color(0xFF31FF26),
  searchHitForeground: DesignSystemPalette.gray950,
);

class _Header extends StatelessWidget {
  const _Header({
    required this.backend,
    required this.booting,
    required this.error,
    required this.onReset,
  });

  final SandboxBackend backend;
  final bool booting;
  final String? error;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(LucideIcons.terminal, size: 14, color: tokens?.fgSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Terminal · ${backend.resolvedLabel(l10n)}'
                      '${booting ? " · booting…" : ""}'
                      '${error != null ? " · error" : ""}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens?.textPrimary,
              ),
            ),
          ),
          FTooltip(
            tipAnchor: Alignment.topCenter,
            childAnchor: Alignment.bottomCenter,
            tipBuilder: (_, _) => Text(l10n.restartShell),
            child: FButton.icon(
              onPress: onReset,
              child: const Icon(LucideIcons.rotateCcw, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _BootingBody extends StatelessWidget {
  const _BootingBody({required this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 24, height: 24, child: FProgress()),
          const SizedBox(height: 12),
          Text(
            error ?? 'starting shell…',
            style: TextStyle(
              fontSize: 12,
              color: tokens?.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.triangleAlert,
              size: 28,
              color: tokens?.textErrorPrimary,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: tokens?.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            FButton(
              onPress: onRetry,
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
