import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/domain/ports/git_command_port.dart';
import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:path/path.dart' as p;

/// Phase of a clone/fetch operation.
enum PrClonePhase {
  /// Performing the initial `git clone`.
  cloning,

  /// Running `git fetch` to pull the PR head ref.
  fetching,

  /// Computing diff statistics and patches.
  computing,

  /// Ready — data is available.
  ready,

  /// An unrecoverable error occurred.
  error,
}

/// Progress event emitted while a clone or fetch is running.
class PrCloneProgress {
  /// Creates a [PrCloneProgress].
  const PrCloneProgress({required this.phase, this.message = '', this.error});

  /// The current phase of the clone/fetch operation.
  final PrClonePhase phase;

  /// A human-readable progress message.
  final String message;

  /// An error object if the phase is [PrClonePhase.error].
  final Object? error;

  /// Whether this progress event represents a terminal state.
  bool get isTerminal =>
      phase == PrClonePhase.ready || phase == PrClonePhase.error;
}

/// Manages one blobless partial clone per GitHub repo under the workspace
/// pr_clones directory. The same clone is reused across PRs; only the PR's
/// base + head refs are fetched on demand (incremental).
///
/// Credentials are injected via the remote URL (`https://x-access-token:TOKEN@…`)
/// for maximum compatibility (works with any git version, any credential
/// helper configuration). The token is never persisted: for clone, the remote
/// URL is immediately reset to the clean HTTPS URL after the clone completes;
/// for fetch, the auth URL is passed as a positional argument and is never
/// written to `.git/config`.
class PrCloneManager {
  /// Creates a [PrCloneManager] for the given repository.
  PrCloneManager({
    required GitCommandPort git,
    required WorkspaceFilesystemPort filesystem,
    required String workspaceId,
    required String owner,
    required String repo,
    required String githubToken,
    String? localCheckoutPath,
    RiftClient? rift,
  }) : _git = git,
       _filesystem = filesystem,
       _workspaceId = workspaceId,
       _owner = owner,
       _repo = repo,
       _githubToken = githubToken,
       _localCheckoutPath = localCheckoutPath,
       _rift = rift;

  final GitCommandPort _git;
  final WorkspaceFilesystemPort _filesystem;
  final String _workspaceId;
  final String _owner;
  final String _repo;
  final String _githubToken;

  /// Absolute path to the already-registered local checkout of this repo, when
  /// known. Used to seed the PR clone via a fast copy-on-write copy (rift)
  /// instead of a network clone.
  final String? _localCheckoutPath;

  /// CoW backend; null/unavailable falls back to a network clone.
  final RiftClient? _rift;

  bool _busy = false;

  /// Public HTTPS URL — stored as the remote after cloning (no token).
  String get _cleanUrl => 'https://github.com/$_owner/$_repo.git';

  /// Auth URL with token embedded as the password. Used only as a transient
  /// CLI argument; never stored in `.git/config`.
  String get _authUrl =>
      'https://x-access-token:$_githubToken@github.com/$_owner/$_repo.git';

  /// Minimal env overrides.
  ///
  /// - `GIT_TERMINAL_PROMPT=0` — prevents git from blocking on any terminal
  ///   prompt (e.g. if credential negotiation fails).
  /// - `GIT_ASKPASS=echo` — returns empty strings for any credential prompts
  ///   that do slip through, so they fail fast rather than hang.
  /// - `GIT_CONFIG_NOSYSTEM=1` — ignores `/etc/gitconfig` which can contain
  ///   credential helpers on managed machines.
  Map<String, String> get _baseEnv => const {
    'GIT_TERMINAL_PROMPT': '0',
    'GIT_ASKPASS': 'echo',
    'GIT_CONFIG_NOSYSTEM': '1',
  };

  /// Args prepended before the git subcommand to disable credential helpers
  /// for this invocation. Setting `credential.helper` to an empty string
  /// disables ALL helpers (osxkeychain, gh, etc.) so only the token embedded
  /// in the URL is used. Supported since git 1.7.10+.
  List<String> get _noCredHelperArgs => ['-c', 'credential.helper='];

  /// Ensures the repository clone exists and fetches the PR head ref, emitting progress events.
  Stream<PrCloneProgress> ensureCloneAndFetch({
    required int prNumber,
    required String baseRef,
    required String headSha,
  }) async* {
    if (_busy) {
      return;
    }
    _busy = true;
    try {
      final cloneDir = await _filesystem.prCloneDir(
        _workspaceId,
        _owner,
        _repo,
      );

      if (!Directory('${cloneDir.path}/.git').existsSync()) {
        yield const PrCloneProgress(phase: PrClonePhase.cloning, message: '');
        // Prefer a fast copy-on-write copy of the already-linked local repo;
        // fall back to a network clone when rift is unavailable / fails.
        final usedCow = await _tryRiftCopy(cloneDir);
        if (!usedCow) {
          yield* _doClone(cloneDir);
        }
      }

      yield const PrCloneProgress(phase: PrClonePhase.fetching, message: '');
      yield* _doFetch(cloneDir, prNumber: prNumber, baseRef: baseRef);

      yield const PrCloneProgress(phase: PrClonePhase.ready);
    } catch (e, st) {
      AppLog.e('PrCloneManager', 'clone/fetch failed: $e', e, st);
      yield PrCloneProgress(phase: PrClonePhase.error, error: e);
    } finally {
      _busy = false;
    }
  }

  /// Seeds [cloneDir] from the local checkout via a copy-on-write copy.
  ///
  /// Returns true when the CoW copy succeeded (so the network clone is skipped).
  /// The token is never involved here — the copy inherits the source's clean
  /// `origin`; the subsequent [_doFetch] pulls PR refs over HTTPS.
  Future<bool> _tryRiftCopy(Directory cloneDir) async {
    final src = _localCheckoutPath;
    final rift = _rift;
    if (src == null ||
        src.isEmpty ||
        rift == null ||
        !rift.isAvailable ||
        !Directory('$src/.git').existsSync()) {
      return false;
    }
    try {
      if (!cloneDir.parent.existsSync()) {
        await cloneDir.parent.create(recursive: true);
      }
      // rift create requires the destination to not exist.
      if (cloneDir.existsSync()) {
        await cloneDir.delete(recursive: true);
      }
      await rift.init(at: src);
      final dest = await rift.create(
        from: src,
        into: cloneDir.parent.path,
        name: p.basename(cloneDir.path),
      );
      AppLog.i('PrCloneManager', 'Seeded PR clone via CoW: $src -> $dest');
      return true;
    } on RiftException catch (e) {
      AppLog.w(
        'PrCloneManager',
        'CoW copy unavailable (${e.code}); using network clone: ${e.message}',
      );
      return false;
    } catch (e) {
      AppLog.w('PrCloneManager', 'CoW copy failed; using network clone: $e');
      return false;
    }
  }

  Stream<PrCloneProgress> _doClone(Directory cloneDir) async* {
    if (!cloneDir.parent.existsSync()) {
      await cloneDir.parent.create(recursive: true);
    }

    final args = [
      ..._noCredHelperArgs, // must precede the subcommand
      // Prevent git gc --auto and git maintenance --auto from running after
      // clone. For blobless clones these would attempt to fetch ALL promised
      // blob objects over the network, blocking indefinitely on large repos.
      '-c', 'gc.auto=0',
      '-c', 'maintenance.auto=false',
      'clone',
      '--filter=blob:none',
      '--no-checkout',
      '--no-tags',
      '--progress',
      // Note: --reference-if-able is intentionally omitted. While it seeds
      // objects from the local checkout (saving bandwidth), it triggers git's
      // alternates connectivity check after clone which runs silently and can
      // take minutes for large repos, keeping the process alive with no output.
      _authUrl,
      cloneDir.path,
    ];

    await for (final line in _git.runStreaming(
      args,
      workdir: cloneDir.parent.path,
      env: _baseEnv,
    )) {
      AppLog.d('PrCloneManager', 'clone: $line');
      yield PrCloneProgress(
        phase: PrClonePhase.cloning,
        message: _sanitize(line),
      );
    }

    // Reset the remote to the clean URL so the token is not stored on disk.
    await _git.run(
      [..._noCredHelperArgs, 'remote', 'set-url', 'origin', _cleanUrl],
      workdir: cloneDir.path,
      env: _baseEnv,
    );
  }

  Stream<PrCloneProgress> _doFetch(
    Directory cloneDir, {
    required int prNumber,
    required String baseRef,
  }) async* {
    // Pass the auth URL as the remote argument — never written to .git/config.
    // Store the base branch at refs/remotes/origin/<base> so that
    // `git merge-base origin/<base> ...` resolves correctly in _resolveMergeBase.
    await for (final line in _git.runStreaming(
      [
        ..._noCredHelperArgs, // must precede the subcommand
        'fetch',
        '--filter=blob:none',
        '--no-tags',
        '--force',
        '--progress',
        _authUrl,
        '$baseRef:refs/remotes/origin/$baseRef',
        'refs/pull/$prNumber/head:refs/pr/$prNumber/head',
      ],
      workdir: cloneDir.path,
      env: _baseEnv,
    )) {
      AppLog.d('PrCloneManager', 'fetch: $line');
      yield PrCloneProgress(
        phase: PrClonePhase.fetching,
        message: _sanitize(line),
      );
    }
  }

  /// Strips ANSI escape codes and the "remote: " prefix from git output.
  static String _sanitize(String line) {
    final noAnsi = line.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
    return noAnsi.replaceFirst(RegExp(r'^remote:\s*'), '').trim();
  }

  /// Returns the absolute path to the clone directory for this repository.
  Future<String> clonePath() async {
    final dir = await _filesystem.prCloneDir(_workspaceId, _owner, _repo);
    return dir.path;
  }
}
