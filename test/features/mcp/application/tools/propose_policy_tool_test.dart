import 'dart:convert';

import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/domain/services/memory_access_policy.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';
import 'package:control_center/features/mcp/application/tools/propose_policy_tool.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:control_center/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:control_center/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

// Dummy repos — never called, only satisfy constructor types.
class _D implements MemoryFactRepository {
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class _P implements MemoryPolicyRepository {
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class _G implements MemoryAccessGrantRepository {
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}
class _M implements MemoryDomainRepository {
  @override dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakePromoteFactsToPolicyUseCase extends PromoteFactsToPolicyUseCase {
  _FakePromoteFactsToPolicyUseCase()
      : super(
          factRepository: _D(),
          policyRepository: _P(),
          grantRepository: _G(),
          accessPolicy: const MemoryAccessPolicy(),
        );

  MemoryPolicy? _nextResult;
  String? lastWorkspaceId;
  String? lastDomain;
  String? lastRule;
  List<String>? lastSourceFactIds;
  AgentRole? lastAuthorRole;

  void stub(MemoryPolicy? result) => _nextResult = result;

  @override
  Future<MemoryPolicy?> execute({
    required String workspaceId,
    required String domain,
    required String rule,
    required List<String> sourceFactIds,
    required AgentRole authorRole,
  }) async {
    lastWorkspaceId = workspaceId;
    lastDomain = domain;
    lastRule = rule;
    lastSourceFactIds = sourceFactIds;
    lastAuthorRole = authorRole;
    return _nextResult;
  }
}

class _FakeResolveOrCreateDomainUseCase
    extends ResolveOrCreateDomainUseCase {
  _FakeResolveOrCreateDomainUseCase()
      : super(domainRepository: _M(), grantRepository: _G());

  MemoryDomain? _nextResult;
  String? lastWorkspaceId;
  String? lastDomainInput;
  String? lastDomainLabel;
  String? lastDomainDescription;
  AgentRole? lastAuthorRole;

  void stub(MemoryDomain result) => _nextResult = result;

  @override
  Future<MemoryDomain> execute({
    required String workspaceId,
    required String domainInput,
    String? domainLabel,
    String? domainDescription,
    required AgentRole authorRole,
  }) async {
    lastWorkspaceId = workspaceId;
    lastDomainInput = domainInput;
    lastDomainLabel = domainLabel;
    lastDomainDescription = domainDescription;
    lastAuthorRole = authorRole;
    return _nextResult!;
  }
}

class _ThrowingPromoteUseCase extends PromoteFactsToPolicyUseCase {
  _ThrowingPromoteUseCase()
      : super(
          factRepository: _D(),
          policyRepository: _P(),
          grantRepository: _G(),
          accessPolicy: const MemoryAccessPolicy(),
        );

  @override
  Future<MemoryPolicy?> execute({
    required String workspaceId,
    required String domain,
    required String rule,
    required List<String> sourceFactIds,
    required AgentRole authorRole,
  }) async {
    throw InsufficientMemoryPermission(
      agentRole: authorRole,
      domain: domain,
      required: MemoryPermission.write,
      actual: MemoryPermission.read,
    );
  }
}

MemoryPolicy _makePolicy({String id = 'pol_1', String domain = 'auth-flow'}) {
  final now = DateTime.now();
  return MemoryPolicy(
    id: id,
    workspaceId: 'ws_1',
    domain: domain,
    rule: 'All tokens MUST be rotated.',
    sourceFactIds: const ['fact_a', 'fact_b'],
    active: true,
    createdAt: now,
    updatedAt: now,
  );
}

MemoryDomain _makeDomain({String id = 'dom_1', String name = 'auth-flow'}) {
  return MemoryDomain(
    id: id,
    workspaceId: 'ws_1',
    name: name,
    label: 'Auth Flow',
    description: 'Authentication policies',
    createdAt: DateTime.now(),
    createdByRole: 'coder',
  );
}

void main() {
  late _FakePromoteFactsToPolicyUseCase useCase;
  late _FakeResolveOrCreateDomainUseCase resolveDomainUseCase;
  late ProposePolicyTool tool;

  setUp(() {
    useCase = _FakePromoteFactsToPolicyUseCase();
    resolveDomainUseCase = _FakeResolveOrCreateDomainUseCase();
    tool = ProposePolicyTool(
      useCase: useCase,
      resolveDomainUseCase: resolveDomainUseCase,
    );
  });

  group('ProposePolicyTool', () {
    test('tool metadata', () {
      expect(tool.name, 'propose_policy');
      expect(tool.description, contains('Stores a policy'));
      expect(tool.inputSchema['type'], 'object');
      expect(tool.inputSchema['required'], ['workspace_id', 'domain', 'rule']);
    });

    group('argument validation', () {
      test('rejects missing workspace_id', () async {
        final result = await tool.run({'domain': 'auth', 'rule': 'Do X'});
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Missing workspace_id'));
      });

      test('rejects workspace_id as non-string', () async {
        final result = await tool.run({
          'workspace_id': 123,
          'domain': 'auth',
          'rule': 'Do X',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Missing workspace_id'));
      });

      test('rejects missing domain', () async {
        final result = await tool
            .run({'workspace_id': 'ws_1', 'rule': 'Do X'});
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Missing domain'));
      });

      test('rejects empty domain string', () async {
        final result = await tool.run({
          'workspace_id': 'ws_1',
          'domain': '',
          'rule': 'Do X',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Missing domain'));
      });

      test('rejects domain as non-string', () async {
        final result = await tool.run({
          'workspace_id': 'ws_1',
          'domain': 42,
          'rule': 'Do X',
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Missing domain'));
      });

      test('rejects missing rule', () async {
        final result = await tool
            .run({'workspace_id': 'ws_1', 'domain': 'auth'});
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Missing rule'));
      });

      test('rejects rule as non-string', () async {
        final result = await tool.run({
          'workspace_id': 'ws_1',
          'domain': 'auth',
          'rule': 123,
        });
        expect(result.isError, isTrue);
        expect(result.content.first.text, contains('Missing rule'));
      });
    });

    group('success', () {
      test('resolves domain, promotes policy, returns JSON', () async {
        final domain = _makeDomain(name: 'auth-flow');
        final policy = _makePolicy(id: 'pol_abc', domain: 'auth-flow');
        resolveDomainUseCase.stub(domain);
        useCase.stub(policy);

        final result = await tool.run({
          'workspace_id': 'ws_1',
          'domain': 'auth-flow',
          'rule': 'All tokens MUST be rotated.',
          'source_fact_ids': ['fact_a', 'fact_b'],
          'agent_role': 'coder',
        });

        expect(result.isError, isFalse);
        final parsed = jsonDecode(result.content.first.text) as Map<String, dynamic>;
        expect(parsed['policy_id'], 'pol_abc');
        expect(parsed['domain'], 'auth-flow');
        expect(parsed['status'], 'created');
      });

      test('passes all fields to resolve domain use case', () async {
        final domain = _makeDomain();
        final policy = _makePolicy();
        resolveDomainUseCase.stub(domain);
        useCase.stub(policy);

        await tool.run({
          'workspace_id': 'ws_1',
          'domain': 'auth-flow',
          'domain_label': 'Auth Rules',
          'domain_description': 'All auth policies',
          'rule': 'All tokens MUST be rotated.',
          'agent_role': 'CEO',
        });

        expect(resolveDomainUseCase.lastWorkspaceId, 'ws_1');
        expect(resolveDomainUseCase.lastDomainInput, 'auth-flow');
        expect(resolveDomainUseCase.lastDomainLabel, 'Auth Rules');
        expect(resolveDomainUseCase.lastDomainDescription, 'All auth policies');
        expect(resolveDomainUseCase.lastAuthorRole, AgentRole.ceo);
      });

      test('passes all fields to promote use case', () async {
        final domain = _makeDomain();
        final policy = _makePolicy();
        resolveDomainUseCase.stub(domain);
        useCase.stub(policy);

        await tool.run({
          'workspace_id': 'ws_1',
          'domain': 'auth-flow',
          'rule': 'All tokens MUST be rotated.',
          'source_fact_ids': ['fact_a'],
          'agent_role': 'reviewer',
        });

        expect(useCase.lastWorkspaceId, 'ws_1');
        expect(useCase.lastDomain, domain.name);
        expect(useCase.lastRule, 'All tokens MUST be rotated.');
        expect(useCase.lastSourceFactIds, ['fact_a']);
        expect(useCase.lastAuthorRole, AgentRole.reviewer);
      });

      test('defaults agent_role to general when absent', () async {
        final domain = _makeDomain();
        final policy = _makePolicy();
        resolveDomainUseCase.stub(domain);
        useCase.stub(policy);

        await tool.run({
          'workspace_id': 'ws_1',
          'domain': 'auth-flow',
          'rule': 'All tokens MUST be rotated.',
        });

        expect(resolveDomainUseCase.lastAuthorRole, AgentRole.general);
        expect(useCase.lastAuthorRole, AgentRole.general);
      });

      test('defaults agent_role to general when unrecognized', () async {
        final domain = _makeDomain();
        final policy = _makePolicy();
        resolveDomainUseCase.stub(domain);
        useCase.stub(policy);

        await tool.run({
          'workspace_id': 'ws_1',
          'domain': 'auth-flow',
          'rule': 'All tokens MUST be rotated.',
          'agent_role': 'nonexistent_role',
        });

        expect(resolveDomainUseCase.lastAuthorRole, AgentRole.general);
        expect(useCase.lastAuthorRole, AgentRole.general);
      });

      test('defaults source_fact_ids to empty list when absent', () async {
        final domain = _makeDomain();
        final policy = _makePolicy();
        resolveDomainUseCase.stub(domain);
        useCase.stub(policy);

        await tool.run({
          'workspace_id': 'ws_1',
          'domain': 'auth-flow',
          'rule': 'All tokens MUST be rotated.',
        });

        expect(useCase.lastSourceFactIds, isEmpty);
      });
    });

    group('errors', () {
      test('returns error when promote returns null', () async {
        final domain = _makeDomain();
        resolveDomainUseCase.stub(domain);
        useCase.stub(null);

        final result = await tool.run({
          'workspace_id': 'ws_1',
          'domain': 'auth-flow',
          'rule': 'All tokens MUST be rotated.',
        });

        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('Failed to create policy'),
        );
      });

      test('returns error on InsufficientMemoryPermission', () async {
        final domain = _makeDomain(name: 'secret-domain');
        resolveDomainUseCase.stub(domain);
        final throwingUseCase = _ThrowingPromoteUseCase();
        final tool2 = ProposePolicyTool(
          useCase: throwingUseCase,
          resolveDomainUseCase: resolveDomainUseCase,
        );

        final result = await tool2.run({
          'workspace_id': 'ws_1',
          'domain': 'secret-domain',
          'rule': 'Never expose secrets.',
          'agent_role': 'general',
        });

        expect(result.isError, isTrue);
        expect(
          result.content.first.text,
          contains('InsufficientMemoryPermission'),
        );
        expect(result.content.first.text, contains('general'));
        expect(result.content.first.text, contains('secret-domain'));
      });
    });
  });
}
