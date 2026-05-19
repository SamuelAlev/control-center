import 'package:control_center/core/domain/ports/schema_validator_port.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration_proposal.dart';

/// Deterministically validates an [OrchestrationProposal] before it is
/// persisted / approved. Returns a list of human-readable violations (empty
/// means valid) so the orchestrator agent can self-correct in the same run.
class OrchestrationProposalValidator {
  /// Creates an [OrchestrationProposalValidator].
  const OrchestrationProposalValidator({this.schemaValidator});

  /// Optional validator for the well-formedness of declared schemas.
  final SchemaValidatorPort? schemaValidator;

  /// Engine concurrency is bounded, and the approval UI must stay legible —
  /// cap roles / sub-tickets so a proposal can't green-light a 40-node fan-out.
  static const int maxRoles = 8;

  /// Maximum number of sub-tickets in one proposal.
  static const int maxSubTickets = 16;

  /// Returns all violations (empty = valid).
  List<String> validate(OrchestrationProposal p) {
    final issues = <String>[];

    if (p.goal.trim().isEmpty) {
      issues.add('goal must not be empty');
    }
    if (p.roles.isEmpty) {
      issues.add('at least one role is required');
    }
    if (p.subTickets.isEmpty) {
      issues.add('at least one sub-ticket is required');
    }
    if (p.roles.length > maxRoles) {
      issues.add('too many roles (${p.roles.length}); max is $maxRoles');
    }
    if (p.subTickets.length > maxSubTickets) {
      issues.add(
          'too many sub-tickets (${p.subTickets.length}); max is $maxSubTickets');
    }

    // Role keys: unique, non-empty, well-specified (exactly one of existing /
    // hire).
    final roleKeys = <String>{};
    for (final r in p.roles) {
      if (r.roleKey.trim().isEmpty) {
        issues.add('a role has an empty roleKey');
        continue;
      }
      if (!roleKeys.add(r.roleKey)) {
        issues.add('duplicate roleKey "${r.roleKey}"');
      }
      final hasExisting =
          r.existingAgentId != null && r.existingAgentId!.isNotEmpty;
      final hasHire = r.hireSpec != null;
      if (hasExisting == hasHire) {
        issues.add('role "${r.roleKey}" must set exactly one of '
            'existingAgentId or hireSpec');
      }
      if (hasHire && r.hireSpec!.name.trim().isEmpty) {
        issues.add('role "${r.roleKey}" hire spec has an empty name');
      }
    }

    // Sub-tickets: unique keys, valid roleKey, dependencies exist, schema
    // well-formed.
    final ticketKeys = <String>{};
    for (final t in p.subTickets) {
      if (t.key.trim().isEmpty) {
        issues.add('a sub-ticket has an empty key');
        continue;
      }
      if (!ticketKeys.add(t.key)) {
        issues.add('duplicate sub-ticket key "${t.key}"');
      }
      if (!roleKeys.contains(t.roleKey)) {
        issues.add('sub-ticket "${t.key}" references unknown role '
            '"${t.roleKey}"');
      }
      final schema = t.expectedOutputSchema;
      if (schema != null && schemaValidator != null) {
        for (final problem in schemaValidator!.validateSchema(schema)) {
          issues.add('sub-ticket "${t.key}" output schema is malformed: '
              '$problem');
        }
      }
    }
    // dependsOn must reference existing sub-tickets.
    for (final t in p.subTickets) {
      for (final dep in t.dependsOn) {
        if (!ticketKeys.contains(dep)) {
          issues.add('sub-ticket "${t.key}" depends on unknown "$dep"');
        }
      }
    }

    // Acyclic dependency graph (Kahn).
    if (_hasCycle(p.subTickets)) {
      issues.add('sub-ticket dependencies contain a cycle');
    }

    // Synthesis role must resolve.
    if (p.synthesis.roleKey.trim().isEmpty ||
        !roleKeys.contains(p.synthesis.roleKey)) {
      issues.add('synthesis references unknown role '
          '"${p.synthesis.roleKey}"');
    }
    if (p.synthesis.outputSchema.isEmpty) {
      issues.add('synthesis must declare an output schema');
    } else if (schemaValidator != null) {
      for (final problem
          in schemaValidator!.validateSchema(p.synthesis.outputSchema)) {
        issues.add('synthesis output schema is malformed: $problem');
      }
    }

    // Research role (when set) must resolve.
    if (p.research.enabled &&
        p.research.roleKey != null &&
        p.research.roleKey!.isNotEmpty &&
        !roleKeys.contains(p.research.roleKey)) {
      issues.add('research references unknown role "${p.research.roleKey}"');
    }

    return issues;
  }

  bool _hasCycle(List<ProposedSubTicket> tickets) {
    final indegree = <String, int>{for (final t in tickets) t.key: 0};
    final edges = <String, List<String>>{for (final t in tickets) t.key: []};
    for (final t in tickets) {
      for (final dep in t.dependsOn) {
        if (indegree.containsKey(dep)) {
          // dep -> t.
          edges[dep]!.add(t.key);
          indegree[t.key] = (indegree[t.key] ?? 0) + 1;
        }
      }
    }
    final queue = <String>[
      for (final e in indegree.entries)
        if (e.value == 0) e.key,
    ];
    var visited = 0;
    while (queue.isNotEmpty) {
      final n = queue.removeLast();
      visited++;
      for (final m in edges[n]!) {
        indegree[m] = indegree[m]! - 1;
        if (indegree[m] == 0) {
          queue.add(m);
        }
      }
    }
    return visited != tickets.length;
  }
}
