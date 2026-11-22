/// One task-boundary routing decision (report 4A: "Prefer changing
/// model/effort at task boundaries rather than repeatedly mid-session").
class RoutingDecision {
  /// Creates a [RoutingDecision].
  const RoutingDecision({this.modelId, this.effortLevel, this.note = ''});

  /// Parses from JSON.
  factory RoutingDecision.fromJson(Map<String, dynamic> json) =>
      RoutingDecision(
        modelId: json['modelId'] as String?,
        effortLevel: json['effortLevel'] as String?,
        note: json['note'] as String? ?? '',
      );

  /// Model to use, or null to keep the pinned model.
  final String? modelId;

  /// Effort to use, or null to keep the pinned effort.
  final String? effortLevel;

  /// Why this route was chosen (audit trail).
  final String note;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (modelId != null) 'modelId': modelId,
    if (effortLevel != null) 'effortLevel': effortLevel,
    if (note.isNotEmpty) 'note': note,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutingDecision &&
          modelId == other.modelId &&
          effortLevel == other.effortLevel &&
          note == other.note;

  @override
  int get hashCode => Object.hash(modelId, effortLevel, note);
}
