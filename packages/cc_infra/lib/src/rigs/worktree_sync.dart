import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;

/// Single-quotes [value] for a POSIX shell inside a guest.
///
/// These strings are interpolated into a remote command line, so quoting is
/// not cosmetic. Worktree paths come from workspace configuration rather than
/// from a model, but "not currently attacker-controlled" is a property that
/// changes without warning — and the file lane next door interpolates names
/// that came from a DROP, i.e. from wherever the user dragged them.
String shellQuoteForGuest(String value) =>
    "'${value.replaceAll("'", r"'\''")}'";

/// Paths never copied into a rig.
///
/// Deliberately UNANCHORED (no `./` prefix): a monorepo keeps `node_modules`
/// and `.env` files in nested packages, and GNU tar only matches a
/// `./`-prefixed pattern at the archive root — on a Linux host the anchored
/// form shipped every nested `.env` into the guest. bsdtar and GNU tar both
/// match a bare component name at any depth.
///
/// **The secret half is a NAME list, not a suffix list.** `*.pem` and `*.key`
/// cover a certificate and miss the two files that matter most: an SSH
/// private key is called `id_rsa` or `id_ed25519` and matches neither
/// pattern. Everything left in the tree is streamed into a guest an agent
/// drives and a person may not be watching, so the list below is by name for
/// the credential files that carry no extension. Over-excluding costs a
/// developer one `cp`; under-excluding costs them a key.
const List<String> worktreeSyncExcludes = [
  // Build/vendor noise — excluded for size, not for secrecy.
  '.git/objects/pack/tmp_*',
  'node_modules',
  '.dart_tool',
  'build',
  'target',
  '.venv',
  '__pycache__',
  '.next',
  '.gradle',
  'Pods',
  // Secrets by extension.
  '.env',
  '.env.*',
  '*.pem',
  '*.key',
  '*.p12',
  '*.pfx',
  '*.jks',
  '*.keystore',
  // Secrets by NAME (no extension to match on).
  'id_rsa',
  'id_dsa',
  'id_ecdsa',
  'id_ed25519',
  'id_ed25519_sk',
  'id_ecdsa_sk',
  '.ssh',
  '.gnupg',
  '.netrc',
  '_netrc',
  '.npmrc',
  '.pypirc',
  '.envrc',
  '.git-credentials',
  'credentials.json',
  'service-account.json',
  'service_account.json',
  // Tool config directories that hold long-lived tokens.
  '.aws',
  '.docker',
  '.kube',
  '.gcloud',
  '.config/gh',
];

/// The outcome of a sync in either direction.
class WorktreeSyncResult {
  /// Creates a [WorktreeSyncResult].
  const WorktreeSyncResult({
    required this.ok,
    required this.message,
    this.bytes = 0,
    this.commits = 0,
  });

  /// Whether it worked.
  final bool ok;

  /// Operator/model-facing summary.
  final String message;

  /// Bytes transferred, when known.
  final int bytes;

  /// Commits carried back, for a write-back.
  final int commits;
}

/// What a completed guest command produced.
typedef WorktreeCommandResult = ({int exitCode, String stdout, String stderr});

/// How [WorktreeSync] reaches a shell inside a guest.
///
/// The remote command vocabulary — tar in, `git bundle` out, `git diff` — is
/// the same on every enclosure; what differs is the carrier: an SSH channel
/// on a QEMU rig, `smolvm machine exec` on a microVM rig.
abstract interface class WorktreeTransport {
  /// Host binaries the carrier itself needs (beyond `tar`/`git`, which every
  /// carrier needs).
  List<String> get requiredHostTools;

  /// Starts [command] in the guest with piped stdin/stdout.
  Future<Process> start(String command);

  /// Runs [command] in the guest to completion and captures the result.
  Future<WorktreeCommandResult> capture(String command);

  /// The host argv that opens an interactive shell in the guest.
  List<String> interactiveShellArgv({String? workingDirectory});
}

/// An SSH channel into a QEMU rig.
class SshWorktreeTransport implements WorktreeTransport {
  /// Creates a transport to the guest reachable on [sshPort] with
  /// [privateKeyPath].
  const SshWorktreeTransport({
    required this.sshPort,
    required this.privateKeyPath,
    this.guestUser = 'cc',
  });

  /// Host loopback port forwarded to the guest's SSH port.
  final int sshPort;

  /// The per-VM private key.
  final String privateKeyPath;

  /// The guest account.
  final String guestUser;

  /// The SSH options every invocation shares.
  ///
  /// Host-key checking is off and the known-hosts file is /dev/null because
  /// the peer is a VM this process just created, reachable only on host
  /// loopback, with a key this process just minted. There is no trust-on-first-
  /// use question to answer, and a real known_hosts would accumulate an entry
  /// per rig forever.
  List<String> get _sshOptions => [
    '-i',
    privateKeyPath,
    '-p',
    '$sshPort',
    '-o',
    'StrictHostKeyChecking=no',
    '-o',
    'UserKnownHostsFile=/dev/null',
    '-o',
    'LogLevel=ERROR',
    '-o',
    'ConnectTimeout=10',
    '-o',
    'BatchMode=yes',
  ];

  @override
  List<String> get requiredHostTools => const ['ssh'];

  @override
  Future<Process> start(String command) =>
      Process.start('ssh', [..._sshOptions, '$guestUser@127.0.0.1', command]);

  @override
  Future<WorktreeCommandResult> capture(String command) async {
    final result = await Process.run('ssh', [
      ..._sshOptions,
      '$guestUser@127.0.0.1',
      command,
    ]);
    return (
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }

  /// The argv for an interactive shell into the guest.
  ///
  /// `-tt` forces a PTY even though the local side is not a terminal, which is
  /// what makes the in-VM shell behave like the host one: line editing, job
  /// control, window resizes and exit codes all come for free from SSH instead
  /// of being reimplemented over a bespoke protocol.
  @override
  List<String> interactiveShellArgv({String? workingDirectory}) => [
    'ssh',
    '-tt',
    ..._sshOptions,
    '$guestUser@127.0.0.1',
    if (workingDirectory != null) ...[
      // `cd` then exec a login shell, so the terminal opens where the user
      // expects rather than in the guest's home.
      'cd ${shellQuoteForGuest(workingDirectory)} && exec \$SHELL -l',
    ],
  ];
}

/// A `smolvm machine exec` channel into a microVM rig.
///
/// `-i` keeps stdin open for the tar stream; `-t` is deliberately absent on
/// the data path — a PTY would mangle the byte stream. Exit codes propagate,
/// so a failed guest command reads as a failed sync rather than a truncated
/// one.
class SmolvmWorktreeTransport implements WorktreeTransport {
  /// Creates a transport into the machine named [machineName].
  const SmolvmWorktreeTransport({
    required this.smolvmPath,
    required this.machineName,
  });

  /// The resolved smolvm binary (no PATH lookup at spawn time).
  final String smolvmPath;

  /// The smolvm machine name (`ccrig-<rigId>`).
  final String machineName;

  List<String> get _execPrefix => ['machine', 'exec', '--name', machineName];

  @override
  List<String> get requiredHostTools => const [];

  @override
  Future<Process> start(String command) => Process.start(smolvmPath, [
    ..._execPrefix,
    '-i',
    '--',
    'sh',
    '-c',
    command,
  ]);

  @override
  Future<WorktreeCommandResult> capture(String command) async {
    final result = await Process.run(smolvmPath, [
      ..._execPrefix,
      '--',
      'sh',
      '-c',
      command,
    ]);
    return (
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }

  /// The argv for an interactive shell in the guest.
  ///
  /// The same affordance chain the SSH path gets for free — line editing, job
  /// control, resizes, exit codes — comes from smolvm's `-t` PTY allocation,
  /// and TERM is forwarded from the host environment.
  @override
  List<String> interactiveShellArgv({String? workingDirectory}) => [
    smolvmPath,
    ..._execPrefix,
    '-i',
    '-t',
    if (workingDirectory != null) ...['-w', workingDirectory],
    '--',
    '/bin/bash',
    '-l',
  ];
}

/// Moves a repository between the host worktree and a rig's guest.
///
/// **The host worktree is authoritative; the guest copy is a satellite.** That
/// is the whole design in one sentence, and it is what stops the in-VM
/// terminal from quietly becoming a scratch copy: a commit made inside the rig
/// is not real until it lands back on the host, and this class is the only
/// thing that lands it.
///
/// Direction by direction:
///
///  * **In** ([syncIn]) — a tar of the worktree streamed into the guest at
///    boot. Fast, simple, and it does not require the guest to know anything
///    about the host's filesystem.
///  * **Out** ([writeBack]) — `git bundle` of everything the guest committed,
///    streamed back and fetched into the host repository under a
///    `refs/rigs/<rigId>/*` namespace. A FETCH, never a push and never a
///    checkout: the operator's working tree and current branch are theirs, and
///    a rig must not be able to move either. The commits arrive, are visible
///    in the log, and merging them is a human decision.
///  * **Uncommitted work** ([diffOut]) — a plain `git diff` fetched as text so
///    the UI can show it before anything is applied. Nothing writes to the
///    host worktree without a person asking.
class WorktreeSync {
  /// Creates a [WorktreeSync] over SSH, for the guest reachable on [sshPort]
  /// with [privateKeyPath] (QEMU rigs).
  WorktreeSync({
    required int sshPort,
    required String privateKeyPath,
    String guestUser = 'cc',
    this.guestPath = '/home/cc/work',
  }) : _transport = SshWorktreeTransport(
         sshPort: sshPort,
         privateKeyPath: privateKeyPath,
         guestUser: guestUser,
       );

  /// Creates a [WorktreeSync] over `smolvm machine exec` (microVM rigs).
  WorktreeSync.smolvm({
    required String smolvmPath,
    required String machineName,
    this.guestPath = '/home/cc/work',
  }) : _transport = SmolvmWorktreeTransport(
         smolvmPath: smolvmPath,
         machineName: machineName,
       );

  final WorktreeTransport _transport;

  /// Where the worktree lands inside the guest.
  final String guestPath;

  /// Deadline for one bulk transfer (the tar in, the bundle out).
  ///
  /// `syncIn` is AWAITED ON THE BOOT PATH, so a guest whose tar never finishes
  /// hung the whole open() rather than failing it — and `writeBack` held the
  /// operator's action open the same way. SSH's `ConnectTimeout` covers
  /// establishment only; nothing bounded the transfer itself. Sized for a
  /// multi-gigabyte monorepo over a local socket, not for a hang.
  static const Duration _transferTimeout = Duration(minutes: 15);

  /// Deadline for a small control command in the guest (`mkdir`, `rev-parse`,
  /// `git diff`).
  static const Duration _commandTimeout = Duration(minutes: 2);

  /// Runs [command] in the guest under [timeout], reporting an expiry the way
  /// a failed command reports itself rather than as an unhandled exception.
  Future<WorktreeCommandResult> _capture(
    String command, {
    Duration timeout = _commandTimeout,
  }) async {
    try {
      return await _transport.capture(command).timeout(timeout);
    } on TimeoutException {
      return (
        exitCode: 124,
        stdout: '',
        stderr:
            'The guest did not answer within ${timeout.inSeconds}s '
            '(command: $command)',
      );
    }
  }

  /// The argv for an interactive shell into the guest.
  List<String> interactiveShellArgv({String? workingDirectory}) =>
      _transport.interactiveShellArgv(workingDirectory: workingDirectory);

  /// Streams the host worktree at [hostPath] into the guest.
  ///
  /// Excludes what a fresh checkout can rebuild and what must never leave the
  /// host: `node_modules`, build output, and any `.env`. The exclusions are
  /// not merely a speed optimisation — a rig with a deny-by-default NIC that
  /// still received the operator's `.env` would be leaking the interesting
  /// half of the machine into a box an agent drives.
  Future<WorktreeSyncResult> syncIn({
    required String hostPath,
    void Function(String step)? onProgress,
  }) async {
    final dir = Directory(hostPath);
    if (!dir.existsSync()) {
      return WorktreeSyncResult(
        ok: false,
        message: 'The worktree $hostPath does not exist on the host.',
      );
    }
    onProgress?.call('Packing the worktree');
    final tar = await _which('tar');
    final missing = [
      if (tar == null) 'tar',
      for (final tool in _transport.requiredHostTools)
        if (await _which(tool) == null) tool,
    ];
    if (missing.isNotEmpty) {
      return WorktreeSyncResult(
        ok: false,
        message:
            '${missing.join(' and ')} '
            '${missing.length == 1 ? 'is' : 'are'} required to sync a '
            'worktree into a rig.',
      );
    }

    await _capture('mkdir -p ${shellQuoteForGuest(guestPath)}');

    onProgress?.call('Copying the worktree into the rig');
    final tarProcess = await Process.start(tar!, [
      '-C',
      hostPath,
      for (final pattern in worktreeSyncExcludes) ...['--exclude', pattern],
      '-cf',
      '-',
      '.',
    ]);
    final guestProcess = await _transport.start(
      'tar -C ${shellQuoteForGuest(guestPath)} -xf -',
    );

    var bytes = 0;
    final tarErr = tarProcess.stderr.transform(utf8.decoder).join();
    final guestErr = guestProcess.stderr.transform(utf8.decoder).join();
    final int tarCode;
    final int guestCode;
    try {
      // `addStream` honours backpressure; `forEach` + `add` does not. With the
      // latter a slow consumer let the WHOLE tar of a multi-gigabyte repo
      // accumulate in the server's heap, because `IOSink.add` buffers without
      // bound.
      //
      // Bounded as one unit: this whole block is AWAITED ON THE BOOT PATH, so
      // a guest whose `tar -x` wedges did not fail the open, it hung it — and
      // SSH's `ConnectTimeout` covers establishment only, never the transfer.
      await guestProcess.stdin
          .addStream(
            tarProcess.stdout.map((chunk) {
              bytes += chunk.length;
              return chunk;
            }),
          )
          .timeout(_transferTimeout);
      await guestProcess.stdin.close();
      // Drain the remote command's stdout too, or a `tar` that writes anything
      // there fills its pipe and blocks forever.
      unawaited(guestProcess.stdout.drain<void>());
      tarCode = await tarProcess.exitCode.timeout(_transferTimeout);
      guestCode = await guestProcess.exitCode.timeout(_transferTimeout);
    } on TimeoutException {
      tarProcess.kill(ProcessSignal.sigkill);
      guestProcess.kill(ProcessSignal.sigkill);
      return WorktreeSyncResult(
        ok: false,
        message:
            'Copying the worktree into the rig did not finish within '
            '${_transferTimeout.inMinutes} minutes and was cancelled.',
      );
    }
    if (tarCode != 0 || guestCode != 0) {
      return WorktreeSyncResult(
        ok: false,
        message:
            'Copying the worktree failed (tar $tarCode, guest $guestCode): '
                    '${(await tarErr).trim()} ${(await guestErr).trim()}'
                .trim(),
      );
    }
    await _scrubGuestGitCredentials();
    onProgress?.call('Worktree ready');
    return WorktreeSyncResult(
      ok: true,
      message: 'Copied ${_humanBytes(bytes)} into the rig at $guestPath.',
      bytes: bytes,
    );
  }

  /// Strips embedded credentials out of the COPY of `.git/config` in the guest.
  ///
  /// A remote can be stored as `https://user:token@host/org/repo.git`, and
  /// `.git/config` has to travel (the guest needs its branches and remotes),
  /// so it cannot simply be excluded the way `.git-credentials` is. The token
  /// half can: the guest's own push credentials come from the loopback broker
  /// per operation, so a userinfo segment inherited from the host buys nothing
  /// there and is a durable secret sitting in a machine an agent drives.
  ///
  /// Also drops any inherited `credential.helper`: on the host it names a
  /// store this sync deliberately did not copy, so in the guest it is at best
  /// a no-op and at worst a path back to one.
  ///
  /// Best effort by design — a worktree whose `.git` is a FILE (the
  /// `git worktree` backend) has no `.git/config` at all, and a failure here
  /// must not fail a sync that otherwise succeeded.
  Future<void> _scrubGuestGitCredentials() async {
    const sed =
        r"sed -i -E 's#(url[[:space:]]*=[[:space:]]*"
        r"[a-zA-Z][a-zA-Z0-9+.-]*://)[^/@[:space:]]*@#\1#g'";
    final quoted = shellQuoteForGuest(guestPath);
    final result = await _capture(
      'cd $quoted && '
      'for f in .git/config .git/config.worktree; do '
      '[ -f "\$f" ] && $sed "\$f"; done; '
      'git -C $quoted config --local --unset-all credential.helper '
      '>/dev/null 2>&1; true',
    );
    if (result.exitCode != 0) {
      CcInfraLog.warning(
        'rig: could not scrub credentials from the guest git config '
        '(${result.stderr.trim()}) — the copy may still carry a token in a '
        'remote URL.',
      );
    }
  }

  /// Carries commits made inside the rig back to the host repository.
  ///
  /// Implemented as a `git bundle` streamed out of the guest and fetched into
  /// the host repo under `refs/rigs/<rigId>/<branch>`. Deliberately a fetch
  /// into a namespaced ref rather than a push or a checkout: the operator's
  /// branch and working tree stay theirs, and what arrives is inspectable
  /// (`git log refs/rigs/...`) before anyone merges it.
  Future<WorktreeSyncResult> writeBack({
    required String hostPath,
    required String rigId,
    void Function(String step)? onProgress,
  }) async {
    // `rigId` becomes a FILENAME (`<tmp>/<rigId>.bundle`) and a REFSPEC
    // (`refs/rigs/<rigId>/*`) below. It is a server-minted UUIDv4 today, so
    // this guard never fires — which is the point: the day the id gains a
    // caller-supplied component, a `../` or a space in it would write outside
    // the temp dir or forge a ref, and nothing at this layer was looking.
    if (!_safeRigId.hasMatch(rigId)) {
      return WorktreeSyncResult(
        ok: false,
        message:
            'Refusing to carry work back for rig id "$rigId": it is used as a '
            'filename and a git refspec, so it must be letters, digits, '
            'hyphens and underscores only.',
      );
    }
    final git = await _which('git');
    if (git == null) {
      return const WorktreeSyncResult(
        ok: false,
        message: 'git is required to carry work back from a rig.',
      );
    }

    onProgress?.call('Looking for commits in the rig');
    // The guest bundles every local branch (`--all`), so an experimental
    // branch is not silently dropped. A DETACHED head is not covered: the
    // fetch refspec below is `refs/heads/*`, which by construction has no
    // entry for it, so the message says what actually landed rather than
    // promising a ref that does not exist.
    final head = await _capture(
      'cd ${shellQuoteForGuest(guestPath)} && git rev-parse --abbrev-ref HEAD',
    );
    if (head.exitCode != 0) {
      return WorktreeSyncResult(
        ok: false,
        message:
            'The rig has no git repository at $guestPath, so there is nothing '
            'to carry back.',
      );
    }

    final bundleDir = await Directory.systemTemp.createTemp('cc-rig-bundle-');
    final bundlePath = p.join(bundleDir.path, '$rigId.bundle');
    try {
      onProgress?.call('Bundling');
      final bundleProcess = await _transport.start(
        'cd ${shellQuoteForGuest(guestPath)} && git bundle create - --all 2>/dev/null',
      );
      final file = File(bundlePath).openWrite();
      var bytes = 0;
      final int code;
      try {
        try {
          await file
              .addStream(
                bundleProcess.stdout.map((chunk) {
                  bytes += chunk.length;
                  return chunk;
                }),
              )
              .timeout(_transferTimeout);
        } finally {
          // The `finally` below deletes this directory; leaving the sink open
          // would have it writing into a path that no longer exists.
          await file.close();
        }
        unawaited(bundleProcess.stderr.drain<void>());
        code = await bundleProcess.exitCode.timeout(_transferTimeout);
      } on TimeoutException {
        bundleProcess.kill(ProcessSignal.sigkill);
        return WorktreeSyncResult(
          ok: false,
          message:
              'The rig did not finish bundling within '
              '${_transferTimeout.inMinutes} minutes; nothing was fetched.',
        );
      }
      if (code != 0 || bytes == 0) {
        return const WorktreeSyncResult(
          ok: false,
          message: 'The rig produced no bundle — it has no commits to send.',
        );
      }

      onProgress?.call('Fetching into the host repository');
      final fetch = await _runHost(git, [
        '-C',
        hostPath,
        'fetch',
        bundlePath,
        '+refs/heads/*:refs/rigs/$rigId/*',
      ]);
      if (fetch.exitCode != 0) {
        return WorktreeSyncResult(
          ok: false,
          message: 'git fetch from the rig bundle failed: ${fetch.stderr}',
        );
      }

      // Count what the rig ADDED, not the branch's whole history. `rev-list
      // --count <ref>` on a 50k-commit repo reports 50000 for a rig that made
      // one commit, which turns a useful number into a confusing one.
      // `--not --branches --tags --remotes`, deliberately NOT `--not --all`:
      // `--all` covers every ref under refs/ including the refs/rigs/* entry
      // the fetch just wrote, which subtracts the rig's own commits and
      // reports 0 forever.
      final branch = head.stdout.trim();
      final counted = await _runHost(git, [
        '-C',
        hostPath,
        'rev-list',
        '--count',
        'refs/rigs/$rigId/$branch',
        '--not',
        '--branches',
        '--tags',
        '--remotes',
      ]);
      final commits = int.tryParse(counted.stdout.trim()) ?? 0;
      final detached = branch == 'HEAD' || branch.isEmpty;
      return WorktreeSyncResult(
        ok: true,
        message: detached
            ? 'Fetched the rig\'s branches into refs/rigs/$rigId/*. The rig '
                  'was on a detached HEAD, so its current commit may not have '
                  'a branch here — list what arrived with '
                  '`git for-each-ref refs/rigs/$rigId/`. Nothing on your '
                  'branch or working tree was changed.'
            : 'Fetched $commits commit(s) into refs/rigs/$rigId/$branch. '
                  'Nothing on your branch or working tree was changed — '
                  'inspect them with `git log refs/rigs/$rigId/$branch`.',
        bytes: bytes,
        commits: commits,
      );
    } finally {
      try {
        await bundleDir.delete(recursive: true);
      } on Object {
        // Temp cleanup is best effort.
      }
    }
  }

  /// The guest's uncommitted diff, as text.
  ///
  /// Read-only by design: the UI shows it and the operator decides. Applying
  /// a rig's uncommitted changes to the host tree automatically would be the
  /// one thing in this system that edits the user's files without being asked.
  Future<String> diffOut() async {
    // `git diff HEAD`, not a bare `git diff`: the bare form shows only
    // UNSTAGED changes, so anything the agent (or the operator) had already
    // `git add`ed inside the rig was invisible here — the panel showed "no
    // uncommitted changes" over a staged rewrite of the tree.
    //
    // `--intent-to-add` still runs first, so brand-new untracked files appear
    // as additions rather than not at all. It touches the GUEST's index only;
    // the host worktree is never modified by this call.
    final result = await _capture(
      'cd ${shellQuoteForGuest(guestPath)} && git add -A -N . >/dev/null 2>&1; '
      'git diff HEAD',
    );
    return result.exitCode == 0 ? result.stdout : '';
  }

  /// Runs a HOST tool (git) under a deadline.
  ///
  /// `Process.run` cannot be cancelled, so this starts the process itself and
  /// kills it on expiry. `git fetch` from a local bundle is fast, but it can
  /// block on a repository lock another process holds, and an operator's
  /// write-back must fail rather than hang.
  static Future<WorktreeCommandResult> _runHost(
    String binary,
    List<String> args, {
    Duration timeout = _transferTimeout,
  }) async {
    final process = await Process.start(binary, args);
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();
    try {
      final exitCode = await process.exitCode.timeout(timeout);
      return (
        exitCode: exitCode,
        stdout: await stdoutFuture,
        stderr: await stderrFuture,
      );
    } on TimeoutException {
      process.kill(ProcessSignal.sigkill);
      unawaited(stdoutFuture.catchError((_) => ''));
      unawaited(stderrFuture.catchError((_) => ''));
      return (
        exitCode: 124,
        stdout: '',
        stderr:
            '$binary ${args.join(' ')} did not finish within '
            '${timeout.inMinutes} minutes and was cancelled.',
      );
    }
  }

  /// What a rig id may contain when it is interpolated into a path or a ref.
  static final RegExp _safeRigId = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static Future<String?> _which(String binary) async {
    try {
      final result = await Process.run(Platform.isWindows ? 'where' : 'which', [
        binary,
      ]);
      if (result.exitCode != 0) {
        return null;
      }
      final path = '${result.stdout}'.split('\n').first.trim();
      return path.isEmpty ? null : path;
    } on Object {
      return null;
    }
  }

  static String _humanBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
