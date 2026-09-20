import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/runtime_profile.dart';
import 'package:cc_domain/features/governance/domain/repositories/runtime_profile_repository.dart';
import 'package:cc_mcp/src/tools/runtime_profile_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeProfiles repo;

  setUp(() {
    repo = _FakeProfiles();
  });

  test('create_runtime_profile refuses a missing workspace_id', () async {
    final tool = CreateRuntimeProfileTool(repository: repo);
    final result = await tool.run({'name': 'claude', 'command': 'claude'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('create_runtime_profile upserts a profile', () async {
    final tool = CreateRuntimeProfileTool(repository: repo);
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'name': 'claude',
      'command': 'claude',
      'protocol_family': 'claude',
    });
    expect(result.isError, isFalse);
    expect(repo.stored, isNotNull);
    expect(repo.stored!.name, 'claude');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['name'], 'claude');
  });

  test('list_runtime_profiles returns workspace profiles', () async {
    repo.stored = RuntimeProfile(
      id: 'p1',
      workspaceId: 'ws-1',
      name: 'claude',
      command: 'claude',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final tool = ListRuntimeProfilesTool(repository: repo);
    final result = await tool.run({'workspace_id': 'ws-1'});
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['runtime_profiles'] as List, hasLength(1));
    expect(
      ((body['runtime_profiles'] as List).single as Map)['name'],
      'claude',
    );
  });
}

class _FakeProfiles implements RuntimeProfileRepository {
  RuntimeProfile? stored;

  @override
  Future<void> upsert(RuntimeProfile profile) async {
    stored = profile;
  }

  @override
  Future<List<RuntimeProfile>> listByWorkspace(String workspaceId) async =>
      stored == null ? const [] : [stored!];

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
