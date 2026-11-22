import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/shell_action_classifier.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_comment_port.dart'
    show kAgentShellGitHubWriteRefusal;
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart'
    show kAgentShellPrCreateRefusal;
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_config.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_infra/src/harness/script_approval_check.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/process/agent_shell_process_service.dart';
import 'package:cc_infra/src/process/child_process.dart';
import 'package:cc_infra/src/process/process_tree.dart';
import 'package:cc_infra/src/sandboxing/process_group_supervisor.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';

/// Hands the waits on a person that something outside the runner holds while
/// a command runs (the agent run gateway asking about a `git push` the
/// command makes) to the tool call that started the command, so that call's
/// clocks stop for them as they do for the runner's own asks.
abstract interface class CommandWaitRelay {
  /// Registers [listener] for one command whose environment is [env].
  ///
  /// The returned [CommandWait.environment] is what the command's environment
  /// gains so its requests name this registration; [CommandWait.release] ends
  /// it. The registration authorizes nothing and decides nothing: [listener]
  /// hears only of asks the holder makes on its own account, and [decided]
  /// of what the holder decided about a request naming it: `false` when it
  /// denied one (a person declined, a script's budget refused it, the policy
  /// denied it), `true` when a person approved a card for one. A process can
  /// drop or borrow the name, so this labels the call's record and decides
  /// nothing.
  CommandWait register(
    PersonWaitListener listener,
    Map<String, String> env, {
    required void Function(bool approved) decided,
  });

  /// Holds [approvals], the budget of a code mode script of the run, until
  /// the returned call ends the hold.
  ///
  /// While it is held, every approval card the holder raises for the run
  /// counts against it and stops once it refuses, whichever of the run's
  /// commands the request comes from and whether or not it names one: a
  /// process in the sandbox can drop or borrow the name. The end call is
  /// idempotent; a closed holder holds nothing.
  void Function() holdScriptApprovals(ScriptApprovalBudget approvals);
}

/// One command's registration with a [CommandWaitRelay].
final class CommandWait {
  /// Creates a registration.
  const CommandWait({required this.environment, required this.release});

  /// Variables the command's environment gains.
  final Map<String, String> environment;

  /// Ends the registration. Idempotent.
  final void Function() release;
}

/// Runs the harness `bash` tool's commands through CC's command policy, the OS
/// sandbox and (for `prompt`-tier commands) the confirmation flow — the same
/// stack the external-CLI transports use.
///
/// When no [SandboxManager] is wired, commands start through [hostProcesses],
/// the run's own unconfined launcher, which the dispatch hands in only when
/// the host execution posture admitted the run outside a sandbox; without one
/// a command is refused, never run on the host.
class SandboxedHarnessCommandRunner implements HarnessCommandRunner {
  /// Creates a [SandboxedHarnessCommandRunner].
  SandboxedHarnessCommandRunner({
    this.sandboxSessionId,
    required this._mode,
    required this._networkEnabled,
    this._loopbackPorts = const [],
    this._environmentScope,
    this.sandboxManager,
    this.hostProcesses,
    this.confirmationPort,
    this.execGrantRootsResolver,
    this.sandboxSpec,
    this.actionGuard,
    this.workspaceId,
    this.agentId,
    this.conversationId,
    this.spaceId,
    this.runId,
    this.onBehalfOfUserId,
    this._protectedPaths,
    this._baseEnv = const {},
    this._maxOutputChars = 16000,
    HarnessShellRegistry? shellRegistry,
    this.scriptOrigins,
    this.callWaits,
    this.killTree = ChildProcess.killTree,
  }) : _shellRegistry = shellRegistry ?? HarnessShellRegistry.shared;

  /// Ends a command's tree on a stop, a timeout or a kill. Never called for
  /// a command whose exit was seen, except to end a background command's
  /// daemons once its run ended ([HarnessCommandObserver.sweepAfterExit]).
  final ProcessTreeKill killTree;

  /// The scripts running in this run, which name the execution an approval
  /// card raised by a script's command links to. Null leaves such a card
  /// without an origin.
  final RunScriptOrigins? scriptOrigins;

  /// Where a running command's person waits that the agent run gateway holds
  /// are registered, so the calling tool's clocks stop for them too. Null
  /// when the run has no gateway lease.
  final CommandWaitRelay? callWaits;

  /// Where each spawned command is recorded while it runs, so the space's
  /// TERMINALS list can show it and a person can stop it.
  final HarnessShellRegistry _shellRegistry;

  /// The OS sandbox manager, or null when this run is not sandboxed.
  final SandboxManager? sandboxManager;

  /// Starts commands when [sandboxManager] is null: the run's tool process
  /// launcher, unconfined only when the posture admitted the run on the host.
  /// Null with no [sandboxManager] refuses every command.
  final ToolProcessLauncher? hostProcesses;

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

  /// Answers which exec roots this RUN may execute from — the dispatch's own
  /// resolution, so the harness `bash` tool and an external CLI profile get
  /// equivalent scoped roots.
  ///
  /// A resolver rather than the command's cwd on purpose: the model names a
  /// cwd (a subdirectory of one of these roots), and resolving per named cwd
  /// made every `cd` a fresh, unknown tree that re-asked — or, worse, offered
  /// to widen onto a path the server never supplied. The resolver ignores the
  /// command entirely.
  ///
  /// This runner rebuilds its sandbox profile PER COMMAND, so an answer lands
  /// on the agent's very next attempt — unlike an external CLI adapter, which
  /// runs under one profile for the whole dispatch. Null leaves the
  /// writable-dir exec block fully closed.
  final Future<List<String>> Function()? execGrantRootsResolver;

  /// The sandbox spec of the run this runner serves, for its session id.
  ///
  /// A dispatch hands in its own, so a command sees exactly what the run's
  /// CLI would: its bind mounts (the overlay, the agent profile, the space's
  /// worktrees), its runner state and tool dirs, its exec grants. Without it
  /// the spec is built from the command's cwd alone. Rebuilt per command, so
  /// an exec grant answered mid-run applies to the next one.
  final Future<SandboxSpec> Function(String sessionId)? sandboxSpec;

  /// Workspace the run belongs to.
  final String? workspaceId;

  /// Agent the run belongs to.
  final String? agentId;

  /// Conversation identity used for the sandbox session.
  final String? conversationId;

  /// The run's `agent_run_logs` row, and the person it acts for: every guard
  /// row a command's check writes names both, as the harness gate's rows do.
  final String? runId;

  /// The person the run acts for, when one requested it.
  final String? onBehalfOfUserId;

  /// Space containing the conversation; guard rules, approvals and exec
  /// grants are scoped to this id, not to the conversation's own id.
  final String? spaceId;

  final Mode _mode;

  /// The run's network posture, resolved from the "network egress" rule when
  /// the run started.
  final bool _networkEnabled;

  /// Host loopback ports the command must reach — the agent run gateway that
  /// `git push` is routed through. See `SandboxSpec.loopbackPorts`.
  final List<int> _loopbackPorts;
  final String? _environmentScope;

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
    PersonWaitListener? personWait,
    String? parentToolCallId,
    HarnessCommandObserver? observer,
  }) async {
    var preApproved = false;
    // What a person decided for this command, and whether a request it made
    // was denied while it ran ([HarnessCommandResult.personVerdict]).
    var approvedByPerson = false;
    var deniedWhileRunning = false;
    // A script's command: its approval cards name the script, and what the
    // script may still ask of a person bounds them.
    final scripted = parentToolCallId != null && parentToolCallId.isNotEmpty;
    final origin = scripted ? scriptOrigins?.originOf(parentToolCallId) : null;
    final budget = scripted
        ? scriptOrigins?.approvalsOf(parentToolCallId)
        : null;
    // The command's caller stopped waiting: a card it raised comes down, and
    // an answer that arrives afterwards spawns nothing.
    final withdrawn = cancel?.whenCancelled;
    bool gone() => cancel?.isCancelled ?? false;
    // A script's command longer than the guard audit stores whole is refused
    // (and audited) before it is classified, asked about or spawned. A run's
    // loop refuses it first, before its hooks (`nestedCallRefusal`); this
    // holds for a runner a loop drives without that refusal.
    if (scripted) {
      final summary = 'bash: $command';
      if (ActionGuardService.scriptActionRefusal(summary) case final refusal?) {
        if (actionGuard != null && workspaceId != null) {
          await actionGuard!.check(
            workspaceId: workspaceId!,
            classes: {ActionClass.processSpawn},
            command: command,
            spaceId: spaceId,
            runId: runId,
            onBehalfOfUserId: onBehalfOfUserId,
            agentId: agentId,
            actionSummary: summary,
            origin:
                origin ?? ScriptCallOrigin(parentToolCallId: parentToolCallId),
          );
        }
        return HarnessCommandResult.deny(refusal);
      }
    }
    // 0. Pull requests are opened by the server's `open_pull_request` tool,
    // as the person who requested the run; the run's token cannot open
    // one. Refused before any approval is raised.
    final shellClasses = const ShellActionClassifier().classify(command);
    if (shellClasses.contains(ActionClass.prCreate)) {
      return HarnessCommandResult.deny(kAgentShellPrCreateRefusal);
    }
    // This run's GitHub token only reads: comments go through the server's
    // `comment_on_pull_request` tool and title or description edits through
    // `update_pull_request`; anything else is a person's to do.
    if (shellClasses.contains(ActionClass.prPublish) ||
        shellClasses.contains(ActionClass.vendorSyncWrite)) {
      return HarnessCommandResult.deny(kAgentShellGitHubWriteRefusal);
    }
    // 1a. Operator command rules (the policy store), when wired. A stored
    // rule is MORE specific than the built-in net, so it decides first; the
    // net below still runs as the floor, so a stored `allow` can never
    // loosen a mode preset that forbids the effect outright.
    final guard = actionGuard;
    // `processSpawn` for running anything at all, plus whatever the command
    // line itself does — so "Push to a remote: ask first" asks about
    // `git push` typed here as well as about the push gateway.
    final classes = {ActionClass.processSpawn, ...shellClasses};
    // Named branches let branch rules and branch-scoped standing approvals
    // decide, as the Claude Code hook does for the same command.
    final request = ActionRequest(
      classes: classes,
      command: command,
      refs: shellClasses.contains(ActionClass.gitPush)
          ? ShellActionClassifier.pushRefs(command) ?? const []
          : const [],
    );
    GuardVerdict? verdict;
    if (guard != null && workspaceId != null) {
      // A script's call that would ask a person counts its ask before the
      // check can raise the card ([reserveScriptAsk]), or, when the script
      // may not ask any more, is refused without asking: a denial nobody
      // was asked about. The ask is given back when no card went up.
      var reserved = false;
      if (budget != null) {
        final resolution = await guard.resolve(
          workspaceId: workspaceId!,
          classes: classes,
          command: command,
          spaceId: spaceId,
          agentId: agentId,
          mode: _mode,
          request: request,
        );
        if (guardWouldAsk(resolution)) {
          if (reserveScriptAsk([budget]) case final refusal?) {
            guard.recordOutcome(
              workspaceId: workspaceId!,
              resolution: scriptApprovalDenial(resolution, refusal),
              applied: ActionDecision.deny,
              classes: classes,
              agentId: agentId,
              spaceId: spaceId,
              runId: runId,
              onBehalfOfUserId: onBehalfOfUserId,
              actionSummary: 'bash: $command',
              command: command,
            );
            return HarnessCommandResult.deny(
              'Command denied by policy: $refusal',
            );
          }
          reserved = true;
        }
      }
      // A stored `prompt` rule asks the person inside the check, which tells
      // [personWait] exactly when it does.
      var asked = false;
      try {
        verdict = await guard.check(
          workspaceId: workspaceId!,
          classes: classes,
          command: command,
          spaceId: spaceId,
          runId: runId,
          onBehalfOfUserId: onBehalfOfUserId,
          conversationId: conversationId,
          agentId: agentId,
          mode: _mode,
          actionSummary: 'bash: $command',
          request: request,
          withdrawn: withdrawn,
          origin: origin,
          onPersonWait: (waiting) {
            if (waiting) {
              asked = true;
            }
            personWait?.call(waiting);
          },
          // A card the resolution above did not foresee (the policy changed
          // in between) takes the same step just before it goes up: counted,
          // or refused without a card.
          beforeCard: budget == null
              ? null
              : () {
                  if (reserved) {
                    return null;
                  }
                  final refusal = reserveScriptAsk([budget]);
                  reserved = refusal == null;
                  return refusal;
                },
        );
      } finally {
        if (reserved && !asked) {
          budget?.release();
        }
      }
      if (gone()) {
        return HarnessCommandResult.deny(_cancelledBeforeRun(command));
      }
      if (asked) {
        budget?.answered(
          approved: verdict.allowed,
          unanswered: verdict.unanswered,
        );
        approvedByPerson = verdict.allowed;
      }
      if (!verdict.allowed) {
        return HarnessCommandResult.deny(
          'Command denied by policy: ${verdict.reason ?? command}',
          // A card nobody answered is no person's verdict.
          personVerdict: asked && !verdict.unanswered
              ? ToolGateVerdict.denied
              : null,
        );
      }
      // The guard already asked and the human said yes, or a person approved
      // this exact command for a while; the net below must not ask again.
      preApproved =
          verdict.prompted || verdict.standingApprovalCovers(command: command);
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
        if (gone()) {
          return HarnessCommandResult.deny(_cancelledBeforeRun(command));
        }
        if (reserveScriptAsk([?budget]) case final refusal?) {
          if (guard != null && workspaceId != null) {
            if (verdict?.resolution case final resolution?) {
              guard.recordOutcome(
                workspaceId: workspaceId!,
                resolution: scriptApprovalDenial(resolution, refusal),
                applied: ActionDecision.deny,
                classes: classes,
                agentId: agentId,
                spaceId: spaceId,
                runId: runId,
                onBehalfOfUserId: onBehalfOfUserId,
                actionSummary: 'bash: $command',
                command: command,
              );
            }
          }
          return HarnessCommandResult.deny(
            'Command denied by policy: $refusal',
          );
        }
        var unanswered = false;
        final approved = await _waitingOnPerson(
          personWait,
          () => port.requestApproval(
            ActionGuardService.approvalRequest(
              resolution: verdict?.resolution,
              classes: classes,
              askedByPolicy: false,
              request: request,
              spaceId: spaceId,
              conversationId: conversationId,
              workspaceId: workspaceId,
              agentId: agentId,
              actionSummary: 'bash: $command',
              severity: ConfirmationSeverity.warning,
              kind: ConfirmationKind.command,
              withdrawn: withdrawn,
              origin: origin,
              runId: runId,
              onUnanswered: () => unanswered = true,
            ),
          ),
        );
        if (gone()) {
          // Answered, or withdrawn, after the caller stopped waiting: the
          // command is never spawned.
          return HarnessCommandResult.deny(_cancelledBeforeRun(command));
        }
        budget?.answered(approved: approved, unanswered: unanswered);
        if (!approved) {
          // A card nobody answered is no person's verdict.
          return unanswered
              ? HarnessCommandResult.deny(
                  'Command not run, $kUnansweredCardReason: $command',
                )
              : HarnessCommandResult.deny(
                  'Command denied by user: $command',
                  personVerdict: ToolGateVerdict.denied,
                );
        }
        approvedByPerson = true;
      case CommandDecision.allow:
        break;
    }

    // 2. Build argv + working directory.
    final cwd = workdir ?? Directory.current.path;
    final argv = ['bash', '-lc', command];

    // While the command runs, a wait on a person the agent run gateway holds
    // for it (a push waiting for approval) reaches this call's listener.
    // Released when the command returns, so a process it left behind holds a
    // registration that is gone.
    final relay = callWaits;
    CommandWait? wait;
    Map<String, String> withWait(Map<String, String> environment) {
      if (relay == null || personWait == null) {
        return environment;
      }
      final registered = wait ??= relay.register(
        personWait,
        environment,
        decided: (approved) {
          if (approved) {
            approvedByPerson = true;
          } else {
            deniedWhileRunning = true;
          }
        },
      );
      return {...environment, ...registered.environment};
    }

    // The command runs in a process group of its own, under the watcher
    // (outside the OS sandbox), so a kill reaches everything it started and
    // a server that dies takes the group down with it. Windows has no
    // watcher; `ChildProcess.killTree` ends the tree there.
    ({String executable, List<String> argv}) grouped(
      String executable,
      List<String> args,
    ) => canSuperviseProcessGroup
        ? superviseProcessGroup(executable, args)
        : (executable: executable, argv: args);

    // Every process the command starts carries this in its environment, so a
    // kill still finds one that left its tree (a daemon).
    final marker = newProcessTreeMarker();
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
        final launch = grouped(wrap.executable, wrap.argv);
        process = await ChildProcess.start(
          launch.executable,
          launch.argv,
          workingDirectory: cwd,
          environment: withWait({
            ...wrap.environment,
            ..._baseEnv,
            ...?env,
            processTreeMarkerVariable: marker,
          }),
          toolchain: true,
        );
      } else if (hostProcesses case final launcher?) {
        final launch = grouped(argv.first, argv.skip(1).toList());
        process = await launcher.start(
          launch.executable,
          launch.argv,
          workingDirectory: cwd,
          environment: withWait({
            ..._baseEnv,
            ...?env,
            processTreeMarkerVariable: marker,
          }),
        );
      } else {
        return HarnessCommandResult.deny(
          'No sandbox is available to run commands in: $command',
        );
      }

      observer?.onStarted?.call();
      String? outputId;
      final unregister = _shellRegistry.register(
        pid: process.pid,
        workspaceId: workspaceId,
        spaceId: spaceId,
        agentId: agentId,
        command: command,
        onRegistered: (id) => outputId = id,
      );
      unawaited(process.exitCode.then((_) => unregister()));

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
      final outSub = process.stdout.transform(decoder).listen((chunk) {
        outSink.add(chunk);
        observer?.onOutput?.call(chunk);
        if (outputId case final id?) {
          _shellRegistry.append(id, chunk);
        }
      });
      final errSub = process.stderr.transform(decoder).listen((chunk) {
        errSink.add(chunk);
        observer?.onOutput?.call(chunk);
        if (outputId case final id?) {
          _shellRegistry.append(id, chunk);
        }
      });

      // Kill the command's whole tree as soon as the run is cancelled (the
      // user stopped the agent, or a background command was killed or ended
      // with its run) — otherwise a long command would keep running until its
      // own timeout, and what it started would outlive it. Idempotent with
      // the timeout kill below.
      //
      // Never for a command whose exit was seen: its pid may belong to
      // another process by now. The token outlives the command (a run's
      // token, a script's), so a cancel long after the exit is normal and
      // sends nothing; only a background command's run end still ends its
      // daemons, found by [marker] alone.
      var exited = false;
      unawaited(process.exitCode.then((_) => exited = true));
      Future<void>? treeKill;
      Future<void> endTree() => treeKill ??= killTree(
        process.pid,
        exited: () => exited,
        marker: marker,
      );
      var cancelled = false;
      void onCancel() {
        if (!exited) {
          cancelled = true;
          unawaited(endTree());
        } else if (observer?.sweepAfterExit ?? false) {
          unawaited(endTree());
        }
      }

      final cancelSub = cancel?.whenCancelled.then((_) => onCancel());
      if (cancel != null && cancel.isCancelled) {
        onCancel();
      }

      var timedOut = false;
      final exitCode = await process.exitCode.timeout(
        Duration(seconds: timeoutSeconds),
        onTimeout: () async {
          timedOut = true;
          await endTree();
          return 124;
        },
      );
      // Stop listening for cancellation once the process has exited.
      unawaited(cancelSub);
      // A kill returns once the whole tree is gone, not only the command.
      if (treeKill case final kill?) {
        await kill;
      }
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
        personVerdict: deniedWhileRunning
            ? ToolGateVerdict.denied
            : approvedByPerson
            ? ToolGateVerdict.approved
            : null,
      );
    } on Object catch (e) {
      return HarnessCommandResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Failed to run command: $e',
      );
    } finally {
      wait?.release();
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

  static String _cancelledBeforeRun(String command) =>
      'Command cancelled before it ran: $command';

  /// Runs [ask], which may wait on a person, with [personWait] told when the
  /// wait starts and ends, so the caller's clocks stop for exactly that time.
  static Future<T> _waitingOnPerson<T>(
    PersonWaitListener? personWait,
    Future<T> Function() ask,
  ) async {
    personWait?.call(true);
    try {
      return await ask();
    } finally {
      personWait?.call(false);
    }
  }

  /// The exec roots the dispatch resolved for this run (see
  /// [execGrantRootsResolver]). Never derived from the command's cwd. A failure
  /// here never fails the command: it falls back to the stricter, pre-grant
  /// rules.
  Future<List<String>> _execGrantRoots() async {
    final resolve = execGrantRootsResolver;
    if (resolve == null) {
      return const [];
    }
    try {
      return await resolve();
    } on Object catch (e) {
      CcInfraLog.warning(
        'harness command runner: exec-grant resolution failed, '
        'continuing without grants: $e',
      );
      return const [];
    }
  }

  /// The sandbox session commands run in; the dispatch names one per run so
  /// it can release it when the run ends.
  final String? sandboxSessionId;

  String get _sandboxSessionId =>
      sandboxSessionId ??
      'harness-${agentId ?? 'oneshot'}::${conversationId ?? 'no-conv'}';

  Future<SandboxConfig> _buildSandboxConfig(String cwd) async {
    final runSpec = await sandboxSpec?.call(_sandboxSessionId);
    return processSandboxConfig(
      runSpec ??
          processSandboxSpec(
            sessionId: _sandboxSessionId,
            workspaceId: workspaceId ?? '',
            agentId: agentId,
            workdir: cwd,
            networkEnabled: _networkEnabled,
            mode: _mode,
            protectedPaths: await _protectedPaths?.call() ?? const [],
            execGrantRoots: await _execGrantRoots(),
            loopbackPorts: _loopbackPorts,
            environmentScope: _environmentScope,
          ),
    );
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
