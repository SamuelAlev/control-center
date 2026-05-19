import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';
import 'package:cc_domain/features/sandboxing/domain/repositories/sandbox_exec_grant_repository.dart';

/// Owns the operator conversation about running binaries from inside an
/// agent's worktree, and turns the answers into the exec roots the sandbox
/// profile re-opens.
///
/// **Why this needs a conversation at all.** The macOS profile denies
/// `process-exec` across `$HOME`, which is what stops a binary being written
/// somewhere writable and run from there. A CoW worktree lives under `$HOME`,
/// so the same rule blocks every tool a checked-out repo installs for itself —
/// `node_modules/.bin/husky`, `.venv/bin/pytest`. Neither outcome is right by
/// default: silently blocking them breaks ordinary work, and silently allowing
/// them re-opens the hole. So the operator is asked, once per tree.
///
/// **The two moments it can ask, and why both exist.** A Seatbelt profile is
/// written before the process starts and is fixed for that process's life, and
/// the kernel offers no "ask" verdict — so a denial observed mid-run can never
/// be rescued, only recorded. [approvedRoots] therefore asks BEFORE the profile
/// is generated, where an answer still changes the run in front of the
/// operator. [recordDeniedExec] is the fallback for a tree nobody anticipated:
/// it asks after the fact, and the answer applies from the next command (the
/// harness rebuilds its profile per command) or the next dispatch (an external
/// CLI runs under one profile for the whole run).
class SandboxExecGrantService {
  /// Creates a [SandboxExecGrantService].
  SandboxExecGrantService({
    required SandboxExecGrantRepository repository,
    ConfirmationPort? confirmationPort,
    required String Function() idFactory,
    DateTime Function()? clock,
  }) : _repo = repository,
       _confirm = confirmationPort,
       _idFactory = idFactory,
       _clock = clock ?? DateTime.now;

  final SandboxExecGrantRepository _repo;
  final ConfirmationPort? _confirm;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  /// Which of [candidateRoots] the sandbox may execute from, asking the
  /// operator once per tree that has no decision yet.
  ///
  /// Call this while building a sandbox config: the returned roots go into
  /// `SandboxSpec.execGrantRoots`, so an approval is already in the profile
  /// that is about to be written.
  ///
  /// With no [ConfirmationPort] wired this grants nothing and asks nothing —
  /// fail-closed, matching the action guard's "prompt with no approver ⇒ deny".
  Future<List<String>> approvedRoots({
    required String workspaceId,
    required List<String> candidateRoots,
    String? spaceId,
    String? principalId,
    String? label,
  }) async {
    final approved = <String>[];
    for (final root in candidateRoots.toSet()) {
      if (root.isEmpty) {
        continue;
      }
      final existing = await _repo.decisionFor(workspaceId, root);
      if (existing != null) {
        if (existing.decision == SandboxExecGrantDecision.allow) {
          approved.add(root);
        }
        continue;
      }
      final granted = await _ask(
        workspaceId: workspaceId,
        path: root,
        spaceId: spaceId,
        principalId: principalId,
        title: label == null
            ? 'Let agents run programs from this workspace copy?'
            : 'Let agents run programs from $label?',
        detail: _eagerDetail(root, label),
      );
      if (granted) {
        approved.add(root);
      }
    }
    return approved;
  }

  /// Records a `process-exec` denial the sandbox reported and asks whether the
  /// enclosing tree should be opened.
  ///
  /// [deniedPath] is the binary the kernel refused; [candidateRoots] are the
  /// session's worktrees. Returns the root that was just granted, or null when
  /// nothing was granted — including when [deniedPath] is outside every
  /// candidate root, which is deliberately NOT offered as a grant: a denial
  /// under `/nix/store` or `/usr` is a profile bug to fix, not a tree the
  /// operator should be talked into opening.
  Future<String?> recordDeniedExec({
    required String workspaceId,
    required String deniedPath,
    required List<String> candidateRoots,
    String? spaceId,
    String? principalId,
  }) async {
    final root = _enclosingRoot(deniedPath, candidateRoots);
    if (root == null) {
      return null;
    }
    final existing = await _repo.decisionFor(workspaceId, root);
    if (existing != null) {
      // Already answered — an allow that still produced a denial means the
      // profile predates the grant, and re-asking would not change that.
      return existing.decision == SandboxExecGrantDecision.allow ? root : null;
    }
    final granted = await _ask(
      workspaceId: workspaceId,
      path: root,
      spaceId: spaceId,
      principalId: principalId,
      title: 'Blocked: ${_basename(deniedPath)}',
      detail: _lazyDetail(deniedPath, root),
    );
    return granted ? root : null;
  }

  /// Every recorded decision in [workspaceId] (the Settings surface).
  Future<List<SandboxExecGrant>> grants(String workspaceId) =>
      _repo.grants(workspaceId);

  /// Live decisions in [workspaceId].
  Stream<List<SandboxExecGrant>> watchGrants(String workspaceId) =>
      _repo.watchGrants(workspaceId);

  /// Revokes a decision, so the operator is asked again next time.
  Future<void> revoke(String workspaceId, String id) =>
      _repo.revoke(workspaceId, id);

  Future<bool> _ask({
    required String workspaceId,
    required String path,
    required String title,
    required String detail,
    String? spaceId,
    String? principalId,
  }) async {
    final port = _confirm;
    if (port == null) {
      // No approver: grant nothing and record nothing. Recording a deny here
      // would turn a temporarily headless host into a permanent refusal the
      // operator never made.
      return false;
    }
    final approved = await port.requestApproval(
      ConfirmationRequest(
        spaceId: spaceId ?? '',
        workspaceId: workspaceId,
        title: title,
        detail: detail,
        severity: ConfirmationSeverity.warning,
        kind: ConfirmationKind.capabilityEscalation,
        command: path,
        fingerprint: 'sandbox-exec-grant:$path',
      ),
    );
    await _repo.upsert(
      SandboxExecGrant(
        id: _idFactory(),
        workspaceId: workspaceId,
        path: path,
        decision: approved
            ? SandboxExecGrantDecision.allow
            : SandboxExecGrantDecision.deny,
        createdBy: principalId,
        createdAt: _clock(),
      ),
    );
    return approved;
  }

  /// The longest candidate root containing [path], or null.
  static String? _enclosingRoot(String path, List<String> roots) {
    String? best;
    for (final root in roots) {
      if (root.isEmpty) {
        continue;
      }
      final prefix = root.endsWith('/') ? root : '$root/';
      if (path == root || path.startsWith(prefix)) {
        if (best == null || root.length > best.length) {
          best = root;
        }
      }
    }
    return best;
  }

  static String _basename(String path) {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }

  static String _eagerDetail(String root, String? label) =>
      'Agents work in a disposable copy of your repositories at:\n$root\n\n'
      'The sandbox blocks running programs from anywhere writable, which also '
      'blocks the tools a repository installs for itself — git hooks (husky), '
      'test runners, linters. Allowing this lets agents run any program under '
      'that copy, INCLUDING ones an agent writes there itself. Your real '
      'checkouts stay read-only either way.\n\n'
      'Declining keeps those tools blocked. You can change either answer later '
      'in Settings → Server → Sandbox.';

  static String _lazyDetail(String deniedPath, String root) =>
      'The sandbox refused to run:\n$deniedPath\n\n'
      'It sits inside the disposable copy agents work in ($root), where '
      'running programs is blocked by default. Allowing it opens that whole '
      'copy — including programs an agent writes there itself.\n\n'
      'This answer applies from the next command; the run that was just '
      'blocked cannot be resumed, because the sandbox rules are fixed when a '
      'run starts. Change it later in Settings → Server → Sandbox.';
}
