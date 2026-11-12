import 'package:cc_domain/core/domain/entities/episodic_edge.dart'
    show EpisodicEdgeTypes;
import 'package:cc_domain/core/domain/entities/memory_belief.dart';
import 'package:cc_domain/core/domain/entities/memory_conflict.dart';
import 'package:cc_domain/core/domain/entities/message.dart'
    show MessageType, SenderType;
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart'
    show PrincipalType;
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart'
    show CalendarEventStatus;
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting.dart'
    show MeetingMode, MeetingStatus;
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart'
    show MeetingSpeaker;
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_veracity.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_lifecycle_states.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_kind.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/todos/domain/value_objects/todo_status.dart';

/// The closed sets of values stored in text columns of these tables:
/// Conversation, space, notification, meeting, calendar, chat and memory tables.
///
/// Each list is built from the Dart enum that owns the values, with the same
/// accessor the mapper writes (`name`, `wire`, …), so a `CHECK` on the
/// column cannot disagree with the code. A column check reads
/// `text().check(status.isIn(SpacesStoredValues.someStatus))()`.
///
/// Adding a value to one of those enums changes the declared schema: bump the
/// database's schema version so existing files converge to the wider check.
// ignore: avoid_classes_with_only_static_members
abstract final class SpacesStoredValues {
  /// `spaces.mode`: `Mode.toDbValue()`.
  static final List<String> spaceMode = [
    for (final v in Mode.values) v.toDbValue(),
  ];

  /// `spaces.kind`: `SpaceKind.wire`.
  static final List<String> spaceKind = [
    for (final v in SpaceKind.values) v.wire,
  ];

  /// `spaces.provisioning_status`: `SpaceProvisioningStatus.toDbValue()`.
  static final List<String> spaceProvisioningStatus = [
    for (final v in SpaceProvisioningStatus.values) v.toDbValue(),
  ];

  /// `conversations.status`: `ConversationStatus.wire`.
  static final List<String> conversationStatus = [
    for (final v in ConversationStatus.values) v.wire,
  ];

  /// `conversation_messages.sender_type`: `SenderType.wireName`.
  static final List<String> senderType = [
    for (final v in SenderType.values) v.wireName,
  ];

  /// `conversation_messages.message_type`: `MessageType.wire`.
  static final List<String> messageType = [
    for (final v in MessageType.values) v.wire,
  ];

  /// `conversation_messages.plan_status`: `PlanMessageStatus.wire`.
  static final List<String> planStatus = [
    for (final v in PlanMessageStatus.values) v.wire,
  ];

  /// `conversation_messages.steer_state`: `SteeringState.wire`.
  static final List<String> steerState = [
    for (final v in SteeringState.values) v.wire,
  ];

  /// `space_participants.participant_type` and
  /// `message_reactions.principal_type`: `PrincipalType.wireName`.
  static final List<String> principalType = [
    for (final v in PrincipalType.values) v.wireName,
  ];

  /// `space_autonomy.autonomy_level`: `AutonomyLevel.wire`.
  static final List<String> autonomyLevel = [
    for (final v in AutonomyLevel.values) v.wire,
  ];

  /// `todos.status`: `TodoStatus.storage`.
  static final List<String> todoStatus = [
    for (final v in TodoStatus.values) v.storage,
  ];

  /// `chat_space_links.provider` and `chat_user_links.provider`:
  /// `ChatProvider.wire`.
  static final List<String> chatProvider = [
    for (final v in ChatProvider.values) v.wire,
  ];

  /// `chat_user_links.method`: `ChatLinkMethod.wire`.
  static final List<String> chatLinkMethod = [
    for (final v in ChatLinkMethod.values) v.wire,
  ];

  /// `calendar_events.status`: `CalendarEventStatus.toStorage()`.
  static final List<String> calendarEventStatus = [
    for (final v in CalendarEventStatus.values) v.toStorage(),
  ];

  /// `meetings.status`: `MeetingStatus.toStorage()`.
  static final List<String> meetingStatus = [
    for (final v in MeetingStatus.values) v.toStorage(),
  ];

  /// `meetings.mode`: `MeetingMode.toStorage()`.
  static final List<String> meetingMode = [
    for (final v in MeetingMode.values) v.toStorage(),
  ];

  /// `meeting_speakers.channel` and `meeting_transcript_segments.speaker`:
  /// `MeetingSpeaker.toStorage()`.
  static final List<String> meetingSpeaker = [
    for (final v in MeetingSpeaker.values) v.toStorage(),
  ];

  /// Agent roles as the memory tables store them: `AgentRole.name`.
  static final List<String> agentRole = [
    for (final v in AgentRole.values) v.name,
  ];

  /// `memory_access_grants.permission`: `MemoryPermission.name`.
  static final List<String> memoryPermission = [
    for (final v in MemoryPermission.values) v.name,
  ];

  /// `memory_facts.memory_type` and `working_memory_items.memory_type`:
  /// `MemoryType.wireName`.
  static final List<String> memoryType = [
    for (final v in MemoryType.values) v.wireName,
  ];

  /// `memory_facts.veracity` and `working_memory_items.veracity`:
  /// `MemoryVeracity.wireName`.
  static final List<String> memoryVeracity = [
    for (final v in MemoryVeracity.values) v.wireName,
  ];

  /// `memory_beliefs.action`: `MemoryBelief.actions`.
  static final List<String> beliefAction = [...MemoryBelief.actions];

  /// `memory_conflicts.conflict_type`: `MemoryConflict.types`.
  static final List<String> conflictType = [...MemoryConflict.types];

  /// `memory_conflicts.resolution`: `MemoryConflict.resolutions`.
  static final List<String> conflictResolution = [
    ...MemoryConflict.resolutions,
  ];

  /// `episodic_edges.edge_type`: `EpisodicEdgeTypes.all`.
  static final List<String> edgeType = [...EpisodicEdgeTypes.all];
}
