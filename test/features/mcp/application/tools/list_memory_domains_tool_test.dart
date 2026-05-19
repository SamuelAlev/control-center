import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_mcp/src/tools/list_memory_domains_tool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

class _FakeMemoryDomainRepository implements MemoryDomainRepository {
  final List<MemoryDomain> _domains = [];

  void seed(List<MemoryDomain> domains) => _domains.addAll(domains);

  @override
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId) async =>
      _domains.where((d) => d.workspaceId == workspaceId).toList();

  @override
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId) =>
      Stream.value(_domains.where((d) => d.workspaceId == workspaceId).toList());

  @override
  Future<MemoryDomain?> findByName(String workspaceId, String name) async =>
      _domains
          .where((d) => d.workspaceId == workspaceId && d.name == name)
          .firstOrNull;

  @override
  Future<void> upsert(MemoryDomain domain) async {
    final idx = _domains.indexWhere((d) => d.id == domain.id);
    if (idx >= 0) {
      _domains[idx] = domain;
    } else {
      _domains.add(domain);
    }
  }
}

void main() {
  group('ListMemoryDomainsTool', () {
    late _FakeMemoryDomainRepository fakeDomainRepo;
    late FakeMemoryFactRepository fakeFactRepo;
    late FakeMemoryPolicyRepository fakePolicyRepo;
    late ListMemoryDomainsTool tool;
    late DateTime now;

    setUp(() {
      now = DateTime(2026, 6, 1);
      fakeDomainRepo = _FakeMemoryDomainRepository();
      fakeFactRepo = FakeMemoryFactRepository();
      fakePolicyRepo = FakeMemoryPolicyRepository();
      tool = ListMemoryDomainsTool(
        domainRepository: fakeDomainRepo,
        factRepository: fakeFactRepo,
        policyRepository: fakePolicyRepo,
      );
    });

    test('name is list_memory_domains', () {
      expect(tool.name, 'list_memory_domains');
    });

    test('returns error for missing workspace_id', () async {
      final result = await tool.run({});
      expect(result.isError, isTrue);
    });

    test('returns empty domain list when no domains exist', () async {
      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('"domains":[]'));
    });

    test('returns domains with fact and policy counts', () async {
      fakeDomainRepo.seed([
        MemoryDomain(
          id: 'd-1',
          workspaceId: 'ws-1',
          name: 'tech-stack',
          label: 'Tech Stack',
          description: 'Technology choices',
          createdAt: now,
          createdByRole: 'ceo',
        ),
        MemoryDomain(
          id: 'd-2',
          workspaceId: 'ws-1',
          name: 'security',
          label: 'Security',
          description: null,
          createdAt: now,
          createdByRole: 'ceo',
        ),
      ]);

      fakeFactRepo.seed([
        MemoryFact(
          id: 'f-1',
          workspaceId: 'ws-1',
          domain: 'tech-stack',
          topic: 'language',
          content: 'Dart/Flutter',
          createdAt: now,
          updatedAt: now,
        ),
        MemoryFact(
          id: 'f-2',
          workspaceId: 'ws-1',
          domain: 'tech-stack',
          topic: 'db',
          content: 'Drift',
          createdAt: now,
          updatedAt: now,
        ),
        MemoryFact(
          id: 'f-3',
          workspaceId: 'ws-1',
          domain: 'tech-stack',
          topic: 'old',
          content: 'Superseded fact',
          supersededBy: 'f-4',
          createdAt: now,
          updatedAt: now,
        ),
        MemoryFact(
          id: 'f-4',
          workspaceId: 'ws-1',
          domain: 'security',
          topic: 'auth',
          content: 'Use OAuth',
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      fakePolicyRepo.seed([
        MemoryPolicy(
          id: 'p-1',
          workspaceId: 'ws-1',
          domain: 'tech-stack',
          rule: 'Use Drift for DB',
          active: true,
          createdAt: now,
          updatedAt: now,
        ),
        MemoryPolicy(
          id: 'p-2',
          workspaceId: 'ws-1',
          domain: 'tech-stack',
          rule: 'Use Riverpod',
          active: true,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      final text = result.content.first.text;

      // tech-stack: 2 active facts (f-1, f-2; f-3 is superseded), 2 policies
      expect(text, contains('"name":"tech-stack"'));
      expect(text, contains('"label":"Tech Stack"'));
      expect(text, contains('"description":"Technology choices"'));
      expect(text, contains('"fact_count":2'));
      expect(text, contains('"policy_count":2'));

      // security: 1 active fact, 0 policies
      expect(text, contains('"name":"security"'));
      expect(text, contains('"fact_count":1'));
      expect(text, contains('"policy_count":0'));
    });

    test('scopes domains by workspace_id', () async {
      fakeDomainRepo.seed([
        MemoryDomain(
          id: 'd-1',
          workspaceId: 'ws-1',
          name: 'ws1-domain',
          label: 'WS1',
          createdAt: now,
          createdByRole: 'ceo',
        ),
        MemoryDomain(
          id: 'd-2',
          workspaceId: 'ws-2',
          name: 'ws2-domain',
          label: 'WS2',
          createdAt: now,
          createdByRole: 'ceo',
        ),
      ]);

      final result = await tool.run({'workspace_id': 'ws-1'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('ws1-domain'));
      expect(result.content.first.text, isNot(contains('ws2-domain')));
    });
  });
}
