/// Per-call `description` argument for script tools (`bash`, `eval`).
///
/// A script call has no scannable target the way `read`/`edit` have a path:
/// without a short label, a transcript is `bash` / `bash` / `bash` over
/// opaque commands. Requiring a 5–10 word summary per call makes the
/// transcript legible — the chat row shows the description as its primary
/// label and demotes the tool name to a subtitle.
///
/// This is deliberately NOT injected on every tool via `toSchema()`:
/// `task.description` is the subagent prompt and several MCP tools use
/// `description` as a domain field, so a blanket key would collide. Tools
/// that need it opt in with [withRequiredCallDescription] +
/// [missingCallDescription].
library;

import 'package:cc_harness/src/tools/tool.dart';

/// The JSON Schema property for the per-call description.
const Map<String, dynamic> callDescriptionProperty = {
  'type': 'string',
  'description':
      'Clear, concise description of what this call does in 5-10 words. '
      'Shown to the user in the transcript in place of the raw command or '
      'code, so it must say what the call accomplishes.',
};

/// Returns [schema] with a required per-call `description` argument merged in.
///
/// Adds [callDescriptionProperty] under `properties.description` and appends
/// `description` to `required`.
Map<String, dynamic> withRequiredCallDescription(Map<String, dynamic> schema) {
  final properties = {
    ...?(schema['properties'] as Map<String, dynamic>?),
    'description': callDescriptionProperty,
  };
  final required = [
    ...?(schema['required'] as List?)?.cast<String>(),
    'description',
  ];
  return {...schema, 'properties': properties, 'required': required};
}

/// Returns the error result for a missing/blank per-call description, or null
/// when [args] carries a usable one.
///
/// Same phrasing the tools use for their other required arguments, so the
/// model gets one consistent correction signal.
HarnessToolResult? missingCallDescription(Map<String, dynamic> args) {
  final description = args['description'];
  if (description is! String || description.trim().isEmpty) {
    return HarnessToolResult.error('Missing or invalid argument: description');
  }
  return null;
}
