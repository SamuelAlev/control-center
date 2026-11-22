import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';

/// A waiting wake as a person sees it in a conversation (`wakes.*` ops): what
/// it is, when it is due, and where it stands. Not the payload: that is the
/// agent's data.
class WakeView {
  /// Creates a view. Throws [ArgumentError] for an empty id or target.
  WakeView({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.conversationId,
    required this.agentId,
    required this.reason,
    required this.origin,
    required this.headline,
    required this.state,
    required this.lane,
    required DateTime notBefore,
    required DateTime createdAt,
    required this.canRelease,
    this.stateReason,
    DateTime? expiresAt,
    this.requestedByUserId,
    this.attempt = 0,
    this.sourceAgentId,
    this.goalId,
    this.ruleId,
    this.askId,
  }) : notBefore = notBefore.toUtc(),
       createdAt = createdAt.toUtc(),
       expiresAt = expiresAt?.toUtc() {
    for (final (name, value) in [
      ('id', id),
      ('workspaceId', workspaceId),
      ('conversationId', conversationId),
      ('agentId', agentId),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
  }

  /// The wake's id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The conversation's space.
  final String spaceId;

  /// The conversation.
  final String conversationId;

  /// The agent it wakes.
  final String agentId;

  /// Why.
  final WakeReason reason;

  /// The label its first line carries (`your-note`, `peer-message`, …).
  final String origin;

  /// Its first line's text, written by the server from typed fields.
  final String headline;

  /// `pending` or `held` (the watch lists nothing else).
  final WakeState state;

  /// Why it waits or is held, when it says.
  final String? stateReason;

  /// How it enters a live run.
  final WakeLane lane;

  /// Not delivered before this.
  final DateTime notBefore;

  /// It expires at this time, when it does.
  final DateTime? expiresAt;

  /// When it was raised.
  final DateTime createdAt;

  /// The person it acts for; null for a bot wake.
  final String? requestedByUserId;

  /// Delivery attempts so far.
  final int attempt;

  /// Whether the viewing person may release or deliver it, as the server
  /// decided (a wake that acts for a person is only theirs). Cancel is
  /// open to anyone who sees it.
  final bool canRelease;

  /// The agent whose message, reply or finished work raised it, when one did
  /// (a client shows its name: "Reply from Ada").
  final String? sourceAgentId;

  /// The goal it continues or verifies, when it belongs to one.
  final String? goalId;

  /// The schedule or watch that fired it, when a rule did.
  final String? ruleId;

  /// The question to another agent it answers or delivers, when it does.
  final String? askId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WakeView &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          spaceId == other.spaceId &&
          conversationId == other.conversationId &&
          agentId == other.agentId &&
          reason == other.reason &&
          origin == other.origin &&
          headline == other.headline &&
          state == other.state &&
          stateReason == other.stateReason &&
          lane == other.lane &&
          notBefore == other.notBefore &&
          expiresAt == other.expiresAt &&
          createdAt == other.createdAt &&
          requestedByUserId == other.requestedByUserId &&
          attempt == other.attempt &&
          canRelease == other.canRelease &&
          sourceAgentId == other.sourceAgentId &&
          goalId == other.goalId &&
          ruleId == other.ruleId &&
          askId == other.askId;

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    spaceId,
    conversationId,
    agentId,
    reason,
    origin,
    headline,
    state,
    stateReason,
    lane,
    notBefore,
    expiresAt,
    createdAt,
    requestedByUserId,
    attempt,
    canRelease,
    sourceAgentId,
    goalId,
    ruleId,
    askId,
  ]);
}

/// A client's view of a conversation's waiting wakes and a person's controls
/// over them. Every call names its workspace; a wake or conversation outside
/// it is refused by the server.
abstract interface class ConversationWakesRepository {
  /// The pending and held wakes of [conversationId], earliest due first.
  Stream<List<WakeView>> watchForConversation(
    String workspaceId,
    String conversationId,
  );

  /// Cancels the wake. False when it already settled or a run took it.
  Future<bool> cancel(String workspaceId, String wakeId);

  /// Releases a held wake ([wakeId]) or the held wakes of [conversationId]
  /// the caller may release (theirs and the bot wakes). Returns how many
  /// were released. Refused (kind `wake_not_yours`) for another person's
  /// wake, or when every held wake of the conversation is another person's.
  Future<int> release(
    String workspaceId, {
    String? wakeId,
    String? conversationId,
  });

  /// Delivers the wake now, whatever its due time. Refused (kind
  /// `wake_not_yours`) for another person's wake.
  Future<WakeReceipt> deliverNow(String workspaceId, String wakeId);
}
