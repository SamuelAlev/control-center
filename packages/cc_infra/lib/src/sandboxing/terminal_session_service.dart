import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException, WorkspaceMismatchException;
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/terminal_session_port.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';
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
/// Pure so the one branch that DEGRADES can be pinned by a test. There are
/// exactly three outcomes and they are deliberately different:
///
///  * an unknown name is refused ([ValidationException]) — answering a typo
///    with the host default is the silent downgrade this feature exists to
///    prevent, dressed up as a default;
///  * an EXPLICIT `microvm` on a host with no rig service is returned as
///    `microvm` so the PTY start fails loudly ("I asked for a VM and got my
///    laptop" is the one degradation this feature cannot afford);
///  * only an UNSPECIFIED backend that defaults to `microvm` on a rig-less
///    host steps down to the native sandbox, and it says so in the log.
SandboxBackend resolveTerminalBackend({
  required String? requested,
  required SandboxBackend defaultBackend,
  required bool hasVmShell,
}) {
  if (requested == null) {
    if (defaultBackend == SandboxBackend.microvm && !hasVmShell) {
      CcInfraLog.warning(
        'terminal: microvm is the default here but no rig service is wired '
        'in — falling back to the native sandbox for this session.',
      );
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
  return parsed;
}

/// Resolves [path] and returns it only when it lands inside one of [roots].
///
/// Returns null when the path does not exist or is outside every root.
///
/// **Why this exists.** A directory handed to the microvm terminal becomes the
/// rig's `worktreePath`, and a rig tars its worktree INTO a guest the caller
/// drives. Without this, `terminal.spawn(backend: "microvm", cwd: "~/.ssh")`
/// is a host-directory read primitive for any workspace member — the exact
/// thing `rig.open` refuses by building its spec from a closed field set.
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

/// The sandbox profile a terminal session runs under. The terminal is the
/// user's playground (capability gating only applies to the agent dispatcher):
/// home is writable, secret paths (`~/.ssh`, `~/.aws`, …) are read-denied,
/// network is open. Kept identical to the desktop copy.
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

/// Boots an interactive terminal PTY (on `libccpty`) under the given [backend]:
///  * microvm → `ssh` into an enclosed VM, so nothing runs on the host,
///  * none    → host shell directly,
///  * native  → `sandbox-exec`/`bwrap`-wrapped shell via [manager].
///
/// The microvm path is a PTY running `ssh -tt` rather than a bespoke protocol.
/// That is what keeps every terminal affordance identical to the host shell:
/// line editing, job control, window resize, exit codes and OSC titles all
/// come from SSH and the guest's own shell, so the client sees no difference
/// beyond a status badge.
Future<Pty> _startTerminalPty({
  required SandboxManager manager,
  required SandboxBackend backend,
  required String sessionId,
  required String cwd,
  required int rows,
  required int cols,
  List<String>? vmShellArgv,
  void Function(String notice)? onNotice,
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
    return _startHostShellPty(rows: rows, cols: cols, cwd: cwd);
  }
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

class _Session {
  _Session({
    required this.workspaceId,
    required this.sandboxSessionId,
    required this.backend,
    required this.pty,
  }) : _foreground = TerminalForegroundTracker(shellPid: pty.pid) {
    _ptyOut = pty.output.listen(
      _output.add,
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

  /// The backend this session ACTUALLY runs under, which is not always the one
  /// requested.
  final SandboxBackend backend;
  final Pty pty;

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

  Stream<List<int>> get output => _output.stream;

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
    try {
      pty.kill();
    } catch (_) {}
    if (!_output.isClosed) {
      await _output.close();
    }
    if (!_titles.isClosed) {
      await _titles.close();
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
/// owning `workspaceId` before touching the PTY — a connected client physically
/// cannot drive another workspace's terminal (the workspace-isolation
/// invariant).
class TerminalSessionService implements TerminalSessionPort {
  /// Creates the service over a [manager] (sandbox lifecycle), a [filesystem]
  /// (working-dir resolution) and a [defaultBackend] used when the client does
  /// not name one (the headless server defaults to the host shell).
  TerminalSessionService({
    required SandboxManager manager,
    required WorkspaceFilesystemPort filesystem,
    SandboxBackend defaultBackend = SandboxBackend.none,
    TerminalVmShellResolver? vmShell,
    TerminalGuestRootsResolver? guestRoots,
  }) : _manager = manager,
       _fs = filesystem,
       _defaultBackend = defaultBackend,
       _vmShell = vmShell,
       _guestRoots = guestRoots;

  final SandboxManager _manager;
  final WorkspaceFilesystemPort _fs;
  final SandboxBackend _defaultBackend;
  final TerminalVmShellResolver? _vmShell;
  final TerminalGuestRootsResolver? _guestRoots;

  final Map<String, _Session> _sessions = {};
  int _counter = 0;

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
  _Session _require(String sessionId, String workspaceId) {
    final session = _sessions[sessionId];
    if (session == null) {
      throw NotFoundException('Terminal session not found: $sessionId');
    }
    _assertOwned(session, workspaceId);
    return session;
  }

  @override
  /// [actingUserId] is the member opening the shell.
  ///
  /// For an ENCLOSED terminal it decides which rig is opened or reused and
  /// whose forge access the guest's credentials are bounded by — so one
  /// member's shell can never mint on another's behalf, nor land inside a VM
  /// where another member's agent is running with its token in the
  /// environment.
  Future<String> spawn({
    required String workspaceId,
    required int rows,
    required int cols,
    String? spaceId,
    String? cwd,
    String? backend,
    String? actingUserId,
  }) async {
    final String workingDir;
    if (cwd != null && cwd.isNotEmpty) {
      workingDir = cwd;
    } else if (spaceId != null && spaceId.isNotEmpty) {
      workingDir = await _fs.ensureSpaceDir(workspaceId, spaceId);
    } else {
      await _fs.ensureWorkspaceDirs(workspaceId);
      workingDir = await _fs.workspaceDir(workspaceId);
    }

    final resolvedBackend = resolveTerminalBackend(
      requested: backend,
      defaultBackend: _defaultBackend,
      hasVmShell: _vmShell != null,
    );

    final sessionId = 'tty${++_counter}-${spaceId ?? workspaceId}';
    final vmShell = resolvedBackend == SandboxBackend.microvm
        ? await _vmShell?.call(
            workspaceId: workspaceId,
            conversationId: spaceId,
            actingUserId: actingUserId,
            // Confined, because this value becomes the rig's `worktreePath`
            // and a rig tars its worktree into a guest the caller drives.
            worktreePath: await _confinedWorktreePath(workspaceId, workingDir),
          )
        : null;
    final Pty pty;
    try {
      pty = await _startTerminalPty(
        manager: _manager,
        backend: resolvedBackend,
        sessionId: sessionId,
        cwd: workingDir,
        rows: rows,
        cols: cols,
        vmShellArgv: vmShell?.argv,
      );
    } on Object {
      // The pin is taken before the PTY exists, so a spawn failure must give
      // it back or the VM is held open by a terminal that never opened.
      vmShell?.release();
      rethrow;
    }
    _sessions[sessionId] = _Session(
      workspaceId: workspaceId,
      sandboxSessionId: '$terminalSandboxSessionPrefix$sessionId',
      backend: resolvedBackend,
      pty: pty,
    )..releaseVm = vmShell?.release;
    return sessionId;
  }

  /// [workingDir] proven to be a directory this workspace may sync INTO a
  /// guest, or a loud refusal.
  ///
  /// The host shell needs no such proof (it opens a directory in place, on the
  /// machine the operator already owns); an enclosed shell does, because the
  /// directory is COPIED into a VM whose filesystem the caller reads freely.
  /// Membership is the access boundary, so "a member asked for it" is not an
  /// answer — the workspace's own tree and its registered checkouts are.
  Future<String> _confinedWorktreePath(
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
    throw StateError(
      'The enclosed-VM terminal is confined to this workspace\'s own '
      'directories and its registered repositories. "$workingDir" is outside '
      'all of them, and an enclosed terminal copies its working directory '
      'into the VM — so this would hand that directory to whoever drives it.',
    );
  }

  @override
  Stream<List<int>> output({
    required String workspaceId,
    required String sessionId,
  }) => _require(sessionId, workspaceId).output;

  @override
  Stream<String> titles({
    required String workspaceId,
    required String sessionId,
  }) => _require(sessionId, workspaceId).titles;

  @override
  Future<void> write({
    required String workspaceId,
    required String sessionId,
    required List<int> data,
  }) async {
    final session = _sessions[sessionId];
    _assertOwned(session, workspaceId);
    session?.pty.write(Uint8List.fromList(data));
  }

  @override
  Future<void> resize({
    required String workspaceId,
    required String sessionId,
    required int rows,
    required int cols,
  }) async {
    final session = _sessions[sessionId];
    _assertOwned(session, workspaceId);
    session?.pty.resize(rows, cols);
  }

  @override
  Future<void> kill({
    required String workspaceId,
    required String sessionId,
  }) async {
    final session = _sessions[sessionId];
    _assertOwned(session, workspaceId);
    if (session == null) {
      return;
    }
    _sessions.remove(sessionId);
    await session.dispose();
    try {
      await _manager.disposeSession(session.sandboxSessionId);
    } catch (_) {}
  }

  @override
  String? backendOf(String sessionId) => _sessions[sessionId]?.backend.name;

  /// Tears down every live session (host shutdown).
  Future<void> disposeAll() async {
    final sessions = _sessions.values.toList();
    _sessions.clear();
    for (final s in sessions) {
      await s.dispose();
      try {
        await _manager.disposeSession(s.sandboxSessionId);
      } catch (_) {}
    }
  }
}
