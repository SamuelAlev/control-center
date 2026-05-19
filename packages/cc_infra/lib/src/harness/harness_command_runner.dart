import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/sandboxing/env_sanitizer.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';

/// Runs the harness `bash` tool's commands through CC's command policy, the OS
/// sandbox and (for `prompt`-tier commands) the confirmation flow — the same
/// stack the external-CLI transports use.
///
/// When no [SandboxManager] is wired, commands run with environment
/// sanitization only (and a warning), mirroring the dispatch session's
/// no-sandbox fallback.
class SandboxedHarnessCommandRunner implements HarnessCommandRunner {
  /// Creates a [SandboxedHarnessCommandRunner].
  SandboxedHarnessCommandRunner({
    required Mode mode,
    required AgentCapabilities capabilities,
    this.sandboxManager,
    this.confirmationPort,
    this.execGrantService,
    this.actionGuard,
    this.workspaceId,
    this.agentId,
    this.conversationId,
    Future<List<String>> Function()? protectedPaths,
    Map<String, String> baseEnv = const {},
    int maxOutputChars = 16000,
  }) : _mode = mode,
       _capabilities = capabilities,
       _protectedPaths = protectedPaths,
       _baseEnv = baseEnv,
       _maxOutputChars = maxOutputChars;

  /// The OS sandbox manager, or null to run with env sanitization only.
  final SandboxManager? sandboxManager;

  /// Confirmation port for `prompt`-tier commands. Null denies them.
  final ConfirmationPort? confirmationPort;

  /// The unified guardrail gate. When wired, the operator's OWN command rules
  /// (stored `action_policies` rows with a `commandPrefix`) are consulted
  /// before the hardcoded mode command net.
  ///
  /// Those rules had a table, an editor-shaped API, a resolver and a what-if
  /// probe — and never fired, because no chokepoint ever passed the command
  /// down. Two engines with opposite conflict rules (`CommandPolicy` is flat
  /// `allow > deny > prompt`; the resolver is specificity-then-restrictiveness)
  /// also meant the probe could confidently report a verdict the runtime would
  /// never reach. This is that wire.
  final ActionGuardService? actionGuard;

  /// Asks whether programs may be run from inside the agent's worktree.
  ///
  /// This runner rebuilds its sandbox profile PER COMMAND, so an approval takes
  /// effect on the agent's very next attempt — unlike an external CLI adapter,
  /// which runs under one profile for the whole dispatch. Null leaves the
  /// writable-dir exec block fully closed.
  final SandboxExecGrantService? execGrantService;

  /// Workspace the run belongs to.
  final String? workspaceId;

  /// Agent the run belongs to.
  final String? agentId;

  /// Conversation the run belongs to (used in the confirmation request).
  final String? conversationId;

  final Mode _mode;
  final AgentCapabilities _capabilities;
  final Map<String, String> _baseEnv;
  final int _maxOutputChars;

  /// Resolves the workspace's original repo checkout paths, folded into the
  /// sandbox spec as deny-write rules (never writable in any mode). Null →
  /// no extra denies.
  final Future<List<String>> Function()? _protectedPaths;

  @override
  Future<HarnessCommandResult> run(
    String command, {
    String? workdir,
    int timeoutSeconds = 120,
    Map<String, String>? env,
    CancellationToken? cancel,
  }) async {
    var preApproved = false;
    // 1a. Operator command rules (the policy store), when wired. A stored
    // rule is MORE specific than the built-in net, so it decides first; the
    // net below still runs as the floor, so a stored `allow` can never
    // loosen a mode preset that forbids the effect outright.
    final guard = actionGuard;
    if (guard != null && workspaceId != null) {
      final verdict = await guard.check(
        workspaceId: workspaceId!,
        classes: const {ActionClass.processSpawn},
        command: command,
        spaceId: conversationId,
        agentId: agentId,
        mode: _mode,
        actionSummary: 'bash: $command',
      );
      if (!verdict.allowed) {
        return HarnessCommandResult.deny(
          'Command denied by policy: ${verdict.reason ?? command}',
        );
      }
      // The guard already asked and the human said yes; the net below must
      // not ask again for the same command.
      preApproved = verdict.prompted;
    }

    // 1b. Command policy preflight (the built-in mode net). It stays the
    // FLOOR: a stored `allow` above cannot loosen a mode that forbids the
    // command outright, it can only spare the operator a second prompt.
    final decision = commandPolicyForMode(_mode).evaluate(command);
    switch (decision) {
      case CommandDecision.deny:
        return HarnessCommandResult.deny('Command denied by policy: $command');
      case CommandDecision.prompt:
        if (preApproved) {
          break;
        }
        final port = confirmationPort;
        if (port == null) {
          return HarnessCommandResult.deny(
            'Command requires approval but no approver is connected: $command',
          );
        }
        final approved = await port.requestApproval(
          ConfirmationRequest(
            spaceId: conversationId ?? '',
            workspaceId: workspaceId,
            title: 'Approve command',
            detail: 'An agent is about to run:',
            command: command,
          ),
        );
        if (!approved) {
          return HarnessCommandResult.deny('Command denied by user: $command');
        }
      case CommandDecision.allow:
        break;
    }

    // 2. Build argv + working directory.
    final cwd = workdir ?? Directory.current.path;
    final argv = ['bash', '-lc', command];
    final sanitizedParent = const EnvSanitizer().hardenPlatform({});

    try {
      final manager = sandboxManager;
      final Process process;
      if (manager != null) {
        final config = await _buildSandboxConfig(cwd);
        final wrap = await manager.wrap(
          config: config,
          argv: argv,
          workingDirectory: cwd,
        );
        process = await Process.start(
          wrap.executable,
          wrap.argv,
          workingDirectory: cwd,
          environment: {
            ...sanitizedParent,
            ...wrap.environment,
            ..._baseEnv,
            ...?env,
          },
          includeParentEnvironment: false,
          runInShell: false,
        );
      } else {
        CcInfraLog.warning(
          'Harness bash: no native sandbox available; running with env '
          'sanitization only.',
        );
        process = await Process.start(
          argv.first,
          argv.skip(1).toList(),
          workingDirectory: cwd,
          environment: {...sanitizedParent, ..._baseEnv, ...?env},
          includeParentEnvironment: false,
          runInShell: false,
        );
      }

      // Collect output with bounded memory (head + rolling tail) and tolerate
      // malformed/binary bytes rather than losing the whole output on one bad
      // byte. Listening (not .join()) lets us stop waiting on the pipes even if
      // a leaked grandchild keeps them open after the child is killed. The full
      // (untruncated) stdout is also streamed to a spill file inside the
      // workspace so the agent can read the middle that inline truncation drops.
      const decoder = Utf8Decoder(allowMalformed: true);
      final spill = _openSpillFile(cwd);
      final outSink = _BoundedOutput(_maxOutputChars, spill: spill?.sink);
      final errSink = _BoundedOutput(_maxOutputChars);
      final outSub = process.stdout.transform(decoder).listen(outSink.add);
      final errSub = process.stderr.transform(decoder).listen(errSink.add);

      // Kill the process as soon as the run is cancelled (the user stopped the
      // agent) — otherwise a long command would keep running until its own
      // timeout. Idempotent with the timeout kill below.
      var cancelled = false;
      final cancelSub = cancel?.whenCancelled.then((_) {
        cancelled = true;
        process.kill(ProcessSignal.sigkill);
      });
      if (cancel != null && cancel.isCancelled) {
        cancelled = true;
        process.kill(ProcessSignal.sigkill);
      }

      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () {
          timedOut = true;
          process.kill(ProcessSignal.sigkill);
          return 124;
        },
      );
      // Stop listening for cancellation once the process has exited.
      unawaited(cancelSub);
      // Give the pipes a brief grace to flush the last bytes, then stop waiting.
      // Orphaned grandchildren can hold the pipe open forever; we must not hang
      // the run on them (the OS sandbox reaps them where it can).
      await Future.wait([
        outSub.asFuture<void>(),
        errSub.asFuture<void>(),
      ]).timeout(const Duration(seconds: 2), onTimeout: () => const <void>[]);
      await outSub.cancel();
      await errSub.cancel();

      // Finalize the spill: keep it only when stdout was actually truncated
      // (otherwise the inline output is complete) and surface a workspace-
      // relative pointer the agent can `read`.
      var stdout = outSink.render();
      if (spill != null) {
        final rel = await spill.finalize(keep: outSink.wasTruncated);
        if (rel != null) {
          stdout =
              '$stdout\n\n[full stdout saved to $rel — read it for the '
              'untruncated output]';
        }
      }
      var stderr = errSink.render();
      if (cancelled) {
        stderr = stderr.isEmpty
            ? 'Command cancelled — the run was stopped.'
            : '$stderr\n[command cancelled — the run was stopped]';
      }
      return HarnessCommandResult(
        exitCode: exitCode,
        stdout: stdout,
        stderr: stderr,
        timedOut: timedOut,
      );
    } on Object catch (e) {
      return HarnessCommandResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Failed to run command: $e',
      );
    }
  }

  /// Opens a best-effort stdout spill file under the workspace run dir. Returns
  /// null when the file cannot be created (spill is a nicety, never fatal).
  _SpillFile? _openSpillFile(String cwd) {
    try {
      final dir = Directory('$cwd/.cc-runs/bash-output')
        ..createSync(recursive: true);
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final file = File('${dir.path}/out-$stamp.log');
      // Closed in _SpillFile.finalize(); the analyzer can't see across the class.
      // ignore: close_sinks
      final sink = file.openWrite();
      final rel = '.cc-runs/bash-output/${file.uri.pathSegments.last}';
      return _SpillFile(file, sink, rel);
    } on Object {
      return null;
    }
  }

  /// Operator-approved exec roots for [cwd], asking once per undecided tree.
  /// A failure here never fails the command: it falls back to the stricter,
  /// pre-grant rules.
  Future<List<String>> _execGrantRoots(String cwd) async {
    final service = execGrantService;
    final wsId = workspaceId ?? '';
    if (service == null || wsId.isEmpty) {
      return const [];
    }
    try {
      return await service.approvedRoots(
        workspaceId: wsId,
        candidateRoots: [cwd],
        spaceId: conversationId,
      );
    } on Object catch (e) {
      CcInfraLog.warning(
        'harness command runner: exec-grant resolution failed, '
        'continuing without grants: $e',
      );
      return const [];
    }
  }

  Future<SandboxConfig> _buildSandboxConfig(String cwd) async {
    final home = Platform.environment['HOME'];
    final sessionId =
        'harness-${agentId ?? 'oneshot'}::${conversationId ?? 'no-conv'}';
    final spec = SandboxSpec(
      sessionId: sessionId,
      workspaceId: workspaceId ?? '',
      agentId: agentId,
      bindMounts: [SandboxBindMount(hostPath: cwd, guestPath: cwd)],
      guestWorkdir: cwd,
      networkEnabled: _capabilities.canAccessNetwork,
      mode: _mode,
      capabilities: _capabilities,
      protectedPaths: await _protectedPaths?.call() ?? const [],
      execGrantRoots: await _execGrantRoots(cwd),
    );
    final policy = const SandboxPolicyResolver().resolve(
      spec: spec,
      capabilities: _capabilities,
      homeDir: (home != null && home.isNotEmpty) ? home : null,
      runDir: '$cwd/.cc-runs/$sessionId',
    );
    return buildSandboxConfigFromPolicy(policy);
  }
}

/// Accumulates streamed process output with bounded memory: the first `headCap`
/// characters (20%) are kept verbatim and the most recent `tailCap` characters
/// (80%) roll, so both the command's setup logs and its final result survive a
/// flood without buffering the entire stream. Never retains more than roughly
/// `maxChars` characters regardless of how much the command emits.
class _BoundedOutput {
  _BoundedOutput(this.maxChars, {this.spill})
    : headCap = (maxChars * 0.2).floor();

  final int maxChars;
  final int headCap;

  /// Optional full-output sink (the spill file); receives every chunk raw.
  final IOSink? spill;

  final StringBuffer _head = StringBuffer();
  final StringBuffer _tail = StringBuffer();
  int _total = 0;

  /// Whether the collected output exceeded [maxChars] (inline is truncated).
  bool get wasTruncated => _total > maxChars;

  void add(String s) {
    spill?.write(s);
    _total += s.length;
    if (_head.length < headCap) {
      final room = headCap - _head.length;
      if (s.length <= room) {
        _head.write(s);
        return;
      }
      _head.write(s.substring(0, room));
      s = s.substring(room);
    }
    _tail.write(s);
    final tailCap = maxChars - headCap;
    // Trim with slack so we are not re-slicing on every chunk.
    if (_tail.length > tailCap + 4096) {
      final t = _tail.toString();
      _tail
        ..clear()
        ..write(t.substring(t.length - tailCap));
    }
  }

  String render() {
    if (_total <= maxChars) {
      return _head.toString() + _tail.toString();
    }
    final tailCap = maxChars - headCap;
    var tail = _tail.toString();
    if (tail.length > tailCap) {
      tail = tail.substring(tail.length - tailCap);
    }
    final omitted = _total - _head.length - tail.length;
    return '$_head\n\n… [$omitted characters truncated] …\n\n$tail';
  }
}

/// A best-effort stdout spill file: the full untruncated output is streamed here
/// so the agent can `read` the middle that inline head/tail truncation drops.
class _SpillFile {
  _SpillFile(this._file, this.sink, this._relativePath);

  final File _file;

  /// The sink [_BoundedOutput] writes every chunk to.
  final IOSink sink;

  final String _relativePath;

  /// Flushes and closes the sink. When [keep] is true (stdout was truncated)
  /// the workspace-relative path is returned; otherwise the file is deleted and
  /// null is returned. Never throws.
  Future<String?> finalize({required bool keep}) async {
    try {
      await sink.flush();
      await sink.close();
      if (!keep) {
        if (_file.existsSync()) {
          _file.deleteSync();
        }
        return null;
      }
      return _relativePath;
    } on Object {
      return null;
    }
  }
}
