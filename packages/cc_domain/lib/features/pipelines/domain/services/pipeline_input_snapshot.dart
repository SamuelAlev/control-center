import 'dart:convert';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';

/// Snapshots the body's input — config metadata, the rendered prompt with
/// `{{key}}` placeholders substituted, the values of the keys listed in
/// `inputKeys` and the trigger payload. Stored on the step run so the
/// run-detail card can show what the body actually saw.
String encodePipelineInputSnapshot(
  PipelineStepDefinition stepDef,
  PipelineContext ctx,
) {
  final config = stepDef.config;
  final inputs = <String, dynamic>{};
  for (final key in config.inputKeys) {
    final v = ctx.state[key] ?? ctx.triggerPayload?[key];
    if (v != null) {
      inputs[key] = _redactSecret(key, v);
    }
  }
  final rendered = config.prompt?.replaceAllMapped(
    RegExp(r'\{\{\s*([a-zA-Z0-9_.$]+)\s*\}\}'),
    (m) {
      final key = m.group(1)!;
      final v = ctx.state[key] ?? ctx.triggerPayload?[key];
      return v == null ? '' : '${_redactSecret(key, v)}';
    },
  );
  return jsonEncode({
    'bodyKey': stepDef.bodyKey,
    if (config.agentId != null) 'agentId': config.agentId,
    if (config.outputKey != null) 'outputKey': config.outputKey,
    'prompt': ?rendered,
    if (inputs.isNotEmpty) 'inputs': inputs,
    if (ctx.triggerPayload != null) 'triggerPayload': ctx.triggerPayload,
  });
}

final RegExp _secretKeyPattern = RegExp(
  r'(token|secret|password|passwd|apikey|api_key|authorization|credential|private_key)',
  caseSensitive: false,
);

/// Redacts values whose key name looks secret, so the persisted input
/// snapshot never writes credentials to disk in cleartext.
Object? _redactSecret(String key, Object? value) {
  if (_secretKeyPattern.hasMatch(key)) {
    return '***redacted***';
  }
  return value;
}
