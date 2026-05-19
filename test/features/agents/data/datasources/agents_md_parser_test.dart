import 'dart:io';

import 'package:cc_infra/src/util/agents_md_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('agents_md_test_').path;
  });

  tearDown(() {
    Directory(tempDir).deleteSync(recursive: true);
  });

  group('AgentsMdParser - frontmatter extraction', () {
    test('extracts valid YAML frontmatter', () {
      const input = '''---
name: tester
title: QA Agent
reportsTo: lead
skills:
  - testing
  - validation
---

# Persona

I am a tester agent.''';

      final parser = AgentsMdParser();
      final result = parser.parseAgentFile(
        _writeFile('$tempDir/test_agent.md', input),
      );

      expect(result.name, 'tester');
      expect(result.title, 'QA Agent');
      expect(result.reportsTo, 'lead');
      expect(result.skills, ['testing', 'validation']);
      expect(result.personaMarkdown, '# Persona\n\nI am a tester agent.');
      expect(result.agentMdPath, endsWith('test_agent.md'));
    });

    test('defaults title to name when not provided', () {
      const input = '''---
name: builder
---

I build things.''';

      final parser = AgentsMdParser();
      final result = parser.parseAgentFile(
        _writeFile('$tempDir/builder.md', input),
      );

      expect(result.name, 'builder');
      expect(result.title, 'builder');
    });

    test('throws FormatException when no frontmatter', () {
      const input = '# Just markdown\n\nNo frontmatter here.';

      final parser = AgentsMdParser();
      expect(
        () => parser.parseAgentFile(_writeFile('$tempDir/no_fm.md', input)),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when name is missing', () {
      const input = '''---
title: Untitled
---

Some content.''';

      final parser = AgentsMdParser();
      expect(
        () => parser.parseAgentFile(_writeFile('$tempDir/no_name.md', input)),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException when name is empty', () {
      const input = '''---
name: ""
---

Content.''';

      final parser = AgentsMdParser();
      expect(
        () =>
            parser.parseAgentFile(_writeFile('$tempDir/empty_name.md', input)),
        throwsA(isA<FormatException>()),
      );
    });

    test('handles null reportsTo', () {
      const input = '''---
name: solo
---

Solo agent.''';

      final parser = AgentsMdParser();
      final result = parser.parseAgentFile(
        _writeFile('$tempDir/solo.md', input),
      );

      expect(result.reportsTo, isNull);
    });

    test('handles empty skills list', () {
      const input = '''---
name: novice
---

Novice agent.''';

      final parser = AgentsMdParser();
      final result = parser.parseAgentFile(
        _writeFile('$tempDir/novice.md', input),
      );

      expect(result.skills, isEmpty);
    });

    test('skills as YAML list', () {
      const input = '''---
name: expert
skills:
  - dev
  - ops
  - security
---

Expert.''';

      final parser = AgentsMdParser();
      final result = parser.parseAgentFile(
        _writeFile('$tempDir/expert.md', input),
      );

      expect(result.skills, ['dev', 'ops', 'security']);
    });

    test('skills as inline YAML list', () {
      const input = '''---
name: inline
skills: [a, b, c]
---

Content.''';

      final parser = AgentsMdParser();
      final result = parser.parseAgentFile(
        _writeFile('$tempDir/inline.md', input),
      );

      expect(result.skills, ['a', 'b', 'c']);
    });

    test('handles malformed file gracefully', () {
      const input = '';

      final parser = AgentsMdParser();
      expect(
        () => parser.parseAgentFile(_writeFile('$tempDir/empty.md', input)),
        throwsA(isA<Exception>()),
      );
    });

    test('extracts markdown body after frontmatter', () {
      const input = '''---
name: writer
---

## Section

Some **rich** content.

- item 1
- item 2
''';

      final parser = AgentsMdParser();
      final result = parser.parseAgentFile(
        _writeFile('$tempDir/writer.md', input),
      );

      expect(result.personaMarkdown, contains('## Section'));
      expect(result.personaMarkdown, contains('**rich**'));
      expect(result.personaMarkdown, contains('item 1'));
    });

    test('handles content without closing frontmatter delimiter', () {
      const input = '''---
name: broken
Content without closing delimiter.''';

      final parser = AgentsMdParser();
      expect(
        () => parser.parseAgentFile(_writeFile('$tempDir/broken.md', input)),
        throwsA(isA<Exception>()),
      );
    });

    test('frontmatter with complex YAML values', () {
      const input = '''---
name: complex
title: "Agent with Quotes"
reportsTo: lead
skills:
  - "skill one"
  - skill_two
  - "skill-three"
---

Complex persona text.''';

      final parser = AgentsMdParser();
      final result = parser.parseAgentFile(
        _writeFile('$tempDir/complex.md', input),
      );

      expect(result.name, 'complex');
      expect(result.title, 'Agent with Quotes');
      expect(result.skills, ['skill one', 'skill_two', 'skill-three']);
    });

    test('AgentMdParseResult equality by value', () {
      const a = AgentMdParseResult(
        name: 'test',
        title: 'Test',
        reportsTo: null,
        skills: [],
        personaMarkdown: '',
        agentMdPath: '',
      );
      const b = AgentMdParseResult(
        name: 'test',
        title: 'Test',
        reportsTo: null,
        skills: [],
        personaMarkdown: '',
        agentMdPath: '',
      );

      expect(a.name, b.name);
      expect(a.title, b.title);
    });
  });

  group('AgentsMdParser - team file parsing', () {
    test('parseTeamFile returns null for nonexistent file', () {
      final parser = AgentsMdParser();
      final result = parser.parseTeamFile('$tempDir/nonexistent.md');
      expect(result, isNull);
    });

    test('parseTeamFile returns null when no frontmatter', () {
      const input = 'Just some markdown.';
      final path = _writeFile('$tempDir/team_no_fm.md', input);
      final parser = AgentsMdParser();
      final result = parser.parseTeamFile(path);
      expect(result, isNull);
    });

    test('parseTeamFile returns null when missing name', () {
      const input = '''---
slug: my-team
---

Content.''';

      final path = _writeFile('$tempDir/team_no_name.md', input);
      final parser = AgentsMdParser();
      final result = parser.parseTeamFile(path);
      expect(result, isNull);
    });

    test('parseTeamFile returns null when missing slug', () {
      const input = '''---
name: My Team
---

Content.''';

      final path = _writeFile('$tempDir/team_no_slug.md', input);
      final parser = AgentsMdParser();
      final result = parser.parseTeamFile(path);
      expect(result, isNull);
    });

    test('parseTeamFile parses valid team file', () {
      const input = '''---
name: Engineering
slug: eng
description: The engineering team
manager: eng-lead.md
includes:
  - dev.md
  - ops.md
tags:
  - backend
  - frontend
---

# Team Context

Engineering team description.''';

      final path = _writeFile('$tempDir/team_valid.md', input);
      final parser = AgentsMdParser();
      final result = parser.parseTeamFile(path)!;

      expect(result.name, 'Engineering');
      expect(result.slug, 'eng');
      expect(result.description, 'The engineering team');
      expect(result.managerPath, 'eng-lead.md');
      expect(result.includes, ['dev.md', 'ops.md']);
      expect(result.tags, ['backend', 'frontend']);
      expect(
        result.teamMarkdown,
        '# Team Context\n\nEngineering team description.',
      );
    });

    test('parseTeamFile handles missing optional fields', () {
      const input = '''---
name: Solo
slug: solo
---

Team body.''';

      final path = _writeFile('$tempDir/team_minimal.md', input);
      final parser = AgentsMdParser();
      final result = parser.parseTeamFile(path)!;

      expect(result.name, 'Solo');
      expect(result.slug, 'solo');
      expect(result.description, '');
      expect(result.managerPath, isNull);
      expect(result.includes, isEmpty);
      expect(result.tags, isEmpty);
    });
  });

  group('AgentMdParseResult', () {
    test('all fields stored correctly', () {
      const result = AgentMdParseResult(
        name: 'agent1',
        title: 'Agent One',
        reportsTo: 'manager',
        skills: ['coding', 'testing'],
        personaMarkdown: '# Persona',
        agentMdPath: '/path/to/agent.md',
      );

      expect(result.name, 'agent1');
      expect(result.title, 'Agent One');
      expect(result.reportsTo, 'manager');
      expect(result.skills, ['coding', 'testing']);
      expect(result.personaMarkdown, '# Persona');
      expect(result.agentMdPath, '/path/to/agent.md');
    });
  });

  group('TeamMdParseResult', () {
    test('all fields stored correctly', () {
      const result = TeamMdParseResult(
        name: 'Team A',
        description: 'A test team',
        slug: 'team-a',
        managerPath: '/path/manager.md',
        includes: ['a.md', 'b.md'],
        tags: ['tag1'],
        teamMarkdown: '# Team',
      );

      expect(result.name, 'Team A');
      expect(result.description, 'A test team');
      expect(result.slug, 'team-a');
      expect(result.managerPath, '/path/manager.md');
      expect(result.includes, ['a.md', 'b.md']);
      expect(result.tags, ['tag1']);
      expect(result.teamMarkdown, '# Team');
    });
  });
}

String _writeFile(String path, String content) {
  final file = File(path);
  file.writeAsStringSync(content);
  return path;
}
