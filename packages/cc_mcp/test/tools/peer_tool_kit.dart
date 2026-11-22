import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart'
    show CallResult;
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';

import '../../../cc_infra/test/dispatch/peer_test_kit.dart';

export '../../../cc_infra/test/dispatch/peer_test_kit.dart';

/// Agents over a [PeerKit]'s map.
class KitAgents implements AgentRepository {
  /// Reads [kit]'s agents.
  KitAgents(this.kit);

  /// The kit.
  final PeerKit kit;

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => Stream.value([
    for (final a in kit.agents.values)
      if (a.workspaceId == workspaceId) a,
  ]);

  @override
  Future<Agent?> getById(String workspaceId, String id) =>
      kit.agentRepository.getById(workspaceId, id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Spaces and messages over a [PeerKit]: a space's messages land in its
/// standing conversation `c-<space id>`, registered on the kit.
class KitMessaging implements MessagingRepository {
  /// Writes into [kit].
  KitMessaging(this.kit);

  /// The kit.
  final PeerKit kit;

  /// Spaces by id.
  final Map<String, Space> spaces = {};

  /// Participants by space.
  final Map<String, List<SpaceParticipant>> participants = {};

  /// Every message posted, in order.
  final List<Message> posted = [];

  /// The repo ids of the last created space.
  List<String>? createdWithRepoIds;

  /// Whether a space was created.
  bool get createSpaceCalled => spaces.isNotEmpty;

  int _ids = 0;

  /// The standing conversation of [spaceId].
  static String conversationOf(String spaceId) => 'c-$spaceId';

  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value([
        for (final s in spaces.values)
          if (s.workspaceId == workspaceId) s,
      ]);

  @override
  Future<List<SpaceParticipant>> getParticipants(
    String workspaceId,
    String spaceId,
  ) async => participants[spaceId] ?? const [];

  @override
  Future<bool> spaceExists(String workspaceId, String spaceId) async =>
      spaces[spaceId]?.workspaceId == workspaceId;

  @override
  Future<void> addParticipant(
    String workspaceId,
    String spaceId,
    String principalId, {
    PrincipalType participantType = PrincipalType.agent,
  }) async {
    participants
        .putIfAbsent(spaceId, () => [])
        .add(
          SpaceParticipant(
            id: 'p-${++_ids}',
            spaceId: spaceId,
            principalId: principalId,
            participantType: participantType,
            role: 'member',
            joinedAt: kit.now,
          ),
        );
  }

  /// Adds an existing space with [agentIds].
  Space space(
    String id, {
    String workspaceId = PeerKit.ws,
    SpaceKind kind = SpaceKind.topic,
    List<String> agentIds = const [],
  }) {
    final space = spaces[id] = Space(
      id: id,
      name: id,
      workspaceId: workspaceId,
      kind: kind,
      createdAt: kit.now,
      updatedAt: kit.now,
    );
    kit.conversation(conversationOf(id), spaceId: id, workspaceId: workspaceId);
    for (final agent in agentIds) {
      participants
          .putIfAbsent(id, () => [])
          .add(
            SpaceParticipant(
              id: 'p-${++_ids}',
              spaceId: id,
              principalId: agent,
              participantType: PrincipalType.agent,
              role: 'member',
              joinedAt: kit.now,
            ),
          );
    }
    return space;
  }

  @override
  Future<Space> createSpace(
    String workspaceId,
    String name,
    List<String> agentIds, {
    dynamic mode,
    List<String>? repoIds,
    Map<String, String>? repoBranches,
    String? pipelineRunId,
    String? createdByUserId,
    SpaceKind kind = SpaceKind.topic,
  }) async {
    createdWithRepoIds = repoIds;
    return space(
      'dm-${spaces.length + 1}',
      workspaceId: workspaceId,
      kind: kind,
      agentIds: agentIds,
    );
  }

  @override
  Future<String> sendMessage({
    required String workspaceId,
    required String spaceId,
    required String content,
    required String senderId,
    required String senderType,
    String? conversationId,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
    String? id,
  }) async {
    final messageId = id ?? 'm-${++_ids}';
    final message = Message(
      id: messageId,
      spaceId: spaceId,
      conversationId: conversationId ?? conversationOf(spaceId),
      senderId: senderId,
      senderType: senderType == 'agent'
          ? SenderType.agent
          : senderType == 'user'
          ? SenderType.user
          : SenderType.system,
      content: content,
      messageType: messageType == 'system'
          ? MessageType.system
          : MessageType.text,
      metadata: metadata,
      createdAt: kit.now,
    );
    posted.add(message);
    kit.messages[messageId] = message;
    return messageId;
  }

  @override
  Future<Message?> getMessageById(String workspaceId, String messageId) =>
      kit.messageRepository.getMessageById(workspaceId, messageId);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Tickets by id; `getById` scoped to the workspace.
class KitTickets implements TicketRepository {
  /// Tickets by id.
  final Map<String, Ticket> byId = {};

  @override
  Future<Ticket?> getById(String workspaceId, String id) async {
    final t = byId[id];
    return t?.workspaceId == workspaceId ? t : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A ticket workflow whose gate admits every hand-off unless a test says
/// otherwise.
TicketWorkflowService openGate({
  TicketRepository? tickets,
  AutonomyLevel Function(String agentId)? autonomy,
  int? Function()? remainingBudget,
}) => TicketWorkflowService(
  repository: tickets ?? KitTickets(),
  eventBus: DomainEventBus(),
  resolveEffectiveAutonomy:
      ({required workspaceId, required agentId, spaceId}) async =>
          autonomy?.call(agentId) ?? AutonomyLevel.actWithApproval,
  resolveRemainingBudgetMicros:
      ({required workspaceId, required agentId}) async =>
          remainingBudget?.call(),
);

/// The attested scope of [runId], [agentId]'s run in [conversationId].
McpCallScope runScope({
  required String agentId,
  required String runId,
  required String conversationId,
  String workspaceId = PeerKit.ws,
  String spaceId = 'sp-a',
}) => McpCallScope(
  workspaceId: workspaceId,
  agentId: agentId,
  spaceId: spaceId,
  conversationId: conversationId,
  runLogId: runId,
  attested: true,
);

/// A field of a refusal's structured data (`kind`, `ask_id`).
Object? refusalField(CallResult result, String key) =>
    (result.structured as Map?)?[key];
