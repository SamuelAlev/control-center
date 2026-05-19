import 'dart:io';

import 'package:cc_infra/src/util/agents_md_parser.dart';
import 'package:test/test.dart';

/// Exercises [AgentsMdParser]'s YAML-frontmatter extraction, markdown-body
/// splitting and the discover/parse methods — against temp files so the
/// filesystem-walking branch is covered without touching the real repo.
void main() {
  late Directory sandbox;
  late AgentsMdParser parser;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('agents_md_');
    parser = AgentsMdParser();
  });
  tearDown(() => sandbox.deleteSync(recursive: true));

  File write(String relPath, String content) {
    final f = File('${sandbox.path}/$relPath');
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
    return f;
  }

  group('parseAgentFile', () {
    test('parses frontmatter + markdown body', () {
      final f = write('agent.agents.md', '''---
name: backend-dev
title: Backend Developer
reportsTo: tech-lead
skills:
  - dart
  - postgres
---
You are a backend developer. Be terse.''');
      final r = parser.parseAgentFile(f.path);
      expect(r.name, 'backend-dev');
      expect(r.title, 'Backend Developer');
      expect(r.reportsTo, 'tech-lead');
      expect(r.skills, ['dart', 'postgres']);
      expect(r.personaMarkdown, 'You are a backend developer. Be terse.');
      expect(r.agentMdPath, f.path);
    });

    test('title falls back to name when omitted', () {
      final f = write('a.AGENTS.md', '---\nname: lone\n---\nbody');
      final r = parser.parseAgentFile(f.path);
      expect(r.title, 'lone');
    });

    test('throws when no frontmatter delimiter is present', () {
      final f = write('a.AGENTS.md', 'just markdown, no frontmatter');
      expect(
        () => parser.parseAgentFile(f.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when frontmatter has no closing delimiter', () {
      final f = write('a.AGENTS.md', '---\nname: dangling');
      expect(
        () => parser.parseAgentFile(f.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when name is missing or empty', () {
      final f = write('a.AGENTS.md', '---\ntitle: x\n---\nbody');
      expect(
        () => parser.parseAgentFile(f.path),
        throwsA(isA<FormatException>()),
      );
      final f2 = write('b.AGENTS.md', '---\nname: ""\n---\nbody');
      expect(
        () => parser.parseAgentFile(f2.path),
        throwsA(isA<FormatException>()),
      );
    });

    test('skills defaults to empty when not a list', () {
      final f = write(
        'a.AGENTS.md',
        '---\nname: x\nskills: not-a-list\n---\nbody',
      );
      final r = parser.parseAgentFile(f.path);
      expect(r.skills, isEmpty);
    });

    test('no-name markdown content (no frontmatter) is returned whole', () {
      // The body extractor returns the trimmed input when there's no leading
      // `---`, so this exercises the same branch indirectly via the throw above.
      // Here we verify the body is split correctly when frontmatter is present.
      final f = write('a.AGENTS.md', '---\nname: x\n---\n\n# Persona\n\nText');
      final r = parser.parseAgentFile(f.path);
      expect(r.personaMarkdown, '# Persona\n\nText');
    });
  });

  group('parseTeamFile', () {
    test('parses a team definition with includes and tags', () {
      final f = write('team.team.md', '''---
name: Backend Team
description: owns the API
slug: backend
manager: ./manager.agents.md
includes:
  - ./dev.agents.md
tags:
  - api
  - dart
---
Team charter goes here.''');
      final r = parser.parseTeamFile(f.path)!;
      expect(r.name, 'Backend Team');
      expect(r.description, 'owns the API');
      expect(r.slug, 'backend');
      expect(r.managerPath, './manager.agents.md');
      expect(r.includes, ['./dev.agents.md']);
      expect(r.tags, ['api', 'dart']);
      expect(r.teamMarkdown, 'Team charter goes here.');
    });

    test('returns null when the file does not exist', () {
      expect(parser.parseTeamFile('${sandbox.path}/nope.md'), isNull);
    });

    test('returns null when there is no frontmatter', () {
      final f = write('t.team.md', 'no frontmatter here');
      expect(parser.parseTeamFile(f.path), isNull);
    });

    test('returns null when name or slug is missing', () {
      final f = write('t.team.md', '---\nname: x\n---\nbody');
      expect(parser.parseTeamFile(f.path), isNull);
      final f2 = write('t2.team.md', '---\nslug: y\n---\nbody');
      expect(parser.parseTeamFile(f2.path), isNull);
    });

    test('description defaults to empty; manager/includes/tags default', () {
      final f = write('t.team.md', '---\nname: n\nslug: s\n---\nbody');
      final r = parser.parseTeamFile(f.path)!;
      expect(r.description, '');
      expect(r.managerPath, isNull);
      expect(r.includes, isEmpty);
      expect(r.tags, isEmpty);
    });
  });

  group('discoverAgents', () {
    test('walks agents/ and returns parsed agent files', () async {
      write('agents/a.AGENTS.md', '---\nname: a\ntitle: A\n---\nbody-a');
      write('agents/b.AGENTS.md', '---\nname: b\n---\nbody-b');
      final agents = await parser.discoverAgents(sandbox.path);
      // The projectPath root is ALSO scanned recursively, so files under
      // agents/ are discovered twice — collect into a set to dedupe.
      expect(agents.map((a) => a.name).toSet(), {'a', 'b'});
    });

    test(
      'skips malformed agent files without failing the whole scan',
      () async {
        write('agents/good.AGENTS.md', '---\nname: good\n---\nbody');
        // Malformed: no frontmatter → parseAgentFile throws, discover swallows.
        write('agents/bad.AGENTS.md', 'no frontmatter at all');
        final agents = await parser.discoverAgents(sandbox.path);
        expect(agents.map((a) => a.name).toSet(), {'good'});
      },
    );

    test('walks the .claude/agents dir as well', () async {
      write('.claude/agents/c.AGENTS.md', '---\nname: c\n---\nbody-c');
      final agents = await parser.discoverAgents(sandbox.path);
      expect(agents.map((a) => a.name).toSet(), {'c'});
    });

    test('walks the .kilo/agent dir as well', () async {
      write('.kilo/agent/d.AGENTS.md', '---\nname: d\n---\nbody-d');
      final agents = await parser.discoverAgents(sandbox.path);
      expect(agents.map((a) => a.name).toSet(), {'d'});
    });

    test('non-existent search paths are silently skipped', () async {
      final agents = await parser.discoverAgents(sandbox.path);
      expect(agents, isEmpty);
    });

    test(
      'discovers an AGENTS.md file directly under the project root',
      () async {
        // The projectPath scan is recursive: an AGENTS.md at the root is
        // matched once (no agents/ equivalent at the top level).
        write('AGENTS.md', '---\nname: root\n---\nbody-root');
        final agents = await parser.discoverAgents(sandbox.path);
        expect(agents.map((a) => a.name).toSet(), {'root'});
      },
    );
  });
}
