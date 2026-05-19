import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A stable fingerprint of one tool in the effective config: its name plus a
/// hash of its JSON schema, so a schema change re-keys the config (PRD 21 §1).
class ToolFingerprint {
  /// Creates a [ToolFingerprint].
  const ToolFingerprint({required this.name, required this.schemaHash});

  /// Builds a fingerprint by hashing the tool's [schema] map.
  factory ToolFingerprint.fromSchema(
    String name,
    Map<String, dynamic> schema,
  ) => ToolFingerprint(name: name, schemaHash: canonicalHash(schema));

  /// Tool name.
  final String name;

  /// SHA-256 over the tool's canonical JSON schema.
  final String schemaHash;

  /// Canonical `[name, schemaHash]` pair for the config document.
  List<String> toCanonical() => [name, schemaHash];
}

/// The effective agent configuration, and its content hash (PRD 21 §1, §6).
///
/// The hash is **normative** (spec Clarifications): SHA-256 over a canonical
/// JSON document with sorted keys and a fixed field list — the post-assembly
/// system prompt, sorted mode prompts, sorted tool `(name, schemaHash)` pairs,
/// the model id, sorted memory-policy `id@version` refs, and the routing-table
/// hash. The field list itself carries a [hashVersion] so *adding a field later
/// re-keys deliberately*, never silently — old hashes stay comparable within
/// their version.
class AgentConfigSnapshot {
  /// Creates an [AgentConfigSnapshot].
  const AgentConfigSnapshot({
    required this.systemPrompt,
    required this.modePrompts,
    required this.tools,
    required this.modelId,
    required this.memoryPolicies,
    required this.routingHash,
    this.hashVersion = currentHashVersion,
  });

  /// The current config-hash field-list version. Bump ONLY when the hashed
  /// field set changes (which deliberately re-keys every config).
  static const int currentHashVersion = 1;

  /// The fully-assembled system prompt text.
  final String systemPrompt;

  /// The mode prompt block texts (sorted before hashing).
  final List<String> modePrompts;

  /// The tool fingerprints (sorted by name before hashing).
  final List<ToolFingerprint> tools;

  /// The resolved model id (e.g. `anthropic/claude-opus-4-8`).
  final String modelId;

  /// Memory-policy refs as `id@version` strings (sorted before hashing).
  final List<String> memoryPolicies;

  /// A hash of the routing table (opaque; the router computes it).
  final String routingHash;

  /// The field-list version this snapshot was hashed under.
  final int hashVersion;

  /// The canonical JSON document the hash is computed over. Deterministic:
  /// keys are emitted in sorted order and every list is sorted.
  Map<String, dynamic> canonicalDocument() {
    final sortedModePrompts = [...modePrompts]..sort();
    final sortedTools = [...tools]..sort((a, b) => a.name.compareTo(b.name));
    final sortedPolicies = [...memoryPolicies]..sort();
    // Keys listed alphabetically so the encoded document is canonical.
    return {
      'hashVersion': hashVersion,
      'memoryPolicies': sortedPolicies,
      'modelId': modelId,
      'modePrompts': sortedModePrompts,
      'routingHash': routingHash,
      'systemPrompt': systemPrompt,
      'tools': sortedTools.map((t) => t.toCanonical()).toList(),
    };
  }

  /// The `sha256:...`-prefixed content hash of [canonicalDocument].
  String get configHash => 'sha256:${canonicalHash(canonicalDocument())}';

  /// The stored config JSON (same as the canonical document — self-describing).
  String toJsonString() => jsonEncode(canonicalDocument());
}

/// SHA-256 over a value's canonical JSON encoding (sorted keys, recursively).
/// Shared by [ToolFingerprint] and [AgentConfigSnapshot] so hashing is
/// deterministic regardless of map insertion order.
String canonicalHash(Object? value) =>
    sha256.convert(utf8.encode(_canonicalEncode(value))).toString();

String _canonicalEncode(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    final buffer = StringBuffer('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        buffer.write(',');
      }
      buffer
        ..write(jsonEncode(keys[i]))
        ..write(':')
        ..write(_canonicalEncode(value[keys[i]]));
    }
    buffer.write('}');
    return buffer.toString();
  }
  if (value is List) {
    final buffer = StringBuffer('[');
    for (var i = 0; i < value.length; i++) {
      if (i > 0) {
        buffer.write(',');
      }
      buffer.write(_canonicalEncode(value[i]));
    }
    buffer.write(']');
    return buffer.toString();
  }
  return jsonEncode(value);
}
