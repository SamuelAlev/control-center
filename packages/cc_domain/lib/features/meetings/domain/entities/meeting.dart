/// How a meeting was captured, which decides what diarization splits.
enum MeetingMode {
  /// Remote call: mic = the user ("me"), system output = the others ("them").
  /// Diarization splits the `them` channel into individual remote speakers.
  remote,

  /// In-person: one shared microphone with several people in the room (no
  /// system-audio capture). Diarization splits the mic into in-room speakers.
  inPerson;

  /// Parses a stored mode string, defaulting to [MeetingMode.remote].
  static MeetingMode fromStorage(String? value) {
    return MeetingMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => MeetingMode.remote,
    );
  }

  /// The string persisted in the database.
  String toStorage() => name;
}

/// Lifecycle status of a recorded meeting.
enum MeetingStatus {
  /// Audio is being captured and transcribed live.
  recording,

  /// Recording stopped; the summarizer agent is augmenting the notes.
  processing,

  /// Notes are finalized.
  done,

  /// Recording or summarization failed.
  failed;

  /// Parses a stored status string, defaulting to [MeetingStatus.done].
  static MeetingStatus fromStorage(String? value) {
    return MeetingStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MeetingStatus.done,
    );
  }

  /// The string persisted in the database.
  String toStorage() => name;
}

/// A recorded meeting with augment-my-notes.
class Meeting {
  /// Creates a [Meeting].
  Meeting({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.startedAt,
    this.mode = MeetingMode.remote,
    this.sourceApp,
    this.userNotes = '',
    this.enhancedNotes,
    this.summary,
    this.summaryInstructions,
    this.audioPath,
    this.endedAt,
    this.titleIsCustom = false,
  }) : assert(
          workspaceId.isNotEmpty,
          'Meeting workspaceId must not be empty',
        );

  /// Unique identifier.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// User-edited title.
  final String title;

  /// Lifecycle status.
  final MeetingStatus status;

  /// How the meeting was captured (remote vs in-person) — decides what
  /// diarization splits.
  final MeetingMode mode;

  /// Detected source application, when known.
  final String? sourceApp;

  /// Sparse notes the user typed live.
  final String userNotes;

  /// AI-augmented notes (null until summarization completes).
  final String? enhancedNotes;

  /// Short executive summary (null until summarization completes).
  final String? summary;

  /// The summary template's instructions captured when summarization first ran,
  /// so a later "Re-run summary" reproduces the original template even if the
  /// user has since switched/edited their active template. Null for meetings
  /// recorded before this snapshot existed (they fall back to the current
  /// template).
  final String? summaryInstructions;

  /// On-disk path to retained raw audio, when retention is enabled.
  final String? audioPath;

  /// Whether the user has manually renamed the meeting. While false, a linked
  /// calendar event's title keeps the meeting title in sync (on link and on
  /// every calendar sync); once the user edits the title it is "custom" and the
  /// calendar never overwrites it again.
  final bool titleIsCustom;

  /// When recording began.
  final DateTime startedAt;

  /// When recording stopped.
  final DateTime? endedAt;

  /// When the row was created.
  final DateTime createdAt;

  /// When the row was last updated.
  final DateTime updatedAt;

  /// Whether summarization has produced enhanced notes.
  bool get isEnhanced => enhancedNotes != null && enhancedNotes!.isNotEmpty;

  /// Returns a copy with optional field overrides.
  Meeting copyWith({
    String? title,
    MeetingStatus? status,
    MeetingMode? mode,
    String? sourceApp,
    String? userNotes,
    String? enhancedNotes,
    String? summary,
    String? summaryInstructions,
    String? audioPath,
    DateTime? endedAt,
    DateTime? updatedAt,
    bool? titleIsCustom,
  }) {
    return Meeting(
      id: id,
      workspaceId: workspaceId,
      title: title ?? this.title,
      status: status ?? this.status,
      mode: mode ?? this.mode,
      sourceApp: sourceApp ?? this.sourceApp,
      userNotes: userNotes ?? this.userNotes,
      enhancedNotes: enhancedNotes ?? this.enhancedNotes,
      summary: summary ?? this.summary,
      summaryInstructions: summaryInstructions ?? this.summaryInstructions,
      audioPath: audioPath ?? this.audioPath,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      titleIsCustom: titleIsCustom ?? this.titleIsCustom,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Meeting &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          title == other.title &&
          status == other.status &&
          mode == other.mode &&
          sourceApp == other.sourceApp &&
          userNotes == other.userNotes &&
          enhancedNotes == other.enhancedNotes &&
          summary == other.summary &&
          summaryInstructions == other.summaryInstructions &&
          audioPath == other.audioPath &&
          startedAt == other.startedAt &&
          endedAt == other.endedAt &&
          titleIsCustom == other.titleIsCustom;

  @override
  int get hashCode => Object.hash(
        id,
        workspaceId,
        title,
        status,
        mode,
        sourceApp,
        userNotes,
        enhancedNotes,
        summary,
        summaryInstructions,
        audioPath,
        startedAt,
        endedAt,
        titleIsCustom,
      );
}
