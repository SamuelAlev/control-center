import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/sandboxing/git_global_config.dart';
import 'package:meta/meta.dart';

/// Signs a git object for a sandboxed agent run.
abstract interface class CommitSigner {
  /// Returns the armored signature git expects for [payload] (a commit or tag
  /// object), or throws [CommitSigningException].
  Future<String> sign(List<int> payload);
}

/// Signing failed; [message] is shown to the agent by git.
class CommitSigningException implements Exception {
  /// Creates a [CommitSigningException].
  const CommitSigningException(this.message);

  /// Why signing failed, in words the operator can act on.
  final String message;

  @override
  String toString() => message;
}

/// A signer program the host may run, and how to prove it is genuine.
class TrustedSshSigner {
  /// Creates a [TrustedSshSigner].
  const TrustedSshSigner(this.path, {this.teamId});

  /// Absolute path, outside anything a sandbox may write.
  final String path;

  /// macOS: the Developer ID team the binary must be signed by. Null for
  /// SIP-protected system binaries.
  final String? teamId;
}

/// Signs with the host user's own SSH signing setup (`gpg.format=ssh`), outside
/// the sandbox, where the SSH agent (1Password's included) is reachable.
///
/// What it trusts, and why:
/// - **Config.** Only the global git config, top level (`--no-includes`): a
///   worktree's config and an included file are the agent's to write. The
///   global files themselves are write-denied to every sandbox
///   (`SandboxPolicyResolver.homeMandatoryDenyRels`).
/// - **Program.** `gpg.ssh.program` must resolve to one of [trustedSigners]:
///   fixed paths no sandbox can write, and on macOS 1Password's must carry
///   AgileBits' code signature. Anything else is refused, never run, so a
///   tampered config can at worst fail a signature.
/// - **Use.** The namespace is always `git`; the caller decides which objects
///   reach [sign] at all (`AgentRunGateway`).
class HostCommitSigner implements CommitSigner {
  /// Creates a [HostCommitSigner].
  HostCommitSigner({
    Map<String, String>? environment,
    List<TrustedSshSigner>? signers,
  }) : _env = environment ?? Platform.environment,
       _signers = signers ?? trustedSigners;

  /// How long a signature may wait, which includes a human approving the key
  /// use in their SSH agent (1Password asks per app).
  static const Duration signTimeout = Duration(minutes: 5);

  /// The signers this host will run for an agent.
  static List<TrustedSshSigner> get trustedSigners => [
    const TrustedSshSigner('/usr/bin/ssh-keygen'),
    if (Platform.isMacOS)
      const TrustedSshSigner(
        '/Applications/1Password.app/Contents/MacOS/op-ssh-sign',
        teamId: '2BUA8C4S2C',
      ),
    if (Platform.isLinux) const TrustedSshSigner('/opt/1Password/op-ssh-sign'),
  ];

  final Map<String, String> _env;
  final List<TrustedSshSigner> _signers;

  @override
  Future<String> sign(List<int> payload) async {
    final format = await readGlobalGitConfig('gpg.format', environment: _env);
    if (format != 'ssh') {
      throw CommitSigningException(
        'Control Center signs agent commits with SSH signing only, and the '
        'global git config sets gpg.format=${format ?? 'openpgp'}.',
      );
    }
    final key = await readGlobalGitConfig('user.signingkey', environment: _env);
    if (key == null || key.isEmpty) {
      throw const CommitSigningException(
        'Commit signing is on, but the global git config sets no '
        'user.signingkey.',
      );
    }
    final program = await trustedProgram(
      await readGlobalGitConfig('gpg.ssh.program', environment: _env) ??
          'ssh-keygen',
    );

    final scratch = await Directory.systemTemp.createTemp('cc-git-sign-');
    try {
      final buffer = File('${scratch.path}/buffer');
      await buffer.writeAsBytes(payload, flush: true);
      // Mirrors git: a literal key (`key::…`, or the legacy bare `ssh-…`) goes
      // to a file and is looked up in the agent (`-U`); otherwise it is a path.
      final literal = key.startsWith('key::')
          ? key.substring('key::'.length)
          : key.startsWith('ssh-')
          ? key
          : null;
      final String keyFile;
      if (literal != null) {
        keyFile = '${scratch.path}/key.pub';
        await File(keyFile).writeAsString('$literal\n', flush: true);
      } else {
        keyFile = _expandHome(key);
      }
      final process = await Process.start(program, [
        '-Y',
        'sign',
        '-n',
        'git',
        '-f',
        keyFile,
        if (literal != null) '-U',
        buffer.path,
      ], environment: _env);
      unawaited(process.stdin.close());
      final stderr = process.stderr.transform(utf8.decoder).join();
      unawaited(process.stdout.drain<void>());
      final exitCode = await process.exitCode.timeout(
        signTimeout,
        onTimeout: () {
          process.kill();
          throw const CommitSigningException(
            'Commit signing timed out waiting for the SSH agent; approve the '
            'key use when your agent asks.',
          );
        },
      );
      final signature = File('${buffer.path}.sig');
      if (exitCode != 0 || !signature.existsSync()) {
        final reason = (await stderr).trim();
        throw CommitSigningException(
          'Commit signing failed on the host'
          '${reason.isEmpty ? '' : ': $reason'}',
        );
      }
      final armored = await signature.readAsString();
      if (!armored.startsWith('-----BEGIN SSH SIGNATURE-----')) {
        throw const CommitSigningException(
          'The host signer returned something that is not an SSH signature.',
        );
      }
      return armored;
    } finally {
      try {
        await scratch.delete(recursive: true);
      } on FileSystemException {
        // Leftover scratch in the temp dir is harmless.
      }
    }
  }

  /// Resolves [configured] to one of [_signers], or refuses.
  @visibleForTesting
  Future<String> trustedProgram(String configured) async {
    // A bare name means the trusted signer of that name, never a PATH lookup:
    // the server's PATH may hold directories a sandbox can write.
    final located = configured.contains('/')
        ? _expandHome(configured)
        : _signers
              .map((s) => s.path)
              .where((path) => path.endsWith('/$configured'))
              .firstOrNull;
    final real = located == null ? null : _realPath(located);
    for (final signer in _signers) {
      if (real == null || real != _realPath(signer.path)) {
        continue;
      }
      final teamId = signer.teamId;
      if (teamId != null && !await _signedBy(real, teamId)) {
        throw CommitSigningException(
          '$real is not signed by its vendor; Control Center will not run it.',
        );
      }
      return real;
    }
    throw CommitSigningException(
      'Control Center only runs these SSH signers for agent commits: '
      '${_signers.map((s) => s.path).join(', ')}. gpg.ssh.program is '
      '"$configured"${real == null ? '' : ' ($real)'}.',
    );
  }

  /// macOS code signature check: a valid Developer ID signature from
  /// [teamId], so a look-alike at the trusted path is never run.
  static Future<bool> _signedBy(String path, String teamId) async {
    if (!Platform.isMacOS) {
      return true;
    }
    final result = await Process.run('/usr/bin/codesign', [
      '--verify',
      '--strict',
      '-R=anchor apple generic and certificate leaf[subject.OU] = "$teamId"',
      path,
    ]);
    return result.exitCode == 0;
  }

  static String? _realPath(String path) {
    try {
      return File(path).resolveSymbolicLinksSync();
    } on FileSystemException {
      return null;
    }
  }

  String _expandHome(String path) {
    final home = _env['HOME'];
    if (home != null && (path == '~' || path.startsWith('~/'))) {
      return '$home${path.substring(1)}';
    }
    return path;
  }
}
