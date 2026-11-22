/// Marks an approval card or a question as coming from a code mode script
/// rather than from the model directly.
///
/// The card and the form say so and link to the script's transcript row: a
/// person asked to approve a push needs to know the request came from inside a
/// script the model wrote, not from a call they could read in full above.
///
/// Lives in the shared kernel, not in the code mode feature, because the
/// confirmation and question ports that carry it are core contracts.
class ScriptCallOrigin {
  /// Creates an origin. Throws [ArgumentError] when [parentToolCallId] is
  /// empty, or when [executionId] is given and empty.
  ScriptCallOrigin({required this.parentToolCallId, this.executionId}) {
    if (parentToolCallId.isEmpty) {
      throw ArgumentError.value(
        parentToolCallId,
        'parentToolCallId',
        'must not be empty',
      );
    }
    if (executionId case final id? when id.isEmpty) {
      throw ArgumentError.value(id, 'executionId', 'must not be empty');
    }
  }

  /// Rebuilds from [toJson]'s output, or returns null when [json] is not a map
  /// carrying a parent call id. Tolerant on purpose: an origin is display
  /// context, and a malformed one must not cost the card it rides on. An
  /// execution id that is missing or not a non-empty string is dropped, so
  /// the card still says a script asked but links no record.
  static ScriptCallOrigin? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final parent = json['parent_tool_call_id'];
    final execution = json['execution_id'];
    if (parent is! String || parent.isEmpty) {
      return null;
    }
    return ScriptCallOrigin(
      parentToolCallId: parent,
      executionId: execution is String && execution.isNotEmpty
          ? execution
          : null,
    );
  }

  /// The tool call id of the `repl` call whose script made the request.
  final String parentToolCallId;

  /// The code execution record's id, or null when the gate knows of no
  /// running script under [parentToolCallId]. Set only when the gate
  /// knows the execution the call belongs to, so a card never links a record
  /// that does not exist or belongs to another script.
  final String? executionId;

  /// The wire form. `execution_id` is absent when there is no record.
  Map<String, dynamic> toJson() => {
    'parent_tool_call_id': parentToolCallId,
    'execution_id': ?executionId,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScriptCallOrigin &&
          other.parentToolCallId == parentToolCallId &&
          other.executionId == executionId;

  @override
  int get hashCode => Object.hash(parentToolCallId, executionId);

  @override
  String toString() => 'ScriptCallOrigin($parentToolCallId, $executionId)';
}
