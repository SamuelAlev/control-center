import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart' as arch;
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/features/ide/domain/code_server_port.dart';
import 'package:cc_domain/features/ide/domain/code_server_session.dart';
import 'package:cc_infra/src/ide/code_server_bridge_extension.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:path/path.dart' as p;

/// The code-server binary name looked up on PATH / install prefixes.
const String codeServerBinaryName = 'code-server';

/// The pinned code-server release tag vendored / downloaded on demand
/// (Renovate-tracked — bump here and the CI fetch + managed download follow).
/// Matches the `coder/code-server` GitHub release naming (`v<version>`).
const String codeServerVersion = '4.141.0';

/// Curated language extensions pre-provisioned into the shared `--extensions-dir`
/// so the embedded editor demonstrably ships one LSP end-to-end (the "one LSP
/// milestone"). Matches this repo (a Dart/Flutter monorepo): the Dart extension
/// brings Dart analysis server completions, diagnostics and hover against the
/// worktree — visible the moment a `.dart` file opens. Renovate-tracked: bump
/// the version here and the Open VSX fetch follows.
///
/// Each entry is (publisher, name, version) on the Open VSX registry.
const List<({String publisher, String name, String version})>
codeServerCuratedExtensions = [
  (publisher: 'Dart-Code', name: 'dart-code', version: '3.144.0'),
];

/// Session capability TTL: a minted capability authorizes the proxy for this
/// long before the idle-GC sweep reaps it (a client re-mints by re-opening).
const Duration _sessionTtl = Duration(hours: 12);

/// Idle grace: a code-server process with no open references is left running
/// for this long (cheap re-opens, surviving tab flicker) before being killed.
const Duration _idleGrace = Duration(minutes: 10);

/// Pure-Dart [CodeServerPort]: one code-server per `(workspaceId, worktreePath)`,
/// refcounted, idle-GC'd; `codeServer.*` RPC + `/proxy/vscode/`.
///
/// Binds loopback only; opens the CoW worktree from
/// [IsolatedRepoRepository.forUnitRepo] — never the raw checkout. Foreign ids
/// → no session. [ensureSession]/[closeSession]/[lookup] enforce workspace.
class CodeServerService implements CodeServerPort {
  /// Creates the service over an [isolatedRepos] resolver (worktree lookup), a
  /// `filesystem` (workspace layout) and a [_dataRoot] (managed code-server
  /// install + shared extensions dir, e.g. cc_server's data dir).
  CodeServerService({
    required IsolatedRepoRepository isolatedRepos,
    required this._dataRoot,
    this.attemptManagedDownload = true,
  }) : _repos = isolatedRepos;

  final IsolatedRepoRepository _repos;
  final String _dataRoot;

  /// Whether [ensureSession] / [warmUp] may attempt an on-demand download of
  /// the pinned code-server archive when no install is found. Default true
  /// (production: download on first use). Tests pass false for deterministic
  /// `unavailable` behavior without a network round-trip.
  final bool attemptManagedDownload;

  /// Capability id → live instance. One code-server per `(workspaceId,
  /// worktreePath)`; the key is the capability token.
  final Map<String, _CodeServerInstance> _instances = {};

  /// Reverse index: `(workspaceId, worktreePath)` → capability id, so a re-open
  /// reuses the running process instead of spawning a second one.
  final Map<String, String> _byWorktree = {};
  Timer? _gcTimer;
  final Random _rnd = Random.secure();

  /// Fans out bridge-extension "open this file as an app tab" reports to the
  /// `codeServer.watchOpenRequests` subscription. Broadcast so multiple clients
  /// (or the same client re-subscribing on reconnect) can listen.
  final StreamController<CodeServerOpenRequest> _openRequests =
      StreamController<CodeServerOpenRequest>.broadcast();

  /// Fans out bridge-extension "this file's dirty state changed" reports to the
  /// `codeServer.watchDirtyState` subscription. Broadcast for the same reason.
  final StreamController<CodeServerDirtyEvent> _dirtyEvents =
      StreamController<CodeServerDirtyEvent>.broadcast();

  /// Resolves `cc_server`'s own loopback base (`http://127.0.0.1:<rpcPort>`) so
  /// the bridge extension — which runs server-side in code-server's extension
  /// host — knows where to POST its reports. Set by the runtime AFTER the RPC
  /// server binds (the port isn't known when this service is constructed).
  Uri Function()? resolveProxyBase;

  /// The isolated-repo repository backing worktree lookups.
  IsolatedRepoRepository get isolatedRepos => _repos;

  /// Per-workspace user-data dir (`<dataRoot>/code-server/<workspaceId>`):
  /// code-server keeps its settings/keybindings/UI state here.
  String _userDataDir(String workspaceId) =>
      p.join(_dataRoot, 'code-server', workspaceId);

  /// SHARED extensions dir (`<dataRoot>/code-server/extensions`): an extension
  /// installs once per server, not per worktree, so re-opens are instant.
  String get _extensionsDir => p.join(_dataRoot, 'code-server', 'extensions');

  /// Seeds code-server User `settings.json`: trusted + editor-only chrome.
  ///
  /// Trust avoids language-server/tasks/debug prompts the embed cannot answer.
  /// Hides activity/status/tab/menu/chat chrome (app shell owns those); bridge
  /// closes side bars/panel on activation and editor focus. `showTabs: none` so
  /// navigation replaces the single editor (no competing VS Code tabs).
  /// [autoSave] written verbatim after sanitise; merges existing settings.
  Future<void> _ensureWorkbenchSettings(
    String workspaceId,
    String autoSave,
  ) async {
    final userDir = Directory(p.join(_userDataDir(workspaceId), 'User'));
    await userDir.create(recursive: true);
    final file = File(p.join(userDir.path, 'settings.json'));
    var settings = <String, dynamic>{};
    if (file.existsSync()) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          settings = decoded;
        }
      } catch (_) {
        // Corrupt / hand-edited — overwrite rather than fail the open.
      }
    }
    // Trust: open the worktree without Restricted Mode.
    settings['security.workspace.trust.enabled'] = false;
    settings['security.workspace.trust.startupPrompt'] = 'never';
    settings['security.workspace.trust.banner'] = 'never';
    settings['security.workspace.trust.emptyWindow'] = false;
    // Editor-only chrome: hide code-server's own shell parts that duplicate the
    // app's (tabs / activity / status / terminal-panel toggle / menus).
    settings['workbench.activityBar.location'] = 'hidden';
    settings['workbench.statusBar.visible'] = false;
    settings['workbench.editor.showTabs'] = 'none';
    settings['window.menuBarVisibility'] = 'hidden';
    settings['window.commandCenter'] = false;
    settings['workbench.layoutControl.enabled'] = false;
    settings['workbench.startupEditor'] = 'none';
    settings['workbench.tips.enabled'] = false;
    settings['workbench.editor.editorActionsLocation'] = 'hidden';
    settings['workbench.editor.emptyWindowText'] = 'none';
    settings['breadcrumbs.enabled'] = false;
    settings['explorer.autoReveal'] = false;
    settings['explorer.openEditors.visible'] = 0;
    settings['chat.showHomeChatButton'] = false;
    settings['chat.editing.alwaysShowCopilotBanner'] = false;
    // Chat toolbar: recent VS Code renders a standalone Copilot/Chat control in
    // the title bar that survives `window.commandCenter: false`. Disable it so
    // no chat toolbar appears in the embedded editor's chrome.
    settings['chat.commandCenter.enabled'] = false;
    // A new workspace opens the secondary side bar (chat) by default. Keep it
    // closed from the first paint instead of waiting for the bridge to close
    // it after the extension host activates.
    settings['workbench.secondarySideBar.defaultVisibility'] = 'hidden';

    // The app shell owns tabs: one editor window serves every app tab of the
    // worktree, and the bridge switches its file as tabs switch. Force
    // permanent (non-preview) opens so a go-to-definition / quick-open adds an
    // editor rather than REPLACING the one another app tab still shows.
    settings['workbench.editor.enablePreview'] = false;
    settings['workbench.editor.enablePreviewFromQuickOpen'] = false;

    // Silence IDE notifications the embedded editor can't sensibly act on:
    // extension-install recommendations ("do you want to install …"),
    // update/experiment prompts and telemetry. Anything actionable is surfaced
    // by the app shell, not code-server.
    settings['extensions.ignoreRecommendations'] = true;
    settings['extensions.autoCheckUpdates'] = false;
    settings['extensions.autoUpdate'] = false;
    settings['workbench.enableExperiments'] = false;
    settings['telemetry.telemetryLevel'] = 'off';
    settings['update.mode'] = 'none';
    settings['workbench.welcomePage.walkthroughs.openOnInstall'] = false;

    // Save behaviour: honour the client's auto-save preference (pushed on every
    // open). `hotExit: off` makes the app's Save / Don't-save tab-close dialog
    // authoritative — a "don't save" that disposes the editor window genuinely
    // drops the buffer instead of code-server silently restoring it on reopen.
    settings['files.autoSave'] = _sanitizeAutoSave(autoSave);
    settings['files.autoSaveDelay'] = 1000;
    settings['files.hotExit'] = 'off';

    // Gutter diff stays on. The bridge extension supplies the original
    // resource (git's own provider never matches this window's editor URIs).
    settings['scm.diffDecorations'] = 'all';
    settings['scm.diffDecorationsGutterVisibility'] = 'always';

    // Use the app's code font (Fira Code, with ligatures) so the embedded editor
    // matches the rest of the app; fall back to platform monospaces if the user
    // doesn't have Fira Code installed for the webview to pick up.
    const codeFont =
        "'Fira Code', 'Fira Code VF', 'FiraCode Nerd Font', ui-monospace, "
        'SFMono-Regular, Menlo, Consolas, monospace';
    settings['editor.fontFamily'] = codeFont;
    settings['editor.fontLigatures'] = true;
    settings['terminal.integrated.fontFamily'] = codeFont;
    settings['chat.editor.fontFamily'] = codeFont;

    // Follow the OS/app appearance (light ↔ dark) instead of a fixed theme and
    // tint both base themes with Control Center's palette: warm near-white /
    // ink-black surfaces, warm borders and the single orange accent
    // (brand500 #FB6224). autoDetectColorScheme picks light/dark from the
    // webview's `prefers-color-scheme`, which tracks the OS appearance.
    settings['window.autoDetectColorScheme'] = true;
    settings['workbench.preferredLightColorTheme'] = 'Default Light Modern';
    settings['workbench.preferredDarkColorTheme'] = 'Default Dark Modern';
    const accent = '#FB6224'; // brand500
    const accentHover = '#FA500F'; // brand600
    settings['workbench.colorCustomizations'] = <String, dynamic>{
      // Accent-driven chrome (applies in both light and dark).
      'focusBorder': accent,
      'editorCursor.foreground': accent,
      'progressBar.background': accent,
      'button.background': accent,
      'button.hoverBackground': accentHover,
      'button.foreground': '#FFFFFF',
      'activityBarBadge.background': accent,
      'textLink.foreground': accentHover,
      'textLink.activeForeground': accent,
      'editorLink.activeForeground': accent,
      'selection.background': '#FB622455',
      // Light: warm near-white surfaces (gray25/50/100), warm borders (gray200),
      // ink text (gray900), muted line numbers (gray400).
      '[Default Light Modern]': <String, dynamic>{
        'editor.background': '#FDFCFA',
        'editor.foreground': '#1F1F1F',
        'editorGutter.background': '#FDFCFA',
        'editorLineNumber.foreground': '#B8B2A4',
        'editorLineNumber.activeForeground': '#3D3D3D',
        'editor.lineHighlightBackground': '#F2F0E9',
        'editor.selectionBackground': '#FDDDD2',
        'editor.selectionHighlightBackground': '#FEEFEA',
        'editorWidget.background': '#FCFBF9',
        'editorHoverWidget.background': '#FCFBF9',
        'editorGroupHeader.tabsBackground': '#FCFBF9',
        'editorGroup.border': '#E8E5DC',
        'sideBar.background': '#FCFBF9',
        'sideBar.border': '#E8E5DC',
        'panel.background': '#FCFBF9',
        'panel.border': '#E8E5DC',
        'terminal.background': '#FDFCFA',
        'terminal.foreground': '#1F1F1F',
        'input.background': '#FFFFFF',
        'input.border': '#E8E5DC',
        'scrollbarSlider.background': '#D8D3C680',
      },
      // Dark: ink-black surfaces (gray950/900/800), warm-neutral borders,
      // near-white text (gray100).
      '[Default Dark Modern]': <String, dynamic>{
        'editor.background': '#171614',
        'editor.foreground': '#F2F0E9',
        'editorGutter.background': '#171614',
        'editorLineNumber.foreground': '#3D3D3D',
        'editorLineNumber.activeForeground': '#B8B2A4',
        'editor.lineHighlightBackground': '#1F1F1F',
        'editor.selectionBackground': '#7A280966',
        'editor.selectionHighlightBackground': '#7A280940',
        'editorWidget.background': '#1F1F1F',
        'editorHoverWidget.background': '#1F1F1F',
        'editorGroupHeader.tabsBackground': '#1F1F1F',
        'editorGroup.border': '#2C2C2A',
        'sideBar.background': '#1F1F1F',
        'sideBar.border': '#2C2C2A',
        'panel.background': '#1F1F1F',
        'panel.border': '#2C2C2A',
        'terminal.background': '#171614',
        'terminal.foreground': '#F2F0E9',
        'input.background': '#262522',
        'input.border': '#2C2C2A',
        'scrollbarSlider.background': '#3D3D3D80',
      },
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(settings),
    );
  }

  /// Clamps a client-supplied auto-save preference to a valid VS Code
  /// `files.autoSave` value, defaulting to `'afterDelay'` for anything else —
  /// never writes an arbitrary string into `settings.json`.
  static String _sanitizeAutoSave(String value) {
    const allowed = {'off', 'afterDelay', 'onFocusChange', 'onWindowChange'};
    return allowed.contains(value) ? value : 'afterDelay';
  }

  /// Vendored code-server archive extract dir
  /// (`<dataRoot>/code-server/<platform>`): the on-demand managed install
  /// location, holding the stripped archive (`bin/code-server`, `lib/…`).
  String get _managedBinDir => p.join(_dataRoot, 'code-server', _platformTag);

  /// Bundle-relative vendored dir
  /// (`<cc_server.exe>/code-server/<platform>`): the CI package script stages
  /// the standalone archive here so a bundled server is offline-first
  /// regardless of the user's `--data-dir`.
  String? get _bundledBinDir {
    final exe = Platform.resolvedExecutable;
    if (exe.isEmpty) {
      return null;
    }
    return p.join(p.dirname(exe), 'code-server', _platformTag);
  }

  /// Platform/arch tag for the vendored standalone archive directory. Dart's
  /// `Platform` has no stable arch getter, so the arch is read from the OS
  /// (`uname -m` equivalent) lazily; defaults to x64 when it cannot be read.
  String get _platformTag {
    final os = Platform.isMacOS
        ? 'darwin'
        : Platform.isLinux
        ? 'linux'
        : 'unsupported';
    return '$os-${_hostArch()}';
  }

  String _hostArch() {
    // code-server ships no native Windows host; the Windows-local case is
    // WSL/remote-only.
    if (Platform.isWindows) {
      return 'unsupported';
    }
    try {
      // Synchronous, runs once per probe; cheap enough for an open-editor path.
      final result = Process.runSync('uname', ['-m']);
      if (result.exitCode == 0) {
        final out = (result.stdout as String).trim().toLowerCase();
        if (out.contains('arm64') || out.contains('aarch64')) {
          return 'arm64';
        }
        if (out.contains('x86_64') || out.contains('amd64')) {
          return 'x64';
        }
      }
    } catch (_) {
      // Arch probe is best-effort; default to x64 below.
    }
    return 'x64';
  }

  @override
  Future<CodeServerSession> ensureSession({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String deviceId,
    String? path,
    String autoSave = 'afterDelay',
  }) async {
    // Resolve the conversation's isolated CoW worktree. Foreign ids / a repo
    // not yet provisioned for this conversation → no worktree → no session.
    // NEVER fall back to a raw checkout (would bypass the CoW isolation).
    //
    // An empty [repoId] means "the conversation's editor" without naming a
    // specific repo (the ⌘T full editor). Resolve it to the space's first
    // provisioned worktree rather than requiring the caller to know the repo id
    // — still workspace+space scoped, so no cross-workspace leak.
    IsolatedRepo? worktree;
    if (repoId.isNotEmpty) {
      worktree = await _repos.forUnitRepo(workspaceId, spaceId, repoId);
    } else {
      final all = await _repos.forSpace(workspaceId, spaceId);
      worktree = all.isEmpty ? null : all.first;
    }
    if (worktree == null) {
      throw StateError(
        'No isolated worktree for this conversation — open the channel first.',
      );
    }
    // The registry row can outlive the directory on disk (a worktree GC'd on
    // conversation/PR end, or a provisioning that never materialized). Spawning
    // code-server with a missing `workingDirectory` throws an opaque
    // `ProcessException: No such file or directory` that looks like the binary
    // is gone — so validate the worktree exists and fail with an actionable
    // message instead. Re-provisioning belongs to the space-open path (never a
    // raw checkout here — that would bypass the CoW isolation).
    if (!Directory(worktree.path).existsSync()) {
      throw StateError(
        'The isolated worktree for this conversation is missing on disk '
        '(${worktree.path}) — reopen the channel (or re-add the repo) to '
        're-provision it before opening the editor.',
      );
    }

    final key = '${worktree.workspaceId}\x1f${worktree.path}';

    // Seed / refresh the workbench settings on EVERY open (including a reuse
    // below) so a changed client preference — chiefly auto-save — applies to an
    // already-running instance: VS Code hot-reloads User `settings.json`. Cheap,
    // idempotent write of a small file; requires the user-data dir to exist.
    await Directory(_userDataDir(workspaceId)).create(recursive: true);
    // Open the worktree TRUSTED (no VS Code "Restricted Mode"), else the
    // language server + tasks are gated behind a trust prompt the embedded
    // editor can't sensibly answer.
    await _ensureWorkbenchSettings(workspaceId, autoSave);

    // Reuse a running instance for the same worktree (one code-server per
    // worktree, shared across tabs).
    final existingId = _byWorktree[key];
    if (existingId != null) {
      final instance = _instances[existingId];
      if (instance != null && instance.process.pid > 0) {
        instance.refCount++;
        return _sessionFor(instance, deviceId, path);
      }
    }

    final binary = await _resolveBinary();
    if (binary == null) {
      // No code-server on this host. Return an unavailable session so the
      // client can render guidance rather than spin forever. The capability is
      // not entered into the proxy table (no port → nothing to proxy).
      return CodeServerSession(
        sessionId: _mintCapability(),
        workspaceId: workspaceId,
        port: 0,
        folderPath: worktree.path,
        deviceId: deviceId,
        expiresAt: DateTime.now().add(_sessionTtl),
        status: CodeServerStatus.unavailable,
      );
    }

    await Directory(_extensionsDir).create(recursive: true);

    // Pre-provision the curated language extensions (the one-LSP milestone) so
    // the embedded editor ships Dart completions/diagnostics/hover out of the
    // box. Best-effort + cached under --extensions-dir; runs once per server.
    await _ensureCuratedExtensions();

    // The bundled bridge extension turns in-editor navigation (cmd-click "go to
    // definition", Explorer opens) into app-tab open requests, keeping each
    // editor window pinned on its entry file. Best-effort.
    await _ensureBridgeExtension(binary);

    // Deep-link the clicked file as a second positional (VS Code opens the
    // folder as the workspace AND the file as an editor). Confined to the
    // worktree — a `..` path that escapes is dropped rather than opened.
    // NOTE: do NOT use `--open` for this — code-server's `--open` means "open in
    // the SYSTEM browser on startup", which popped a real browser window
    // alongside the embedded editor.
    String? fileArg;
    if (path != null && path.isNotEmpty) {
      final resolved = p.normalize(p.join(worktree.path, path));
      if (p.isWithin(worktree.path, resolved)) {
        fileArg = resolved;
      }
    }

    // Mint the capability BEFORE spawn so the bridge extension's report URL can
    // embed it (the extension POSTs back to `/proxy/vscode/<sid>/__cc_open__`,
    // authorized by the same capability the proxy checks).
    final capability = _mintCapability();

    // `--bind-addr 127.0.0.1:0` makes the kernel pick a free ephemeral port;
    // code-server prints the resolved URL (with the port) to stdout.
    final args = <String>[
      '--auth', 'none',
      '--disable-telemetry',
      '--disable-update-check',
      // Open the worktree TRUSTED (no Restricted Mode). Belt-and-suspenders with
      // the settings.json seed above: the flag is per-session, the setting is
      // global — neither a version quirk nor a stale setting re-gates the LSP.
      '--disable-workspace-trust',
      '--bind-addr', '127.0.0.1:0',
      '--user-data-dir', _userDataDir(workspaceId),
      '--extensions-dir', _extensionsDir,
      worktree.path,
      ?fileArg,
    ];
    // Generated port-forward links (forwarded server ports) resolve under the
    // proxy sub-path so they aren't broken by the prefix strip. `CC_IDE_*` tells
    // the bundled bridge extension where to POST its open-file reports (the
    // capability-scoped proxy endpoint on cc_server's own loopback base).
    final env = Map<String, String>.from(Platform.environment)
      ..['VSCODE_PROXY_URI'] = '/proxy/vscode/{{session}}/{{port}}/';
    final reportUrl = _bridgeReportUrl(capability);
    if (reportUrl != null) {
      env['CC_IDE_REPORT_URL'] = reportUrl;
    }
    // Reverse command space: the bridge extension opens this as an SSE stream
    // and executes the `{cmd, …}` events cc_server pushes (e.g. a Save-on-close
    // relayed by [saveFile]). Same capability-scoped proxy base as the report.
    final commandsUrl = _bridgeCommandsUrl(capability);
    if (commandsUrl != null) {
      env['CC_IDE_COMMANDS_URL'] = commandsUrl;
    }

    final process = await Process.start(
      binary,
      args,
      environment: env,
      workingDirectory: worktree.path,
    );
    final port = await _readEphemeralPort(process).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        throw TimeoutException('code-server did not report a port in time');
      },
    );

    final instance = _CodeServerInstance(
      capability: capability,
      workspaceId: workspaceId,
      spaceId: spaceId,
      // Use the RESOLVED worktree's repo id, never the (possibly empty) caller
      // arg: a `⌘T` open passes `repoId: ''` ("server picks the first
      // worktree"), but the open-report and dirty-report fan-outs must carry the
      // real repo id so the client can key them to the file tabs it opened with
      // that repo id (otherwise the dirty dot never matches).
      repoId: worktree.repoId,
      folderPath: worktree.path,
      port: port,
      process: process,
      refCount: 1,
      lastTouched: DateTime.now(),
    );
    _instances[capability] = instance;
    _byWorktree[key] = capability;
    _ensureGc();

    return _sessionFor(instance, deviceId, path);
  }

  @override
  Future<void> closeSession({
    required String workspaceId,
    required String sessionId,
  }) async {
    final instance = _instances[sessionId];
    if (instance == null) {
      return;
    }
    _assertOwned(instance, workspaceId);
    if (instance.refCount > 0) {
      instance.refCount--;
    }
    instance.lastTouched = DateTime.now();
    // The actual kill happens on the idle-GC sweep after [_idleGrace], so a
    // quick tab flicker / re-open reuses the warm process.
  }

  @override
  CodeServerSession? lookup(String sessionId) {
    final instance = _instances[sessionId];
    if (instance == null) {
      return null;
    }
    if (DateTime.now().isAfter(instance.expiresAt)) {
      return null;
    }
    return CodeServerSession(
      sessionId: instance.capability,
      workspaceId: instance.workspaceId,
      port: instance.port,
      folderPath: instance.folderPath,
      deviceId: '',
      expiresAt: instance.expiresAt,
      status: CodeServerStatus.ready,
    );
  }

  /// Pre-provisions code-server (download the pinned standalone archive) AND
  /// the curated language extensions, OFF the boot/ready path so the embedded
  /// editor is warm by the time a user opens a file — the first `ensureSession`
  /// then only spawns an already-installed binary. Idempotent + guarded by a
  /// lock so concurrent warm-ups (re-entry on boot) don't double-download.
  /// Failures are logged + non-fatal: a failed warm-up degrades to a lazy
  /// on-demand download on first open (or `unavailable` if that also fails).
  Future<void> warmUp() async {
    if (Platform.isWindows) {
      return; // no native Windows host
    }
    if (_warmupDone) {
      return;
    }
    if (_warmupInFlight != null) {
      return _warmupInFlight;
    }
    final completer = Completer<void>();
    _warmupInFlight = completer.future;
    try {
      final binary = await _resolveBinary();
      if (binary == null) {
        CcInfraLog.warning(
          'code-server warm-up: could not obtain the binary (download failed or '
          'host unsupported); the editor will try again on first open.',
        );
      } else {
        CcInfraLog.info('code-server warm-up ready: $binary');
        // Pre-provision the curated extensions so the one-LSP milestone ships
        // warm too (best-effort; logged internally).
        await _ensureCuratedExtensions();
        // Seed the bridge extension so in-editor navigation hands off to app
        // tabs from the first open.
        await _ensureBridgeExtension(binary);
      }
    } catch (e, st) {
      CcInfraLog.warning('code-server warm-up failed: $e\n$st');
    } finally {
      _warmupDone = true;
      _warmupInFlight = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  bool _warmupDone = false;
  Future<void>? _warmupInFlight;

  CodeServerSession _sessionFor(
    _CodeServerInstance instance,
    String deviceId,
    String? path,
  ) {
    return CodeServerSession(
      sessionId: instance.capability,
      workspaceId: instance.workspaceId,
      port: instance.port,
      folderPath: instance.folderPath,
      deviceId: deviceId,
      expiresAt: instance.expiresAt,
      status: CodeServerStatus.ready,
    );
  }

  void _assertOwned(_CodeServerInstance instance, String workspaceId) {
    if (instance.workspaceId != workspaceId) {
      // Deny loudly — never silently no-op (hides the bug) nor proceed (leaks).
      throw StateError('Code-server session belongs to a different workspace');
    }
  }

  /// Vendored path first (bundle-relative, then data-root managed dir), then
  /// PATH / install prefixes, then on-demand managed download. The binary lives
  /// at `<installDir>/bin/code-server` in every layout (the archive's stripped
  /// `bin/code-server`).
  Future<String?> _resolveBinary() async {
    if (Platform.isWindows) {
      // code-server ships no native Windows host. The Windows-local case is
      // WSL/remote-only; surface unavailable here.
      return null;
    }
    // 1. Bundle-relative vendored install (CI package script stages it here for
    //    offline-first bundled servers — survives regardless of --data-dir).
    if (_bundledBinDir case final bundled?) {
      final bin = p.join(bundled, 'bin', codeServerBinaryName);
      if (File(bin).existsSync()) {
        return bin;
      }
    }
    // 2. Data-root managed dir (on-demand download lands it here).
    final managed = p.join(_managedBinDir, 'bin', codeServerBinaryName);
    if (File(managed).existsSync()) {
      return managed;
    }
    // 3. On PATH (a developer machine with code-server installed).
    final onPath = await resolveBinaryPath(codeServerBinaryName);
    if (onPath != null) {
      return onPath;
    }
    // 4. Last resort: on-demand managed download of the pinned standalone
    //    archive (Node bundled; no source build). Keeps the base installer small
    //    while still working offline-first when the CI vendoring step
    //    pre-populated the managed dir. Returns null on failure → `unavailable`.
    //    Skipped when [attemptManagedDownload] is false (tests / offline-only).
    return attemptManagedDownload ? _ensureInstalled() : null;
  }

  /// Downloads + extracts the pinned code-server standalone archive into the
  /// managed bin dir (no source build). Returns the binary path, or null when
  /// the platform is unsupported / the download failed.
  Future<String?> _ensureInstalled() async {
    if (Platform.isWindows) {
      return null;
    }
    // Already installed by a previous call or the CI vendoring step.
    final managed = _managedBinaryPath;
    if (managed != null && File(managed).existsSync()) {
      return managed;
    }
    final archiveUrl = _codeServerArchiveUrl();
    if (archiveUrl == null) {
      return null;
    }
    CcInfraLog.info(
      'Started download code-server v$codeServerVersion → $archiveUrl',
    );
    final tmpDir = await Directory.systemTemp.createTemp('cc-code-server-');
    final tarball = File(p.join(tmpDir.path, 'code-server.tar.gz'));
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..userAgent = 'control-center-code-server-installer';
      var received = 0;
      try {
        final req = await client.getUrl(Uri.parse(archiveUrl));
        final resp = await req.close().timeout(const Duration(minutes: 5));
        if (resp.statusCode != 200) {
          CcInfraLog.warning(
            'code-server download failed: HTTP ${resp.statusCode} for $archiveUrl',
          );
          return null;
        }
        // Stream the archive (~100 MB) straight to disk — never buffer it in
        // memory — logging coarse progress (every ~25%) so the console shows the
        // download advancing instead of hanging silently.
        final total = resp.contentLength;
        final sink = tarball.openWrite();
        var nextThreshold = 0.25;
        try {
          await for (final chunk in resp) {
            sink.add(chunk);
            received += chunk.length;
            if (total > 0 && received / total >= nextThreshold) {
              CcInfraLog.info(
                'Downloading code-server… ${(received / total * 100).round()}% '
                '(${_mb(received)} / ${_mb(total)} MB)',
              );
              nextThreshold += 0.25;
            }
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
      } finally {
        client.close(force: true);
      }
      CcInfraLog.info(
        'Downloaded code-server v$codeServerVersion (${_mb(received)} MB)',
      );

      await Directory(_managedBinDir).create(recursive: true);
      CcInfraLog.info('Extracting code-server → $_managedBinDir');
      // Extract with the SYSTEM `tar`, which preserves Unix modes exactly. The
      // in-memory `archive` package drops the executable bit on some entries
      // (notably the ~120 MB bundled `lib/node`), which then fails to exec with
      // "Permission denied" — code-server's `bin/code-server` wrapper execs
      // `lib/node`, so it dies before binding a port. `tar` is guaranteed on
      // macOS/Linux (the only hosts code-server runs on) and also streams from
      // disk. `--strip-components=1` drops the archive's top-level
      // `code-server-<version>-<os>-<arch>/` dir so `bin/code-server` + `lib/…`
      // land directly in the managed dir.
      final res = await Process.run('tar', [
        '-xzf',
        tarball.path,
        '-C',
        _managedBinDir,
        '--strip-components=1',
      ]);
      if (res.exitCode != 0) {
        CcInfraLog.warning(
          'code-server extract (tar) failed: exit ${res.exitCode}: ${res.stderr}',
        );
        return null;
      }
      final bin = p.join(_managedBinDir, 'bin', codeServerBinaryName);
      if (!File(bin).existsSync()) {
        CcInfraLog.warning(
          'code-server extracted but no `bin/code-server` at $bin — archive '
          'layout may have changed.',
        );
        return null;
      }
      // Belt-and-suspenders: guarantee the launch-critical executables even if a
      // future extraction/copy step drops their bit. The wrapper execs `lib/node`.
      _forceExecutable(bin);
      _forceExecutable(p.join(_managedBinDir, 'lib', 'node'));
      CcInfraLog.info('code-server v$codeServerVersion ready at $bin');
      return bin;
    } catch (e, st) {
      CcInfraLog.warning('code-server download/extract failed: $e\n$st');
      return null;
    } finally {
      try {
        await tmpDir.delete(recursive: true);
      } catch (e) {
        CcInfraLog.warning('code-server: temp dir cleanup failed: $e');
      }
    }
  }

  /// The resolved managed binary path (or null on an unsupported platform),
  /// i.e. `<managedBinDir>/bin/code-server`.
  String? get _managedBinaryPath => Platform.isWindows
      ? null
      : p.join(_managedBinDir, 'bin', codeServerBinaryName);

  /// Force-marks [path] executable (0755). dart:io's `File` has no chmod, so
  /// shell out. Best-effort: warns on failure, no-ops when the file is absent.
  /// Used to guarantee the code-server launcher (`bin/code-server`) and the
  /// bundled Node (`lib/node`) it execs keep their executable bit.
  void _forceExecutable(String path) {
    if (!File(path).existsSync()) {
      return;
    }
    try {
      final r = Process.runSync('chmod', ['755', path]);
      if (r.exitCode != 0) {
        CcInfraLog.warning('chmod 755 $path failed (exit ${r.exitCode}).');
      }
    } catch (e) {
      CcInfraLog.warning('chmod 755 $path failed: $e.');
    }
  }

  /// Bytes → megabytes, 1 decimal, for the download-progress console logs.
  static String _mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);

  /// The platform's pinned code-server standalone archive URL, or null on an
  /// unsupported host (Windows — code-server ships no native build there).
  String? _codeServerArchiveUrl() {
    if (Platform.isWindows) {
      return null;
    }
    final os = Platform.isMacOS ? 'macos' : 'linux';
    final archTag = _hostArch() == 'arm64' ? 'arm64' : 'amd64';
    return 'https://github.com/coder/code-server/releases/download/'
        'v$codeServerVersion/code-server-$codeServerVersion-$os-$archTag.tar.gz';
  }

  /// Ensures every curated extension in [codeServerCuratedExtensions] is
  /// extracted into the shared `--extensions-dir`, downloading the VSIX from
  /// Open VSX on first use. This is the "one LSP milestone": the Dart extension
  /// is pre-provisioned so completions, diagnostics and hover demonstrably
  /// work against the worktree the moment a `.dart` file opens. Best-effort — a
  /// failed fetch degrades to a code-server with no curated LSP (the user can
  /// still install extensions from the in-editor marketplace).
  Future<void> _ensureCuratedExtensions() async {
    await Directory(_extensionsDir).create(recursive: true);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..userAgent = 'control-center-code-server-installer';
    try {
      for (final ext in codeServerCuratedExtensions) {
        // code-server extracts a VSIX into <dir>/<publisher>.<name>-<version>/.
        final dest = p.join(
          _extensionsDir,
          '${ext.publisher}.${ext.name}-${ext.version}',
        );
        if (Directory(dest).existsSync()) {
          continue;
        }
        final url =
            'https://open-vsx.org/api/${ext.publisher}/${ext.name}/'
            '${ext.version}/file/${ext.publisher}.${ext.name}-${ext.version}.vsix';
        CcInfraLog.info(
          'Downloading editor extension ${ext.publisher}.${ext.name} '
          'v${ext.version}…',
        );
        try {
          final req = await client.getUrl(Uri.parse(url));
          final resp = await req.close().timeout(const Duration(minutes: 3));
          if (resp.statusCode != 200) {
            CcInfraLog.warning(
              'Curated extension ${ext.publisher}.${ext.name} fetch failed '
              '(HTTP ${resp.statusCode}); the editor will lack this LSP.',
            );
            continue;
          }
          final buf = BytesBuilder();
          await for (final chunk in resp) {
            buf.add(chunk);
          }
          // A VSIX is a zip; extract its `extension/` payload into dest.
          final archive = arch.ZipDecoder().decodeBytes(buf.takeBytes());
          await Directory(dest).create(recursive: true);
          for (final file in archive) {
            final rel = file.name.startsWith('extension/')
                ? file.name.substring('extension/'.length)
                : file.name;
            if (rel.isEmpty) {
              continue;
            }
            final out = p.join(dest, rel);
            if (file.isFile) {
              await Directory(p.dirname(out)).create(recursive: true);
              await File(out).writeAsBytes(file.content as List<int>);
            } else {
              await Directory(out).create(recursive: true);
            }
          }
          CcInfraLog.info(
            'Pre-provisioned extension ${ext.publisher}.${ext.name}-'
            '${ext.version} for the embedded editor.',
          );
        } catch (e) {
          CcInfraLog.warning(
            'Curated extension ${ext.publisher}.${ext.name} install failed: $e; '
            'the editor will lack this LSP.',
          );
        }
      }
    } finally {
      client.close(force: true);
    }
  }

  @override
  Stream<CodeServerOpenRequest> watchOpenRequests(String workspaceId) =>
      _openRequests.stream.where((r) => r.workspaceId == workspaceId);

  @override
  void reportOpen({
    required String sessionId,
    required String absPath,
    int? line,
    String? windowId,
  }) {
    final instance = _instances[sessionId];
    if (instance == null) {
      return; // unknown / expired capability → ignore.
    }
    // Confine to the worktree; a report for a path outside it (e.g. an
    // out-of-tree definition target) is ignored rather than opened.
    final normalized = p.normalize(absPath);
    if (!p.equals(instance.folderPath, normalized) &&
        !p.isWithin(instance.folderPath, normalized)) {
      return;
    }
    final rel = p.relative(normalized, from: instance.folderPath);
    if (rel.isEmpty || rel == '.') {
      return;
    }
    _openRequests.add(
      CodeServerOpenRequest(
        workspaceId: instance.workspaceId,
        spaceId: instance.spaceId,
        repoId: instance.repoId,
        path: rel,
        line: line,
        windowId: windowId,
      ),
    );
  }

  @override
  Stream<CodeServerDirtyEvent> watchDirtyState(String workspaceId) =>
      _dirtyEvents.stream.where((e) => e.workspaceId == workspaceId);

  @override
  void reportDirty({
    required String sessionId,
    required String absPath,
    required bool dirty,
  }) {
    final instance = _instances[sessionId];
    if (instance == null) {
      return; // unknown / expired capability → ignore.
    }
    // Confine to the worktree (same guard as [reportOpen]): a report for a path
    // outside it is ignored rather than surfaced.
    final normalized = p.normalize(absPath);
    if (!p.equals(instance.folderPath, normalized) &&
        !p.isWithin(instance.folderPath, normalized)) {
      return;
    }
    final rel = p.relative(normalized, from: instance.folderPath);
    if (rel.isEmpty || rel == '.') {
      return;
    }
    _dirtyEvents.add(
      CodeServerDirtyEvent(
        workspaceId: instance.workspaceId,
        spaceId: instance.spaceId,
        repoId: instance.repoId,
        path: rel,
        dirty: dirty,
      ),
    );
  }

  @override
  Stream<Map<String, Object?>> commandStream(String sessionId) {
    final instance = _instances[sessionId];
    if (instance == null) {
      return const Stream<Map<String, Object?>>.empty();
    }
    return instance.commands.stream;
  }

  /// The running code-server for the conversation's worktree, keyed the same
  /// way [ensureSession] keys instances. Null when the worktree doesn't resolve
  /// or no instance is running for it.
  Future<_CodeServerInstance?> _runningInstance({
    required String workspaceId,
    required String spaceId,
    required String repoId,
  }) async {
    IsolatedRepo? worktree;
    if (repoId.isNotEmpty) {
      worktree = await _repos.forUnitRepo(workspaceId, spaceId, repoId);
    } else {
      final all = await _repos.forSpace(workspaceId, spaceId);
      worktree = all.isEmpty ? null : all.first;
    }
    if (worktree == null) {
      return null;
    }
    final key = '${worktree.workspaceId}\x1f${worktree.path}';
    final capability = _byWorktree[key];
    final instance = capability == null ? null : _instances[capability];
    if (instance == null || instance.process.pid <= 0) {
      return null;
    }
    // Cross-workspace guard: the resolved worktree is workspace-scoped, but
    // assert the instance too (defence in depth against a stale reverse index).
    _assertOwned(instance, workspaceId);
    return instance;
  }

  /// [path] resolved against [instance]'s worktree as the ABSOLUTE path the
  /// bridge matches on (`TextDocument.uri.fsPath`), or null when it escapes the
  /// worktree.
  String? _confinedPath(_CodeServerInstance instance, String path) {
    final abs = p.normalize(p.join(instance.folderPath, path));
    if (!p.equals(instance.folderPath, abs) &&
        !p.isWithin(instance.folderPath, abs)) {
      return null;
    }
    return abs;
  }

  @override
  Future<bool> openFile({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String windowId,
    required String path,
    int? line,
  }) async {
    final instance = await _runningInstance(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
    );
    final abs = instance == null ? null : _confinedPath(instance, path);
    if (instance == null || abs == null || windowId.isEmpty) {
      return false;
    }
    instance.commands.add({
      'cmd': 'open',
      'window': windowId,
      'path': abs,
      if (line != null && line > 0) 'line': line,
    });
    return true;
  }

  @override
  Future<bool> closeFile({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String path,
    bool revert = false,
  }) async {
    final instance = await _runningInstance(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
    );
    final abs = instance == null ? null : _confinedPath(instance, path);
    if (instance == null || abs == null) {
      return false;
    }
    instance.commands.add({'cmd': 'close', 'path': abs, 'revert': revert});
    return true;
  }

  @override
  Future<bool> saveFile({
    required String workspaceId,
    required String spaceId,
    required String repoId,
    required String path,
  }) async {
    // No running instance → nothing to save.
    final instance = await _runningInstance(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
    );
    final abs = instance == null ? null : _confinedPath(instance, path);
    if (instance == null || abs == null) {
      return false;
    }

    // The extension acks by reporting the file clean; wait for that (bounded) so
    // the caller can close the tab only once the write has landed. Subscribe
    // BEFORE pushing the command to avoid missing a fast ack.
    final rel = p.relative(abs, from: instance.folderPath);
    final ack = _dirtyEvents.stream
        .firstWhere(
          (e) => e.spaceId == instance.spaceId && e.path == rel && !e.dirty,
        )
        .then((_) => true)
        // The stream closes on service teardown before a match → best-effort
        // true rather than a thrown StateError propagating out of saveFile.
        .catchError((_) => true);
    instance.commands.add({'cmd': 'save', 'path': abs});
    return ack.timeout(
      const Duration(seconds: 3),
      // Timeout is not a failure to write — the extension may have no listener
      // attached yet, or the file was already clean. Report best-effort success
      // so the close proceeds; a genuinely failed write is vanishingly rare on a
      // loopback save and would surface as a still-dirty dot.
      onTimeout: () => true,
    );
  }

  /// The capability-scoped URL the bridge extension POSTs open-file reports to
  /// (`<cc_server loopback base>/proxy/vscode/<sid>/__cc_open__`). Null when the
  /// runtime has not wired [resolveProxyBase] yet — the bridge then simply stays
  /// dormant (the editor still works, it just won't hand off in-editor opens).
  String? _bridgeReportUrl(String capability) {
    final base = resolveProxyBase?.call();
    if (base == null) {
      return null;
    }
    return base.resolve('/proxy/vscode/$capability/__cc_open__').toString();
  }

  /// The capability-scoped URL the bridge extension opens as an SSE stream to
  /// receive reverse commands (`/proxy/vscode/<sid>/__cc_commands__`). Null when
  /// [resolveProxyBase] is not wired yet (the bridge stays dormant on commands).
  String? _bridgeCommandsUrl(String capability) {
    final base = resolveProxyBase?.call();
    if (base == null) {
      return null;
    }
    return base.resolve('/proxy/vscode/$capability/__cc_commands__').toString();
  }

  /// Installs the bundled bridge extension so code-server actually LOADS it.
  ///
  /// Dropping a folder into `--extensions-dir` is NOT enough — code-server (VS
  /// Code ≥1.9x) only loads extensions listed in
  /// `<extensions-dir>/extensions.json`, the installed-extensions manifest that
  /// `--install-extension`
  /// maintains. So we package the extension as a `.vsix` and install it via the
  /// code-server CLI, which registers it with the correct metadata. Idempotent:
  /// skipped once the manifest lists our current version. Best-effort.
  Future<void> _ensureBridgeExtension(String binary) async {
    try {
      if (await _bridgeExtensionRegistered()) {
        return;
      }
      _pruneOldBridgeDirs();
      final vsix = await _buildBridgeVsix();
      try {
        final res = await Process.run(binary, [
          '--install-extension',
          vsix.path,
          '--extensions-dir',
          _extensionsDir,
          '--user-data-dir',
          p.join(_dataRoot, 'code-server', '_install'),
          '--force',
        ]);
        if (res.exitCode != 0) {
          CcInfraLog.warning(
            'code-server bridge extension install failed (exit '
            '${res.exitCode}): ${res.stderr}; in-editor navigation will not '
            'hand off to app tabs.',
          );
        } else {
          CcInfraLog.info('code-server bridge extension installed.');
        }
      } finally {
        try {
          await vsix.parent.delete(recursive: true);
        } catch (e) {
          CcInfraLog.warning('code-server: vsix temp cleanup failed: $e');
        }
      }
    } catch (e) {
      CcInfraLog.warning(
        'code-server bridge extension install error: $e; in-editor navigation '
        "won't hand off to app tabs.",
      );
    }
  }

  /// Whether the installed-extensions manifest already lists our bridge at the
  /// current [codeServerBridgeExtensionVersion]. code-server rewrites this file
  /// on every install, so it is the source of truth for "will it load".
  Future<bool> _bridgeExtensionRegistered() async {
    try {
      final manifest = File(p.join(_extensionsDir, 'extensions.json'));
      if (!manifest.existsSync()) {
        return false;
      }
      final decoded = jsonDecode(await manifest.readAsString());
      if (decoded is! List) {
        return false;
      }
      for (final entry in decoded) {
        if (entry is Map &&
            entry['identifier'] is Map &&
            (entry['identifier'] as Map)['id'] ==
                'control-center.cc-ide-bridge' &&
            entry['version'] == codeServerBridgeExtensionVersion) {
          return true;
        }
      }
    } catch (e) {
      CcInfraLog.warning(
        'code-server: failed to read installed extensions: $e',
      );
    }
    return false;
  }

  /// Removes stale unpacked bridge dirs (any version) so a re-install is clean.
  void _pruneOldBridgeDirs() {
    final extDir = Directory(_extensionsDir);
    if (!extDir.existsSync()) {
      return;
    }
    for (final entry in extDir.listSync()) {
      final name = p.basename(entry.path);
      if (entry is Directory &&
          name.startsWith('control-center.cc-ide-bridge-')) {
        try {
          entry.deleteSync(recursive: true);
        } catch (e) {
          CcInfraLog.warning(
            'code-server: stale bridge-ext cleanup failed: $e',
          );
        }
      }
    }
  }

  /// Packages the bridge extension as a `.vsix` (an OPC/ZIP package) in a fresh
  /// temp dir and returns the file. The caller installs it via the code-server
  /// CLI and deletes the temp dir.
  Future<File> _buildBridgeVsix() async {
    final tmp = await Directory.systemTemp.createTemp('cc-ide-bridge-vsix-');
    final archive = arch.Archive()
      ..addFile(
        _vsixEntry('extension.vsixmanifest', codeServerBridgeVsixManifest),
      )
      ..addFile(
        _vsixEntry('[Content_Types].xml', codeServerBridgeVsixContentTypes),
      )
      ..addFile(
        _vsixEntry(
          'extension/package.json',
          codeServerBridgeExtensionPackageJson,
        ),
      )
      ..addFile(
        _vsixEntry('extension/extension.js', codeServerBridgeExtensionSource),
      );
    final bytes = arch.ZipEncoder().encode(archive);
    final vsix = File(p.join(tmp.path, 'cc-ide-bridge.vsix'));
    await vsix.writeAsBytes(bytes);
    return vsix;
  }

  arch.ArchiveFile _vsixEntry(String name, String content) {
    final bytes = utf8.encode(content);
    return arch.ArchiveFile(name, bytes.length, bytes);
  }

  /// Parses the ephemeral port code-server bound from its startup stdout
  /// (`HTTP server listening on http://127.0.0.1:<port>`).
  ///
  /// Both stdout and stderr are drained for the process's whole life (tails
  /// capped) so its pipes never fill and block it. If the process exits before a
  /// port appears, the error carries the captured stderr/stdout + exit code —
  /// so a startup crash (e.g. `lib/node: Permission denied`) is self-diagnosing
  /// instead of an opaque "exited before binding a port".
  Future<int> _readEphemeralPort(Process process) async {
    final completer = Completer<int>();
    final stderrTail = <String>[];
    final stdoutTail = <String>[];
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (stdoutTail.length < 20) {
              stdoutTail.add(line);
            }
            if (completer.isCompleted) {
              return;
            }
            // code-server prints: "HTTP server listening on http://127.0.0.1:8080"
            final m = _portLine.firstMatch(line);
            if (m != null) {
              final port = int.tryParse(m.group(1)!);
              if (port != null) {
                completer.complete(port);
              }
            }
          },
          onError: (Object e) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
          },
        );
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (stderrTail.length < 20) {
            stderrTail.add(line);
          }
        });
    unawaited(
      process.exitCode.then((code) {
        if (completer.isCompleted) {
          return;
        }
        final detail = [
          if (stderrTail.isNotEmpty) 'stderr: ${stderrTail.join(' | ')}',
          if (stdoutTail.isNotEmpty) 'stdout: ${stdoutTail.join(' | ')}',
        ].join('; ');
        completer.completeError(
          StateError(
            'code-server exited (code $code) before binding a port'
            '${detail.isEmpty ? '' : ' — $detail'}',
          ),
        );
      }),
    );
    return completer.future;
  }

  /// High-entropy, unguessable capability token (32 bytes, base64url). Authorizes
  /// the proxy; never derived from public inputs.
  String _mintCapability() {
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => _rnd.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  void _ensureGc() {
    if (_gcTimer != null) {
      return;
    }
    _gcTimer = Timer.periodic(const Duration(minutes: 1), (_) => _sweep());
  }

  /// Reaps expired capabilities and idle processes (no open references past the
  /// grace window). Keeps a warm process around for quick re-opens.
  void _sweep() {
    final now = DateTime.now();
    final dead = <String>[];
    _instances.forEach((capability, instance) {
      final expired = now.isAfter(instance.expiresAt);
      final idle =
          instance.refCount <= 0 &&
          now.difference(instance.lastTouched) > _idleGrace;
      if (expired || idle) {
        dead.add(capability);
      }
    });
    for (final capability in dead) {
      _killAndRemove(capability);
    }
    if (_instances.isEmpty) {
      _gcTimer?.cancel();
      _gcTimer = null;
    }
  }

  void _killAndRemove(String capability) {
    final instance = _instances.remove(capability);
    if (instance == null) {
      return;
    }
    final key = '${instance.workspaceId}\x1f${instance.folderPath}';
    if (_byWorktree[key] == capability) {
      _byWorktree.remove(key);
    }
    // Close the reverse command space so any live SSE handler ends cleanly.
    unawaited(instance.commands.close());
    try {
      instance.process.kill(ProcessSignal.sigterm);
    } catch (_) {
      // Process already exited — nothing to signal.
    }
    // Hard-kill shortly after if it hasn't exited.
    Timer(const Duration(seconds: 3), () {
      try {
        instance.process.kill(ProcessSignal.sigkill);
      } catch (_) {
        // Process already exited — nothing to signal.
      }
    });
  }

  /// Tears down every live code-server process (host shutdown).
  Future<void> disposeAll() async {
    _gcTimer?.cancel();
    _gcTimer = null;
    final capabilities = _instances.keys.toList();
    for (final capability in capabilities) {
      final instance = _instances[capability];
      if (instance == null) {
        continue;
      }
      try {
        instance.process.kill(ProcessSignal.sigterm);
      } catch (_) {
        // Process already exited — nothing to signal.
      }
      unawaited(instance.commands.close());
    }
    _instances.clear();
    _byWorktree.clear();
    await _openRequests.close();
    await _dirtyEvents.close();
  }
}

/// One running code-server process + its bookkeeping. NOT exposed via the port.
class _CodeServerInstance {
  _CodeServerInstance({
    required this.capability,
    required this.workspaceId,
    required this.spaceId,
    required this.repoId,
    required this.folderPath,
    required this.port,
    required this.process,
    required this.refCount,
    required this.lastTouched,
  }) : expiresAt = DateTime.now().add(_sessionTtl);

  final String capability;
  final String workspaceId;

  /// The conversation this worktree belongs to — carried on bridge open-reports
  /// so the client can scope them to the right IDE surface.
  final String spaceId;

  /// The repo whose worktree this is (may be empty when the server picked the
  /// conversation's first linked worktree).
  final String repoId;
  final String folderPath;
  final int port;
  final Process process;
  int refCount;
  DateTime lastTouched;
  final DateTime expiresAt;

  /// Reverse command space to the bridge extension: `{cmd, …}` maps the proxy
  /// relays over this session's `/__cc_commands__` SSE endpoint (e.g. a `save`
  /// pushed by [CodeServerService.saveFile]). Broadcast so the SSE handler can
  /// (re)subscribe on the extension's reconnect without losing the controller.
  /// Closed by the owning [CodeServerService] in `_killAndRemove` / `disposeAll`.
  // ignore: close_sinks
  final StreamController<Map<String, Object?>> commands =
      StreamController<Map<String, Object?>>.broadcast();
}

/// Matches `http://127.0.0.1:<port>` in code-server's startup banner.
final RegExp _portLine = RegExp(r'127\.0\.0\.1:(\d{2,5})');
