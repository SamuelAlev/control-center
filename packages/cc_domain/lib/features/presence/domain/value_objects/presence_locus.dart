/// Where a participant currently is, down to the artifact (PRD 16 §3).
///
/// A typed tagged union carried on the ephemeral presence lane — never
/// persisted. Compact wire keys (`t` = tag) because cursor-cadence presence
/// updates ride it at up to 10 Hz.
sealed class PresenceLocus {
  const PresenceLocus();

  /// Parses a locus from its wire map; null for unknown tags (forward
  /// compatibility — an old client simply doesn't render the new locus kind).
  static PresenceLocus? fromWire(Map<String, dynamic> wire) {
    switch (wire['t']) {
      case 'ch':
        return ChannelLocus(channelId: wire['c'] as String? ?? '');
      case 'file':
        return FileLocus(
          repoId: wire['r'] as String? ?? '',
          path: wire['p'] as String? ?? '',
          line: (wire['l'] as num?)?.toInt(),
        );
      case 'pr':
        return PrLocus(
          repoFullName: wire['r'] as String? ?? '',
          prNumber: (wire['n'] as num?)?.toInt() ?? 0,
        );
      case 'tk':
        return TicketLocus(ticketId: wire['id'] as String? ?? '');
      case 'plan':
        return PlanNodeLocus(
          orchestrationId: wire['o'] as String? ?? '',
          nodeId: wire['n'] as String? ?? '',
        );
      default:
        return null;
    }
  }

  /// Serializes to the compact wire map.
  Map<String, dynamic> toWire();

  /// A short, human-readable label for roster rows and follow toasts
  /// (workspace metadata only — never file contents).
  String get label;
}

/// Viewing / typing in a channel (a conversation).
class ChannelLocus extends PresenceLocus {
  /// Creates a [ChannelLocus].
  const ChannelLocus({required this.channelId});

  /// The channel id.
  final String channelId;

  @override
  Map<String, dynamic> toWire() => {'t': 'ch', 'c': channelId};

  @override
  String get label => 'channel';

  @override
  bool operator ==(Object other) =>
      other is ChannelLocus && other.channelId == channelId;

  @override
  int get hashCode => Object.hash('ch', channelId);
}

/// Viewing / editing a file (optionally a specific line).
class FileLocus extends PresenceLocus {
  /// Creates a [FileLocus].
  const FileLocus({required this.repoId, required this.path, this.line});

  /// The repo the file belongs to.
  final String repoId;

  /// Worktree-relative path.
  final String path;

  /// 1-based line, when known.
  final int? line;

  @override
  Map<String, dynamic> toWire() => {
    't': 'file',
    'r': repoId,
    'p': path,
    'l': ?line,
  };

  @override
  String get label => line == null ? path : '$path:$line';

  @override
  bool operator ==(Object other) =>
      other is FileLocus &&
      other.repoId == repoId &&
      other.path == path &&
      other.line == line;

  @override
  int get hashCode => Object.hash('file', repoId, path, line);
}

/// Viewing a pull request.
class PrLocus extends PresenceLocus {
  /// Creates a [PrLocus].
  const PrLocus({required this.repoFullName, required this.prNumber});

  /// `owner/repo`.
  final String repoFullName;

  /// The PR number.
  final int prNumber;

  @override
  Map<String, dynamic> toWire() => {
    't': 'pr',
    'r': repoFullName,
    'n': prNumber,
  };

  @override
  String get label => '$repoFullName#$prNumber';

  @override
  bool operator ==(Object other) =>
      other is PrLocus &&
      other.repoFullName == repoFullName &&
      other.prNumber == prNumber;

  @override
  int get hashCode => Object.hash('pr', repoFullName, prNumber);
}

/// Viewing / editing a ticket.
class TicketLocus extends PresenceLocus {
  /// Creates a [TicketLocus].
  const TicketLocus({required this.ticketId});

  /// The ticket id.
  final String ticketId;

  @override
  Map<String, dynamic> toWire() => {'t': 'tk', 'id': ticketId};

  @override
  String get label => 'ticket';

  @override
  bool operator ==(Object other) =>
      other is TicketLocus && other.ticketId == ticketId;

  @override
  int get hashCode => Object.hash('tk', ticketId);
}

/// Viewing / editing a plan node (an orchestration proposal step).
class PlanNodeLocus extends PresenceLocus {
  /// Creates a [PlanNodeLocus].
  const PlanNodeLocus({required this.orchestrationId, required this.nodeId});

  /// The orchestration id.
  final String orchestrationId;

  /// The plan node id.
  final String nodeId;

  @override
  Map<String, dynamic> toWire() => {
    't': 'plan',
    'o': orchestrationId,
    'n': nodeId,
  };

  @override
  String get label => 'plan';

  @override
  bool operator ==(Object other) =>
      other is PlanNodeLocus &&
      other.orchestrationId == orchestrationId &&
      other.nodeId == nodeId;

  @override
  int get hashCode => Object.hash('plan', orchestrationId, nodeId);
}
