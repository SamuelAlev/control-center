import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';

/// Maps a vendor-native workflow-state name to a normalized [TicketStatus].
///
/// A single heuristic shared by every vendor adapter and webhook parser so the
/// status vocabulary stays consistent across Linear / Jira / GitHub. Order
/// matters: more specific substrings ("in review", "in progress") are tested
/// before the generic fallbacks.
TicketStatus normalizeVendorStatus(String stateName) {
  final s = stateName.toLowerCase().trim();
  if (s.isEmpty) {
    return TicketStatus.open;
  }
  if (s.contains('progress') || s == 'doing' || s == 'started') {
    return TicketStatus.inProgress;
  }
  if (s.contains('review') || s.contains('qa') || s.contains('verify')) {
    return TicketStatus.inReview;
  }
  if (s.contains('block')) {
    return TicketStatus.blocked;
  }
  if (s.contains('backlog') || s.contains('triage')) {
    return TicketStatus.backlog;
  }
  if (s.contains('cancel') ||
      s.contains('duplicate') ||
      s.contains("won't") ||
      s.contains('wontfix') ||
      s.contains('abandon')) {
    return TicketStatus.cancelled;
  }
  if (s.contains('done') ||
      s.contains('complete') ||
      s.contains('closed') ||
      s.contains('merged') ||
      s.contains('resolved') ||
      s.contains('shipped')) {
    return TicketStatus.done;
  }
  if (s.contains('todo') ||
      s.contains('to do') ||
      s.contains('open') ||
      s.contains('ready') ||
      s.contains('selected') ||
      s == 'new') {
    return TicketStatus.open;
  }
  return TicketStatus.open;
}
