import 'dart:async';
import 'dart:convert';

import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/mcp/application/tools/list_pull_requests_tool.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_generation.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePrLifecycleRepository implements PrLifecycleRepository {
  final Map<String, List<PrGeneration>> _byWorkspace = {};

  void setPrsForWorkspace(String workspaceId, List<PrGeneration> prs) {
    _byWorkspace[workspaceId] = prs;
  }

  @override
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId) {
    return Stream.value(_byWorkspace[workspaceId] ?? []);
  }

  @override
  Future<PrGeneration?> getById(String id) async => null;

  @override
  Future<String> createDraft({
    required String workspaceId,
    required String title,
    required String body,
    String? diffSummary,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateDraft(
    String prId, {
    String? title,
    String? body,
    String? status,
    int? githubPrNumber,
    String? githubPrUrl,
  }) async {}

  @override
  Future<Map<String, dynamic>> createOnGitHub({
    required String prId,
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
    List<String> assignees = const [],
    List<String> reviewerUsers = const [],
    List<String> reviewerTeams = const [],
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) async {}
}

class _FakeWorkspaceRepository implements WorkspaceRepository {
  final List<Workspace> _workspaces = [];
  final _controller = StreamController<List<Workspace>>.broadcast();

  void addWorkspace(Workspace w) {
    _workspaces.add(w);
    _controller.add(List.unmodifiable(_workspaces));
  }

  @override
  Stream<List<Workspace>> watchAll() {
    scheduleMicrotask(() => _controller.add(List.unmodifiable(_workspaces)));
    return _controller.stream;
  }

  @override
  Future<String> upsert(Workspace workspace) async => workspace.id;

  @override
  Future<void> delete(String id) async {}

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) {
    return Stream.value(const []);
  }

  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {}

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async =>
      false;

  @override
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId) async {}

  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {}

  void dispose() => _controller.close();
}

PrGeneration _pr({
  String id = 'pr-1',
  String workspaceId = 'ws-1',
  PrGenerationStatus status = const Draft(),
  String title = 'Test PR',
}) {
  return PrGeneration(
    id: id,
    workspaceId: workspaceId,
    status: status,
    title: title,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Workspace _workspace({String id = 'ws-1', String name = 'WS 1'}) {
  return Workspace(
    id: id,
    name: name,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('ListPullRequestsTool', () {
    late _FakePrLifecycleRepository prRepo;
    late _FakeWorkspaceRepository workspaceRepo;
    late ListPullRequestsTool tool;

    setUp(() {
      prRepo = _FakePrLifecycleRepository();
      workspaceRepo = _FakeWorkspaceRepository();
      tool = ListPullRequestsTool(
        prRepo: prRepo,
        workspaceRepo: workspaceRepo,
      );
    });

    test('has correct name', () {
      expect(tool.name, 'list_pull_requests');
    });

    test('has non-empty description', () {
      expect(tool.description, isNotEmpty);
    });

    test('has valid inputSchema', () {
      final schema = tool.inputSchema;
      expect(schema['type'], 'object');
      expect(((schema['properties'] as Map<String, dynamic>)['workspace_id'] as Map<String, dynamic>)['type'], 'string');
      expect(((schema['properties'] as Map<String, dynamic>)['status'] as Map<String, dynamic>)['type'], 'string');
    });

    test('returns empty list for workspace with no PRs', () async {
      prRepo.setPrsForWorkspace('ws-1', []);

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['pull_requests'], isEmpty);
      expect(data['count'], 0);
    });

    test('returns PRs for specific workspace', () async {
      prRepo.setPrsForWorkspace('ws-1', [
        _pr(id: 'pr-1', title: 'Feature A'),
        _pr(id: 'pr-2', title: 'Feature B'),
      ]);

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 2);
      expect(((data['pull_requests'] as List<dynamic>)[0] as Map<String, dynamic>)['title'], 'Feature A');
      expect(((data['pull_requests'] as List<dynamic>)[1] as Map<String, dynamic>)['title'], 'Feature B');
    });

    test('includes PR fields in response', () async {
      prRepo.setPrsForWorkspace('ws-1', [
        _pr(id: 'pr-1', workspaceId: 'ws-1', title: 'My PR'),
      ]);

      final result = await tool.call({'workspace_id': 'ws-1'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      final pr = (data['pull_requests'] as List<dynamic>)[0] as Map<String, dynamic>;
      expect(pr['id'], 'pr-1');
      expect(pr['workspace_id'], 'ws-1');
      expect(pr['title'], 'My PR');
      expect(pr['status'], 'draft');
      expect(pr['created_at'], contains('2026-01-01'));
    });

    test('filters PRs by status', () async {
      prRepo.setPrsForWorkspace('ws-1', [
        _pr(id: 'pr-1', status: const Draft(), title: 'Draft PR'),
        _pr(id: 'pr-2', status: const Created(), title: 'Created PR'),
      ]);

      final result = await tool.call({
        'workspace_id': 'ws-1',
        'status': 'created',
      });

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(((data['pull_requests'] as List<dynamic>)[0] as Map<String, dynamic>)['title'], 'Created PR');
    });

    test('scans all workspaces when no workspace_id', () async {
      workspaceRepo.addWorkspace(_workspace(id: 'ws-1'));
      workspaceRepo.addWorkspace(_workspace(id: 'ws-2'));
      prRepo.setPrsForWorkspace('ws-1', [
        _pr(id: 'pr-1', workspaceId: 'ws-1', title: 'WS1 PR'),
      ]);
      prRepo.setPrsForWorkspace('ws-2', [
        _pr(id: 'pr-2', workspaceId: 'ws-2', title: 'WS2 PR'),
      ]);

      final result = await tool.call({});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 2);
    });

    test('filters by status across all workspaces', () async {
      workspaceRepo.addWorkspace(_workspace(id: 'ws-1'));
      workspaceRepo.addWorkspace(_workspace(id: 'ws-2'));
      prRepo.setPrsForWorkspace('ws-1', [
        _pr(id: 'pr-1', workspaceId: 'ws-1', status: const Draft()),
      ]);
      prRepo.setPrsForWorkspace('ws-2', [
        _pr(id: 'pr-2', workspaceId: 'ws-2', status: const Published()),
      ]);

      final result = await tool.call({'status': 'published'});

      final data = jsonDecode(result.content.first.text) as Map<String, dynamic>;
      expect(data['count'], 1);
      expect(((data['pull_requests'] as List<dynamic>)[0] as Map<String, dynamic>)['id'], 'pr-2');
    });
  });
}
