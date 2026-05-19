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
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_step.dart';
import 'package:cc_host/cc_host.dart';

/// PR-review provisioning context: when a channel is linked to a pull request,
/// its repo worktree is checked out at the PR head ref (`headRef`, e.g.
/// `refs/pull/42/head`) on `branch` (e.g. `pr/42`) instead of the default base,
/// so the conversation's worktree IS the PR's proposed tree.
typedef PrProvisionContext = ({
  String headRef,
  String repoFullName,
  String branch,
});

/// Background-provisions a channel's conversation workspace at creation time:
/// repo worktrees + per-agent overlay + derived `.mcp.json`, so the first agent
/// turn doesn't pay the setup cost.
///
/// Provisioning runs **unawaited** off the `ChannelCreated` domain event
/// (the user can keep using the app). Message dispatch is gated on the
/// channel's `provisioningStatus` until this flips it to `ready` (or `failed`).
///
/// `ensureConversationWorkspace` is best-effort and never throws, so success is
/// verified post-hoc: every linked repo must have an on-disk worktree row and
/// every agent overlay must contain `.mcp.json`.
class ChannelProvisioningService {
  /// Creates a [ChannelProvisioningService].
  ChannelProvisioningService({
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
      String channelId,
      ChannelProvisioningStatus status,
    )
    setProvisioningStatus,
    Future<void> Function(
      String workspaceId,
      String channelId,
      ChannelProvisioningStep step,
    )?
    setProvisioningStep,
    Future<PrProvisionContext?> Function(String workspaceId, String channelId)?
    resolvePrContext,
    Future<List<String>> Function(String workspaceId, String channelId)?
    channelRepoIds,
    DomainEventBus? eventBus,
    Duration timeout = const Duration(minutes: 10),
  }) : _provisioner = provisioner,
       _writeMcpConfig = writeMcpConfig,
       _agentRepository = agentRepository,
       _messagingRepository = messagingRepository,
       _workspaceRepository = workspaceRepository,
       _isolatedRepoRepository = isolatedRepoRepository,
       _setProvisioningStatus = setProvisioningStatus,
       _setProvisioningStep = setProvisioningStep,
       _resolvePrContext = resolvePrContext,
       _channelRepoIds = channelRepoIds,
       _eventBus = eventBus,
       _timeout = timeout;

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
    String channelId,
    ChannelProvisioningStatus status,
  )
  _setProvisioningStatus;

  /// Publishes the granular step an in-flight provision is on (cloning repo X,
  /// setting up agent Y) so clients can render live progress instead of a
  /// static "preparing" label. Optional — null means no progress surface.
  final Future<void> Function(
    String workspaceId,
    String channelId,
    ChannelProvisioningStep step,
  )?
  _setProvisioningStep;
  final Future<PrProvisionContext?> Function(
    String workspaceId,
    String channelId,
  )?
  _resolvePrContext;

  /// Announces the same progress the channel row records, for the surfaces that
  /// are not watching a row — the chat bridge reports it on its task card so a
  /// reader in Slack is not left watching nothing for the length of a clone.
  final DomainEventBus? _eventBus;

  /// Watchdog for the whole provision run: a hung step (e.g. a git fetch that
  /// never returns) flips the channel to `failed` — which carries a retry
  /// affordance — instead of leaving it behind an eternal spinner.
  final Duration _timeout;

  /// Resolves the repo ids a channel selected at creation. Empty → all
  /// workspace repos. Null callback (or absent) also means all repos.
  final Future<List<String>> Function(String workspaceId, String channelId)?
  _channelRepoIds;

  /// Provisions (or re-provisions on retry) the workspace for [channelId].
  ///
  /// Short-circuits to `ready` when there is nothing to provision (no linked
  /// repos or no participant agents). Sets `failed` when verification detects a
  /// missing worktree or overlay, when the run throws, or when it exceeds the
  /// watchdog timeout — never leaves the channel stranded in `provisioning`.
  Future<void> provision({
    required String workspaceId,
    required String channelId,
  }) async {
    await _setStatus(
      workspaceId,
      channelId,
      ChannelProvisioningStatus.provisioning,
    );
    try {
      await _provision(
        workspaceId: workspaceId,
        channelId: channelId,
      ).timeout(_timeout);
    } on Object catch (e, st) {
      CcHostLog.error(
        'channel provisioning: $channelId did not complete: $e',
        e,
        st,
      );
      // `failed` (not `provisioning`) so the UI offers a retry. On a timeout
      // the underlying run is not cancelled — if it eventually finishes it
      // writes its own terminal status over this one, which is strictly newer
      // information.
      await _setStatus(
        workspaceId,
        channelId,
        ChannelProvisioningStatus.failed,
      );
    }
  }

  Future<void> _provision({
    required String workspaceId,
    required String channelId,
  }) async {
    // Nothing to provision without repos → ready immediately.
    final repos = await _workspaceRepository
        .watchReposForWorkspace(workspaceId)
        .first;
    if (repos.isEmpty) {
      await _setStatus(workspaceId, channelId, ChannelProvisioningStatus.ready);
      return;
    }

    // A PR-review channel checks its repo out at the PR head ref (so the
    // terminal / file editor / agent all see the PR's proposed tree).
    final prContext = await _resolvePrContext?.call(workspaceId, channelId);

    // The repos this channel actually provisions: a PR channel scopes to the
    // ONE repo under review; a regular channel provisions the repos it selected
    // at creation (all workspace repos when it selected none).
    final Set<String> targetRepoIds;
    if (prContext != null) {
      targetRepoIds = {
        for (final r in repos)
          if ('${r.remoteOwner}/${r.remoteName}' == prContext.repoFullName)
            r.id,
      };
    } else {
      final selected =
          (await _channelRepoIds?.call(workspaceId, channelId)) ??
          const <String>[];
      final workspaceRepoIds = repos.map((r) => r.id).toSet();
      targetRepoIds = selected.isEmpty
          ? workspaceRepoIds
          : selected.toSet().intersection(workspaceRepoIds);
    }
    // The PR's repo isn't linked (or an empty selection somehow) → nothing to do.
    if (targetRepoIds.isEmpty) {
      await _setStatus(workspaceId, channelId, ChannelProvisioningStatus.ready);
      return;
    }

    final participants = await _messagingRepository.getParticipants(
      workspaceId,
      channelId,
    );
    final agents = await _loadAgents(workspaceId, participants);
    if (agents.isEmpty) {
      // No agents yet. A PR channel still provisions its repo worktree at the
      // head so chat/terminal/files work before the first agent is summoned;
      // an ordinary empty channel short-circuits to ready.
      if (prContext == null) {
        await _setStatus(
          workspaceId,
          channelId,
          ChannelProvisioningStatus.ready,
        );
        return;
      }
      await _provisioner.ensureConversationWorkspace(
        workspaceId: workspaceId,
        channelId: channelId,
        agentSlug: '_pr',
        fallbackDir: '',
        prHeadRef: prContext.headRef,
        prHeadRepoFullName: prContext.repoFullName,
        prBranch: prContext.branch,
        repoAllowlist: targetRepoIds,
        onRepoProvision: _repoStepEmitter(workspaceId, channelId),
      );
      final ready = await _verify(
        workspaceId: workspaceId,
        channelId: channelId,
        repoCount: targetRepoIds.length,
        overlays: const [],
      );
      await _setStatus(
        workspaceId,
        channelId,
        ready
            ? ChannelProvisioningStatus.ready
            : ChannelProvisioningStatus.failed,
      );
      return;
    }

    // Provision each agent's overlay + write its derived `.mcp.json`.
    final overlays = <String>[];
    for (final agent in agents) {
      try {
        final agentSlug = _slugFor(agent);
        final agentConfigDir = _agentConfigDir(agent.agentMdPath);
        _emitStep(
          workspaceId,
          channelId,
          ChannelProvisioningStep(
            kind: ChannelProvisioningStepKind.agent,
            subject: agent.name.isNotEmpty ? agent.name : agentSlug,
          ),
        );
        final overlay = await _provisioner.ensureConversationWorkspace(
          workspaceId: workspaceId,
          channelId: channelId,
          agentSlug: agentSlug,
          fallbackDir: agentConfigDir,
          agentConfigDir: agentConfigDir,
          prHeadRef: prContext?.headRef,
          prHeadRepoFullName: prContext?.repoFullName,
          prBranch: prContext?.branch,
          repoAllowlist: targetRepoIds,
          // The first agent's call materializes the shared repo worktrees, so
          // its repo steps overwrite the agent step until checkout completes.
          onRepoProvision: _repoStepEmitter(workspaceId, channelId),
        );
        // Track the overlay before writing `.mcp.json` so verification always
        // checks it — a failed write leaves `.mcp.json` absent, which `_verify`
        // catches and reports as `failed`.
        overlays.add(overlay);
        await _writeMcpConfig(
          overlay,
          workspaceId: workspaceId,
          agentId: agent.id,
          conversationId: channelId,
        );
      } on Object catch (e, st) {
        CcHostLog.error(
          'channel provisioning: overlay failed for agent ${agent.id}: $e',
          e,
          st,
        );
      }
    }

    // Verify: every TARGET repo has a worktree row AND every overlay has
    // `.mcp.json`. `ensureConversationWorkspace` never throws, so this is the
    // authoritative success signal.
    final ready = await _verify(
      workspaceId: workspaceId,
      channelId: channelId,
      repoCount: targetRepoIds.length,
      overlays: overlays,
    );

    await _setStatus(
      workspaceId,
      channelId,
      ready
          ? ChannelProvisioningStatus.ready
          : ChannelProvisioningStatus.failed,
    );
  }

  /// Records where provisioning stands, both on the channel row (what clients
  /// watching the channel read) and on the event bus (what the chat bridge
  /// reports on its card).
  Future<void> _setStatus(
    String workspaceId,
    String channelId,
    ChannelProvisioningStatus status,
  ) async {
    await _setProvisioningStatus(workspaceId, channelId, status);
    _announce(workspaceId, channelId, status);
  }

  /// Publishes a step, fire-and-forget: progress is decorative, so a failed
  /// write must never fail (or slow) provisioning itself.
  void _emitStep(
    String workspaceId,
    String channelId,
    ChannelProvisioningStep step,
  ) {
    final emit = _setProvisioningStep;
    if (emit == null) {
      return;
    }
    unawaited(
      emit(workspaceId, channelId, step).catchError((Object e) {
        CcHostLog.warning('channel provisioning: step publish failed: $e');
      }),
    );
    _announce(
      workspaceId,
      channelId,
      ChannelProvisioningStatus.provisioning,
      step: step,
    );
  }

  /// Publishes progress, never throwing: this is a progress report and one that
  /// fails must not take provisioning with it.
  void _announce(
    String workspaceId,
    String channelId,
    ChannelProvisioningStatus status, {
    ChannelProvisioningStep? step,
  }) {
    try {
      _eventBus?.publish(
        ChannelProvisioningChanged(
          workspaceId: workspaceId,
          channelId: channelId,
          status: status,
          step: step,
          occurredAt: DateTime.now(),
        ),
      );
    } on Object catch (e) {
      CcHostLog.warning('channel provisioning: announce failed: $e');
    }
  }

  /// The [RepoWorkspaceProvisionerPort.ensureConversationWorkspace] progress
  /// callback for [channelId] in [workspaceId]: maps each materializing repo to
  /// a step.
  void Function(String, {required bool prHead}) _repoStepEmitter(
    String workspaceId,
    String channelId,
  ) =>
      (repoName, {required bool prHead}) => _emitStep(
        workspaceId,
        channelId,
        ChannelProvisioningStep(
          kind: prHead
              ? ChannelProvisioningStepKind.prCheckout
              : ChannelProvisioningStepKind.repo,
          subject: repoName,
        ),
      );

  Future<List<Agent>> _loadAgents(
    String workspaceId,
    List<ChannelParticipant> participants,
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
    required String channelId,
    required int repoCount,
    required List<String> overlays,
  }) async {
    final worktrees = await _isolatedRepoRepository.forChannel(
      workspaceId,
      channelId,
    );
    if (worktrees.length < repoCount) {
      CcHostLog.warning(
        'channel provisioning: $channelId expected $repoCount worktree(s), '
        'found ${worktrees.length}',
      );
      return false;
    }
    for (final overlay in overlays) {
      if (!File('$overlay/.mcp.json').existsSync()) {
        CcHostLog.warning(
          'channel provisioning: $channelId overlay $overlay missing .mcp.json',
        );
        return false;
      }
    }
    return true;
  }
}
