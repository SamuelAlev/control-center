import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';
import 'package:cc_domain/features/sandboxing/domain/repositories/sandbox_exec_grant_repository.dart';

/// Operator conversation for running binaries from an agent's worktree →
/// sandbox exec roots.
///
/// macOS denies `process-exec` under `$HOME`, which also blocks
/// `node_modules/.bin` / `.venv/bin` in CoW worktrees — ask once per tree.
/// [approvedRoots] asks before the Seatbelt profile is written (fixed for the
/// process). [recordDeniedExec] asks after a surprise denial; applies on the
/// next command (harness) or next dispatch (CLI).
///
/// SERVER-created disposable trees are the exception, not a second rule:
/// `managedRoots` (see [approvedRoots]) are the provisioner's per-space
/// worktrees and per-conversation overlays, and exec under one is granted
/// without asking. Those roots are per conversation, so keying the prompt on
/// them made every new conversation — and every directory under one — ask
/// again about a copy the server had just made for the agent; a stored
/// decision still wins, and an explicit deny on a subtree beneath a managed
/// root withholds that whole root, because a profile cannot express the
/// subtraction.
class SandboxExecGrantService {
  /// Creates a [SandboxExecGrantService].
  SandboxExecGrantService({
    required SandboxExecGrantRepository repository,
    ConfirmationPort? confirmationPort,
    required this._idFactory,
    DateTime Function()? clock,
  }) : _repo = repository,
       _confirm = confirmationPort,
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
  /// [managedRoots] are SERVER-created disposable trees — the provisioner's
  /// per-space worktrees and the per-conversation overlays under them. A
  /// candidate covered by one is granted WITHOUT asking, and without a row:
  /// the server made that throwaway copy for the agent to work in, so there is
  /// nothing here for the operator to weigh, and the overlay's
  /// per-conversation name would otherwise re-ask on every new conversation.
  /// Never list a durable or operator-chosen path (an original checkout,
  /// `$HOME`, an agent's own config dir, a read-only mount): those stay a
  /// decision, exactly as before.
  ///
  /// A stored decision still decides first, for every candidate including a
  /// managed one, so an explicit `deny` — or a broader covering deny — keeps
  /// the tree blocked and is never overridden by the implicit grant. An
  /// explicit `allow` likewise answers without the implicit path.
  ///
  /// An explicit deny on a DESCENDANT of an approved candidate withholds that
  /// candidate too. A profile carries exec-roots as one allow list, so it
  /// cannot express "everything under this tree except that subtree" — reaching
  /// for the root would silently re-open the path the operator refused, and
  /// asking again would nag about a tree they already answered. Withholding the
  /// root fails closed instead, and the operator's refusal survives.
  ///
  /// A [ConfirmationPort] is only needed for the ASK. With none wired, an
  /// unmanaged candidate is withheld and nothing is recorded — fail-closed,
  /// matching the action guard's "prompt with no approver ⇒ deny" — while a
  /// managed candidate is still granted, because it never needed an answer.
  Future<List<String>> approvedRoots({
    required String workspaceId,
    required List<String> candidateRoots,
    List<String> managedRoots = const [],
    String? spaceId,
    String? principalId,
    String? label,
  }) async {
    final approved = <String>[];
    // Read lazily: a denied or undecided unmanaged candidate needs no full scan.
    List<SandboxExecGrant>? decisions;
    for (final root in candidateRoots.toSet()) {
      if (root.isEmpty) {
        continue;
      }
      final existing = await _repo.decisionFor(workspaceId, root);
      if (existing != null) {
        if (existing.decision == SandboxExecGrantDecision.allow &&
            !_hasDeniedDescendant(
              decisions ??= await _repo.grants(workspaceId),
              root,
            )) {
          approved.add(root);
        }
        continue;
      }
      if (_isManaged(root, managedRoots)) {
        final all = decisions ??= await _repo.grants(workspaceId);
        if (!_hasDeniedDescendant(all, root)) {
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
  ///
  /// [managedRoots] follows [approvedRoots]: a denial inside a server-created
  /// disposable tree is already covered, so the enclosing root comes back as
  /// granted and no prompt is raised for a tree the operator was never asked
  /// about. A stored decision — including a deny, and including one on a
  /// descendant, which [approvedRoots] answers by withholding the root — still
  /// wins; a tree held closed that way has nothing to announce.
  Future<String?> recordDeniedExec({
    required String workspaceId,
    required String deniedPath,
    required List<String> candidateRoots,
    List<String> managedRoots = const [],
    String? spaceId,
    String? principalId,
  }) async {
    final root = _enclosingRoot(deniedPath, candidateRoots);
    if (root == null) {
      return null;
    }
    final existing = await _repo.decisionFor(workspaceId, root);
    if (existing != null) {
      if (existing.decision == SandboxExecGrantDecision.deny) {
        return null;
      }
      final decisions = await _repo.grants(workspaceId);
      return _hasDeniedDescendant(decisions, root) ? null : root;
    }
    if (_isManaged(root, managedRoots)) {
      // Covered beyond question: do not ask about, or record a decision for, a
      // tree the server created for this run alone.
      final decisions = await _repo.grants(workspaceId);
      return _hasDeniedDescendant(decisions, root) ? null : root;
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

  /// Whether [path] is at or beneath one of [managedRoots], on segment
  /// boundaries so a managed `/a/space` cannot cover an unmanaged
  /// `/a/space-secrets`.
  static bool _isManaged(String path, List<String> managedRoots) =>
      _enclosingRoot(path, managedRoots) != null;

  /// Whether any explicit deny sits at or beneath [root].
  ///
  /// A profile's exec grants are a single allow list, so a grant on
  /// [root] would swallow such a deny — the whole tree has to stay closed
  /// instead of re-opening the subtree the operator refused.
  static bool _hasDeniedDescendant(
    List<SandboxExecGrant> decisions,
    String root,
  ) {
    final prefix = root.endsWith('/') ? root : '$root/';
    for (final decision in decisions) {
      if (decision.decision == SandboxExecGrantDecision.deny &&
          (decision.path == root || decision.path.startsWith(prefix))) {
        return true;
      }
    }
    return false;
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
