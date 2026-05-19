import 'dart:io';

import 'package:cc_harness_runtime/src/context/harness_skill_scanner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('skills_'));
  tearDown(() => dir.deleteSync(recursive: true));

  void writeSkill(String skillDir, String slug, String content) {
    final d = Directory(p.join(dir.path, skillDir, slug))
      ..createSync(recursive: true);
    File(p.join(d.path, 'SKILL.md')).writeAsStringSync(content);
  }

  test('parses frontmatter name + description', () async {
    writeSkill('.agents/skills', 'reviewer', '''
---
name: security-reviewer
description: Reviews code for OWASP issues
---
# Body
Do the review.
''');
    final skills = await const HarnessSkillScanner().scan([dir.path]);
    expect(skills, hasLength(1));
    expect(skills.first.name, 'security-reviewer');
    expect(skills.first.description, 'Reviews code for OWASP issues');
    expect(skills.first.path, endsWith('SKILL.md'));
  });

  test('falls back to the directory slug when no name frontmatter', () async {
    writeSkill('.claude/skills', 'my-skill', 'No frontmatter here.');
    final skills = await const HarnessSkillScanner().scan([dir.path]);
    expect(skills.single.name, 'my-skill');
    expect(skills.single.description, isEmpty);
  });

  test('de-duplicates by name across bases and dirs', () async {
    writeSkill('.agents/skills', 'a', '---\nname: dup\n---\n');
    writeSkill('.claude/skills', 'b', '---\nname: dup\n---\n');
    final skills = await const HarnessSkillScanner().scan([dir.path]);
    expect(skills.where((s) => s.name == 'dup'), hasLength(1));
  });

  test('returns empty when there are no skills', () async {
    expect(await const HarnessSkillScanner().scan([dir.path]), isEmpty);
    expect(await const HarnessSkillScanner().scan([null]), isEmpty);
  });

  group('symlinked skill entries', () {
    late Directory managed;

    /// A skill living outside the base, linked in the way
    /// `syncAgentSkillLinks` attaches a workspace skill to an agent.
    void linkSkill(String skillDir, String slug, String content) {
      final target = Directory(p.join(managed.path, slug))
        ..createSync(recursive: true);
      File(p.join(target.path, 'SKILL.md')).writeAsStringSync(content);
      Directory(p.join(dir.path, skillDir)).createSync(recursive: true);
      Link(p.join(dir.path, skillDir, slug)).createSync(target.path);
    }

    setUp(() => managed = Directory.systemTemp.createTempSync('ws_skills_'));
    tearDown(() => managed.deleteSync(recursive: true));

    test('follows a link whose target is inside a permitted root', () async {
      linkSkill(
        '.agents/skills',
        'coordination',
        '---\nname: coordination\n---\n',
      );
      final skills = await const HarnessSkillScanner().scan(
        [dir.path],
        permittedLinkRoots: [managed.path],
      );
      expect(skills.single.name, 'coordination');
      // The LINK path, not the target: it has to stay addressable from the
      // agent's own working directory.
      expect(skills.single.path, startsWith(dir.path));
    });

    test(
      'refuses a link whose target is outside every permitted root',
      () async {
        linkSkill(
          '.agents/skills',
          'coordination',
          '---\nname: coordination\n---\n',
        );
        final elsewhere = Directory.systemTemp.createTempSync('other_');
        addTearDown(() => elsewhere.deleteSync(recursive: true));
        expect(
          await const HarnessSkillScanner().scan(
            [dir.path],
            permittedLinkRoots: [elsewhere.path],
          ),
          isEmpty,
        );
      },
    );

    test('follows nothing when no permitted roots are passed', () async {
      linkSkill(
        '.agents/skills',
        'coordination',
        '---\nname: coordination\n---\n',
      );
      expect(await const HarnessSkillScanner().scan([dir.path]), isEmpty);
    });

    test('real directories still scan without any permitted root', () async {
      writeSkill('.agents/skills', 'plain', '---\nname: plain\n---\n');
      linkSkill('.agents/skills', 'linked', '---\nname: linked\n---\n');
      final skills = await const HarnessSkillScanner().scan([dir.path]);
      expect(skills.map((s) => s.name), ['plain']);
    });
  });
}
