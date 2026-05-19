import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/rigs/worktree_sync.dart';

/// Runs a kernel INSIDE the conversation's enclosure.
///
/// **Why this is the launcher that matters.** A persistent interpreter driven
/// by an agent is the exact shape the enclosure-only execution rule exists for:
/// it holds state across calls, it reads and writes whatever the process can
/// reach, and the code in it was written by a model reading an untrusted repo.
/// A one-shot `bash` call at least ends; a kernel is a shell that remembers.
///
/// The NDJSON channel rides the same [WorktreeTransport] the terminal and the
/// worktree sync already use, so this adds no port, no secret and no egress
/// rule — the guest's networking is unchanged.
class RigKernelLauncher implements KernelLauncher {
  /// Creates a [RigKernelLauncher] over [transport].
  const RigKernelLauncher({
    required this.transport,
    required this.guestWorkingDirectory,
  });

  /// The carrier into the guest.
  final WorktreeTransport transport;

  /// Where cells run inside the guest.
  final String guestWorkingDirectory;

  @override
  Future<void> writeFile(String relativePath, String contents) async {
    // Written through a base64 heredoc rather than a quoted echo: the runner
    // source contains quotes, backslashes, dollars and newlines, and every
    // shell-quoting scheme that "usually works" corrupts one of them.
    final encoded = base64.encode(utf8.encode(contents));
    final cd = _quote(guestWorkingDirectory);
    final target = _quote(relativePath);
    final payload = _quote(encoded);
    final result = await transport.capture(
      'cd $cd && printf ${_quote('%s')} $payload | base64 -d > $target',
    );
    if (result.exitCode != 0) {
      throw StateError(
        'could not write the kernel runner into the enclosure: '
        '${result.stderr.trim()}',
      );
    }
  }

  @override
  Future<Process> start(KernelLanguage language, String runnerPath) {
    // Interpreter resolution INSIDE the guest, in the order a developer would
    // expect: an active virtualenv, then the checkout's own `.venv`, then the
    // image's python. A cell that cannot import the package the repo depends
    // on reads as broken code rather than as the wrong interpreter.
    final command = switch (language) {
      KernelLanguage.python =>
        'cd ${_quote(guestWorkingDirectory)} && '
            'PY="\${VIRTUAL_ENV:+\$VIRTUAL_ENV/bin/python3}"; '
            '[ -x "\$PY" ] || PY=./.venv/bin/python3; '
            '[ -x "\$PY" ] || PY=python3; '
            'exec "\$PY" -u ${_quote(runnerPath)}',
      KernelLanguage.javascript =>
        'cd ${_quote(guestWorkingDirectory)} && '
            'exec node ${_quote(runnerPath)}',
    };
    return transport.start(command);
  }

  static String _quote(String value) => "'${value.replaceAll("'", r"'\''")}'";
}
