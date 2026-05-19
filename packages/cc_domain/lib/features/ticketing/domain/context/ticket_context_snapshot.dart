/// Options controlling which sections a ticket context snapshot includes and
/// how deep / large it may grow before truncation.
class TicketContextOptions {
  /// Creates a [TicketContextOptions].
  const TicketContextOptions({
    this.includeComments = true,
    this.includeChildren = true,
    this.includeRelations = true,
    this.includeAttachments = false,
    this.maxComments = 20,
    this.maxChildren = 20,
    this.maxRelations = 20,
    this.maxAttachments = 20,
    this.budgetChars = 12000,
  });

  /// Whether to render comments.
  final bool includeComments;

  /// Whether to render child / sub-issues.
  final bool includeChildren;

  /// Whether to render relations.
  final bool includeRelations;

  /// Whether to render attachments.
  final bool includeAttachments;

  /// Max comments rendered (depth cap).
  final int maxComments;

  /// Max children rendered (depth cap).
  final int maxChildren;

  /// Max relations rendered (depth cap).
  final int maxRelations;

  /// Max attachments rendered (depth cap).
  final int maxAttachments;

  /// Hard character budget for the whole snapshot.
  final int budgetChars;
}

/// Metadata about a rendered snapshot: whether it was truncated and any
/// per-section load errors.
class TicketContextMeta {
  /// Creates a [TicketContextMeta].
  const TicketContextMeta({
    this.partial = false,
    this.truncatedSections = const {},
    this.sectionErrors = const {},
  });

  /// True when any section was truncated by the budget/depth caps, or any
  /// section failed to load.
  final bool partial;

  /// Names of sections that were cut short by the budget or depth cap.
  final Set<String> truncatedSections;

  /// Per-section load errors carried through from the input.
  final Map<String, String> sectionErrors;

  /// JSON shape for embedding in a tool response.
  Map<String, dynamic> toJson() => {
    'partial': partial,
    'truncated_sections': truncatedSections.toList()..sort(),
    'section_errors': sectionErrors,
  };
}

/// A rendered, token-budgeted ticket context block ready for prompt injection.
class TicketContextSnapshot {
  /// Creates a [TicketContextSnapshot].
  const TicketContextSnapshot({required this.text, required this.meta})
    : charCount = text.length;

  /// The rendered text block (≤ [TicketContextOptions.budgetChars]).
  final String text;

  /// Truncation / error metadata.
  final TicketContextMeta meta;

  /// Length of [text] in characters.
  final int charCount;
}
