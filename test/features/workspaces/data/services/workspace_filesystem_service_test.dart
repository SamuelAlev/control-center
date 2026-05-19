import 'dart:io';

import 'package:control_center/features/workspaces/data/services/workspace_filesystem_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

class _TestableService extends WorkspaceFilesystemService {
  _TestableService(this.baseDir);

  final Directory baseDir;

  @override
  Future<Directory> workspaceDir(String workspaceId) async {
    return Directory(p.join(baseDir.path, workspaceId));
  }
}

void main() {
  late Directory tempDir;
  late _TestableService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('wsfs_test_');
    service = _TestableService(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('slugify', () {
    test('converts to lowercase and replaces spaces with hyphens', () {
      expect(slugify('Hello World'), 'hello-world');
    });

    test('removes special characters', () {
      expect(slugify('Agent@2024!'), 'agent-2024');
    });

    test('collapses multiple hyphens', () {
      expect(slugify('hello   world---test'), 'hello-world-test');
    });

    test('trims leading and trailing hyphens', () {
      expect(slugify('-hello-world-'), 'hello-world');
    });

    test('handles mixed case and symbols', () {
      expect(slugify('My Agent (v2)'), 'my-agent-v2');
    });

    test('handles only special characters', () {
      expect(slugify('!!!'), '');
    });
  });

  group('workspaceDir', () {
    test('returns directory for workspace id', () async {
      final dir = await service.workspaceDir('ws-1');
      expect(dir.path, p.join(tempDir.path, 'ws-1'));
    });
  });

  group('skillsDir', () {
    test('returns skills subdirectory', () async {
      final dir = await service.skillsDir('ws-1');
      expect(dir.path, p.join(tempDir.path, 'ws-1', 'skills'));
    });
  });

  group('skillDir', () {
    test('returns skill subdirectory', () async {
      final dir = await service.skillDir('ws-1', 'dart-dev');
      expect(dir.path, p.join(tempDir.path, 'ws-1', 'skills', 'dart-dev'));
    });
  });

  group('skillFilePath', () {
    test('returns SKILL.md path in skill directory', () async {
      final path = await service.skillFilePath('ws-1', 'dart-dev');
      expect(path, p.join(tempDir.path, 'ws-1', 'skills', 'dart-dev', 'SKILL.md'));
    });
  });

  group('agentsDir', () {
    test('returns agents subdirectory', () async {
      final dir = await service.agentsDir('ws-1');
      expect(dir.path, p.join(tempDir.path, 'ws-1', 'agents'));
    });
  });

  group('agentDir', () {
    test('returns agent subdirectory', () async {
      final dir = await service.agentDir('ws-1', 'ceo');
      expect(dir.path, p.join(tempDir.path, 'ws-1', 'agents', 'ceo'));
    });
  });

  group('agentFilePath', () {
    test('returns AGENTS.md path in agent directory', () async {
      final path = await service.agentFilePath('ws-1', 'ceo');
      expect(path, p.join(tempDir.path, 'ws-1', 'agents', 'ceo', 'AGENTS.md'));
    });
  });

  group('agentSkillsLinkDir', () {
    test('returns .agents/skills link directory', () async {
      final dir = await service.agentSkillsLinkDir('ws-1', 'ceo');
      expect(
        dir.path,
        p.join(tempDir.path, 'ws-1', 'agents', 'ceo', '.agents', 'skills'),
      );
    });
  });

  group('ensureWorkspaceDirs', () {
    test('creates workspace, skills, and agents directories', () async {
      await service.ensureWorkspaceDirs('ws-new');

      final wsDir = Directory(p.join(tempDir.path, 'ws-new'));
      final skillsDir = Directory(p.join(tempDir.path, 'ws-new', 'skills'));
      final agentsDir = Directory(p.join(tempDir.path, 'ws-new', 'agents'));

      expect(wsDir.existsSync(), isTrue);
      expect(skillsDir.existsSync(), isTrue);
      expect(agentsDir.existsSync(), isTrue);
    });

    test('does not throw when directories already exist', () async {
      await service.ensureWorkspaceDirs('ws-dup');
      await service.ensureWorkspaceDirs('ws-dup');
    });
  });

  group('ensureAgentDir', () {
    test('creates agent directory', () async {
      await service.ensureAgentDir('ws-1', 'developer');

      final dir = Directory(p.join(tempDir.path, 'ws-1', 'agents', 'developer'));
      expect(dir.existsSync(), isTrue);
    });

    test('does not throw when agent directory already exists', () async {
      await service.ensureAgentDir('ws-1', 'existing');
      await service.ensureAgentDir('ws-1', 'existing');
    });
  });

  group('writeAgentFile', () {
    test('creates agent dir and writes AGENTS.md', () async {
      await service.writeAgentFile('ws-1', 'ceo', '# CEO Agent\nInstructions here.');

      final file = File(
        p.join(tempDir.path, 'ws-1', 'agents', 'ceo', 'AGENTS.md'),
      );
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), '# CEO Agent\nInstructions here.');
    });
  });

  group('deleteAgentDir', () {
    test('deletes agent directory recursively', () async {
      await service.writeAgentFile('ws-1', 'temp-agent', 'content');
      final dir = Directory(p.join(tempDir.path, 'ws-1', 'agents', 'temp-agent'));
      expect(dir.existsSync(), isTrue);

      await service.deleteAgentDir('ws-1', 'temp-agent');

      expect(dir.existsSync(), isFalse);
    });

    test('does not throw when directory does not exist', () async {
      await service.deleteAgentDir('ws-1', 'nonexistent');
    });
  });

  group('listAgentSlugs', () {
    test('returns empty list when agents dir does not exist', () async {
      final slugs = await service.listAgentSlugs('ws-empty');
      expect(slugs, isEmpty);
    });

    test('returns list of agent directory names', () async {
      await service.writeAgentFile('ws-1', 'ceo', 'content');
      await service.writeAgentFile('ws-1', 'developer', 'content');

      final slugs = await service.listAgentSlugs('ws-1');

      expect(slugs, containsAll(['ceo', 'developer']));
      expect(slugs.length, 2);
    });
  });

  group('writeSkillFile', () {
    test('creates skill dir and writes SKILL.md', () async {
      await service.writeSkillFile('ws-1', 'dart', '# Dart Skill');

      final file = File(
        p.join(tempDir.path, 'ws-1', 'skills', 'dart', 'SKILL.md'),
      );
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), '# Dart Skill');
    });
  });

  group('readSkillFile', () {
    test('returns File when skill file exists', () async {
      await service.writeSkillFile('ws-1', 'dart', '# Dart');

      final file = await service.readSkillFile('ws-1', 'dart');

      expect(file, isNotNull);
      expect(file!.existsSync(), isTrue);
    });

    test('returns null when skill file does not exist', () async {
      final file = await service.readSkillFile('ws-1', 'nonexistent');

      expect(file, isNull);
    });
  });

  group('deleteSkillDir', () {
    test('deletes skill directory recursively', () async {
      await service.writeSkillFile('ws-1', 'temp-skill', 'content');
      final dir = Directory(p.join(tempDir.path, 'ws-1', 'skills', 'temp-skill'));
      expect(dir.existsSync(), isTrue);

      await service.deleteSkillDir('ws-1', 'temp-skill');

      expect(dir.existsSync(), isFalse);
    });

    test('does not throw when directory does not exist', () async {
      await service.deleteSkillDir('ws-1', 'nonexistent');
    });
  });

  group('listSkillSlugs', () {
    test('returns empty list when skills dir does not exist', () async {
      final slugs = await service.listSkillSlugs('ws-empty');
      expect(slugs, isEmpty);
    });

    test('returns only directories containing SKILL.md', () async {
      await service.writeSkillFile('ws-1', 'dart', 'content');
      await service.writeSkillFile('ws-1', 'flutter', 'content');

      final slugs = await service.listSkillSlugs('ws-1');

      expect(slugs, containsAll(['dart', 'flutter']));
      expect(slugs.length, 2);
    });

    test('excludes directories without SKILL.md', () async {
      await service.writeSkillFile('ws-1', 'dart', 'content');
      final emptyDir = Directory(p.join(tempDir.path, 'ws-1', 'skills', 'empty'));
      await emptyDir.create(recursive: true);

      final slugs = await service.listSkillSlugs('ws-1');

      expect(slugs, contains('dart'));
      expect(slugs, isNot(contains('empty')));
    });
  });

  group('syncAgentSkillLinks', () {
    test('creates symlinks for requested skills', () async {
      await service.writeSkillFile('ws-1', 'dart', 'content');
      await service.writeSkillFile('ws-1', 'flutter', 'content');

      await service.syncAgentSkillLinks('ws-1', 'ceo', ['dart', 'flutter']);

      final linksDir = Directory(
        p.join(tempDir.path, 'ws-1', 'agents', 'ceo', '.agents', 'skills'),
      );
      expect(linksDir.existsSync(), isTrue);

      final entries = linksDir.listSync();
      expect(entries.length, greaterThanOrEqualTo(2));
    });

    test('removes orphaned symlinks', () async {
      await service.writeSkillFile('ws-1', 'dart', 'content');
      await service.writeSkillFile('ws-1', 'flutter', 'content');

      await service.syncAgentSkillLinks('ws-1', 'ceo', ['dart', 'flutter']);
      await service.syncAgentSkillLinks('ws-1', 'ceo', ['dart']);

      final linksDir = Directory(
        p.join(tempDir.path, 'ws-1', 'agents', 'ceo', '.agents', 'skills'),
      );
      expect(linksDir.existsSync(), isTrue);

      final dartLink = Link(p.join(linksDir.path, 'dart'));
      expect(dartLink.existsSync(), isTrue);
    });
  });
}
