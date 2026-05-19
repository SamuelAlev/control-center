import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:test/test.dart';

AgentConfigSnapshot _snapshot({
  String systemPrompt = 'You are a helpful agent.',
  List<String>? modePrompts,
  List<ToolFingerprint>? tools,
  String modelId = 'anthropic/claude-opus-4-8',
  List<String>? memoryPolicies,
  String routingHash = 'route-abc',
  int hashVersion = AgentConfigSnapshot.currentHashVersion,
}) => AgentConfigSnapshot(
  systemPrompt: systemPrompt,
  modePrompts: modePrompts ?? const ['mode-a', 'mode-b'],
  tools:
      tools ??
      const [
        ToolFingerprint(name: 'read', schemaHash: 'h1'),
        ToolFingerprint(name: 'write', schemaHash: 'h2'),
      ],
  modelId: modelId,
  memoryPolicies: memoryPolicies ?? const ['p1@1', 'p2@1'],
  routingHash: routingHash,
  hashVersion: hashVersion,
);

void main() {
  group('canonicalHash', () {
    test('is order-independent for map keys', () {
      final a = canonicalHash(<String, dynamic>{'a': 1, 'b': 2, 'c': 3});
      final b = canonicalHash(<String, dynamic>{'c': 3, 'a': 1, 'b': 2});
      expect(a, b);
    });

    test('is order-independent for nested map keys', () {
      final a = canonicalHash(<String, dynamic>{
        'outer': <String, dynamic>{'x': 1, 'y': 2},
      });
      final b = canonicalHash(<String, dynamic>{
        'outer': <String, dynamic>{'y': 2, 'x': 1},
      });
      expect(a, b);
    });

    test('a value change changes the hash', () {
      expect(
        canonicalHash(<String, dynamic>{'a': 1}),
        isNot(canonicalHash(<String, dynamic>{'a': 2})),
      );
    });
  });

  group('AgentConfigSnapshot.configHash', () {
    test('identical fields in different list orders hash the same', () {
      final a = _snapshot(
        modePrompts: const ['mode-a', 'mode-b'],
        tools: const [
          ToolFingerprint(name: 'read', schemaHash: 'h1'),
          ToolFingerprint(name: 'write', schemaHash: 'h2'),
        ],
        memoryPolicies: const ['p1@1', 'p2@1'],
      );
      final b = _snapshot(
        modePrompts: const ['mode-b', 'mode-a'],
        tools: const [
          ToolFingerprint(name: 'write', schemaHash: 'h2'),
          ToolFingerprint(name: 'read', schemaHash: 'h1'),
        ],
        memoryPolicies: const ['p2@1', 'p1@1'],
      );
      expect(a.configHash, b.configHash);
    });

    test('a one-character system-prompt change changes the hash', () {
      final a = _snapshot(systemPrompt: 'You are a helpful agent.');
      final b = _snapshot(systemPrompt: 'You are a helpful agent!');
      expect(a.configHash, isNot(b.configHash));
    });

    test('a tool schema change changes the hash', () {
      final v1 = ToolFingerprint.fromSchema('search', <String, dynamic>{
        'type': 'object',
        'q': 'string',
      });
      final v2 = ToolFingerprint.fromSchema('search', <String, dynamic>{
        'type': 'object',
        'q': 'number',
      });
      expect(v1.schemaHash, isNot(v2.schemaHash));
      expect(
        _snapshot(tools: [v1]).configHash,
        isNot(_snapshot(tools: [v2]).configHash),
      );
    });

    test('reordering the same tools does not change the hash', () {
      final read = ToolFingerprint.fromSchema('read', <String, dynamic>{
        'path': 'string',
      });
      final write = ToolFingerprint.fromSchema('write', <String, dynamic>{
        'path': 'string',
        'content': 'string',
      });
      expect(
        _snapshot(tools: [read, write]).configHash,
        _snapshot(tools: [write, read]).configHash,
      );
    });

    test('bumping hashVersion re-keys the hash', () {
      expect(
        _snapshot(hashVersion: 1).configHash,
        isNot(_snapshot(hashVersion: 2).configHash),
      );
    });

    test('configHash is sha256-prefixed with 64 hex chars', () {
      final hash = _snapshot().configHash;
      expect(hash, startsWith('sha256:'));
      final hex = hash.substring('sha256:'.length);
      expect(hex.length, 64);
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hex), isTrue);
    });
  });
}
