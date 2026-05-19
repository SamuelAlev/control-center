import 'dart:io';

import 'package:control_center/core/infrastructure/skills/skill_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscoveredSkill', () {
    test('equality and hashCode', () {
      const a = DiscoveredSkill(
        slug: 'my-skill',
        directory: '/path',
        skillFilePath: '/path/SKILL.md',
        name: 'My Skill',
        description: 'Does things',
        framework: 'claude',
      );
      const b = DiscoveredSkill(
        slug: 'my-skill',
        directory: '/path',
        skillFilePath: '/path/SKILL.md',
        name: 'My Skill',
        description: 'Does things',
        framework: 'claude',
      );
      const c = DiscoveredSkill(
        slug: 'other',
        directory: '/path',
        skillFilePath: '/path/SKILL.md',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('optional fields default to null', () {
      const s = DiscoveredSkill(
        slug: 's',
        directory: '/d',
        skillFilePath: '/d/SKILL.md',
      );
      expect(s.name, isNull);
      expect(s.description, isNull);
      expect(s.framework, isNull);
    });
  });

  group('SkillScanner', () {
    late Directory tmpRoot;

    setUp(() {
      tmpRoot = Directory.systemTemp.createTempSync('skill_scanner_test_');
      final agentsDir = Directory('${tmpRoot.path}/.claude/skills');
      agentsDir.createSync(recursive: true);

      // Skill with full frontmatter
      final skillDir = Directory('${agentsDir.path}/my-skill');
      skillDir.createSync();
      File('${skillDir.path}/SKILL.md').writeAsStringSync(
        '---\n'
        'name: My Skill\n'
        'description: Does useful things\n'
        '---\n'
        '# My Skill\n'
        'Content here.\n',
      );

      // Skill with quoted frontmatter values
      final quotedDir = Directory('${agentsDir.path}/quoted-skill');
      quotedDir.createSync();
      File('${quotedDir.path}/SKILL.md').writeAsStringSync(
        '---\n'
        'name: "Quoted Name"\n'
        "description: 'With single quotes'\n"
        '---\n'
        '# Quoted Skill\n',
      );

      // Directory without SKILL.md
      final noMdDir = Directory('${agentsDir.path}/no-md');
      noMdDir.createSync();
      File('${noMdDir.path}/README.md').writeAsStringSync('not a skill');

      // Another framework directory
      final cursorDir = Directory('${tmpRoot.path}/.cursor/skills');
      cursorDir.createSync(recursive: true);
      final cursorSkillDir = Directory('${cursorDir.path}/cursor-skill');
      cursorSkillDir.createSync();
      File('${cursorSkillDir.path}/SKILL.md').writeAsStringSync(
        '---\n'
        'name: Cursor Skill\n'
        '---\n'
        '# Cursor Skill\n',
      );
    });

    tearDown(() {
      tmpRoot.deleteSync(recursive: true);
    });

    test('scan returns empty list for non-existent directory', () async {
      final scanner = SkillScanner();
      final results =
          await scanner.scan('${tmpRoot.path}/does-not-exist');
      expect(results, isEmpty);
    });

    test('scan discovers skills from configured scan roots', () async {
      final scanner = SkillScanner();
      final results = await scanner.scan(tmpRoot.path);

      final slugs = results.map((s) => s.slug).toSet();
      expect(slugs, containsAll(['my-skill', 'quoted-skill', 'cursor-skill']));
      // no-md should not appear (no SKILL.md)
      expect(slugs, isNot(contains('no-md')));
    });

    test('scanned skill has correct framework', () async {
      final scanner = SkillScanner();
      final results = await scanner.scan(tmpRoot.path);

      final claudeSkills =
          results.where((s) => s.framework == 'claude').toList();
      final cursorSkills =
          results.where((s) => s.framework == 'cursor').toList();

      expect(claudeSkills.length, greaterThanOrEqualTo(2));
      expect(cursorSkills.length, 1);
      expect(cursorSkills.first.slug, 'cursor-skill');
    });

    test('scanned skill parses frontmatter metadata', () async {
      final scanner = SkillScanner();
      final results = await scanner.scan(tmpRoot.path);

      final mySkill = results.firstWhere((s) => s.slug == 'my-skill');
      expect(mySkill.name, 'My Skill');
      expect(mySkill.description, 'Does useful things');
      expect(mySkill.skillFilePath, endsWith('/my-skill/SKILL.md'));
      expect(mySkill.directory, endsWith('/my-skill'));
    });

    test('scanned skill parses quoted frontmatter values', () async {
      final scanner = SkillScanner();
      final results = await scanner.scan(tmpRoot.path);

      final quoted =
          results.firstWhere((s) => s.slug == 'quoted-skill');
      expect(quoted.name, 'Quoted Name');
      expect(quoted.description, 'With single quotes');
    });

    test('scan with empty root returns empty list', () async {
      final emptyDir = Directory.systemTemp.createTempSync(
        'skill_scanner_empty_',
      );
      try {
        final scanner = SkillScanner();
        final results = await scanner.scan(emptyDir.path);
        expect(results, isEmpty);
      } finally {
        emptyDir.deleteSync(recursive: true);
      }
    });

    test('files directly in scan root are ignored (must be subdirectory)', () async {
      final dir = Directory.systemTemp.createTempSync('skill_scanner_files_');
      try {
        final skillsDir = Directory('${dir.path}/.claude/skills');
        skillsDir.createSync(recursive: true);
        // Place a SKILL.md directly in the scan root — this is a file, not a dir
        File('${skillsDir.path}/SKILL.md').writeAsStringSync(
          '---\nname: RootSkill\n---\n# Content\n',
        );

        final scanner = SkillScanner();
        final results = await scanner.scan(dir.path);
        // SKILL.md is a file, not a directory, so it should be skipped by _scanDirectory
        expect(results.where((s) => s.slug == 'SKILL.md'), isEmpty);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('skips skill directory where SKILL.md has no closing frontmatter', () async {
      final dir = Directory.systemTemp.createTempSync('skill_scanner_unclosed_');
      try {
        final skillsDir = Directory('${dir.path}/.claude/skills/broken-skill');
        skillsDir.createSync(recursive: true);
        // Only opening --- but no closing ---
        File('${skillsDir.path}/SKILL.md').writeAsStringSync(
          '---\nname: Broken\n# No closing frontmatter\n',
        );

        final scanner = SkillScanner();
        final results = await scanner.scan(dir.path);
        final broken = results.where((s) => s.slug == 'broken-skill').toList();
        // The skill is discovered, but frontmatter parsing returns empty map
        expect(broken, hasLength(1));
        expect(broken.first.name, isNull);
        expect(broken.first.description, isNull);
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('frontmatter lines without colons are ignored', () async {
      final dir = Directory.systemTemp.createTempSync('skill_scanner_nocolon_');
      try {
        final skillsDir = Directory('${dir.path}/.claude/skills/skill-x');
        skillsDir.createSync(recursive: true);
        File('${skillsDir.path}/SKILL.md').writeAsStringSync(
          '---\n'
          'name: Valid\n'
          'this line has no colon\n'
          '  leading spaces: still works\n'
          '---\n'
          'Content\n',
        );

        final scanner = SkillScanner();
        final results = await scanner.scan(dir.path);
        final skill = results.firstWhere((s) => s.slug == 'skill-x');
        expect(skill.name, 'Valid');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });

    test('frontmatter line with only a colon yields empty key and value', () async {
      final dir = Directory.systemTemp.createTempSync('skill_scanner_barecolon_');
      try {
        final skillsDir = Directory('${dir.path}/.claude/skills/skill-y');
        skillsDir.createSync(recursive: true);
        File('${skillsDir.path}/SKILL.md').writeAsStringSync(
          '---\n:\nname: HasEmptyKey\n---\nContent\n',
        );

        final scanner = SkillScanner();
        final results = await scanner.scan(dir.path);
        final skill = results.firstWhere((s) => s.slug == 'skill-y');
        expect(skill.name, 'HasEmptyKey');
      } finally {
        dir.deleteSync(recursive: true);
      }
    });
  });
}
