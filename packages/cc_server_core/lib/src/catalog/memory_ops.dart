import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart';

/// Builds the workspace memory ops the catalog spreads: `memory_domain.*`,
/// `memory_access_grant.*`, `agent_working_memory.*`, `memory_fact.*` and
/// `memory_policy.*`.
///
/// Every read is scoped to the bound workspace at the repository, and every
/// write refuses a row whose own workspace is not the session's.
List<RepoOp> buildMemoryOps({
  required MemoryDomainRepository memoryDomainRepository,
  required MemoryAccessGrantRepository memoryAccessGrantRepository,
  required AgentWorkingMemoryRepository agentWorkingMemoryRepository,
  required MemoryFactRepository memoryFactRepository,
  required MemoryPolicyRepository memoryPolicyRepository,
}) => [
  RepoOp(
    name: 'memory_domain.getByWorkspace',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final domains = await memoryDomainRepository.getByWorkspace(
        ctx.workspaceId!,
      );
      return {'domains': domains.map(memoryDomainToWire).toList()};
    },
  ),
  RepoOp(
    name: 'memory_domain.findByName',
    kind: RepoOpKind.read,
    requiredArgs: ['name'],
    handler: (ctx) async {
      final domain = await memoryDomainRepository.findByName(
        ctx.workspaceId!,
        ctx.args['name'] as String,
      );
      return {'domain': domain == null ? null : memoryDomainToWire(domain)};
    },
  ),
  RepoOp(
    name: 'memory_domain.upsert',
    kind: RepoOpKind.mutate,
    requiredArgs: ['domain'],
    handler: (ctx) async {
      final domain = memoryDomainFromWire(
        (ctx.args['domain'] as Map).cast<String, dynamic>(),
      );
      // The domain's own workspace must match the bound session — a client
      // can't write a domain into a foreign workspace (isolation invariant).
      if (domain.workspaceId != ctx.workspaceId) {
        throw const WorkspaceMismatchException(
          'Memory domain belongs to a different workspace',
        );
      }
      await memoryDomainRepository.upsert(domain);
      return {'ok': true};
    },
  ),

  RepoOp(
    name: 'memory_access_grant.getByWorkspace',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final grants = await memoryAccessGrantRepository.getByWorkspace(
        ctx.workspaceId!,
      );
      return {'grants': grants.map(memoryAccessGrantToWire).toList()};
    },
  ),
  RepoOp(
    name: 'memory_access_grant.upsert',
    kind: RepoOpKind.mutate,
    requiredArgs: ['grant'],
    handler: (ctx) async {
      final grant = memoryAccessGrantFromWire(
        (ctx.args['grant'] as Map).cast<String, dynamic>(),
      );
      // The grant's own workspace must match the bound session — a client
      // can't write a grant into a foreign workspace (isolation invariant).
      if (grant.workspaceId != ctx.workspaceId) {
        throw const WorkspaceMismatchException(
          'Memory access grant belongs to a different workspace',
        );
      }
      await memoryAccessGrantRepository.upsert(grant);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'memory_access_grant.upsertAll',
    kind: RepoOpKind.mutate,
    requiredArgs: ['grants'],
    handler: (ctx) async {
      final grants = ((ctx.args['grants'] as List?) ?? const [])
          .whereType<Map>()
          .map((g) => memoryAccessGrantFromWire(g.cast<String, dynamic>()))
          .toList();
      // Every grant must belong to the bound session's workspace — reject the
      // whole batch on any foreign row (isolation invariant).
      for (final grant in grants) {
        if (grant.workspaceId != ctx.workspaceId) {
          throw const WorkspaceMismatchException(
            'Memory access grant belongs to a different workspace',
          );
        }
      }
      await memoryAccessGrantRepository.upsertAll(grants);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'agent_working_memory.getByAgent',
    kind: RepoOpKind.read,
    requiredArgs: ['agent_id'],
    handler: (ctx) async {
      final memory = await agentWorkingMemoryRepository.getByAgent(
        ctx.workspaceId!,
        ctx.args['agent_id'] as String,
      );
      return {
        'memory': memory == null ? null : agentWorkingMemoryToWire(memory),
      };
    },
  ),
  RepoOp(
    name: 'agent_working_memory.upsert',
    kind: RepoOpKind.mutate,
    requiredArgs: ['memory'],
    handler: (ctx) async {
      final memory = agentWorkingMemoryFromWire(
        (ctx.args['memory'] as Map).cast<String, dynamic>(),
      );
      // The memory's own workspace must match the bound session — a client
      // can't write into a foreign workspace (isolation invariant).
      if (memory.workspaceId != ctx.workspaceId) {
        throw const WorkspaceMismatchException(
          'Agent working memory belongs to a different workspace',
        );
      }
      await agentWorkingMemoryRepository.upsert(memory);
      return {'ok': true};
    },
  ),

  RepoOp(
    name: 'memory_fact.getByWorkspace',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final facts = await memoryFactRepository.getByWorkspace(ctx.workspaceId!);
      return {'facts': facts.map(memoryFactToWire).toList()};
    },
  ),
  RepoOp(
    name: 'memory_fact.getById',
    kind: RepoOpKind.read,
    requiredArgs: ['fact_id'],
    handler: (ctx) async {
      // Scoped by workspace at the repository — a foreign fact is simply not
      // found (ids are global UUIDs, the workspace is the boundary).
      final fact = await memoryFactRepository.getById(
        ctx.workspaceId!,
        ctx.args['fact_id'] as String,
      );
      if (fact == null) {
        throw const NotFoundException('Memory fact not found');
      }
      return {'fact': memoryFactToWire(fact)};
    },
  ),
  RepoOp(
    name: 'memory_fact.getActiveByTopic',
    kind: RepoOpKind.read,
    requiredArgs: ['topic'],
    handler: (ctx) async {
      final facts = await memoryFactRepository.getActiveByTopic(
        ctx.workspaceId!,
        ctx.args['topic'] as String,
      );
      return {'facts': facts.map(memoryFactToWire).toList()};
    },
  ),
  RepoOp(
    name: 'memory_fact.getByAuthor',
    kind: RepoOpKind.read,
    requiredArgs: ['agent_id'],
    handler: (ctx) async {
      final facts = await memoryFactRepository.getByAuthor(
        ctx.workspaceId!,
        ctx.args['agent_id'] as String,
      );
      return {'facts': facts.map(memoryFactToWire).toList()};
    },
  ),
  RepoOp(
    name: 'memory_fact.search',
    kind: RepoOpKind.read,
    requiredArgs: ['query'],
    handler: (ctx) async {
      // FTS5-only over RPC: the thin client cannot ship a query embedding, so
      // hybrid BM25+vector search stays host-internal.
      final facts = await memoryFactRepository.search(
        ctx.workspaceId!,
        ctx.args['query'] as String,
      );
      return {'facts': facts.map(memoryFactToWire).toList()};
    },
  ),
  RepoOp(
    name: 'memory_fact.upsert',
    kind: RepoOpKind.mutate,
    requiredArgs: ['fact'],
    handler: (ctx) async {
      final fact = memoryFactFromWire(
        (ctx.args['fact'] as Map).cast<String, dynamic>(),
      );
      // The fact's own workspace must match the bound session — a client
      // can't write a fact into a foreign workspace (isolation invariant).
      if (fact.workspaceId != ctx.workspaceId) {
        throw const WorkspaceMismatchException(
          'Memory fact belongs to a different workspace',
        );
      }
      await memoryFactRepository.upsert(fact);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'memory_fact.delete',
    kind: RepoOpKind.mutate,
    requiredArgs: ['fact_id'],
    handler: (ctx) async {
      // delete() is itself workspace-scoped — a foreign fact is a no-op there,
      // so passing the bound workspace is the boundary (no ID-only delete).
      await memoryFactRepository.delete(
        ctx.workspaceId!,
        ctx.args['fact_id'] as String,
      );
      return {'ok': true};
    },
  ),

  RepoOp(
    name: 'memory_policy.getByWorkspace',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final policies = await memoryPolicyRepository.getByWorkspace(
        ctx.workspaceId!,
      );
      return {'policies': policies.map(memoryPolicyToWire).toList()};
    },
  ),
  RepoOp(
    name: 'memory_policy.getById',
    kind: RepoOpKind.read,
    requiredArgs: ['id'],
    handler: (ctx) async {
      // Scoped lookup: a policy owned by another workspace is simply not
      // found (ids are global UUIDs; the workspace is the isolation
      // boundary, not id uniqueness).
      final policy = await memoryPolicyRepository.getById(
        ctx.workspaceId!,
        ctx.args['id'] as String,
      );
      if (policy == null) {
        throw const NotFoundException('Memory policy not found');
      }
      return {'policy': memoryPolicyToWire(policy)};
    },
  ),
  RepoOp(
    name: 'memory_policy.getActiveByWorkspace',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final policies = await memoryPolicyRepository.getActiveByWorkspace(
        ctx.workspaceId!,
        domain: ctx.args['domain'] as String?,
      );
      return {'policies': policies.map(memoryPolicyToWire).toList()};
    },
  ),
  RepoOp(
    name: 'memory_policy.upsert',
    kind: RepoOpKind.mutate,
    requiredArgs: ['policy'],
    handler: (ctx) async {
      final policy = memoryPolicyFromWire(
        (ctx.args['policy'] as Map).cast<String, dynamic>(),
      );
      // The policy's own workspace must match the bound session — a client
      // can't write a policy into a foreign workspace (isolation invariant).
      if (policy.workspaceId != ctx.workspaceId) {
        throw const WorkspaceMismatchException(
          'Memory policy belongs to a different workspace',
        );
      }
      await memoryPolicyRepository.upsert(policy);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'memory_policy.delete',
    kind: RepoOpKind.mutate,
    requiredArgs: ['id'],
    handler: (ctx) async {
      // Scoped delete: the repository filters by workspaceId, so one
      // workspace can never delete another's policy.
      await memoryPolicyRepository.delete(
        ctx.workspaceId!,
        ctx.args['id'] as String,
      );
      return {'ok': true};
    },
  ),
];
