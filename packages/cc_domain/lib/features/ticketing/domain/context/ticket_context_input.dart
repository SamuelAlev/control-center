import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';

/// A provider-neutral comment on a ticket, for the context snapshot.
class TicketContextComment {
  /// Creates a [TicketContextComment].
  const TicketContextComment({
    required this.author,
    required this.body,
    this.createdAt,
  });

  /// Display name / id of the comment author.
  final String author;

  /// Comment body (plain text or markdown).
  final String body;

  /// When the comment was posted, if known.
  final DateTime? createdAt;
}

/// A child / sub-issue reference, for the context snapshot.
class TicketContextChild {
  /// Creates a [TicketContextChild].
  const TicketContextChild({
    required this.key,
    required this.title,
    required this.status,
  });

  /// Display key (e.g. `ENG-124` or the CC id).
  final String key;

  /// Child title.
  final String title;

  /// Child status (display string).
  final String status;
}

/// A relation to another ticket, for the context snapshot.
class TicketContextRelation {
  /// Creates a [TicketContextRelation].
  const TicketContextRelation({
    required this.kind,
    required this.otherKey,
    this.otherTitle,
  });

  /// Relation kind (e.g. `blocked by`, `relates to`).
  final String kind;

  /// The other ticket's display key.
  final String otherKey;

  /// The other ticket's title, if known.
  final String? otherTitle;
}

/// An attachment reference, for the context snapshot.
class TicketContextAttachment {
  /// Creates a [TicketContextAttachment].
  const TicketContextAttachment({required this.name, this.url});

  /// Attachment file / display name.
  final String name;

  /// Attachment URL, if any.
  final String? url;
}

/// Everything the snapshot builder may render for one ticket.
///
/// Each optional section can also carry a load error in [sectionErrors] (keyed
/// by `comments` / `children` / `relations` / `attachments`); the builder marks
/// the snapshot partial and notes the error inline rather than dropping the
/// section silently.
class TicketContextInput {
  /// Creates a [TicketContextInput].
  const TicketContextInput({
    required this.ticket,
    this.assigneeName,
    this.externalKey,
    this.comments = const [],
    this.children = const [],
    this.relations = const [],
    this.attachments = const [],
    this.sectionErrors = const {},
  });

  /// The ticket itself.
  final Ticket ticket;

  /// Resolved assignee display name, if any (the ticket carries only an id).
  final String? assigneeName;

  /// Vendor-native key to show, overriding the ticket's own when synced.
  final String? externalKey;

  /// Comments, newest-last. Capped by options.
  final List<TicketContextComment> comments;

  /// Child / sub-issues. Capped by options.
  final List<TicketContextChild> children;

  /// Relations to other tickets. Capped by options.
  final List<TicketContextRelation> relations;

  /// Attachments. Capped by options.
  final List<TicketContextAttachment> attachments;

  /// Per-section load errors, keyed by section name.
  final Map<String, String> sectionErrors;
}
