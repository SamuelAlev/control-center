import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/json_safe.dart';

/// How the run a wake starts is dispatched (`agent_wakes.run_options`).
///
/// Null on a wake means the defaults: the conversation's history, the
/// agent's normal tools, the default run cap and no output contract.
class WakeRunOptions {
  /// Creates run options. Throws [ArgumentError] for a negative cap or an
  /// output schema that is not JSON.
  WakeRunOptions({
    this.freshHistory = false,
    this.readOnly = false,
    this.costCapMicros,
    Map<String, Object?>? outputSchema,
  }) : outputSchema = outputSchema == null
           ? null
           : Map.unmodifiable(outputSchema) {
    final cap = costCapMicros;
    if (cap != null && cap <= 0) {
      throw ArgumentError.value(cap, 'costCapMicros', 'must be positive');
    }
    if (outputSchema != null) {
      JsonSafe.require(outputSchema, 'outputSchema');
    }
  }

  /// The run starts without the conversation's earlier turns (the plan's
  /// `history: none`): a goal reviewer, a `--fresh` goal, the learning
  /// review.
  final bool freshHistory;

  /// The run gets read-only tools (review mode).
  final bool readOnly;

  /// The run's cost cap in micro-dollars, or null for the default cap.
  final int? costCapMicros;

  /// The JSON schema the run's `submit_output` must satisfy (the run log's
  /// `expectedOutputSchema`), or null for no output contract.
  final Map<String, Object?>? outputSchema;

  /// The stored JSON object. Defaults are omitted.
  Map<String, Object?> toJson() => {
    if (freshHistory) 'freshHistory': true,
    if (readOnly) 'readOnly': true,
    'costCapMicros': ?costCapMicros,
    'outputSchema': ?outputSchema,
  };

  /// [toJson] encoded, as the column stores it.
  String encode() => jsonEncode(toJson());

  /// Rebuilds from [toJson]'s output, or null for anything that is not an
  /// object. A field of the wrong type, or a non-positive cap, is dropped.
  static WakeRunOptions? fromJson(Object? json) {
    if (json is! Map) {
      return null;
    }
    final cap = JsonSafe.intOrNull(json['costCapMicros']);
    return WakeRunOptions(
      freshHistory: json['freshHistory'] == true,
      readOnly: json['readOnly'] == true,
      costCapMicros: cap != null && cap > 0 ? cap : null,
      outputSchema: JsonSafe.mapOrNull(json['outputSchema']),
    );
  }

  /// Decodes the stored column. Null, empty or malformed reads as null (the
  /// defaults); it never throws.
  static WakeRunOptions? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WakeRunOptions &&
          freshHistory == other.freshHistory &&
          readOnly == other.readOnly &&
          costCapMicros == other.costCapMicros &&
          JsonSafe.equals(outputSchema, other.outputSchema);

  @override
  int get hashCode => Object.hash(
    freshHistory,
    readOnly,
    costCapMicros,
    JsonSafe.hash(outputSchema),
  );

  @override
  String toString() => 'WakeRunOptions(${toJson()})';
}
