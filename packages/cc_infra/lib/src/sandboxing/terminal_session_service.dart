import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart'
    show
        AuthException,
        NotFoundException,
        ValidationException,
        WorkspaceMismatchException;
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_command_buffer.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/rig_port_service.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/terminal_foreground_title.dart';
import 'package:cc_natives/cc_natives.dart' show Pty;
import 'package:path/path.dart' as p;

/// Session-id prefix that keeps a terminal's sandbox session distinct from the
/// agent's sandbox session in the same conversation. Mirrors the desktop copy
/// in `lib/features/sandboxing/data/services/sandbox_terminal_pty.dart`; the two
/// stay in sync until the thin-client flip (Phase 5) deletes the desktop one.
const String terminalSandboxSessionPrefix = 'term-';

/// A shell inside an enclosed VM: how to open it, and how to say it is closed.
///
/// `release` is what keeps the VM alive for as long as the terminal is open.
/// The rig service measures idleness from the last ACTION it saw, and a
/// terminal's keystrokes never reach it — they go down an SSH connection.
/// Without this the machine parks mid-keystroke and is destroyed, with the
/// user's uncommitted work in it, while they are still typing.
typedef TerminalVmShell = ({List<String> argv, void Function() release});

/// Resolves the shell that opens inside the conversation's enclosed VM,
/// booting one on demand when there is none yet.
///
/// A function rather than a port so `cc_infra`'s terminal service does not
/// depend on the rig service: the composition root supplies it, and a host
/// with no rig support simply passes null, which is what makes `microvm`
/// probe-gated instead of a runtime surprise. Returns null when a VM could
/// not be provided; the caller then fails loudly rather than silently running
/// the shell on the host.
typedef TerminalVmShellResolver =
    Future<TerminalVmShell?> Function({
      required String workspaceId,
      String? conversationId,
      String? worktreePath,
      String? actingUserId,
    });

/// The host directories a workspace's enclosed terminal may be rooted in.
///
/// Supplied by the composition root (the workspace's own directory tree plus
/// its registered repo checkouts) because `cc_infra`'s terminal service has no
/// repo registry of its own. An empty list confines the terminal to whatever
/// [WorkspaceFilesystemPort] already resolves, which is always safe.
typedef TerminalGuestRootsResolver =
    Future<List<String>> Function(String workspaceId);

/// The backend a terminal session actually runs under.
///
/// Pure so every branch can be pinned by a test:
///
///  * an unknown name is refused ([ValidationException]) — answering a typo
///    with the host default is the silent downgrade this feature exists to
///    prevent, dressed up as a default;
///  * an EXPLICIT `none` (the host shell, unsandboxed) is refused
///    ([AuthException]) unless [hostShellAllowed]: only the server's owner
///    runs anything on the host outside a sandbox;
///  * an EXPLICIT `microvm` on a host with no rig service is returned as
///    `microvm` so the PTY start fails loudly ("I asked for a VM and got my
///    laptop" is the one degradation this feature cannot afford);
///  * an UNSPECIFIED backend is the default, except that a `microvm` default
///    on a rig-less host steps down to the native sandbox (and says so in the
///    log), and a `none` default is the native sandbox for anyone who may not
///    use the host shell.
SandboxBackend resolveTerminalBackend({
  required String? requested,
  required SandboxBackend defaultBackend,
  required bool hasVmShell,
  required bool hostShellAllowed,
}) {
  if (requested == null) {
    if (defaultBackend == SandboxBackend.microvm && !hasVmShell) {
      CcInfraLog.warning(
        'terminal: microvm is the default here but no rig service is wired '
        'in — falling back to the native sandbox for this session.',
      );
      return SandboxBackend.native;
    }
    if (defaultBackend == SandboxBackend.none && !hostShellAllowed) {
      return SandboxBackend.native;
    }
    return defaultBackend;
  }
  final parsed = SandboxBackend.values.asNameMap()[requested];
  if (parsed == null) {
    throw ValidationException(
      'Unknown terminal backend "$requested". Expected one of: '
      '${SandboxBackend.values.map((b) => b.name).join(', ')}.',
    );
  }
  if (parsed == SandboxBackend.none && !hostShellAllowed) {
    throw const AuthException(
      'The host shell runs on the server without a sandbox, so only the '
      "server's owner can open one. Open a sandboxed terminal instead.",
    );
  }
  return parsed;
}

/// Resolves [path] and returns it only when it lands inside one of [roots].
///
/// Returns null when the path does not exist or is outside every root.
///
/// **Why this exists.** A terminal's working directory is what its sandbox
/// opens for writing, and a directory handed to the microvm terminal becomes
/// the rig's `worktreePath`, which a rig tars INTO a guest the caller drives.
/// Without this, `terminal.spawn(cwd: "~/.ssh")` is a host-directory read or
/// write primitive for any workspace member — the exact thing `rig.open`
/// refuses by building its spec from a closed field set.
///
/// Both sides are resolved through symlinks before comparison: a path can sit
/// inside an allowed root by string and outside it by content, and it is the
/// content that lands in the guest.
String? confineToGuestRoots({
  required String path,
  required List<String> roots,
}) {
  final String resolved;
  try {
    resolved = Directory(path).resolveSymbolicLinksSync();
  } on FileSystemException {
    return null;
  }
  for (final root in roots) {
    if (root.trim().isEmpty) {
      continue;
    }
    final String resolvedRoot;
    try {
      resolvedRoot = Directory(root).resolveSymbolicLinksSync();
    } on FileSystemException {
      // A root that does not exist on this host confines nothing; skip it
      // rather than letting it widen or narrow the check by accident.
      continue;
    }
    if (resolved == resolvedRoot || p.isWithin(resolvedRoot, resolved)) {
      return resolved;
    }
  }
  return null;
}

/// The sandbox profile the server owner's native terminal runs under: the
/// owner's playground (they may open the host shell anyway), so home is
/// writable, secret paths (`~/.ssh`, `~/.aws`, …) are read-denied and the
/// network is open. Anyone else gets [memberTerminalSandboxConfig].
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
      allowWrite: [cwd, if (home.isNotEmpty) home, '/tmp'],
    ),
    skipMandatoryHomeRcDenies: true,
  );
}

/// The sandbox profile the native terminal of anyone but the server owner runs
/// under: an agent's ([processSandboxConfig]), rooted at [cwd] with its own
/// [runDir]. Writes stay inside [cwd], `$HOME` outside the persistence and
/// credential paths, `/tmp` and [runDir]; secrets are read-denied; the
/// network is the agent egress allowlist; and code runs from [cwd] and the
/// toolchains only. So a member's shell can do on the host what an agent in
/// their workspace can, and no more.
Future<SandboxConfig> memberTerminalSandboxConfig({
  required String sessionId,
  required String workspaceId,
  required String cwd,
  required String runDir,
}) => processSandboxConfig(
  processSandboxSpec(
    sessionId: '$terminalSandboxSessionPrefix$sessionId',
    workspaceId: workspaceId,
    workdir: cwd,
    networkEnabled: true,
    mode: Mode.chat,
    // [cwd] may be a registered checkout the person opened on purpose, so
    // there is no original here to protect from them.
    protectedPaths: const [],
    execGrantRoots: [cwd],
    loopbackPorts: const [],
    environmentScope: null,
  ),
  runDir: runDir,
);

/// Boots an interactive terminal PTY (on `libccpty`) under the given [backend]:
///  * microvm → `ssh` into an enclosed VM, so nothing runs on the host,
///  * none    → host shell directly,
///  * native  → `sandbox-exec`/`bwrap`-wrapped shell via [manager], under
///    [sandbox].
///
/// The microvm path is a PTY running `ssh -tt` rather than a bespoke protocol.
/// That is what keeps every terminal affordance identical to the host shell:
/// line editing, job control, window resize, exit codes and OSC titles all
/// come from SSH and the guest's own shell, so the client sees no difference
/// beyond a status badge.
Future<Pty> _startTerminalPty({
  required SandboxManager manager,
  required SandboxBackend backend,
  required SandboxConfig? sandbox,
  required String cwd,
  required int rows,
  required int cols,
  List<String>? vmShellArgv,
  Map<String, String> hostEnvironment = const {},
}) async {
  if (backend == SandboxBackend.microvm) {
    if (vmShellArgv == null || vmShellArgv.isEmpty) {
      // Fail loudly. Quietly dropping to a host shell would be the exact
      // silent weakening the enclosure exists to prevent: the user asked for
      // a VM and would get a shell on their laptop with the same badge.
      throw StateError(
        'The enclosed-VM terminal is unavailable: no rig is running for this '
        'conversation. Check Settings → Rigs, or pick another backend '
        'explicitly.',
      );
    }
    return Pty.start(
      vmShellArgv.first,
      arguments: vmShellArgv.sublist(1),
      environment: {
        if (Platform.environment['TERM'] != null)
          'TERM': Platform.environment['TERM']!,
      },
      rows: rows,
      columns: cols,
    );
  }
  if (backend == SandboxBackend.none) {
    return _startHostShellPty(
      rows: rows,
      cols: cols,
      cwd: cwd,
      environment: hostEnvironment,
    );
  }
  if (sandbox == null) {
    throw StateError('A native terminal needs its sandbox profile.');
  }
  final shell = Platform.isMacOS ? '/bin/zsh' : '/bin/bash';
  final wrap = await manager.wrap(
    config: sandbox,
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
}

Future<Pty> _startHostShellPty({
  required int rows,
  required int cols,
  required String cwd,
  Map<String, String> environment = const {},
}) async {
  return Pty.start(
    Platform.isWindows ? 'cmd.exe' : '/bin/zsh',
    arguments: const ['-il'],
    workingDirectory: cwd,
    environment: environment,
    rows: rows,
    columns: cols,
  );
}

class _Session {
  _Session({
    required this.workspaceId,
    required this.sandboxSessionId,
    required this.backend,
    required this.pty,
    this.openedBy,
    this.runDir,
    this.spaceId,
    this.owner,
    void Function(List<int> bytes)? onOutput,
  }) : _foreground = TerminalForegroundTracker(shellPid: pty.pid) {
    _ptyOut = pty.output.listen(
      (bytes) {
        onOutput?.call(bytes);
        _remember(bytes);
        _output.add(bytes);
      },
      onDone: () {
        _stopTitlePolling();
        if (!_output.isClosed) {
          unawaited(_output.close());
        }
        if (!_titles.isClosed) {
          unawaited(_titles.close());
        }
      },
    );
    // Foreground-process title polling (the ghostty/VS Code tab-title
    // fallback). `ps` based, so not available on Windows PTYs.
    if (!Platform.isWindows) {
      _titlePoll = Timer.periodic(
        const Duration(seconds: 1),
        (_) => unawaited(_pollTitle()),
      );
    }
  }

  final String workspaceId;
  final String sandboxSessionId;

  /// The person who opened this session, the only one who may use it. Null
  /// for an owned session ([owner]), which no person opened.
  final String? openedBy;

  /// The member sandbox's run directory, removed with the session.
  final String? runDir;

  /// The backend this session ACTUALLY runs under, which is not always the one
  /// requested.
  final SandboxBackend backend;
  final Pty pty;
  final TerminalCommandBuffer commands = TerminalCommandBuffer();

  /// Conversation (space) this shell was opened in, when the client named
  /// one. Host-shell ports publish into Browser (VM) / Android only when
  /// this is non-null; a missing space never broadcasts.
  final String? spaceId;

  /// The server-side owner, or null for a session a tab opened and closes.
  final String? owner;

  /// Set once the command has exited, after which its pid may be reused and
  /// must not be signalled.
  bool exited = false;

  /// Releases the VM pin this session holds, if it runs in one. Called exactly
  /// once, on teardown.
  void Function()? releaseVm;
  final TerminalForegroundTracker _foreground;

  final StreamController<List<int>> _output =
      StreamController<List<int>>.broadcast();
  StreamSubscription<List<int>>? _ptyOut;

  final StreamController<String> _titles = StreamController<String>.broadcast();
  Timer? _titlePoll;
  bool _sampling = false;
  int _sampleFailures = 0;

  /// What an owned session printed before anyone watched it, bounded.
  ///
  /// The process starts before its tab attaches, and a prompt lost in that gap
  /// leaves a person looking at an empty terminal that is waiting for them. A
  /// shell needs none of this: it redraws its prompt.
  late BytesBuilder? _unseen = owner == null ? null : BytesBuilder();

  /// The end of the output, to tell what the next line typed is answering.
  String _lastOutput = '';

  static const int _unseenLimit = 64 * 1024;
  static const int _lastOutputLimit = 256;

  void _remember(List<int> bytes) {
    final unseen = _unseen;
    if (unseen != null && unseen.length < _unseenLimit) {
      unseen.add(bytes);
    }
    final text = _lastOutput + utf8.decode(bytes, allowMalformed: true);
    _lastOutput = text.length > _lastOutputLimit
        ? text.substring(text.length - _lastOutputLimit)
        : text;
  }

  /// Whether what the person just typed may be a secret.
  ///
  /// An owned session runs a program that isn't a shell, so its input is
  /// answers rather than commands. Otherwise the prompt decides, for `sudo` or
  /// `ssh` in a shell. Terminal echo would be the better signal, but the PTY
  /// doesn't expose it.
  bool get answersPrompt =>
      owner != null || terminalAsksForSecret(_lastOutput);

  Stream<List<int>> get output {
    if (owner == null) {
      return _output.stream;
    }
    return Stream.multi((controller) {
      final held = _unseen?.takeBytes();
      _unseen = null;
      if (held != null && held.isNotEmpty) {
        controller.add(held);
      }
      final subscription = _output.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = subscription.cancel;
    });
  }

  /// Current foreground title first (so a client attaching mid-run sees the
  /// running job immediately), then every change.
  Stream<String> get titles async* {
    yield _foreground.currentTitle;
    yield* _titles.stream;
  }

  Future<void> _pollTitle() async {
    if (_sampling || _titles.isClosed) {
      return;
    }
    _sampling = true;
    try {
      final change = await sampleForegroundTitle(_foreground);
      _sampleFailures = 0;
      if (change != null && !_titles.isClosed) {
        _titles.add(change);
      }
    } catch (_) {
      // `ps` unavailable/failing on this host: give up after a few strikes
      // rather than spawning a doomed process every second forever.
      if (++_sampleFailures >= 5) {
        _stopTitlePolling();
      }
    } finally {
      _sampling = false;
    }
  }

  void _stopTitlePolling() {
    _titlePoll?.cancel();
    _titlePoll = null;
  }

  Future<void> dispose() async {
    releaseVm?.call();
    releaseVm = null;
    _stopTitlePolling();
    await _ptyOut?.cancel();
    _ptyOut = null;
    if (!exited) {
      try {
        pty.kill();
      } catch (_) {}
    }
    if (!_output.isClosed) {
      await _output.close();
    }
    if (!_titles.isClosed) {
      await _titles.close();
    }
    final dir = runDir;
    if (dir != null) {
      try {
        await Directory(dir).delete(recursive: true);
      } on FileSystemException {
        // Already gone, or the OS temp sweep will take it.
      }
    }
  }
}

/// Pure-Dart [TerminalSessionPort] for the headless `cc_server`: owns `libccpty`
/// PTYs and exposes them over the `terminal.*` RPC ops so a connected web/thin
/// client runs a REAL terminal on the server host. The Flutter-free sibling of
/// the desktop `DesktopTerminalSessionPort` (which takes a Riverpod `Ref`); this
/// takes its deps directly so it links into the `dart build cli` binary.
///
/// Every [output]/[titles]/[write]/[resize]/[kill] validates the session's
/// owning `workspaceId` and the person who opened it before touching the PTY
/// — a connected client cannot drive another workspace's terminal (the
/// workspace-isolation invariant) or a terminal another member opened.
class TerminalSessionService
    implements TerminalSessionPort, OwnedTerminalSessionPort {
  /// Creates the service over a [_manager] (sandbox lifecycle), a [filesystem]
  /// (working-dir resolution) and a [_defaultBackend] used when the client does
  /// not name one (the headless server defaults to the host shell, which
  /// [resolveTerminalBackend] turns into the native sandbox for anyone but the
  /// server's owner).
  TerminalSessionService({
    required this._manager,
    required WorkspaceFilesystemPort filesystem,
    this._defaultBackend = SandboxBackend.none,
    this._vmShell,
    this._guestRoots,
    this._hostShellPorts,
  }) : _fs = filesystem;

  final SandboxManager _manager;
  final WorkspaceFilesystemPort _fs;
  final SandboxBackend _defaultBackend;
  final TerminalVmShellResolver? _vmShell;
  final TerminalGuestRootsResolver? _guestRoots;
  final RigPortsService? _hostShellPorts;

  /// The space's environment variables, for host shells.
  ///
  /// Set once the environment service exists. A failure costs the terminal
  /// its variables, never the terminal.
  Future<Map<String, String>> Function(String workspaceId, String spaceId)?
  hostEnvironment;

  Future<Map<String, String>> _hostEnvironmentFor(
    String workspaceId,
    String? spaceId,
  ) async {
    final resolver = hostEnvironment;
    if (resolver == null || spaceId == null || spaceId.isEmpty) {
      return const {};
    }
    try {
      return await resolver(workspaceId, spaceId);
    } on Object {
      return const {};
    }
  }

  final Map<String, _Session> _sessions = {};
  final Random _random = Random.secure();

  /// A session id nobody can guess: 96 random bits.
  String _newSessionId() {
    final hex = StringBuffer('tty-');
    for (var i = 0; i < 12; i++) {
      hex.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return hex.toString();
  }

  void _assertOwned(_Session? session, String workspaceId) {
    if (session != null && session.workspaceId != workspaceId) {
      // Deny loudly — never silently no-op (hides the bug) nor proceed (leaks).
      throw const WorkspaceMismatchException(
        'Terminal session belongs to a different workspace',
      );
    }
  }

  /// The live session for [sessionId], or a typed rejection.
  ///
  /// A gone session must surface as a [NotFoundException], never a bare
  /// [StateError]: the RPC layer maps the former to `RpcErrorCodes.notFound`,
  /// which every client treats as unrecoverable. As a generic internal error it
  /// read as transient and a client still holding a session id from before a
  /// server restart resubscribed against it forever.
  _Session _require(String sessionId, String workspaceId, String userId) {
    final session = _find(sessionId, workspaceId, userId);
    if (session == null) {
      throw NotFoundException('Terminal session not found: $sessionId');
    }
    return session;
  }

  /// The session [userId] may use, or null when there is none: a session
  /// somebody else opened is treated exactly like one that does not exist,
  /// so a member learns nothing about another's terminals. A session of
  /// another workspace is refused loudly.
  _Session? _find(String sessionId, String workspaceId, String userId) {
    final session = _sessions[sessionId];
    _assertOwned(session, workspaceId);
    if (session == null) {
      return null;
    }
    final opener = session.openedBy;
    if (opener != null && opener != userId) {
      return null;
    }
    return session;
  }

  @override
  /// [actingUserId] is the member opening the shell, and the only one who may
  /// use it afterwards.
  ///
  /// For an ENCLOSED terminal it also decides which rig is opened or reused
  /// and whose forge access the guest's credentials are bounded by — so one
  /// member's shell can never mint on another's behalf, nor land inside a VM
  /// where another member's agent is running with its token in the
  /// environment.
  Future<String> spawn({
    required String workspaceId,
    required String actingUserId,
    required bool hostShellAllowed,
    required int rows,
    required int cols,
    String? spaceId,
    String? cwd,
    String? backend,
  }) async {
    final resolvedBackend = resolveTerminalBackend(
      requested: backend,
      defaultBackend: _defaultBackend,
      hasVmShell: _vmShell != null,
      hostShellAllowed: hostShellAllowed,
    );
    var workingDir = await _workingDir(workspaceId, spaceId, cwd);
    if (resolvedBackend != SandboxBackend.none) {
      // Only the owner's host shell opens anywhere; every sandboxed terminal
      // opens in this workspace's own directories.
      workingDir = await _confinedWorkingDir(workspaceId, workingDir);
    }

    final sessionId = _newSessionId();
    final vmShell = resolvedBackend == SandboxBackend.microvm
        ? await _vmShell?.call(
            workspaceId: workspaceId,
            conversationId: spaceId,
            actingUserId: actingUserId,
            // Confined above, because this value becomes the rig's
            // `worktreePath` and a rig tars its worktree into a guest the
            // caller drives.
            worktreePath: workingDir,
          )
        : null;
    String? runDir;
    final Pty pty;
    try {
      SandboxConfig? sandbox;
      if (resolvedBackend == SandboxBackend.native) {
        if (hostShellAllowed) {
          sandbox = terminalSandboxConfig(sessionId: sessionId, cwd: workingDir);
        } else {
          runDir = await _memberRunDir();
          sandbox = await memberTerminalSandboxConfig(
            sessionId: sessionId,
            workspaceId: workspaceId,
            cwd: workingDir,
            runDir: runDir,
          );
        }
      }
      pty = await _startTerminalPty(
        manager: _manager,
        backend: resolvedBackend,
        sandbox: sandbox,
        cwd: workingDir,
        rows: rows,
        cols: cols,
        vmShellArgv: vmShell?.argv,
        hostEnvironment: await _hostEnvironmentFor(workspaceId, spaceId),
      );
    } on Object {
      // The pin is taken before the PTY exists, so a spawn failure must give
      // it back or the VM is held open by a terminal that never opened.
      vmShell?.release();
      if (runDir != null) {
        await Directory(runDir).delete(recursive: true);
      }
      rethrow;
    }
    _sessions[sessionId] = _Session(
      workspaceId: workspaceId,
      sandboxSessionId: '$terminalSandboxSessionPrefix$sessionId',
      backend: resolvedBackend,
      pty: pty,
      openedBy: actingUserId,
      runDir: runDir,
      spaceId: spaceId == null || spaceId.isEmpty ? null : spaceId,
    )..releaseVm = vmShell?.release;
    if (resolvedBackend != SandboxBackend.microvm) {
      _hostShellPorts?.attachHostShell(
        sessionId: sessionId,
        workspaceId: workspaceId,
        conversationId: spaceId,
        rootPid: pty.pid,
      );
    }
    return sessionId;
  }

  /// The directory a terminal opens in: [cwd] when given, else the space's
  /// directory, else the workspace's.
  Future<String> _workingDir(
    String workspaceId,
    String? spaceId,
    String? cwd,
  ) async {
    if (cwd != null && cwd.isNotEmpty) {
      return cwd;
    }
    if (spaceId != null && spaceId.isNotEmpty) {
      return _fs.ensureSpaceDir(workspaceId, spaceId);
    }
    await _fs.ensureWorkspaceDirs(workspaceId);
    return _fs.workspaceDir(workspaceId);
  }

  /// A fresh run directory for a member's sandbox, by its resolved path
  /// (Seatbelt matches `/private/var/folders`, not `/var/folders`).
  Future<String> _memberRunDir() async {
    final dir = await Directory.systemTemp.createTemp('cc-term-');
    return dir.resolveSymbolicLinksSync();
  }

  /// [workingDir], resolved, when it lies in this workspace's own directory
  /// tree or one of its registered checkouts; otherwise a loud refusal, never
  /// a replacement directory.
  ///
  /// Only the owner's host shell needs no such proof (it opens a directory in
  /// place, on the machine its owner runs). A sandboxed shell does, because
  /// its working directory is what the sandbox opens for writing, and an
  /// enclosed one COPIES it into a VM whose filesystem the caller reads
  /// freely. Membership is the access boundary, so "a member asked for it" is
  /// not an answer — the workspace's own tree and its registered checkouts
  /// are.
  Future<String> _confinedWorkingDir(
    String workspaceId,
    String workingDir,
  ) async {
    final roots = <String>[
      await _fs.workspaceDir(workspaceId),
      ...?await _guestRoots?.call(workspaceId),
    ];
    final confined = confineToGuestRoots(path: workingDir, roots: roots);
    if (confined != null) {
      return confined;
    }
    throw ValidationException(
      "A terminal opens only in this workspace's own directories and its "
      'registered repositories, and "$workingDir" is outside all of them.',
    );
  }

  @override
  Stream<List<int>> output({
    required String workspaceId,
    required String userId,
    required String sessionId,
  }) => _require(sessionId, workspaceId, userId).output;

  @override
  Stream<String> titles({
    required String workspaceId,
    required String userId,
    required String sessionId,
  }) => _require(sessionId, workspaceId, userId).titles;

  @override
  Future<TerminalWriteResult> write({
    required String workspaceId,
    required String userId,
    required String sessionId,
    required List<int> data,
  }) async {
    final session = _find(sessionId, workspaceId, userId);
    if (session == null) {
      return TerminalWriteResult.none;
    }
    session.pty.write(Uint8List.fromList(data));
    final outcome = session.commands.feed(data);
    // The trail keeps that a line was sent. Its text would be the password.
    return outcome.sent && session.answersPrompt
        ? const TerminalWriteResult(sent: true)
        : outcome;
  }

  @override
  Future<void> resize({
    required String workspaceId,
    required String userId,
    required String sessionId,
    required int rows,
    required int cols,
  }) async {
    _find(sessionId, workspaceId, userId)?.pty.resize(rows, cols);
  }

  @override
  Future<void> kill({
    required String workspaceId,
    required String userId,
    required String sessionId,
  }) async {
    final session = _find(sessionId, workspaceId, userId);
    if (session == null) {
      return;
    }
    if (session.owner != null) {
      // A tab closing. Its stream subscription already ended; the process
      // belongs to its owner and keeps running.
      return;
    }
    await _end(sessionId, session);
  }

  Future<void> _end(String sessionId, _Session session) async {
    _sessions.remove(sessionId);
    await _hostShellPorts?.detach(sessionId);
    await session.dispose();
    try {
      await _manager.disposeSession(session.sandboxSessionId);
    } catch (_) {}
  }

  @override
  Future<OwnedTerminalSession> spawnOwned({
    required String workspaceId,
    required String owner,
    required String executable,
    required String cwd,
    List<String> arguments = const [],
    Map<String, String> environment = const {},
    String? spaceId,
    int rows = 30,
    int cols = 120,
    void Function(List<int> bytes)? onOutput,
  }) async {
    if (owner.isEmpty) {
      throw const ValidationException('An owned terminal needs an owner');
    }
    final space = spaceId == null || spaceId.isEmpty ? null : spaceId;
    final sessionId = _newSessionId();
    final pty = Pty.start(
      executable,
      arguments: arguments,
      environment: environment,
      workingDirectory: cwd,
      rows: rows,
      columns: cols,
    );
    final session = _Session(
      workspaceId: workspaceId,
      sandboxSessionId: '$terminalSandboxSessionPrefix$sessionId',
      backend: SandboxBackend.none,
      pty: pty,
      spaceId: space,
      owner: owner,
      onOutput: onOutput,
    );
    _sessions[sessionId] = session;
    _hostShellPorts?.attachHostShell(
      sessionId: sessionId,
      workspaceId: workspaceId,
      conversationId: space,
      rootPid: pty.pid,
    );
    final exitCode = pty.exitCode.then((code) async {
      session.exited = true;
      // Nobody closes a supervised session the way a tab closes a shell, so
      // its exit is what releases it.
      if (identical(_sessions[sessionId], session)) {
        await _end(sessionId, session);
      }
      return code;
    });
    return OwnedTerminalSession(
      sessionId: sessionId,
      pid: pty.pid,
      exitCode: exitCode,
    );
  }

  @override
  Future<void> killOwned({
    required String workspaceId,
    required String sessionId,
    required String owner,
  }) async {
    final session = _sessions[sessionId];
    _assertOwned(session, workspaceId);
    if (session == null) {
      return;
    }
    if (session.owner != owner) {
      throw ValidationException(
        'Terminal session $sessionId does not belong to $owner',
      );
    }
    await _end(sessionId, session);
  }

  @override
  String? ownerOf(String sessionId) => _sessions[sessionId]?.owner;

  @override
  List<String> sessionsOwnedBy({
    required String workspaceId,
    required String ownerPrefix,
  }) => [
    for (final entry in _sessions.entries)
      if (entry.value.workspaceId == workspaceId &&
          (entry.value.owner?.startsWith(ownerPrefix) ?? false))
        entry.key,
  ];

  @override
  String? backendOf(String sessionId) => _sessions[sessionId]?.backend.name;

  @override
  ({String? spaceId})? ownedSessionOf(String sessionId) => switch (_sessions[
    sessionId
  ]) {
    final session? when session.owner != null => (spaceId: session.spaceId),
    _ => null,
  };

  @override
  String? openerOf(String sessionId) => _sessions[sessionId]?.openedBy;

  /// Tears down every live session (host shutdown).
  Future<void> disposeAll() async {
    final sessions = Map<String, _Session>.from(_sessions);
    _sessions.clear();
    for (final entry in sessions.entries) {
      await _hostShellPorts?.detach(entry.key);
      await entry.value.dispose();
      try {
        await _manager.disposeSession(entry.value.sandboxSessionId);
      } catch (_) {}
    }
  }
}
