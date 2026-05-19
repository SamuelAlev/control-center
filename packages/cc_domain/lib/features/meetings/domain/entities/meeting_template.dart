import 'dart:convert';

/// A meeting-notes template: a named bundle of extra instructions injected into
/// the `meeting_summary` agent prompt so the output is shaped for a kind of
/// meeting (1:1, discovery call, stand-up, …).
///
/// [instructions] are model-facing (appended to the summarize prompt), so the
/// built-in names/instructions are intentionally NOT localized (data layer, no
/// BuildContext — same convention as default agent names). Custom templates
/// carry whatever the user typed.
class MeetingTemplate {
  /// Creates a [MeetingTemplate].
  const MeetingTemplate({
    required this.id,
    required this.name,
    required this.instructions,
    this.builtIn = false,
  });

  /// Parses a custom template from stored JSON. Returns null on malformed input.
  static MeetingTemplate? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return null;
    }
    return MeetingTemplate(
      id: id,
      name: name,
      instructions: json['instructions'] is String
          ? json['instructions'] as String
          : '',
    );
  }

  /// Stable id (slug for built-ins, uuid for custom).
  final String id;

  /// Display name shown in the picker / manager.
  final String name;

  /// Extra prompt instructions injected into the summarize step (may be empty).
  final String instructions;

  /// Whether this is a built-in preset (not user-deletable).
  final bool builtIn;

  /// JSON for persistence (custom templates only).
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'instructions': instructions,
      };

  /// Copy with overrides.
  MeetingTemplate copyWith({String? name, String? instructions}) =>
      MeetingTemplate(
        id: id,
        name: name ?? this.name,
        instructions: instructions ?? this.instructions,
        builtIn: builtIn,
      );

  @override
  bool operator ==(Object other) =>
      other is MeetingTemplate &&
      other.id == id &&
      other.name == name &&
      other.instructions == instructions &&
      other.builtIn == builtIn;

  @override
  int get hashCode => Object.hash(id, name, instructions, builtIn);

  /// The id of the no-op default template (general-purpose, no extra steering).
  static const String defaultId = 'default';

  /// The built-in presets, in picker order. `default` first (current behaviour).
  static const List<MeetingTemplate> builtIns = [
    MeetingTemplate(
      id: defaultId,
      name: 'General',
      instructions: '',
      builtIn: true,
    ),
    MeetingTemplate(
      id: 'one_on_one',
      name: '1:1',
      instructions:
          'This is a 1:1 meeting. Center the notes on the individual: their '
          'updates, wins, blockers, growth/feedback discussed, and personal '
          'action items. Keep it concise and people-focused.',
      builtIn: true,
    ),
    MeetingTemplate(
      id: 'discovery',
      name: 'Discovery call',
      instructions:
          'This is a customer/user discovery call. Capture the customer\'s '
          'goals, pain points, current workflow, objections, budget/timeline '
          'signals, and feature requests. Clearly separate verified facts from '
          'hypotheses or assumptions.',
      builtIn: true,
    ),
    MeetingTemplate(
      id: 'hiring',
      name: 'Hiring interview',
      instructions:
          'This is a hiring interview. Summarize the candidate\'s background '
          'and strengths, concerns/risks, signal per competency, and end with '
          'a clear hire / no-hire leaning and its rationale.',
      builtIn: true,
    ),
    MeetingTemplate(
      id: 'standup',
      name: 'Stand-up',
      instructions:
          'This is a stand-up. For each person, capture three things tersely: '
          'what they did, what they will do next, and any blockers. Prefer '
          'tight bullets over prose.',
      builtIn: true,
    ),
    MeetingTemplate(
      id: 'weekly',
      name: 'Weekly sync',
      instructions:
          'This is a weekly sync / status meeting. Organize the notes by '
          'workstream or project, each with progress, risks, decisions, and '
          'next steps.',
      builtIn: true,
    ),
  ];

  /// Serializes a list of custom templates to a JSON string for prefs.
  static String encodeCustom(List<MeetingTemplate> custom) =>
      jsonEncode([for (final t in custom) t.toJson()]);

  /// Parses custom templates from a prefs JSON string (tolerant of garbage).
  static List<MeetingTemplate> decodeCustom(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) {
      return const [];
    }
    final out = <MeetingTemplate>[];
    for (final e in decoded) {
      if (e is Map) {
        final t = fromJson(e.cast<String, dynamic>());
        if (t != null) {
          out.add(t);
        }
      }
    }
    return out;
  }
}
