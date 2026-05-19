// Web / thin-client interactive terminal panel.
//
// `xterm` is pure Dart and renders fine on Flutter web; only the LOCAL PTY
// (`flutter_pty`, FFI) is desktop-only. So instead of a placeholder, this panel
// drives a REAL terminal that runs on the connected SERVER's host: it spawns a
// sandboxed shell over the `terminal.spawn` RPC op, streams its output over the
// `terminal.output` subscription into the xterm `Terminal`, and forwards xterm
// input/resize back over `terminal.write`/`terminal.resize`. On dispose it kills
// the server-side session.
//
// When the connected server does NOT host these ops (a pure-Dart headless
// server that links no PTY), `terminal.spawn` fails with `opUnknown`; the panel
// then renders an honest "the terminal runs on the server host" message rather
// than erroring. `TerminalSession` mirrors the desktop value (same shape) so the
// messaging screen composes this panel exactly like the io one.
library;

import 'dart:async';
import 'dart:convert';

import 'package:cc_data/cc_data.dart' show RemoteTerminalRepository;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

/// Mirror of the desktop `TerminalSession` value (web-safe; no PTY). Kept
/// shape-identical to the io panel's so the messaging screen passes one without
/// caring which variant compiled in.
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

/// Interactive xterm-rendered terminal attached, over RPC, to a PTY the
/// connected SERVER runs inside the agent sandbox.
///
/// The widget owns one [Terminal] + one server-side session id for the lifetime
/// of the panel. "Restart shell" kills the server session and spawns a fresh
/// one. Public API matches the desktop [TerminalPanel] so the messaging screen
/// composes it unchanged.
class TerminalPanel extends ConsumerStatefulWidget {
  /// Creates a [TerminalPanel].
  const TerminalPanel({
    required this.session,
    this.onShellExit,
    this.backgroundColor,
    super.key,
  });

  /// Channel + mount metadata.
  final TerminalSession session;

  /// Called when the server-side shell session ends.
  final VoidCallback? onShellExit;

  /// Background color override; null falls back to `bgPrimaryAlt`.
  final Color? backgroundColor;

  @override
  ConsumerState<TerminalPanel> createState() => _TerminalPanelState();
}

class _TerminalPanelState extends ConsumerState<TerminalPanel> {
  late final Terminal _terminal = Terminal(maxLines: 10000);
  final TerminalController _termCtl = TerminalController();

  RemoteTerminalRepository? _repo;
  String? _sessionId;
  StreamSubscription<List<int>>? _outputSub;

  bool _booting = false;
  String? _error;

  /// True when the connected server hosts no terminal ops — the panel then
  /// renders the honest "runs on the server host" message instead of an error.
  bool _unavailable = false;

  int _rows = 40;
  int _cols = 100;

  @override
  void initState() {
    super.initState();
    _terminal.onOutput = (data) {
      final repo = _repo;
      final id = _sessionId;
      if (repo == null || id == null) {
        return;
      }
      // Forward keystrokes to the server PTY (base64-framed in the repository).
      unawaited(repo.write(id, utf8.encode(data)));
    };
    _terminal.onResize = (cols, rows, _, _) {
      _cols = cols;
      _rows = rows;
      final repo = _repo;
      final id = _sessionId;
      if (repo != null && id != null) {
        unawaited(repo.resize(id, rows, cols));
      }
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
      _unavailable = false;
    });
    try {
      final repo = RemoteTerminalRepository(ref.read(rpcClientProvider));
      final sessionId = await repo.spawn(
        rows: _rows,
        cols: _cols,
        channelId: widget.session.sessionId,
      );
      if (!mounted) {
        unawaited(repo.kill(sessionId));
        return;
      }
      _repo = repo;
      _sessionId = sessionId;
      _attach(repo, sessionId);
    } on RemoteRpcException catch (e) {
      // The connected server doesn't host the terminal ops — degrade honestly.
      if (e.code == RpcErrorCodes.opUnknown) {
        if (mounted) {
          setState(() => _unavailable = true);
        }
      } else if (mounted) {
        setState(() => _error = e.message);
      }
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

  void _attach(RemoteTerminalRepository repo, String sessionId) {
    _outputSub?.cancel();
    _outputSub = repo
        .output(sessionId)
        .listen(
          (bytes) => _terminal.write(utf8.decode(bytes, allowMalformed: true)),
          onError: (Object e) {
            if (!mounted) {
              return;
            }
            _terminal.write('\r\n[stream error: $e]\r\n');
          },
          onDone: () {
            if (!mounted) {
              return;
            }
            _terminal.write('\r\n[shell exited]\r\n');
            widget.onShellExit?.call();
          },
        );
  }

  Future<void> _reset() async {
    await _outputSub?.cancel();
    _outputSub = null;
    final repo = _repo;
    final id = _sessionId;
    _repo = null;
    _sessionId = null;
    if (repo != null && id != null) {
      try {
        await repo.kill(id);
      } catch (_) {}
    }
    if (!mounted) {
      return;
    }
    _terminal.buffer.clear();
    _terminal.buffer.setCursor(0, 0);
    await _boot();
  }

  @override
  void dispose() {
    _outputSub?.cancel();
    _outputSub = null;
    final repo = _repo;
    final id = _sessionId;
    _repo = null;
    _sessionId = null;
    if (repo != null && id != null) {
      // Best-effort: tell the server to tear the PTY down.
      unawaited(repo.kill(id));
    }
    _termCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final codeFont = ref.watch(codeFontFamilyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = widget.backgroundColor ?? tokens?.bgPrimaryAlt ?? theme.colorScheme.surface;
    final termTheme = isDark ? _darkTerminalTheme : _lightTerminalTheme;

    return Container(
      decoration: BoxDecoration(color: bg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(booting: _booting, error: _error, onReset: _reset),
          const Divider(height: 1),
          Expanded(
            child: _unavailable
                ? const _UnavailableBody()
                : _booting
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
    required this.booting,
    required this.error,
    required this.onReset,
  });

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
          Icon(AppIcons.terminal, size: 14, color: tokens?.fgSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Terminal · server host'
              '${booting ? " · booting…" : ""}'
              '${error != null ? " · error" : ""}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: tokens?.textPrimary,
              ),
            ),
          ),
          CcIconButton(
            icon: AppIcons.rotateCcw,
            onPressed: onReset,
            tooltip: l10n.restartShell,
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
          const SizedBox(width: 24, height: 24, child: CcProgressBar()),
          const SizedBox(height: 12),
          Text(
            error ?? 'starting shell…',
            style: TextStyle(fontSize: 12, color: tokens?.textTertiary),
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
              AppIcons.triangleAlert,
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
            CcButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

/// Shown when the connected server hosts no terminal ops (e.g. a pure-Dart
/// headless server that links no PTY). The terminal is a host-side capability,
/// so there is nothing to retry from the client.
class _UnavailableBody extends StatelessWidget {
  const _UnavailableBody();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.terminal, size: 28, color: tokens?.fgQuaternary),
            const SizedBox(height: 12),
            Text(
              'The terminal runs on the server host and is not available on '
              'this server.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: tokens?.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
