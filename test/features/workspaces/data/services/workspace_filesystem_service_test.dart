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

  group('conversationsDir', () {
    test('returns conversations subdirectory', () async {
      final dir = await service.conversationsDir('ws-1');
      expect(dir.path, p.join(tempDir.path, 'ws-1', 'conversations'));
    });
  });

  group('conversationDir', () {
    test('returns conversation subdirectory for id', () async {
      final dir = await service.conversationDir('ws-1', 'conv-42');
      expect(
        dir.path,
        p.join(tempDir.path, 'ws-1', 'conversations', 'conv-42'),
      );
    });
  });

  group('ensureConversationDir', () {
    test('creates conversation directory on first call', () async {
      final dir = await service.ensureConversationDir('ws-1', 'conv-1');
      expect(dir.existsSync(), isTrue);
      expect(
        dir.path,
        p.join(tempDir.path, 'ws-1', 'conversations', 'conv-1'),
      );
    });

    test('does not throw on repeated calls', () async {
      await service.ensureConversationDir('ws-1', 'conv-1');
      await service.ensureConversationDir('ws-1', 'conv-1');
    });
  });

  group('ensureMcpSymlink', () {
    test('creates .mcp.json symlink in agent dir', () async {
      await service.ensureMcpSymlink('ws-1', 'agent-a');

      final linkPath = p.join(
        tempDir.path, 'ws-1', 'agents', 'agent-a', '.mcp.json',
      );
      final link = Link(linkPath);
      expect(link.existsSync(), isTrue);
      final target = await link.target();
      expect(target, p.join(tempDir.path, 'mcp.json'));
      // Verify target file was created with default content
      final targetFile = File(p.join(tempDir.path, 'mcp.json'));
      expect(targetFile.existsSync(), isTrue);
      expect(
        targetFile.readAsStringSync(),
        contains('"control-center"'),
      );
    });

    test('silently no-ops when same symlink already exists', () async {
      await service.ensureMcpSymlink('ws-1', 'agent-a');
      await service.ensureMcpSymlink('ws-1', 'agent-a');
      // Should not throw
    });

    test('replaces symlink when target differs', () async {
      await service.ensureMcpSymlink('ws-1', 'agent-a');

      // Manually alter the symlink to point somewhere else
      final linkPath = p.join(
        tempDir.path, 'ws-1', 'agents', 'agent-a', '.mcp.json',
      );
      await Link(linkPath).delete();
      await Link(linkPath).create('/tmp/fake-mcp.json');

      // Re-run — should replace with correct target
      await service.ensureMcpSymlink('ws-1', 'agent-a');

      final target = await Link(linkPath).target();
      expect(target, p.join(tempDir.path, 'mcp.json'));
    });

    test('replaces regular file at link path with symlink', () async {
      // Create agent dir manually
      final agentDir = Directory(p.join(
        tempDir.path, 'ws-1', 'agents', 'agent-b',
      ));
      await agentDir.create(recursive: true);
      final filePath = p.join(agentDir.path, '.mcp.json');
      await File(filePath).writeAsString('not a link');

      await service.ensureMcpSymlink('ws-1', 'agent-b');

      final type = FileSystemEntity.typeSync(filePath, followLinks: false);
      expect(type, FileSystemEntityType.link);
    });

    test('bails out without modifying when a directory sits at link path', () async {
      // Create agent dir manually
      final agentDir = Directory(p.join(
        tempDir.path, 'ws-1', 'agents', 'agent-c',
      ));
      await agentDir.create(recursive: true);
      final dirPath = p.join(agentDir.path, '.mcp.json');
      await Directory(dirPath).create();

      // Should not throw and should not replace the directory
      await service.ensureMcpSymlink('ws-1', 'agent-c');

      final type = FileSystemEntity.typeSync(dirPath, followLinks: false);
      expect(type, FileSystemEntityType.directory);
    });
  });

  group('ensureAgentDir - symlink side-effect', () {
    test('creates .mcp.json symlink alongside agent dir', () async {
      await service.ensureAgentDir('ws-1', 'dev');

      final linkPath = p.join(
        tempDir.path, 'ws-1', 'agents', 'dev', '.mcp.json',
      );
      expect(Link(linkPath).existsSync(), isTrue);
    });
  });

  group('prCloneDir', () {
    test('returns pr_clones subdirectory for owner/repo', () async {
      final dir = await service.prCloneDir('ws-1', 'acme', 'project');
      expect(
        dir.path,
        p.join(tempDir.path, 'ws-1', 'pr_clones', 'acme__project'),
      );
    });

    test('sanitizes special characters in owner', () async {
      final dir = await service.prCloneDir('ws-1', 'evil/../owner', 'repo');
      expect(
        dir.path,
        p.join(tempDir.path, 'ws-1', 'pr_clones', 'evil_.._owner__repo'),
      );
    });

    test('sanitizes special characters in repo', () async {
      final dir = await service.prCloneDir('ws-1', 'owner', 'repo;rm -rf');
      expect(
        dir.path,
        p.join(tempDir.path, 'ws-1', 'pr_clones', 'owner__repo_rm_-rf'),
      );
    });

    test('preserves hyphens and dots', () async {
      final dir = await service.prCloneDir('ws-1', 'my-org', 'my.repo');
      expect(
        dir.path,
        p.join(tempDir.path, 'ws-1', 'pr_clones', 'my-org__my.repo'),
      );
    });
  });

  group('persistLogo', () {
    test('copies source file to workspace as logo with extension', () async {
      final wsDir = Directory(p.join(tempDir.path, 'ws-1'));
      await wsDir.create(recursive: true);

      final source = File(p.join(tempDir.path, 'branding.png'));
      await source.writeAsBytes([1, 2, 3]);

      final result = await service.persistLogo('ws-1', source.path);

      expect(result, p.join(wsDir.path, 'logo.png'));
      final dest = File(result!);
      expect(dest.existsSync(), isTrue);
      expect(dest.readAsBytesSync(), [1, 2, 3]);
    });

    test('lowercases file extension', () async {
      final wsDir = Directory(p.join(tempDir.path, 'ws-1'));
      await wsDir.create(recursive: true);

      final source = File(p.join(tempDir.path, 'icon.PNG'));
      await source.writeAsString('data');

      final result = await service.persistLogo('ws-1', source.path);

      expect(result, p.join(wsDir.path, 'logo.png'));
    });

    test('uses bare "logo" when source has no extension', () async {
      final wsDir = Directory(p.join(tempDir.path, 'ws-1'));
      await wsDir.create(recursive: true);

      final source = File(p.join(tempDir.path, 'justbytes'));
      await source.writeAsBytes([1]);

      final result = await service.persistLogo('ws-1', source.path);

      expect(result, p.join(wsDir.path, 'logo'));
    });

    test(
        'creates workspace directory if it does not already exist', () async {
      final source = File(p.join(tempDir.path, 'icon.svg'));
      await source.writeAsString('<svg/>');

      await service.persistLogo('ws-fresh', source.path);

      final wsDir = Directory(p.join(tempDir.path, 'ws-fresh'));
      expect(wsDir.existsSync(), isTrue);
    });

    test('returns null for empty source path', () async {
      final result = await service.persistLogo('ws-1', '');
      expect(result, isNull);
    });

    test('returns null when source file does not exist', () async {
      final result = await service.persistLogo('ws-1', '/no/such/file.png');
      expect(result, isNull);
    });
  });

  group('ensureDir', () {
    test('creates directory if it does not exist', () async {
      final dirPath = p.join(tempDir.path, 'a', 'deep', 'path');
      await service.ensureDir(dirPath);

      expect(Directory(dirPath).existsSync(), isTrue);
    });

    test('does not throw when directory already exists', () async {
      final dirPath = p.join(tempDir.path, 'existing-dir');
      await Directory(dirPath).create();

      await service.ensureDir(dirPath);
    });

    test('creates nested directories recursively', () async {
      final dirPath = p.join(tempDir.path, 'level1', 'level2', 'level3');
      await service.ensureDir(dirPath);

      expect(Directory(dirPath).existsSync(), isTrue);
      expect(
        Directory(p.join(tempDir.path, 'level1')).existsSync(),
        isTrue,
      );
    });
  });

  group('writeString', () {
    test('writes content to file, creating parent directories', () async {
      final filePath = p.join(tempDir.path, 'deep', 'nested', 'out.txt');
      await service.writeString(filePath, 'hello world');

      final file = File(filePath);
      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), 'hello world');
    });

    test('overwrites existing file', () async {
      final filePath = p.join(tempDir.path, 'overwrite.txt');
      await File(filePath).writeAsString('original');

      await service.writeString(filePath, 'updated');

      expect(File(filePath).readAsStringSync(), 'updated');
    });

    test('creates file when parent directory already exists', () async {
      final parentDir = Directory(p.join(tempDir.path, 'existing-parent'));
      await parentDir.create();
      final filePath = p.join(parentDir.path, 'child.txt');

      await service.writeString(filePath, 'content');

      expect(File(filePath).readAsStringSync(), 'content');
    });
  });

  group('syncAgentSkillLinks - extended', () {
    test('preserves existing symlink when target is unchanged', () async {
      await service.writeSkillFile('ws-1', 'dart', 'content');
      await service.syncAgentSkillLinks('ws-1', 'ceo', ['dart']);

      final linksDir = Directory(
        p.join(tempDir.path, 'ws-1', 'agents', 'ceo', '.agents', 'skills'),
      );
      final dartLink = Link(p.join(linksDir.path, 'dart'));
      expect(dartLink.existsSync(), isTrue);

      // Second sync with same slug should not break anything
      await service.syncAgentSkillLinks('ws-1', 'ceo', ['dart']);
      expect(dartLink.existsSync(), isTrue);
    });

    test('creates symlinks that point to the correct skill directories',
        () async {
      await service.writeSkillFile('ws-1', 'python', 'content');
      await service.syncAgentSkillLinks('ws-1', 'dev', ['python']);

      final link = Link(
        p.join(
          tempDir.path,
          'ws-1', 'agents', 'dev', '.agents', 'skills', 'python',
        ),
      );
      expect(link.existsSync(), isTrue);
      final target = await link.target();
      expect(
        target,
        p.join(tempDir.path, 'ws-1', 'skills', 'python'),
      );
    });

    test('empty skill list removes all existing links', () async {
      await service.writeSkillFile('ws-1', 'dart', 'content');
      await service.writeSkillFile('ws-1', 'rust', 'content');
      await service.syncAgentSkillLinks('ws-1', 'ceo', ['dart', 'rust']);

      await service.syncAgentSkillLinks('ws-1', 'ceo', []);

      final linksDir = Directory(
        p.join(tempDir.path, 'ws-1', 'agents', 'ceo', '.agents', 'skills'),
      );
      final remaining = linksDir.listSync().whereType<Link>();
      expect(remaining, isEmpty);
    });
  });

  group('listAgentSlugs - extended', () {
    test('ignores non-directory entries in agents dir', () async {
      // Ensure agents dir exists
      await service.ensureAgentDir('ws-1', 'real-agent');
      // Place a stray file directly inside agents dir
      final strayFile = File(
        p.join(tempDir.path, 'ws-1', 'agents', 'README.txt'),
      );
      await strayFile.writeAsString('ignore me');

      final slugs = await service.listAgentSlugs('ws-1');

      expect(slugs, contains('real-agent'));
      expect(slugs, isNot(contains('README.txt')));
    });
  });

  group('listSkillSlugs - extended', () {
    test('ignores non-directory entries in skills dir', () async {
      await service.writeSkillFile('ws-1', 'dart', 'content');
      // Place a stray file directly inside skills dir
      final strayFile = File(
        p.join(tempDir.path, 'ws-1', 'skills', 'notes.txt'),
      );
      await strayFile.writeAsString('ignore me');

      final slugs = await service.listSkillSlugs('ws-1');

      expect(slugs, contains('dart'));
      expect(slugs, isNot(contains('notes.txt')));
    });
  });
}
