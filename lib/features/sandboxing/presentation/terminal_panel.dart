// Interactive terminal view — a thin client over RPC.
//
// `xterm` is pure Dart and renders fine on every target; the only thing that
// used to differ between desktop and web was the PTY transport. The desktop
// no longer spawns a local PTY (`flutter_pty`): it is a thin client like web,
// so both targets share this single view. A `TerminalSessionController`
// (terminal_session_controller.dart) spawns a sandboxed shell over the
// `terminal.spawn` RPC op on the connected `cc_server`, streams its output
// over the `terminal.output` subscription into the xterm `Terminal`, and
// forwards xterm input/resize back over `terminal.write`/`terminal.resize`.
// Killing the server-side session is the controller owner's call — the
// keep-alive registry (messaging IDE) disposes on tab close / shell exit /
// LRU eviction, the [TerminalPanel] compat wrapper on unmount.
//
// When the connected server does NOT host these ops (a pure-Dart headless
// server with no terminal support wired in), `terminal.spawn` fails with
// `opUnknown`; the view then renders an honest "the terminal runs on the
// server host" message rather than erroring.
library;

import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/keybindings/text_input_surface.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';

/// Bundle of metadata identifying which conversation's terminal we're
/// rendering and which on-disk directory should be writable inside the
/// sandbox.
class TerminalSession {
  /// Creates a [TerminalSession].
  const TerminalSession({
    required this.sessionId,
    required this.channelId,
    required this.workspaceId,
    this.agentId = '',
  });

  /// Unique id for THIS terminal tab — keeps two terminals in the same
  /// conversation isolated. NOT the conversation id (use [channelId] for that).
  final String sessionId;

  /// The conversation (channel) this terminal belongs to. The server resolves
  /// its conversation root (`conversations/<channelId>`) as the working
  /// directory. Empty when no conversation is open (server falls back to the
  /// workspace root).
  final String channelId;

  /// Workspace id (for diagnostic purposes).
  final String workspaceId;

  /// Bound agent id, if any.
  final String agentId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalSession &&
          sessionId == other.sessionId &&
          channelId == other.channelId &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId;

  @override
  int get hashCode => Object.hash(sessionId, channelId, workspaceId, agentId);
}

/// Interactive xterm-rendered terminal attached, over RPC, to a PTY the
/// connected SERVER runs inside the agent sandbox.
///
/// Compat wrapper: owns one [TerminalSessionController] for the lifetime of
/// the panel (kill-on-unmount). The messaging IDE does NOT use this — it
/// keeps controllers alive across channel switches via the app-level
/// `terminalRegistryProvider` and renders [TerminalSessionView] directly.
/// "Restart shell" (the IDE tab's context-menu action) kills the server
/// session and spawns a fresh one.
class TerminalPanel extends ConsumerStatefulWidget {
  /// Creates a [TerminalPanel].
  const TerminalPanel({
    required this.session,
    this.onShellExit,
    this.onTitleChange,
    this.backgroundColor,
    super.key,
  });

  /// Channel + mount metadata.
  final TerminalSession session;

  /// Called when the server-side shell session ends.
  final VoidCallback? onShellExit;

  /// Called when the terminal's effective title changes. Two sources feed it,
  /// ghostty-style: OSC 0/2 escapes the shell (or the running program) emits,
  /// and the server-polled *foreground process* of the PTY — so a plain
  /// `pnpm dev serve` retitles the tab even when nothing emits OSC. A title
  /// the program sets during a run (vim, claude) wins over the process name;
  /// a prompt-time title is dropped once a new command takes the foreground.
  /// Fired with an empty string when the shell is restarted, so the host can
  /// fall back to its default label until the fresh shell titles itself.
  final ValueChanged<String>? onTitleChange;

  /// Background color override; null falls back to `bgPrimaryAlt`.
  final Color? backgroundColor;

  @override
  ConsumerState<TerminalPanel> createState() => _TerminalPanelState();
}

/// Backwards-compatible wrapper that owns one [TerminalSessionController]
/// per mounted panel (kill-on-unmount, the historical behaviour — used by the
/// PR review terminal tab). The messaging IDE does NOT use this: it keeps
/// controllers alive across channel switches via the app-level
/// `terminalRegistryProvider` and renders them through [TerminalSessionView].
class _TerminalPanelState extends ConsumerState<TerminalPanel> {
  late final TerminalSessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TerminalSessionController(
      session: widget.session,
      rpcClient: ref.read(rpcClientProvider),
    );
    // Closures over `widget` so callback swaps in didUpdateWidget track.
    _controller.onTitleChange = (title) => widget.onTitleChange?.call(title);
    _controller.onShellExit = () => widget.onShellExit?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_controller.ensureBooted());
      }
    });
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TerminalSessionView(
      controller: _controller,
      backgroundColor: widget.backgroundColor,
    );
  }
}

/// Disposable xterm view over a [TerminalSessionController].
///
/// Owns only the view-scoped [TerminalController]; the xterm [Terminal], the
/// server-side PTY session, and the subscriptions all live on the controller,
/// so unmounting this view (channel switch, hidden tab) loses nothing — a
/// fresh view reattaches to the same live session.
class TerminalSessionView extends ConsumerStatefulWidget {
  /// Creates a [TerminalSessionView] for [controller].
  const TerminalSessionView({
    required this.controller,
    this.backgroundColor,
    super.key,
  });

  /// The session this view renders.
  final TerminalSessionController controller;

  /// Background color override; null falls back to `bgPrimaryAlt`.
  final Color? backgroundColor;

  @override
  ConsumerState<TerminalSessionView> createState() =>
      _TerminalSessionViewState();
}

class _TerminalSessionViewState extends ConsumerState<TerminalSessionView> {
  final TerminalController _termCtl = TerminalController();

  @override
  void initState() {
    super.initState();
    // Boot the session if it isn't already (a re-attached kept session
    // no-ops; a fresh controller spawns its shell).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.controller.ensureBooted());
      }
    });
  }

  @override
  void dispose() {
    _termCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    // Track IndexedStack-tab visibility: while hidden, terminal.resize RPCs are
    // suppressed (layout passes still fire onResize) and the latest geometry is
    // flushed once on reveal.
    controller.updateVisibility(Visibility.of(context));

    final tokens = context.designSystem;
    final codeFont = ref.watch(codeFontFamilyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg =
        widget.backgroundColor ??
        tokens?.bgPrimaryAlt ??
        theme.colorScheme.surface;
    final termTheme = isDark ? _darkTerminalTheme : _lightTerminalTheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(color: bg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: controller.unavailable
                    ? const _UnavailableBody()
                    : controller.booting
                    ? _BootingBody(error: controller.error)
                    : controller.error != null
                    ? _ErrorBody(
                        message: controller.error!,
                        onRetry: controller.ensureBooted,
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        // TextInputSurface tells the keybinding dispatcher this is
                        // a text-input surface (TerminalView is a TextInputClient,
                        // not an EditableText) — without it, `!textInputFocus`
                        // bindings stay active and macOS's unmatched-key silencer
                        // consumes every printable key before the terminal's IME
                        // connection sees it.
                        child: TextInputSurface(
                          child: TerminalView(
                            controller.terminal,
                            controller: _termCtl,
                            autofocus: true,
                            onKeyEvent: controller.onKeyEvent,
                            theme: termTheme,
                            backgroundOpacity: 0,
                            // Fira Code renders visually large for its point size
                            // (tall x-height, wide advance); 12/1.25 matches the
                            // density of native terminal emulators (ghostty,
                            // iTerm) where 13/1.35 read ~2pt oversized.
                            textStyle: CcTerminalStyle(
                              family: codeFont,
                              fontSize: 12,
                              height: 1.25,
                            ),
                            padding: const EdgeInsets.all(2),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Terminal text style resolved through the design-system font pipeline.
///
/// The stock [TerminalStyle] carries only a raw family name, and xterm's
/// painter derives bold cells by setting [FontWeight.bold] on it. That breaks
/// both of our font paths: the bundled Fira Code is a single VARIABLE file
/// (without the `wght` axis pinned the engine renders the default instance
/// and SYNTHESIZES bold on top — the smeared "extra bold" look), and a
/// user-selected Google font registers one Flutter family PER VARIANT (the
/// raw settings name resolves to nothing, so the terminal silently falls back
/// past the design font entirely). Overriding [toTextStyle] routes every cell
/// style through [AppFonts.codeStyleDynamic] — the same resolver the diff
/// viewer and markdown code blocks use — and pins the variable weight axis,
/// so regular and bold cells render the true faces of the user's mono font.
class CcTerminalStyle extends TerminalStyle {
  /// Creates a [CcTerminalStyle] for the settings font [family].
  CcTerminalStyle({required this.family, super.fontSize, super.height})
    : super(fontFamily: AppFonts.codeDynamic(family).fontFamily ?? family);

  /// The user's code font family as stored in settings (NOT a resolved
  /// Flutter family name — Google families resolve per variant).
  final String family;

  @override
  TextStyle toTextStyle({
    Color? color,
    Color? backgroundColor,
    bool bold = false,
    bool italic = false,
    bool underline = false,
  }) {
    return AppFonts.codeStyleDynamic(
      family,
      fontSize: fontSize,
      height: height,
      color: color,
      backgroundColor: backgroundColor,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    ).copyWith(
      decoration: underline ? TextDecoration.underline : TextDecoration.none,
      fontFamilyFallback: fontFamilyFallback,
      // Pin the weight axis so a variable font (the bundled Fira Code)
      // instances the real weight instead of synthesizing bold; static faces
      // carry no axis and ignore it.
      fontVariations: [FontVariation('wght', bold ? 700 : 400)],
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
