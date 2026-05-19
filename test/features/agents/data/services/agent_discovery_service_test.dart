import 'dart:io';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/features/agents/data/services/agent_discovery_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake of the filesystem port: only the two methods discovery uses
/// are implemented; everything else is irrelevant to this test.
class _FakeFs implements WorkspaceFilesystemPort {
  _FakeFs(this.slugToPath);

  final Map<String, String> slugToPath;

  @override
  Future<List<String>> listAgentSlugs(String workspaceId) async =>
      slugToPath.keys.toList();

  @override
  Future<String> agentFilePath(String workspaceId, String agentSlug) async =>
      slugToPath[agentSlug]!;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('agent_discovery_test');
  });

  tearDown(() {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  String writeAgent(String slug, String body) {
    final dir = Directory('${tmp.path}/$slug')..createSync(recursive: true);
    final file = File('${dir.path}/AGENTS.md')..writeAsStringSync(body);
    return file.path;
  }

  test('returns only agents whose name is not already registered', () async {
    final architect = writeAgent('architect', '''
---
name: architect
title: Software architect
skills:
  - architecture
  - design
---
The architect.
''');
    final engineer = writeAgent('engineer', '''
---
name: engineer
title: Engineer
reportsTo: architect
---
Builds things.
''');

    final fs = _FakeFs({'architect': architect, 'engineer': engineer});
    final service = AgentDiscoveryService(filesystem: fs);

    // "architect" already exists in the workspace → only "engineer" is new.
    final found = await service.findImportable(
      workspaceId: 'ws-1',
      existingNamesLower: {'architect'},
    );

    expect(found, hasLength(1));
    expect(found.single.name, 'engineer');
    expect(found.single.title, 'Engineer');
    expect(found.single.reportsTo, 'architect');
  });

  test('skips malformed files and de-duplicates by name', () async {
    final good = writeAgent('good', '''
---
name: good
title: Good agent
---
ok
''');
    final broken = writeAgent('broken', 'no frontmatter here');

    final fs = _FakeFs({'good': good, 'broken': broken});
    final service = AgentDiscoveryService(filesystem: fs);

    final found = await service.findImportable(
      workspaceId: 'ws-1',
      existingNamesLower: const {},
    );

    expect(found.map((a) => a.name), ['good']);
  });

  test('carries skills and persona through to the result', () async {
    final path = writeAgent('qa', '''
---
name: qa
title: Quality
skills:
  - testing
---
I test everything.
''');
    final fs = _FakeFs({'qa': path});
    final service = AgentDiscoveryService(filesystem: fs);

    final found = await service.findImportable(
      workspaceId: 'ws-1',
      existingNamesLower: const {},
    );

    expect(found.single.skills, ['testing']);
    expect(found.single.persona, 'I test everything.');
  });
}
