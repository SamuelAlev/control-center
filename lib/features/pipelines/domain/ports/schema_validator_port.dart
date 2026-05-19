import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart' show PipelineNodeConfig;

/// Validates a value against a JSON-Schema-subset declaration.
///
/// Implemented in the data layer so the domain stays free of any concrete
/// schema library. The engine uses it to enforce a node's
/// [PipelineNodeConfig.outputSchema] before merging the node's output into
/// pipeline state.
abstract interface class SchemaValidatorPort {
  /// Returns a list of human-readable violation messages, or an empty list if
  /// [value] satisfies [schema]. Never throws on a malformed schema — it
  /// returns a single violation describing the problem instead.
  List<String> validate(Object? value, Map<String, dynamic> schema);
}
