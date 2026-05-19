import 'package:yaml/yaml.dart';

/// Extract yaml field.
String? extractYamlField(String content, String field) {
  final trimmed = content.trim();
  if (!trimmed.startsWith('---')) {
    return null;
  }
  final secondDelim = trimmed.indexOf('---', 3);
  if (secondDelim == -1) {
    return null;
  }
  final yamlStr = trimmed.substring(3, secondDelim).trim();
  try {
    final parsed = loadYaml(yamlStr);
    if (parsed is YamlMap) {
      if (parsed.containsKey(field)) {
        return (parsed[field] ?? '').toString();
      }
      return null;
    }
  } on Object catch (_) {}
  return null;
}

/// Extract markdown body.
String extractMarkdownBody(String content) {
  final trimmed = content.trim();
  if (!trimmed.startsWith('---')) {
    return trimmed;
  }
  final secondDelim = trimmed.indexOf('---', 3);
  if (secondDelim == -1) {
    return trimmed;
  }
  return trimmed.substring(secondDelim + 3).trim();
}

