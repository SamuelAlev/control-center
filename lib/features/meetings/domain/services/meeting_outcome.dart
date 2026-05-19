import 'dart:convert';

/// One action item parsed from a meeting-summary agent's structured output.
class ParsedActionItem {
  /// Creates a [ParsedActionItem].
  const ParsedActionItem(this.text, {this.owner});

  /// The action-item text.
  final String text;

  /// Optional owner / assignee.
  final String? owner;

  @override
  bool operator ==(Object other) =>
      other is ParsedActionItem && other.text == text && other.owner == owner;

  @override
  int get hashCode => Object.hash(text, owner);
}

/// The normalized, structured result of a meeting-summary agent run.
///
/// The `meeting_summary` pipeline's agent step returns its result through the
/// pipeline's task-output channel (`complete_ticket`). The engine writes that
/// to the step's `outputKey` either as a JSON object (when the agent passed a
/// structured payload) or as a plain string (when it passed markdown / the
/// `{result: "..."}` convention). [parse] normalizes BOTH shapes into one
/// reliable struct so the deterministic persist steps never have to parse the
/// notes body. This is the single place that understands the agent's output.
class MeetingOutcome {
  /// Creates a [MeetingOutcome].
  const MeetingOutcome({
    this.summary,
    this.enhancedNotes,
    this.actionItems = const [],
    this.decisions = const [],
    this.isStructured = false,
  });

  /// An empty outcome (nothing recognizable).
  static const MeetingOutcome empty = MeetingOutcome();

  /// Whether the agent returned a real structured object (a Map / JSON), vs a
  /// plain-markdown fallback or nothing. When false, the action-item / decision
  /// persist steps SKIP (a degraded run must not wipe previously-saved rows);
  /// only the notes are updated. See `registerMeetingBodies`.
  final bool isStructured;

  /// Short executive summary, when present.
  final String? summary;

  /// Clean enhanced notes (markdown), when present.
  final String? enhancedNotes;

  /// Action items, in the agent's order.
  final List<ParsedActionItem> actionItems;

  /// Decisions, in the agent's order.
  final List<String> decisions;

  /// Parses [raw] — the value the engine wrote under the agent step's
  /// `outputKey`. Accepts a `Map` (structured), a JSON string, a fenced
  /// ```` ```json ```` block, or plain markdown (kept verbatim as
  /// [enhancedNotes] so the recording is never lost).
  static MeetingOutcome parse(Object? raw) {
    final map = _asMap(raw);
    if (map == null) {
      final text = raw is String ? raw.trim() : '';
      return MeetingOutcome(enhancedNotes: text.isEmpty ? null : text);
    }
    return MeetingOutcome(
      isStructured: true,
      summary: _str(map['summary'] ?? map['Summary']),
      enhancedNotes: _str(
        map['enhancedNotes'] ??
            map['enhanced_notes'] ??
            map['notes'] ??
            map['Notes'],
      ),
      actionItems: _actionItems(
        map['actionItems'] ?? map['action_items'] ?? map['actions'],
      ),
      decisions: _decisions(map['decisions'] ?? map['Decisions']),
    );
  }

  static Map<String, dynamic>? _asMap(Object? raw) {
    if (raw is Map) {
      final m = raw.cast<String, dynamic>();
      // The engine may hand us {result: <inner>}; unwrap a structured inner so
      // the agent following the `{result: ...}` convention still works.
      if (m.length == 1 && m.containsKey('result')) {
        final inner = _asMap(m['result']);
        if (inner != null) {
          return inner;
        }
      }
      return m;
    }
    if (raw is String) {
      final decoded = _tryDecode(raw);
      if (decoded is Map) {
        return _asMap(decoded);
      }
    }
    return null;
  }

  static Object? _tryDecode(String raw) {
    var s = raw.trim();
    if (s.isEmpty) {
      return null;
    }
    final fence =
        RegExp(r'^```[a-zA-Z]*\s*([\s\S]*?)\s*```$').firstMatch(s);
    if (fence != null) {
      s = fence.group(1)!.trim();
    }
    if (!s.startsWith('{')) {
      final start = s.indexOf('{');
      final end = s.lastIndexOf('}');
      if (start < 0 || end <= start) {
        return null;
      }
      s = s.substring(start, end + 1);
    }
    try {
      return jsonDecode(s);
    } on FormatException {
      return null;
    }
  }

  static String? _str(Object? v) {
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? null : t;
    }
    return null;
  }

  static List<ParsedActionItem> _actionItems(Object? v) {
    if (v is! List) {
      return const [];
    }
    final out = <ParsedActionItem>[];
    for (final e in v) {
      if (e is String) {
        final t = e.trim();
        if (t.isNotEmpty) {
          out.add(ParsedActionItem(t));
        }
      } else if (e is Map) {
        final m = e.cast<String, dynamic>();
        final text = _str(
          m['text'] ??
              m['action'] ??
              m['item'] ??
              m['title'] ??
              m['task'] ??
              m['description'],
        );
        if (text != null) {
          out.add(
            ParsedActionItem(
              text,
              owner: _str(m['owner'] ?? m['assignee'] ?? m['who']),
            ),
          );
        }
      }
    }
    return out;
  }

  static List<String> _decisions(Object? v) {
    if (v is! List) {
      return const [];
    }
    final out = <String>[];
    for (final e in v) {
      if (e is String) {
        final t = e.trim();
        if (t.isNotEmpty) {
          out.add(t);
        }
      } else if (e is Map) {
        final m = e.cast<String, dynamic>();
        final text = _str(
          m['text'] ?? m['decision'] ?? m['title'] ?? m['description'],
        );
        if (text != null) {
          out.add(text);
        }
      }
    }
    return out;
  }
}
