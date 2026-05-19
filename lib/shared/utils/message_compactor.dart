/// Message compaction.
class MessageCompaction {
  /// Creates a new [MessageCompaction].
  MessageCompaction({required this.idsToCompact, required this.summary});

  /// IDs of the messages that were compacted.
  final List<String> idsToCompact;

  /// Summary text replacing the compacted messages.
  final String summary;
}

/// Compactable message.
class CompactableMessage {
  /// Creates a new [CompactableMessage].
  const CompactableMessage({
    required this.id,
    required this.label,
    required this.content,
    required this.compacted,
  });

  /// Message ID.
  final String id;

  /// Display label for the message.
  final String label;

  /// Full message content.
  final String content;

  /// Length of the content in characters.
  int get contentLength => content.length;

  /// Whether this message has already been compacted.
  final bool compacted;
}

/// Message compactor.
class MessageCompactor {
  /// Creates a new [MessageCompactor].
  const MessageCompactor();

  /// Compact.
  MessageCompaction? compact({
    required List<CompactableMessage> messages,
    required int contextSize,
  }) {
    final nonCompacted = messages.where((m) => !m.compacted).toList();

    var totalChars = 0;
    for (final m in nonCompacted) {
      totalChars += m.contentLength;
    }

    final charLimit = contextSize * 3;
    if (totalChars <= charLimit) {
      return null;
    }

    final toCompact = <String>[];
    final summaryBuf = StringBuffer();
    summaryBuf.writeln('## Previous context summary\n');

    for (final m in nonCompacted) {
      final excerpt = m.contentLength > 120
          ? '${m.content.substring(0, 120)}…'
          : m.content;
      summaryBuf.writeln('- [${m.label}] $excerpt');
      toCompact.add(m.id);
      totalChars -= m.contentLength;
      if (totalChars <= charLimit) {
        break;
      }
    }

    if (toCompact.isEmpty) {
      return null;
    }

    return MessageCompaction(
      idsToCompact: toCompact,
      summary: summaryBuf.toString(),
    );
  }
}

