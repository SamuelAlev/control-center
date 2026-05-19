import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/services/slugify.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_step.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show RepoScriptService;

/// PR-review provisioning context: when a space is linked to a pull request,
/// its repo worktree is checked out at the PR head ref (`headRef`, e.g.
/// `refs/pull/42/head`) on `branch` (e.g. `pr/42`) instead of the default base,
/// so the conversation's worktree IS the PR's proposed tree.
typedef PrProvisionContext = ({
  String headRef,
  String repoFullName,
  String branch,
});

/// Background-provisions a space's conversation workspace at creation time:
/// repo worktrees + per-agent overlay + derived `.mcp.json`, so the first agent
/// turn doesn't pay the setup cost.
///
/// Provisioning runs **unawaited** off the `SpaceCreated` domain event
/// (the user can keep using the app). Message dispatch is gated on the
/// space's `provisioningStatus` until this flips it to `ready` (or `failed`).
///
/// `ensureSpaceWorkspace` is best-effort and never throws, so success is
/// verified post-hoc: every linked repo must have an on-disk worktree row and
/// every agent overlay must contain `.mcp.json`.
class SpaceProvisioningService {
  /// Creates a [SpaceProvisioningService].
  SpaceProvisioningService({
    required RepoWorkspaceProvisionerPort provisioner,
    required Future<void> Function(
      String cwd, {
      String? workspaceId,
      String? agentId,
      String? conversationId,
    })
    writeMcpConfig,
    required AgentRepository agentRepository,
    required MessagingRepository messagingRepository,
    required WorkspaceRepository workspaceRepository,
    required IsolatedRepoRepository isolatedRepoRepository,
    required Future<void> Function(
      String workspaceId,
      String spaceId,
      SpaceProvisioningStatus status,
    )
    setProvisioningStatus,
    Future<void> Function(
      String workspaceId,
      String spaceId,
      SpaceProvisioningStep step,
    )?
    setProvisioningStep,
    Future<PrProvisionContext?> Function(String workspaceId, String spaceId)?
    resolvePrContext,
    Future<List<String>?> Function(String workspaceId, String spaceId)?
    spaceRepoIds,
    DomainEventBus? eventBus,
    Duration timeout = const Duration(minutes: 10),
    Future<int> Function(String workspaceId)? setupScriptedRepoCount,
  }) : _provisioner = provisioner,
       _writeMcpConfig = writeMcpConfig,
       _agentRepository = agentRepository,
       _messagingRepository = messagingRepository,
       _workspaceRepository = workspaceRepository,
       _isolatedRepoRepository = isolatedRepoRepository,
       _setProvisioningStatus = setProvisioningStatus,
       _setProvisioningStep = setProvisioningStep,
       _resolvePrContext = resolvePrContext,
       _spaceRepoIds = spaceRepoIds,
       _eventBus = eventBus,
       _timeout = timeout,
       _setupScriptedRepoCount = setupScriptedRepoCount;

  final RepoWorkspaceProvisionerPort _provisioner;
  final Future<void> Function(
    String cwd, {
    String? workspaceId,
    String? agentId,
    String? conversationId,
  })
  _writeMcpConfig;
  final AgentRepository _agentRepository;
  final MessagingRepository _messagingRepository;
  final WorkspaceRepository _workspaceRepository;
  final IsolatedRepoRepository _isolatedRepoRepository;
  final Future<void> Function(
    String workspaceId,
    String spaceId,
    SpaceProvisioningStatus status,
  )
  _setProvisioningStatus;

  /// Publishes the granular step an in-flight provision is on (cloning repo X,
  /// setting up agent Y) so clients can render live progress instead of a
  /// static "preparing" label. Optional — null means no progress surface.
  final Future<void> Function(
    String workspaceId,
    String spaceId,
    SpaceProvisioningStep step,
  )?
  _setProvisioningStep;
  final Future<PrProvisionContext?> Function(
    String workspaceId,
    String spaceId,
  )?
  _resolvePrContext;

  /// Announces the same progress the space row records, for the surfaces that
  /// are not watching a row — the chat bridge reports it on its task card so a
  /// reader in Slack is not left watching nothing for the length of a clone.
  final DomainEventBus? _eventBus;

  /// Watchdog for the whole provision run: a hung step (e.g. a git fetch that
  /// never returns) flips the space to `failed` — which carries a retry
  /// affordance — instead of leaving it behind an eternal spinner.
  final Duration _timeout;

  /// How many of the workspace's repos have a setup script configured, when
  /// the host can answer. Each scripted repo's setup run is bounded by its own
  /// timeout (default 5 min) but happens INSIDE this service's watchdog, so
  /// the watchdog is extended by one budget per scripted repo — otherwise a
  /// legitimate `pnpm install` would flip the space to `failed` while the
  /// script was still making progress.
  final Future<int> Function(String workspaceId)? _setupScriptedRepoCount;

  /// Spaces stopped through [cancel], so the run unwinding afterwards reports
  /// "stopped" instead of overwriting it with `failed`.
  final Set<String> _cancelledSpaces = {};

  /// Resolves the repo ids a space selected at creation. Null result → no
  /// selection recorded, provision all workspace repos; an EMPTY list → the
  /// space explicitly checks out nothing. Null callback (or absent) means all
  /// repos.
  final Future<List<String>?> Function(String workspaceId, String spaceId)?
  _spaceRepoIds;

  /// Provisions (or re-provisions on retry) the workspace for [spaceId].
  ///
  /// Short-circuits to `ready` when there is nothing to provision (no linked
  /// repos or no participant agents). Sets `failed` when verification detects a
  /// missing worktree or overlay, when the run throws, or when it exceeds the
  /// watchdog timeout — never leaves the space stranded in `provisioning`.
  ///
  /// A deliberate re-provision clears any standing stop first, so the banner's
  /// Retry works after [cancel].
  Future<void> provision({
    required String workspaceId,
    required String spaceId,
  }) async {
    _provisioner.clearSpaceProvisioningCancellation(workspaceId, spaceId);
    _cancelledSpaces.remove(_key(workspaceId, spaceId));
    await _setStatus(
      workspaceId,
      spaceId,
      SpaceProvisioningStatus.provisioning,
    );
    try {
      await _provision(
        workspaceId: workspaceId,
        spaceId: spaceId,
      ).timeout(await _effectiveTimeout(workspaceId));
    } on Object catch (e, st) {
      if (_wasCancelled(workspaceId, spaceId)) {
        // Stopped, not broken. [cancel] already wrote the terminal status;
        // writing `failed` over it here would blame a failure on work the
        // operator interrupted.
        CcHostLog.info('space provisioning: $spaceId was stopped');
        return;
      }
      CcHostLog.error(
        'space provisioning: $spaceId did not complete: $e',
        e,
        st,
      );
      // `failed` (not `provisioning`) so the UI offers a retry. On a timeout
      // the underlying run is not cancelled — if it eventually finishes it
      // writes its own terminal status over this one, which is strictly newer
      // information.
      await _setStatus(workspaceId, spaceId, SpaceProvisioningStatus.failed);
    }
  }

  /// Stops the in-flight provision of [spaceId]: kills the running git command
  /// (a clone/fetch is minutes of work nobody can otherwise interrupt), leaves
  /// no further repo to materialize and flips the space to `cancelled`.
  ///
  /// Cancelling reaches BOTH provisioning paths, because the provisioner keys
  /// its cancellation by space rather than by caller: this background run and
  /// the inline one a dispatch makes while resolving its working directory.
  /// Stopping only this one would leave the clone finishing on the other.
  ///
  /// Idempotent and safe on a space that is already ready/failed — it simply
  /// records the stop so a run that starts moments later is refused too.
  Future<void> cancel({
    required String workspaceId,
    required String spaceId,
  }) async {
    _cancelledSpaces.add(_key(workspaceId, spaceId));
    _provisioner.cancelSpaceProvisioning(workspaceId, spaceId);
    await _setStatus(workspaceId, spaceId, SpaceProvisioningStatus.cancelled);
  }

  /// Whether [spaceId]'s current run was stopped — asked of this service AND of
  /// the provisioner, because the stop can arrive at either (the pipeline
  /// cancels through the provisioner directly).
  bool _wasCancelled(String workspaceId, String spaceId) =>
      _cancelledSpaces.contains(_key(workspaceId, spaceId)) ||
      _provisioner.isSpaceProvisioningCancelled(workspaceId, spaceId);

  static String _key(String workspaceId, String spaceId) =>
      '$workspaceId/$spaceId';

  /// The watchdog for this run: the base timeout plus one setup-script budget
  /// per scripted repo (see [_setupScriptedRepoCount]). Counted over all the
  /// workspace's repos rather than just this space's selection — conservative,
  /// and answerable without duplicating the space's scope resolution here.
  Future<Duration> _effectiveTimeout(String workspaceId) async {
    final counter = _setupScriptedRepoCount;
    if (counter == null) {
      return _timeout;
    }
    try {
      final count = await counter(workspaceId);
      if (count <= 0) {
        return _timeout;
      }
      return _timeout + RepoScriptService.defaultSetupTimeout * count;
    } on Object catch (e) {
      CcHostLog.warning('space provisioning: scripted repo count failed: $e');
      return _timeout;
    }
  }

  Future<void> _provision({
    required String workspaceId,
    required String spaceId,
  }) async {
    // Nothing to provision without repos → ready immediately.
    final repos = await _workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    if (repos.isEmpty) {
      await _setStatus(workspaceId, spaceId, SpaceProvisioningStatus.ready);
      return;
    }

    // A PR-review space checks its repo out at the PR head ref (so the
    // terminal / file editor / agent all see the PR's proposed tree).
    final prContext = await _resolvePrContext?.call(workspaceId, spaceId);

    // The repos this space actually provisions: a PR space scopes to the
    // ONE repo under review; a regular space provisions the repos it selected
    // at creation (all workspace repos when no selection was recorded, none
    // at all when it explicitly selected none).
    final Set<String> targetRepoIds;
    if (prContext != null) {
      targetRepoIds = {
        for (final r in repos)
          if ('${r.remoteOwner}/${r.remoteName}' == prContext.repoFullName)
            r.id,
      };
    } else {
      final selected = await _spaceRepoIds?.call(workspaceId, spaceId);
      final workspaceRepoIds = repos.map((r) => r.id).toSet();
      targetRepoIds = selected == null
          ? workspaceRepoIds
          : selected.toSet().intersection(workspaceRepoIds);
    }
    // Nothing to check out: the PR's repo isn't linked, or the space was
    // created with every repo deselected → ready without worktrees (the same
    // state as a space in a repo-less workspace).
    if (targetRepoIds.isEmpty) {
      await _setStatus(workspaceId, spaceId, SpaceProvisioningStatus.ready);
      return;
    }

    final participants = await _messagingRepository.getParticipants(
      workspaceId,
      spaceId,
    );
    final agents = await _loadAgents(workspaceId, participants);
    if (agents.isEmpty) {
      // No agents yet. A PR space still provisions its repo worktree at the
      // head so chat/terminal/files work before the first agent is summoned;
      // an ordinary empty space short-circuits to ready.
      if (prContext == null) {
        await _setStatus(workspaceId, spaceId, SpaceProvisioningStatus.ready);
        return;
      }
      await _provisioner.ensureSpaceWorkspace(
        workspaceId: workspaceId,
        spaceId: spaceId,
        agentSlug: '_pr',
        fallbackDir: '',
        prHeadRef: prContext.headRef,
        prHeadRepoFullName: prContext.repoFullName,
        prBranch: prContext.branch,
        repoAllowlist: targetRepoIds,
        onRepoProvision: _repoStepEmitter(workspaceId, spaceId),
        onRepoSetupScript: _setupScriptStepEmitter(workspaceId, spaceId),
      );
      if (_wasCancelled(workspaceId, spaceId)) {
        return;
      }
      final ready = await _verify(
        workspaceId: workspaceId,
        spaceId: spaceId,
        repoCount: targetRepoIds.length,
        overlays: const [],
      );
      await _setStatus(
        workspaceId,
        spaceId,
        ready ? SpaceProvisioningStatus.ready : SpaceProvisioningStatus.failed,
      );
      return;
    }

    // Provision each agent's overlay + write its derived `.mcp.json`.
    final overlays = <String>[];
    for (final agent in agents) {
      // A stop during the first agent's clone must not be answered by
      // provisioning the next agent's overlay.
      if (_wasCancelled(workspaceId, spaceId)) {
        return;
      }
      try {
        final agentSlug = _slugFor(agent);
        final agentConfigDir = _agentConfigDir(agent.agentMdPath);
        _emitStep(
          workspaceId,
          spaceId,
          SpaceProvisioningStep(
            kind: SpaceProvisioningStepKind.agent,
            subject: agent.name.isNotEmpty ? agent.name : agentSlug,
          ),
        );
        final overlay = await _provisioner.ensureSpaceWorkspace(
          workspaceId: workspaceId,
          spaceId: spaceId,
          agentSlug: agentSlug,
          fallbackDir: agentConfigDir,
          agentConfigDir: agentConfigDir,
          prHeadRef: prContext?.headRef,
          prHeadRepoFullName: prContext?.repoFullName,
          prBranch: prContext?.branch,
          repoAllowlist: targetRepoIds,
          // The first agent's call materializes the shared repo worktrees, so
          // its repo steps overwrite the agent step until checkout completes.
          onRepoProvision: _repoStepEmitter(workspaceId, spaceId),
          onRepoSetupScript: _setupScriptStepEmitter(workspaceId, spaceId),
        );
        // Track the overlay before writing `.mcp.json` so verification always
        // checks it — a failed write leaves `.mcp.json` absent, which `_verify`
        // catches and reports as `failed`.
        overlays.add(overlay);
        await _writeMcpConfig(
          overlay,
          workspaceId: workspaceId,
          agentId: agent.id,
          conversationId: spaceId,
        );
      } on Object catch (e, st) {
        CcHostLog.error(
          'space provisioning: overlay failed for agent ${agent.id}: $e',
          e,
          st,
        );
      }
    }

    // Stopped mid-run: `cancel` already wrote the terminal status, so leave it
    // alone rather than reporting a verification that was never going to pass.
    if (_wasCancelled(workspaceId, spaceId)) {
      return;
    }

    // Verify: every TARGET repo has a worktree row AND every overlay has
    // `.mcp.json`. `ensureSpaceWorkspace` never throws, so this is the
    // authoritative success signal.
    final ready = await _verify(
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoCount: targetRepoIds.length,
      overlays: overlays,
    );

    await _setStatus(
      workspaceId,
      spaceId,
      ready ? SpaceProvisioningStatus.ready : SpaceProvisioningStatus.failed,
    );
  }

  /// Records where provisioning stands, both on the space row (what clients
  /// watching the space read) and on the event bus (what the chat bridge
  /// reports on its card).
  Future<void> _setStatus(
    String workspaceId,
    String spaceId,
    SpaceProvisioningStatus status,
  ) async {
    await _setProvisioningStatus(workspaceId, spaceId, status);
    _announce(workspaceId, spaceId, status);
  }

  /// Publishes a step, fire-and-forget: progress is decorative, so a failed
  /// write must never fail (or slow) provisioning itself.
  void _emitStep(
    String workspaceId,
    String spaceId,
    SpaceProvisioningStep step,
  ) {
    final emit = _setProvisioningStep;
    if (emit == null) {
      return;
    }
    unawaited(
      emit(workspaceId, spaceId, step).catchError((Object e) {
        CcHostLog.warning('space provisioning: step publish failed: $e');
      }),
    );
    _announce(
      workspaceId,
      spaceId,
      SpaceProvisioningStatus.provisioning,
      step: step,
    );
  }

  /// Publishes progress, never throwing: this is a progress report and one that
  /// fails must not take provisioning with it.
  void _announce(
    String workspaceId,
    String spaceId,
    SpaceProvisioningStatus status, {
    SpaceProvisioningStep? step,
  }) {
    try {
      _eventBus?.publish(
        SpaceProvisioningChanged(
          workspaceId: workspaceId,
          spaceId: spaceId,
          status: status,
          step: step,
          occurredAt: DateTime.now(),
        ),
      );
    } on Object catch (e) {
      CcHostLog.warning('space provisioning: announce failed: $e');
    }
  }

  /// The [RepoWorkspaceProvisionerPort.ensureSpaceWorkspace] progress
  /// callback for [spaceId] in [workspaceId]: maps each materializing repo to
  /// a step.
  void Function(String, {required bool prHead}) _repoStepEmitter(
    String workspaceId,
    String spaceId,
  ) =>
      (repoName, {required bool prHead}) => _emitStep(
        workspaceId,
        spaceId,
        SpaceProvisioningStep(
          kind: prHead
              ? SpaceProvisioningStepKind.prCheckout
              : SpaceProvisioningStepKind.repo,
          subject: repoName,
        ),
      );

  /// Same, for the setup script of a freshly materialized repo worktree.
  void Function(String) _setupScriptStepEmitter(
    String workspaceId,
    String spaceId,
  ) =>
      (repoName) => _emitStep(
        workspaceId,
        spaceId,
        SpaceProvisioningStep(
          kind: SpaceProvisioningStepKind.script,
          subject: repoName,
        ),
      );

  Future<List<Agent>> _loadAgents(
    String workspaceId,
    List<SpaceParticipant> participants,
  ) async {
    final agents = <Agent>[];
    for (final p in participants) {
      if (p.isUser || p.principalId.isEmpty) {
        continue;
      }
      final agent = await _agentRepository.getById(workspaceId, p.principalId);
      if (agent != null) {
        agents.add(agent);
      }
    }
    return agents;
  }

  String _slugFor(Agent agent) {
    if (agent.name.isNotEmpty) {
      final slug = slugify(agent.name);
      if (slug.isNotEmpty) {
        return slug;
      }
    }
    return agent.id.isNotEmpty ? agent.id : 'oneshot';
  }

  /// Mirrors `workingDirectoryFromAgentMdPath` (cc_infra): the parent dir of
  /// the agent's `AGENTS.md` path, or `/tmp` when unset / pathless.
  String _agentConfigDir(String agentMdPath) {
    if (agentMdPath.isEmpty) {
      return '/tmp';
    }
    final i = agentMdPath.lastIndexOf('/');
    return i > 0 ? agentMdPath.substring(0, i) : '/tmp';
  }

  Future<bool> _verify({
    required String workspaceId,
    required String spaceId,
    required int repoCount,
    required List<String> overlays,
  }) async {
    final worktrees = await _isolatedRepoRepository.forSpace(
      workspaceId,
      spaceId,
    );
    if (worktrees.length < repoCount) {
      CcHostLog.warning(
        'space provisioning: $spaceId expected $repoCount worktree(s), '
        'found ${worktrees.length}',
      );
      return false;
    }
    for (final overlay in overlays) {
      if (!File('$overlay/.mcp.json').existsSync()) {
        CcHostLog.warning(
          'space provisioning: $spaceId overlay $overlay missing .mcp.json',
        );
        return false;
      }
    }
    return true;
  }
}
