import 'dart:io';

import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:cc_infra/src/workspaces/workspace_filesystem_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [WorkspaceFilesystemService] against a temp-dir-rooted [CcPaths].
/// Pins every directory layout (workspaces, conversations, agents, skills,
/// pr_clones), the file CRUD, the skill-link reconciliation, the logo
/// persistence helpers, and the path-sanitization for clone dir names.
void main() {
  late Directory tempRoot;
  late CcPaths paths;
  late WorkspaceFilesystemService fs;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('workspace_fs_test_');
    paths = CcPaths(tempRoot.path);
    fs = WorkspaceFilesystemService(paths);
  });

  tearDown(() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('directory layout', () {
    test('workspaceDir nests under the root', () async {
      final dir = await fs.workspaceDir('ws-1');
      expect(dir, p.join(tempRoot.path, 'ws-1'));
    });

    test('conversationsDir nests under the workspace', () async {
      final dir = await fs.conversationsDir('ws-1');
      expect(dir, p.join(tempRoot.path, 'ws-1', 'conversations'));
    });

    test('conversationDir nests under conversations', () async {
      final dir = await fs.conversationDir('ws-1', 'c-1');
      expect(dir, p.join(tempRoot.path, 'ws-1', 'conversations', 'c-1'));
    });

    test('ensureConversationDir creates the directory', () async {
      final path = await fs.ensureConversationDir('ws-1', 'c-1');
      expect(Directory(path).existsSync(), isTrue);
    });

    test('ensureConversationDir is idempotent', () async {
      await fs.ensureConversationDir('ws-1', 'c-1');
      await fs.ensureConversationDir('ws-1', 'c-1'); // no throw
      expect(
        Directory(
          p.join(tempRoot.path, 'ws-1', 'conversations', 'c-1'),
        ).existsSync(),
        isTrue,
      );
    });

    test('skillsDir nests under the workspace', () async {
      expect(
        await fs.skillsDir('ws-1'),
        p.join(tempRoot.path, 'ws-1', 'skills'),
      );
    });

    test('skillFilePath ends with SKILL.md', () async {
      expect(
        await fs.skillFilePath('ws-1', 'git'),
        p.join(tempRoot.path, 'ws-1', 'skills', 'git', 'SKILL.md'),
      );
    });

    test('agentsDir nests under the workspace', () async {
      expect(
        await fs.agentsDir('ws-1'),
        p.join(tempRoot.path, 'ws-1', 'agents'),
      );
    });

    test('agentFilePath ends with AGENTS.md', () async {
      expect(
        await fs.agentFilePath('ws-1', 'qa'),
        p.join(tempRoot.path, 'ws-1', 'agents', 'qa', 'AGENTS.md'),
      );
    });

    test('agentSkillsLinkDir nests under .agents/skills', () async {
      expect(
        await fs.agentSkillsLinkDir('ws-1', 'qa'),
        p.join(tempRoot.path, 'ws-1', 'agents', 'qa', '.agents', 'skills'),
      );
    });
  });

  group('workspace + agent dirs', () {
    test('ensureWorkspaceDirs creates skills and agents', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      expect(Directory(p.join(tempRoot.path, 'ws-1')).existsSync(), isTrue);
      expect(
        Directory(p.join(tempRoot.path, 'ws-1', 'skills')).existsSync(),
        isTrue,
      );
      expect(
        Directory(p.join(tempRoot.path, 'ws-1', 'agents')).existsSync(),
        isTrue,
      );
    });

    test('ensureWorkspaceDirs is idempotent', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.ensureWorkspaceDirs('ws-1');
    });

    test('ensureAgentDir creates the per-agent directory', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.ensureAgentDir('ws-1', 'qa');
      expect(
        Directory(p.join(tempRoot.path, 'ws-1', 'agents', 'qa')).existsSync(),
        isTrue,
      );
    });
  });

  group('agent file CRUD', () {
    test('writeAgentFile creates the dir and writes AGENTS.md', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeAgentFile('ws-1', 'qa', 'body');
      final f = File(
        p.join(tempRoot.path, 'ws-1', 'agents', 'qa', 'AGENTS.md'),
      );
      expect(f.existsSync(), isTrue);
      expect(f.readAsStringSync(), 'body');
    });

    test('deleteAgentDir removes the agent directory', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeAgentFile('ws-1', 'qa', 'body');
      await fs.deleteAgentDir('ws-1', 'qa');
      expect(
        Directory(p.join(tempRoot.path, 'ws-1', 'agents', 'qa')).existsSync(),
        isFalse,
      );
    });

    test('deleteAgentDir is a no-op when the dir is missing', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.deleteAgentDir('ws-1', 'missing');
    });

    test('listAgentSlugs returns empty when agents dir is missing', () async {
      expect(await fs.listAgentSlugs('ws-1'), isEmpty);
    });

    test('listAgentSlugs returns only directories', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeAgentFile('ws-1', 'qa', 'a');
      await fs.writeAgentFile('ws-1', 'arch', 'b');
      // A stray file in agents/ should be ignored.
      await File(
        p.join(tempRoot.path, 'ws-1', 'agents', 'stray.txt'),
      ).writeAsString('x');
      expect((await fs.listAgentSlugs('ws-1')).toSet(), {'qa', 'arch'});
    });
  });

  group('skill file CRUD', () {
    test('writeSkillFile creates the dir and writes SKILL.md', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeSkillFile('ws-1', 'git', 'skill body');
      final f = File(
        p.join(tempRoot.path, 'ws-1', 'skills', 'git', 'SKILL.md'),
      );
      expect(f.existsSync(), isTrue);
      expect(f.readAsStringSync(), 'skill body');
    });

    test('readSkillFile returns null when missing', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      expect(await fs.readSkillFile('ws-1', 'git'), isNull);
    });

    test('readSkillFile returns the content after a write', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeSkillFile('ws-1', 'git', 'skill body');
      expect(await fs.readSkillFile('ws-1', 'git'), 'skill body');
    });

    test('deleteSkillDir removes the skill directory', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeSkillFile('ws-1', 'git', 'skill body');
      await fs.deleteSkillDir('ws-1', 'git');
      expect(
        Directory(p.join(tempRoot.path, 'ws-1', 'skills', 'git')).existsSync(),
        isFalse,
      );
    });

    test('listSkillSlugs only returns dirs that contain SKILL.md', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeSkillFile('ws-1', 'git', 'a');
      // A directory without SKILL.md is ignored.
      Directory(
        p.join(tempRoot.path, 'ws-1', 'skills', 'empty'),
      ).createSync(recursive: true);
      expect(await fs.listSkillSlugs('ws-1'), ['git']);
    });

    test('listSkillSlugs returns empty when skills dir is missing', () async {
      expect(await fs.listSkillSlugs('ws-1'), isEmpty);
    });
  });

  group('syncAgentSkillLinks', () {
    Set<String> linkNames() {
      // On macOS a directory-symlink shows up as _Directory in listSync, so
      // identify links via FileSystemEntity.type with followLinks:false rather
      // than whereType<Link>.
      final dir = Directory(
        p.join(tempRoot.path, 'ws-1', 'agents', 'qa', '.agents', 'skills'),
      );
      return dir
          .listSync()
          .where(
            (e) =>
                FileSystemEntity.typeSync(e.path, followLinks: false) ==
                FileSystemEntityType.link,
          )
          .map((e) => p.basename(e.path))
          .toSet();
    }

    test('creates symlinks for wanted slugs', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      // Target skills must exist for the symlink target path to be sensible.
      await fs.writeSkillFile('ws-1', 'git', 'a');
      await fs.writeSkillFile('ws-1', 'review', 'b');

      // Sync: link git and review.
      await fs.syncAgentSkillLinks('ws-1', 'qa', ['git', 'review']);
      expect(linkNames(), {'git', 'review'});
    });

    test('adds new wanted symlinks alongside existing ones', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeSkillFile('ws-1', 'git', 'a');
      await fs.writeSkillFile('ws-1', 'review', 'b');
      await fs.writeSkillFile('ws-1', 'old', 'c');

      await fs.syncAgentSkillLinks('ws-1', 'qa', ['git', 'review']);
      await fs.syncAgentSkillLinks('ws-1', 'qa', ['git', 'old']);
      // git kept, old added.
      expect(linkNames(), containsAll(['git', 'old']));
    });

    test('is idempotent when the wanted set is unchanged', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      await fs.writeSkillFile('ws-1', 'git', 'a');
      await fs.syncAgentSkillLinks('ws-1', 'qa', ['git']);
      await fs.syncAgentSkillLinks('ws-1', 'qa', ['git']);
      expect(linkNames(), {'git'});
    });
  });

  group('prCloneDir sanitization', () {
    test('joins owner__repo under pr_clones', () async {
      final dir = await fs.prCloneDir('ws-1', 'acme', 'mono-repo');
      expect(
        dir,
        p.join(tempRoot.path, 'ws-1', 'pr_clones', 'acme__mono-repo'),
      );
    });

    test('replaces unsafe characters with underscore', () async {
      final dir = await fs.prCloneDir('ws-1', 'ac/me', 're..po');
      // '/' is unsafe → '_', '.' is kept.
      expect(p.basename(dir), 'ac_me__re..po');
    });
  });

  group('persistLogo', () {
    test('returns null when sourcePath is empty', () async {
      expect(await fs.persistLogo('ws-1', ''), isNull);
    });

    test('returns null when the source file does not exist', () async {
      expect(
        await fs.persistLogo('ws-1', p.join(tempRoot.path, 'nope.png')),
        isNull,
      );
    });

    test('copies the source into the workspace as logo.<ext>', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      final src = File(p.join(tempRoot.path, 'src.PNG'))
        ..writeAsBytesSync([1, 2, 3]);
      final dest = await fs.persistLogo('ws-1', src.path);
      expect(dest, isNotNull);
      expect(dest!, endsWith('.png')); // lowercased extension
      expect(File(dest).existsSync(), isTrue);
      expect(File(dest).readAsBytesSync(), [1, 2, 3]);
    });

    test('uses the bare name "logo" when there is no extension', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      final src = File(p.join(tempRoot.path, 'logo'))..writeAsBytesSync([9]);
      final dest = await fs.persistLogo('ws-1', src.path);
      expect(p.basename(dest!), 'logo');
    });
  });

  group('persistLogoBytes', () {
    test('returns null for empty bytes', () async {
      expect(await fs.persistLogoBytes('ws-1', const [], 'png'), isNull);
    });

    test(
      'writes logo.<ext> into the workspace using the extension verbatim',
      () async {
        await fs.ensureWorkspaceDirs('ws-1');
        // The extension is used verbatim (the caller is expected to include the
        // leading dot); lowercased.
        final dest = await fs.persistLogoBytes('ws-1', [4, 5, 6], '.PNG');
        expect(dest, isNotNull);
        expect(p.basename(dest!), 'logo.png');
        expect(File(dest).readAsBytesSync(), [4, 5, 6]);
      },
    );

    test('uses the bare name "logo" when the extension is empty', () async {
      await fs.ensureWorkspaceDirs('ws-1');
      final dest = await fs.persistLogoBytes('ws-1', [1], '');
      expect(p.basename(dest!), 'logo');
    });
  });

  group('generic helpers', () {
    test('ensureDir creates a nested directory', () async {
      final path = p.join(tempRoot.path, 'a', 'b', 'c');
      await fs.ensureDir(path);
      expect(Directory(path).existsSync(), isTrue);
    });

    test('ensureDir is idempotent', () async {
      final path = p.join(tempRoot.path, 'a');
      await fs.ensureDir(path);
      await fs.ensureDir(path);
    });

    test('writeString creates parent dirs then writes', () async {
      final path = p.join(tempRoot.path, 'x', 'y', 'file.txt');
      await fs.writeString(path, 'hello');
      expect(File(path).readAsStringSync(), 'hello');
    });

    test('writeString overwrites existing content', () async {
      final path = p.join(tempRoot.path, 'file.txt');
      await fs.writeString(path, 'first');
      await fs.writeString(path, 'second');
      expect(File(path).readAsStringSync(), 'second');
    });
  });
}
