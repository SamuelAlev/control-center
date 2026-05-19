/// Semantic validation for a [SwarmDefinition].
///
/// Checks cross-references and mode constraints that the constructor's
/// structural asserts do not cover: dangling / self-referential dependency
/// edges, empty-when-provided model overrides, and `targetCount` bounds.
///
/// Ported from oh-my-pi `swarm-extension/src/swarm/schema.ts`
/// (`validateSwarmDefinition`).
library;

import 'package:cc_domain/features/dispatch/domain/swarm/swarm_definition.dart';

/// Validates [def] and returns a list of human-readable error messages.
///
/// An empty list means the definition is semantically valid. The checks are:
///
/// * [SwarmAgent.waitsFor] / [SwarmAgent.reportsTo] referencing an unknown
///   agent, or referencing the agent itself.
/// * A provided-but-empty [SwarmDefinition.model] or [SwarmAgent.model].
/// * [SwarmDefinition.targetCount] below `1`.
/// * [SwarmDefinition.targetCount] differing from `1` outside
///   [SwarmMode.pipeline].
List<String> validateSwarmDefinition(SwarmDefinition def) {
  final errors = <String>[];
  final agentNames = def.agents.keys.toSet();

  if (def.model != null && def.model!.isEmpty) {
    errors.add('swarm.model must not be empty when provided');
  }

  for (final entry in def.agents.entries) {
    final name = entry.key;
    final agent = entry.value;

    for (final dep in agent.waitsFor) {
      if (!agentNames.contains(dep)) {
        errors.add("Agent '$name' waits_for unknown agent '$dep'");
      }
      if (dep == name) {
        errors.add("Agent '$name' cannot wait for itself");
      }
    }

    for (final target in agent.reportsTo) {
      if (!agentNames.contains(target)) {
        errors.add("Agent '$name' reports_to unknown agent '$target'");
      }
      if (target == name) {
        errors.add("Agent '$name' cannot report to itself");
      }
    }

    if (agent.model != null && agent.model!.isEmpty) {
      errors.add("Agent '$name' model must not be empty when provided");
    }
  }

  if (def.targetCount < 1) {
    errors.add('target_count must be at least 1');
  }
  if (def.mode != SwarmMode.pipeline && def.targetCount != 1) {
    errors.add('target_count is only supported in pipeline mode');
  }

  return errors;
}
