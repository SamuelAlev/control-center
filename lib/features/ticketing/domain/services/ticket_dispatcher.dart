import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/ticketing_events.dart';
import 'package:control_center/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/agents/domain/services/agent_readiness_checker.dart';
import 'package:control_center/features/dispatch/domain/prompts/output_contract_prompt.dart';
import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:uuid/uuid.dart';

/// The single owner of "an assigned ticket → an agent working it".
///
/// Listens to [TicketAssigned] (the one event `createTicket`/`assign`/`reassign`
/// publish) and runs the full dispatch sequence exactly once:
/// readiness check → ensure a discussion channel → transition `open`→`in_progress`
/// → dispatch the agent. No other component dispatches agents off ticket events:
/// [TicketWorkflowService] is pure lifecycle, and `TicketChannelService` only
/// maintains channel participants. This consolidation removes the previous
/// 2–3× concurrent dispatch (which raced ticket completions into
/// `ConcurrencyConflictException`s) and the duplicated coordination prompts.
///
/// Pipeline/team step bodies create the ticket (baking their rendered prompt +
/// coordination footer into `description`) and suspend; this dispatcher gives
/// every ticket in one pipeline run a single shared channel.
class TicketDispatcher {
  /// Creates a [TicketDispatcher].
  TicketDispatcher({
    required this.eventBus,
    required this.ticketRepository,
    required this.ticketWorkflow,
    required this.messagingPort,
    required this.readinessChecker,
    required this.repoProvisioner,
  });

  /// Event bus we subscribe to.
  final DomainEventBus eventBus;

  /// Read access to tickets.
  final TicketRepository ticketRepository;

  /// Lifecycle writes (start / fail / attach channel).
  final TicketWorkflowService ticketWorkflow;

  /// Channel + dispatch operations.
  final MessagingPort messagingPort;

  /// Gate: don't dispatch to an archived / mis-configured agent.
  final AgentReadinessChecker readinessChecker;

  /// Provisions the isolated worktree + branch before the agent is dispatched.
  final RepoWorkspaceProvisionerPort repoProvisioner;

  static const _uuid = Uuid();

  StreamSubscription<TicketAssigned>? _sub;

  /// Serializes channel creation per pipeline run (or per ticket for
  /// non-pipeline tickets) so concurrent steps in one run reuse one channel
  /// instead of each racing to create their own.
  final Map<String, Future<void>> _channelLocks = {};

  /// Start listening for [TicketAssigned] events.
  void start() {
    _sub = eventBus.on<TicketAssigned>().listen(_onTicketAssigned);
  }

  /// Stop listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onTicketAssigned(TicketAssigned event) async {
    try {
      final ticket = await ticketRepository.getById(event.ticketId);
      if (ticket == null || ticket.isTerminal) {
        return;
      }
      final agentId = event.assignedAgentId ?? ticket.assignedAgentId;
      if (agentId == null) {
        return;
      }

      // Always make sure the ticket has a discussion channel + participant,
      // even for user-owned tickets (which are then worked manually).
      final channelId = await _ensureChannel(ticket, agentId);

      // The human works their own tickets — no agent run, no auto-start.
      if (agentId == TicketCollaborator.userSentinel) {
        return;
      }

      final readiness = await readinessChecker.checkFromId(
        agentId,
        workspaceId: event.workspaceId ?? ticket.workspaceId,
      );
      if (!readiness.isReady) {
        AppLog.w(
          'TicketDispatcher',
          'Agent $agentId not ready (${readiness.reason}); failing ticket ${ticket.id}',
        );
        await ticketWorkflow.failTicket(
          ticket.id,
          'Assigned agent is not ready: ${readiness.reason ?? readiness.readiness.name}',
          workspaceId: ticket.workspaceId,
        );
        return;
      }

      // Single-dispatch guard: only the writer that performs the
      // open/backlog → in_progress transition proceeds to dispatch, so a
      // duplicate assignment event can't spawn a second concurrent run.
      final started =
          await ticketWorkflow.tryStart(ticket.id, workspaceId: ticket.workspaceId);
      if (!started) {
        return;
      }

      // Provision an isolated CoW worktree + branch for this ticket BEFORE
      // dispatch, so the agent's working root has the repos checked out on the
      // ticket's branch. No-op-safe: degrades to the agent dir when there is no
      // linked repo or provisioning fails.
      await repoProvisioner.ensureConversationWorkspace(
        workspaceId: ticket.workspaceId,
        channelId: channelId,
        fallbackDir: '',
        ticketId: ticket.id,
        ticketKey: (ticket.externalKey != null && ticket.externalKey!.isNotEmpty)
            ? ticket.externalKey!
            : _shortId(ticket.id),
        ticketTitle: ticket.title,
      );

      // Provisioning above (repo clone / CoW worktree) can take a while. If the
      // pipeline run was stopped during that window, `PipelineEngine.cancel`
      // has since cancelled this ticket — re-read it and abort instead of
      // dispatching an agent for a cancelled run. This is the seam the
      // "stop while cloning still starts the agent" race hits: the ticket read
      // at the top of this handler is stale by the time the clone finishes.
      final latest = await ticketRepository.getById(ticket.id);
      if (latest == null || latest.isTerminal) {
        AppLog.i(
          'TicketDispatcher',
          'Ticket ${ticket.id} no longer dispatchable '
          '(${latest?.status.name ?? 'deleted'}) after provisioning; '
          'skipping dispatch.',
        );
        return;
      }

      final seed = _buildSeed(latest);
      try {
        await messagingPort.sendUserMessage(channelId, seed);
        await messagingPort.dispatchAgent(
          channelId: channelId,
          agentId: agentId,
          prompt: seed,
          workspaceId: ticket.workspaceId,
          ticketId: ticket.id,
          pipelineRunId: ticket.pipelineRunId,
          pipelineStepId: ticket.pipelineStepId,
          inReplyToAgentId: ticket.delegatedByAgentId,
          wakeContext: WakeContext(
            ticketId: ticket.id,
            runId: _uuid.v4(),
            agentId: agentId,
            workspaceId: ticket.workspaceId,
            channelId: channelId,
            wakeReason: ticket.pipelineRunId != null
                ? WakeReason.pipelineStep
                : WakeReason.assignment,
            pipelineRunId: ticket.pipelineRunId,
          ),
        );
      } on Object catch (e, st) {
        // The ticket is already in_progress; if dispatch failed it would hang a
        // suspended pipeline step forever. Fail it so the resume listener can
        // resume the step (as failed) instead of orphaning it.
        AppLog.e('TicketDispatcher', 'Dispatch failed for ${ticket.id}', e, st);
        await ticketWorkflow.failTicket(ticket.id, 'Dispatch failed: $e',
            workspaceId: ticket.workspaceId);
      }
    } on Object catch (e, st) {
      AppLog.e(
        'TicketDispatcher',
        'Failed to handle assignment for ${event.ticketId}',
        e,
        st,
      );
    }
  }

  /// Ensures a discussion channel + participant for [ticket], reusing one
  /// channel per pipeline run. Persists the channel id onto the ticket.
  Future<String> _ensureChannel(Ticket ticket, String agentId) async {
    final isUser = agentId == TicketCollaborator.userSentinel;

    final existing = ticket.channelId;
    if (existing != null && existing.isNotEmpty) {
      if (!isUser) {
        await messagingPort.addAgentToChannel(existing, agentId);
      }
      return existing;
    }

    final lockKey = ticket.pipelineRunId ?? ticket.id;
    final prev = _channelLocks[lockKey];
    final gate = Completer<void>();
    _channelLocks[lockKey] = gate.future;
    if (prev != null) {
      await prev;
    }
    try {
      // A sibling step in the same run may have created the channel while we
      // waited for the lock — re-read before creating a new one.
      final fresh = await ticketRepository.getById(ticket.id) ?? ticket;
      if (fresh.channelId != null && fresh.channelId!.isNotEmpty) {
        if (!isUser) {
          await messagingPort.addAgentToChannel(fresh.channelId!, agentId);
        }
        return fresh.channelId!;
      }

      String? channelId;
      final runId = ticket.pipelineRunId;
      if (runId != null) {
        final siblings =
            await ticketRepository.forPipelineRun(ticket.workspaceId, runId);
        for (final sibling in siblings) {
          final sc = sibling.channelId;
          if (sc != null && sc.isNotEmpty) {
            channelId = sc;
            break;
          }
        }
      }

      if (channelId == null) {
        final name = runId != null
            ? 'Pipeline ${runId.substring(0, runId.length < 8 ? runId.length : 8)}'
            : ticket.title;
        final channel = await messagingPort.createGroup(
          name,
          isUser ? const [] : [agentId],
          mode: ticket.mode,
          workspaceId: ticket.workspaceId,
        );
        channelId = channel.id;
      } else if (!isUser) {
        await messagingPort.addAgentToChannel(channelId, agentId);
      }

      await ticketWorkflow.attachChannel(
        ticket.id,
        channelId,
        workspaceId: ticket.workspaceId,
      );
      return channelId;
    } finally {
      gate.complete();
      // Drop our slot unless a later caller already superseded it. The removed
      // value is our own just-completed gate future; nothing to await.
      if (identical(_channelLocks[lockKey], gate.future)) {
        unawaited(_channelLocks.remove(lockKey) ?? Future<void>.value());
      }
    }
  }

  static String _shortId(String id) =>
      id.length > 8 ? id.substring(0, 8) : id;

  /// Builds the message the agent is dispatched with.
  ///
  /// Pipeline tickets carry their full rendered prompt + step-specific
  /// coordination footer (e.g. `complete_ticket`, or `approve_step` for human
  /// gates) in `description`, so it is dispatched verbatim. Non-pipeline
  /// (user / delegated) tickets get a structured brief + the default
  /// `complete_ticket` / `fail_ticket` coordination footer.
  String _buildSeed(Ticket ticket) {
    if (ticket.pipelineRunId != null) {
      final desc = ticket.description?.trim();
      final body = (desc != null && desc.isNotEmpty) ? desc : ticket.title;
      // Pipeline tickets are dispatched verbatim, but a declared output schema
      // must still reach the agent — append the contract block so the agent
      // knows the exact shape `complete_ticket` will enforce.
      final schema = ticket.expectedOutputSchema;
      if (schema != null && schema.isNotEmpty) {
        return '$body\n${renderOutputContract(schema, mode: ticket.outputContractMode)}';
      }
      return body;
    }

    final buf = StringBuffer()
      ..write('You have been assigned to this ticket: **${ticket.title}**');
    if (ticket.externalKey != null && ticket.externalKey != ticket.id) {
      buf.write(' (${ticket.externalKey})');
    }
    buf.writeln();

    if (ticket.priority != TicketPriority.none) {
      buf.writeln('**Priority:** ${ticket.priority.name}');
    }
    if (ticket.labels.isNotEmpty) {
      buf.writeln('**Labels:** ${ticket.labels.join(', ')}');
    }
    if (ticket.url != null) {
      buf.writeln('**URL:** ${ticket.url}');
    }

    final desc = ticket.description?.trim();
    if (desc != null && desc.isNotEmpty) {
      buf
        ..writeln()
        ..writeln(desc);
    }

    if (ticket.delegatedByAgentId != null) {
      buf
        ..writeln()
        ..writeln(
          '*Delegated by agent `${ticket.delegatedByAgentId}`. '
          'Report your findings back via `complete_ticket`.*',
        );
    }

    final schema = ticket.expectedOutputSchema;
    if (schema != null && schema.isNotEmpty) {
      buf.writeln(renderOutputContract(schema, mode: ticket.outputContractMode));
    }

    buf
      ..writeln()
      ..writeln('── Task coordination ──────────────────────────────')
      ..writeln(
        'ticket_id: `${ticket.id}`  workspace_id: `${ticket.workspaceId}`',
      )
      ..writeln(
        'When you finish, call `complete_ticket` with '
        'ticket_id="${ticket.id}" and your findings in the `output` payload. '
        'If the task cannot be completed, call `fail_ticket` instead with a '
        'description of what went wrong.',
      );

    return buf.toString();
  }
}
