import 'package:cc_domain/core/domain/events/domain_event_bus.dart';

/// An unanswered approval gate escalated to the next routing tier. Carries
/// the principals now responsible so notifications reach them — and only
/// them — instead of broadcasting to every member.
class ApprovalEscalated implements DomainEvent {
  /// Creates an [ApprovalEscalated] event.
  const ApprovalEscalated({
    required this.workspaceId,
    required this.approvalId,
    required this.tier,
    required this.targetUserIds,
    required this.occurredAt,
  });

  /// The workspace the approval belongs to.
  final String workspaceId;

  /// The escalated approval.
  final String approvalId;

  /// The tier now responsible (1 = admins, 2 = owner).
  final int tier;

  /// The users now asked to decide.
  final List<String> targetUserIds;

  @override
  final DateTime occurredAt;
}
