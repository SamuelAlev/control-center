import 'dart:convert';

import 'package:control_center/features/ticketing/domain/value_objects/output_contract_mode.dart';

const _encoder = JsonEncoder.withIndent('  ');

/// Renders the `## Output contract` system block injected into an agent's
/// prompt when its ticket declares an `expectedOutputSchema`.
///
/// The block makes the contract explicit and tells the agent that the
/// `complete_ticket` tool will reject a non-conforming payload with the exact
/// list of violations — so it can self-correct in the same run.
String renderOutputContract(
  Map<String, dynamic> schema, {
  OutputContractMode mode = OutputContractMode.strict,
}) {
  final pretty = _encoder.convert(schema);
  final buf = StringBuffer()
    ..writeln()
    ..writeln('## Output contract')
    ..writeln(
      'When you finish, your `complete_ticket` `output` payload MUST be a '
      'JSON object that validates against this schema:',
    )
    ..writeln('```json')
    ..writeln(pretty)
    ..writeln('```');
  if (mode == OutputContractMode.strict) {
    buf.writeln(
      'The `complete_ticket` tool rejects a non-conforming payload and returns '
      'the exact list of violations — read them, fix the payload, and call '
      '`complete_ticket` again. Do NOT wrap the payload in `{"result": ...}` '
      'unless the schema asks for a `result` field. Emit exactly the fields '
      'the schema declares.',
    );
  } else {
    buf.writeln(
      'Try to conform to this schema; deviations are recorded as warnings '
      'rather than rejected.',
    );
  }
  return buf.toString();
}
