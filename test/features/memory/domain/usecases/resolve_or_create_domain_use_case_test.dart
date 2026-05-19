import 'dart:async';

import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:control_center/features/memory/domain/usecases/resolve_or_create_domain_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMemoryDomainRepository implements MemoryDomainRepository {
  final List<MemoryDomain> _domains = [];

  void seed(List<MemoryDomain> domains) => _domains.addAll(domains);

  @override
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId) async* {
    yield _domains.where((d) => d.workspaceId == workspaceId).toList();
  }

  @override
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId) async =>
      _domains.where((d) => d.workspaceId == workspaceId).toList();

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

class _FakeMemoryAccessGrantRepository implements MemoryAccessGrantRepository {
  final List<MemoryAccessGrant> _grants = [];

  List<MemoryAccessGrant> get grants => List.unmodifiable(_grants);

  @override
  Future<List<MemoryAccessGrant>> getByWorkspace(String workspaceId) async =>
      _grants.where((g) => g.workspaceId == workspaceId).toList();

  @override
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String workspaceId) async* {
    yield _grants.where((g) => g.workspaceId == workspaceId).toList();
  }

  @override
  Future<void> upsert(MemoryAccessGrant grant) async {
    final idx = _grants.indexWhere(
      (g) => g.workspaceId == grant.workspaceId &&
          g.agentRole == grant.agentRole &&
          g.memoryDomain == grant.memoryDomain,
    );
    if (idx >= 0) {
      _grants[idx] = grant;
    } else {
      _grants.add(grant);
    }
  }

  @override
  Future<void> upsertAll(List<MemoryAccessGrant> grants) async {
    for (final g in grants) {
      await upsert(g);
    }
  }
}

void main() {
  group('ResolveOrCreateDomainUseCase', () {
    late _FakeMemoryDomainRepository domainRepo;
    late _FakeMemoryAccessGrantRepository grantRepo;
    late ResolveOrCreateDomainUseCase useCase;

    setUp(() {
      domainRepo = _FakeMemoryDomainRepository();
      grantRepo = _FakeMemoryAccessGrantRepository();
      useCase = ResolveOrCreateDomainUseCase(
        domainRepository: domainRepo,
        grantRepository: grantRepo,
      );
    });

    test('returns existing domain when slug matches', timeout: const Timeout.factor(2), () async {
      final existing = MemoryDomain(
        id: 'd1',
        workspaceId: 'ws1',
        name: 'codebase',
        label: 'Codebase',
        createdAt: DateTime(2025),
        createdByRole: 'coder',
      );
      domainRepo.seed([existing]);

      final result = await useCase.execute(
        workspaceId: 'ws1',
        domainInput: 'codebase',
        authorRole: AgentRole.coder,
      );

      expect(result.id, 'd1');
      expect(result.name, 'codebase');
    });

    test('returns existing domain regardless of input casing', timeout: const Timeout.factor(2), () async {
      final existing = MemoryDomain(
        id: 'd1',
        workspaceId: 'ws1',
        name: 'codebase',
        label: 'Codebase',
        createdAt: DateTime(2025),
        createdByRole: 'coder',
      );
      domainRepo.seed([existing]);

      final result = await useCase.execute(
        workspaceId: 'ws1',
        domainInput: 'CODEBASE',
        authorRole: AgentRole.coder,
      );

      expect(result.id, 'd1');
    });

    test('creates new domain when none exists', timeout: const Timeout.factor(2), () async {
      final result = await useCase.execute(
        workspaceId: 'ws1',
        domainInput: 'Preferences',
        domainLabel: 'User Preferences',
        domainDescription: 'User preference settings',
        authorRole: AgentRole.coder,
      );

      expect(result.workspaceId, 'ws1');
      expect(result.name, 'preferences');
      expect(result.label, 'User Preferences');
      expect(result.description, 'User preference settings');
      expect(result.createdByRole, 'coder');
    });

    test('slugifies domain input for name', timeout: const Timeout.factor(2), () async {
      final result = await useCase.execute(
        workspaceId: 'ws1',
        domainInput: '  My Custom Domain!  ',
        authorRole: AgentRole.coder,
      );

      expect(result.name, 'my-custom-domain');
    });

    test('uses domain input as label when no label provided', timeout: const Timeout.factor(2), () async {
      final result = await useCase.execute(
        workspaceId: 'ws1',
        domainInput: 'My Domain',
        authorRole: AgentRole.coder,
      );

      expect(result.label, 'My Domain');
    });

    test('persists new domain to repository', timeout: const Timeout.factor(2), () async {
      await useCase.execute(
        workspaceId: 'ws1',
        domainInput: 'test-domain',
        authorRole: AgentRole.coder,
      );

      final found = await domainRepo.findByName('ws1', 'test-domain');
      expect(found, isNotNull);
      expect(found!.name, 'test-domain');
    });

    test('seeds access grants for all roles on creation', timeout: const Timeout.factor(2), () async {
      await useCase.execute(
        workspaceId: 'ws1',
        domainInput: 'new-domain',
        authorRole: AgentRole.coder,
      );

      final grants = grantRepo.grants;
      // One grant per AgentRole value
      expect(grants.length, AgentRole.values.length);

      final coderGrant = grants.firstWhere(
        (g) => g.agentRole == AgentRole.coder,
      );
      expect(coderGrant.permission, MemoryPermission.write);
      expect(coderGrant.memoryDomain, 'new-domain');

      // All other roles get read
      for (final role in AgentRole.values) {
        if (role == AgentRole.coder) {
          continue;
        }
        final grant = grants.firstWhere((g) => g.agentRole == role);
        expect(grant.permission, MemoryPermission.read);
      }
    });

    test('does not seed grants when domain already exists', timeout: const Timeout.factor(2), () async {
      domainRepo.seed([
        MemoryDomain(
          id: 'd1',
          workspaceId: 'ws1',
          name: 'existing',
          label: 'Existing',
          createdAt: DateTime(2025),
          createdByRole: 'coder',
        ),
      ]);

      await useCase.execute(
        workspaceId: 'ws1',
        domainInput: 'existing',
        authorRole: AgentRole.coder,
      );

      expect(grantRepo.grants, isEmpty);
    });

    group('_slugify', () {
      test('lowercases input', timeout: const Timeout.factor(2), () async {
        final result = await useCase.execute(
          workspaceId: 'ws1',
          domainInput: 'CODEBASE',
          authorRole: AgentRole.coder,
        );
        expect(result.name, 'codebase');
      });

      test('replaces spaces with hyphens', timeout: const Timeout.factor(2), () async {
        final result = await useCase.execute(
          workspaceId: 'ws1',
          domainInput: 'my code domain',
          authorRole: AgentRole.coder,
        );
        expect(result.name, 'my-code-domain');
      });

      test('removes underscores from input', timeout: const Timeout.factor(2), () async {
        final result = await useCase.execute(
          workspaceId: 'ws1',
          domainInput: 'my_code_domain',
          authorRole: AgentRole.coder,
        );
        // Underscores are removed in the first sanitization step before
        // the whitespace-to-hyphen step runs.
        expect(result.name, 'mycodedomain');
      });

      test('removes special characters', timeout: const Timeout.factor(2), () async {
        final result = await useCase.execute(
          workspaceId: 'ws1',
          domainInput: 'domain@#\$!',
          authorRole: AgentRole.coder,
        );
        expect(result.name, 'domain');
      });

      test('collapses multiple hyphens', timeout: const Timeout.factor(2), () async {
        final result = await useCase.execute(
          workspaceId: 'ws1',
          domainInput: 'a---b',
          authorRole: AgentRole.coder,
        );
        expect(result.name, 'a-b');
      });

      test('strips leading and trailing hyphens', timeout: const Timeout.factor(2), () async {
        final result = await useCase.execute(
          workspaceId: 'ws1',
          domainInput: ' -hello- ',
          authorRole: AgentRole.coder,
        );
        expect(result.name, 'hello');
      });

      test('handles already-slugified input', timeout: const Timeout.factor(2), () async {
        final result = await useCase.execute(
          workspaceId: 'ws1',
          domainInput: 'my-code-base',
          authorRole: AgentRole.coder,
        );
        expect(result.name, 'my-code-base');
      });
    });
  });
}
