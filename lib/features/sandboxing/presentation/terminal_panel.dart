// Interactive terminal view — a thin client over RPC.
//
// `xterm` is pure Dart and renders fine on every target; the only thing that
// used to differ between desktop and web was the PTY transport. The desktop
// no longer spawns a local PTY (`flutter_pty`): it is a thin client like web,
// so both targets share this single view. A `TerminalSessionController`
// (terminal_session_controller.dart) spawns a sandboxed shell over the
// `terminal.spawn` RPC op on the connected `cc_server`, streams its output
// over the `terminal.output` subscription into the xterm `Terminal` and
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
import 'package:control_center/core/infrastructure/clipboard/host_clipboard.dart';
import 'package:control_center/core/keybindings/text_input_surface.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/rigs/presentation/rig_ports_panel.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/rigs/providers/rig_transfer_providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_file_transfer.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:xterm/xterm.dart';

/// A paste that may carry more than text.
///
/// A distinct intent type, deliberately: `TerminalActions` (inside
/// [TerminalView]) already answers [PasteTextIntent] by reading the clipboard
/// as plain text, and an override for it would have to sit ABOVE the terminal
/// where the terminal's own handler shadows it. A type xterm has never heard
/// of passes straight through to the handler installed here.
class TerminalRichPasteIntent extends Intent {
  /// Creates a [TerminalRichPasteIntent].
  const TerminalRichPasteIntent();
}

/// Bundle of metadata identifying which conversation's terminal we're
/// rendering and which on-disk directory should be writable inside the
/// sandbox.
class TerminalSession {
  /// Creates a [TerminalSession].
  const TerminalSession({
    required this.sessionId,
    required this.spaceId,
    required this.workspaceId,
    this.agentId = '',
    this.backend,
  });

  /// Unique id for THIS terminal tab — keeps two terminals in the same
  /// conversation isolated. NOT the conversation id (use [spaceId] for that).
  final String sessionId;

  /// The conversation (space) this terminal belongs to. The server resolves
  /// its conversation root (`conversations/<spaceId>`) as the working
  /// directory. Empty when no conversation is open (server falls back to the
  /// workspace root).
  final String spaceId;

  /// Workspace id (for diagnostic purposes).
  final String workspaceId;

  /// Bound agent id, if any.
  final String agentId;

  /// The `SandboxBackend` name to REQUEST for this shell (e.g. `microvm` for
  /// a terminal inside an enclosed VM), or null for the server's default.
  /// What the shell actually runs under comes back on the controller —
  /// requesting is not getting.
  final String? backend;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TerminalSession &&
          sessionId == other.sessionId &&
          spaceId == other.spaceId &&
          workspaceId == other.workspaceId &&
          agentId == other.agentId &&
          backend == other.backend;

  @override
  int get hashCode =>
      Object.hash(sessionId, spaceId, workspaceId, agentId, backend);
}

/// Interactive xterm-rendered terminal attached, over RPC, to a PTY the
/// connected SERVER runs inside the agent sandbox.
///
/// Compat wrapper: owns one [TerminalSessionController] for the lifetime of
/// the panel (kill-on-unmount). The messaging IDE does NOT use this — it
/// keeps controllers alive across space switches via the app-level
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

  /// Space + mount metadata.
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
/// controllers alive across space switches via the app-level
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
    // A demo server hosts no terminal ops at all, so the spawn is a round trip
    // whose only outcome is `opUnknown`. Skip it: the panel already knows what
    // it will render (see `_terminalBody`), and latency spent being told no is
    // latency wasted.
    if (!ref.read(isDemoServerProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_controller.ensureBooted());
        }
      });
    }
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
/// server-side PTY session and the subscriptions all live on the controller,
/// so unmounting this view (space switch, hidden tab) loses nothing — a
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

  /// The transport to the server's rig file lane, for an enclosed terminal.
  /// Null on a host-shell terminal, which needs no transfer at all.
  RigTransferClient? _transferClient;

  /// Guards a paste or drop already in flight. Holding ctrl+V repeats at the
  /// OS key-repeat rate, and each repeat would copy the same image into the
  /// machine again.
  bool _transferBusy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The controller outlives this view and has no `BuildContext`, so the
    // lines it writes into the terminal buffer are handed to it from here —
    // re-supplied on every dependency change, which is what makes a locale
    // switch reach a session that was already open.
    final l10n = AppLocalizations.of(context);
    widget.controller.notices = (
      reconnecting: l10n.terminalStreamReconnecting,
      streamError: l10n.terminalStreamError,
      shellExited: l10n.terminalShellExited,
    );
    final proxy = MediaProxyScope.configOf(context);
    if (proxy != null && _transferClient?.proxy != proxy) {
      _transferClient?.close();
      _transferClient = rigTransferClientFor(context);
    }
  }

  /// Whether this terminal runs inside a machine of its own.
  bool get _isEnclosed =>
      widget.controller.backend == 'microvm' ||
      widget.controller.session.backend == 'microvm';

  /// The bridge into this terminal's machine, or null when there is none
  /// (a host shell, a machine still booting, no server connection).
  RigClipboardBridge? get _bridge {
    final client = _transferClient;
    final session = widget.controller.session;
    if (client == null || !_isEnclosed || session.spaceId.isEmpty) {
      return null;
    }
    final rig = ref.read(
      conversationExecRigProvider((
        workspaceId: session.workspaceId,
        conversationId: session.spaceId,
      )),
    );
    if (rig == null) {
      return null;
    }
    return rigClipboardBridgeFor(
      client: client,
      workspaceId: session.workspaceId,
      rigId: rig.id,
    );
  }

  /// The shortcut map for the terminal.
  ///
  /// A copy of xterm's own defaults with ONE change: paste raises
  /// [TerminalRichPasteIntent] instead of [PasteTextIntent], so an image or a
  /// file on the clipboard can become a path rather than being silently
  /// dropped (xterm's handler reads `text/plain` and does nothing when there
  /// is none). Written out rather than spread over `defaultTerminalShortcuts`
  /// because `SingleActivator` does not define equality — a "replacement"
  /// entry would sit BESIDE the original, and which one won would be a matter
  /// of map order.
  Map<ShortcutActivator, Intent> get _shortcuts {
    final apple =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
    return {
      // Copy is ctrl+SHIFT+C off Apple platforms: plain ctrl+C is the
      // interrupt, and binding it to copy would take SIGINT away from every
      // shell in the app.
      if (apple)
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            CopySelectionTextIntent.copy
      else
        const SingleActivator(
          LogicalKeyboardKey.keyC,
          control: true,
          shift: true,
        ): CopySelectionTextIntent.copy,
      SingleActivator(LogicalKeyboardKey.keyV, meta: apple, control: !apple):
          const TerminalRichPasteIntent(),
      // The terminal convention everywhere, and harmless on macOS.
      const SingleActivator(
        LogicalKeyboardKey.keyV,
        control: true,
        shift: true,
      ): const TerminalRichPasteIntent(),
      SingleActivator(LogicalKeyboardKey.keyA, meta: apple, control: !apple):
          const SelectAllTextIntent(SelectionChangedCause.keyboard),
    };
  }

  /// Pastes whatever is on the host clipboard into the terminal.
  ///
  /// Text goes to the shell as text. An IMAGE or a FILE cannot — a shell
  /// cannot display one — so it is copied into the machine and its path is
  /// typed instead, which is what every tool that understands the file wants
  /// as an argument anyway.
  Future<void> _richPaste() async {
    if (_transferBusy) {
      return;
    }
    _transferBusy = true;
    try {
      final snapshot = await readHostClipboard();
      if (!mounted) {
        return;
      }
      if (snapshot.files.isNotEmpty || snapshot.imageBytes != null) {
        final bridge = _bridge;
        if (bridge == null) {
          // A host shell shares this computer's filesystem, so a file on the
          // clipboard is already reachable — but only its BYTES came through
          // the clipboard reader, not a path. Fall through to text, which for
          // a file copied in Finder is its name; better than silence.
          final text = snapshot.text;
          if (text != null && text.isNotEmpty) {
            widget.controller.terminal.paste(text);
          }
          return;
        }
        final l10n = AppLocalizations.of(context);
        CcToastScope.of(context).show(l10n.rigTerminalDropSending);
        final result = snapshot.files.isNotEmpty
            ? await sendFilesToGuest(bridge, snapshot.files)
            : await sendImageToGuest(
                bridge,
                snapshot.imageBytes!,
                name: pastedImageName(DateTime.now()),
                mediaType: snapshot.imageMediaType ?? 'image/png',
              );
        if (!mounted) {
          return;
        }
        _applyDrop(result, imagePasted: snapshot.files.isEmpty);
        return;
      }
      final text = snapshot.text;
      if (text != null && text.isNotEmpty) {
        widget.controller.terminal.paste(text);
        _termCtl.clearSelection();
      }
    } finally {
      _transferBusy = false;
    }
  }

  /// Takes a file drop and types the resulting paths at the prompt.
  Future<void> _acceptDrop(PerformDropEvent event) async {
    if (_transferBusy) {
      return;
    }
    _transferBusy = true;
    try {
      final readers = [
        for (final item in event.session.items)
          if (item.dataReader != null) item.dataReader!,
      ];
      final bridge = _bridge;
      if (bridge == null) {
        // A host shell already shares this filesystem: the file needs no
        // transfer, only its own path. Reading the path instead of the bytes
        // is also what keeps a 4 GB video from being loaded into memory to
        // type its name.
        final paths = await readDroppedPaths(readers);
        if (!mounted || paths.isEmpty) {
          return;
        }
        widget.controller.terminal.paste(
          paths.map(shellQuoteForPrompt).join(' '),
        );
        return;
      }
      if (mounted) {
        CcToastScope.of(
          context,
        ).show(AppLocalizations.of(context).rigTerminalDropSending);
      }
      final snapshot = await snapshotFromReader(readers);
      if (!mounted) {
        return;
      }
      if (snapshot.files.isEmpty) {
        final text = snapshot.text;
        if (text != null && text.isNotEmpty) {
          widget.controller.terminal.paste(text);
        }
        return;
      }
      _applyDrop(await sendFilesToGuest(bridge, snapshot.files));
    } finally {
      _transferBusy = false;
    }
  }

  /// Types [result] at the prompt, or reports why it could not.
  void _applyDrop(TerminalDropResult result, {bool imagePasted = false}) {
    if (!mounted) {
      return;
    }
    if (result.toType.isNotEmpty) {
      widget.controller.terminal.paste(result.toType);
      if (imagePasted) {
        CcToastScope.of(
          context,
        ).show(AppLocalizations.of(context).rigTerminalPasteImage);
      }
      return;
    }
    final notice = result.notice;
    if (notice != null && notice.isNotEmpty) {
      CcToastScope.of(context).show(
        notice,
        variant: result.isError
            ? CcToastVariant.danger
            : CcToastVariant.neutral,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Boot the session if it isn't already (a re-attached kept session
    // no-ops; a fresh controller spawns its shell). Never on a demo — see the
    // note in `_TerminalPanelState.initState`.
    if (!ref.read(isDemoServerProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(widget.controller.ensureBooted());
        }
      });
    }
  }

  @override
  void dispose() {
    _transferClient?.close();
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
        // The forwarded-ports affordance rides in the terminal's top-right,
        // VS Code / Cursor style. It renders NOTHING unless this is an
        // enclosed-VM terminal whose conversation has a live machine with
        // ports — a host shell never shows it (there is no VM to have ports).
        final isVmTerminal =
            controller.backend == 'microvm' ||
            controller.session.backend == 'microvm';
        return Container(
          decoration: BoxDecoration(color: bg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _terminalBody(controller, termTheme, codeFont),
                    ),
                    if (isVmTerminal && controller.session.spaceId.isNotEmpty)
                      Positioned(
                        top: 2,
                        right: 6,
                        child: RigPortsButton(
                          workspaceId: controller.session.workspaceId,
                          conversationId: controller.session.spaceId,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _terminalBody(
    TerminalSessionController controller,
    TerminalTheme termTheme,
    String codeFont,
  ) {
    // The demo notice comes FIRST and is more specific than
    // `_UnavailableBody`: "this server has no PTY" is true of any headless
    // host, but a visitor here should be told it is the demo, and why.
    return ref.watch(isDemoServerProvider)
        ? const DemoUnavailable(capability: DemoCapability.terminal)
        : controller.unavailable
        ? const _UnavailableBody()
        : controller.booting
        ? _BootingBody(error: controller.error)
        : controller.error != null
        ? _ErrorBody(
            message: controller.error!,
            onRetry: controller.ensureBooted,
          )
        : _terminalSurface(controller, termTheme, codeFont);
  }

  /// The live terminal, wrapped in everything that carries content across its
  /// boundary.
  ///
  /// The nesting is load-bearing, outermost first:
  ///
  ///  * [TextInputSurface] tells the keybinding dispatcher this focus IS
  ///    typing. Without it every `!textInputFocus` app binding stays active
  ///    and macOS's unmatched-key silencer eats printable keys before the
  ///    terminal's IME connection sees them.
  ///  * [DropRegion] accepts files dragged in from the OS.
  ///  * [Actions] answers [TerminalRichPasteIntent], which the shortcut map
  ///    raises instead of xterm's text-only [PasteTextIntent]. It has to be
  ///    ABOVE the terminal because that is where the intent resolves, and it
  ///    has to be a DIFFERENT intent type because xterm's own handler, which
  ///    is below, would otherwise shadow it.
  Widget _terminalSurface(
    TerminalSessionController controller,
    TerminalTheme termTheme,
    String codeFont,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
    child: TextInputSurface(
      child: DropRegion(
        formats: Formats.standardFormats,
        hitTestBehavior: HitTestBehavior.opaque,
        // Copy, never move: dropping a file onto a shell must not invite the
        // source application to delete the original.
        onDropOver: (_) => DropOperation.copy,
        onPerformDrop: _acceptDrop,
        child: Actions(
          actions: {
            TerminalRichPasteIntent: CallbackAction<TerminalRichPasteIntent>(
              onInvoke: (_) {
                unawaited(_richPaste());
                return null;
              },
            ),
          },
          child: TerminalView(
            controller.terminal,
            controller: _termCtl,
            autofocus: true,
            onKeyEvent: controller.onKeyEvent,
            shortcuts: _shortcuts,
            theme: termTheme,
            backgroundOpacity: 0,
            // Fira Code renders visually large for its point size (tall
            // x-height, wide advance); 12/1.25 matches the density of native
            // terminal emulators (ghostty, iTerm) where 13/1.35 read ~2pt
            // oversized.
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
  );
}

/// Terminal text style resolved through the design-system font pipeline.
///
/// The stock [TerminalStyle] carries only a raw family name and xterm's
/// painter derives bold cells by setting [FontWeight.bold] on it. That breaks
/// both of our font paths: the bundled Fira Code is a single VARIABLE file
/// (without the `wght` axis pinned the engine renders the default instance
/// and SYNTHESIZES bold on top — the smeared "extra bold" look) and a
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
  selection: Color(0x33FA500F),
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
  selection: Color(0x40FB6224),
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
