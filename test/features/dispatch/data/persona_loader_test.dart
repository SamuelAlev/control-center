import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/persona/agent_persona.dart';
import 'package:cc_infra/src/dispatch/persona_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const loader = PersonaLoader();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('persona_loader_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writePersona(String dir, String fileName, String content) async {
    final directory = Directory(dir);
    await directory.create(recursive: true);
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(content);
    return file;
  }

  String agentsDir(String root) {
    return '$root${Platform.pathSeparator}.cc'
        '${Platform.pathSeparator}agents';
  }

  group('parsePersona', () {
    test('parses all frontmatter fields and the markdown body', () {
      const content = '''
---
name: reviewer
description: Reviews pull requests
tools:
  - read
  - grep
spawns: "*"
model: claude-sonnet
thinkingLevel: high
blocking: true
readSummarize: false
autoloadSkills:
  - code-review
  - security
---
You are a meticulous reviewer.

Be thorough.
''';

      final persona = loader.parsePersona(
        content,
        source: AgentPersonaSource.project,
        filePath: '/x/reviewer.md',
      );

      expect(persona.name, 'reviewer');
      expect(persona.description, 'Reviews pull requests');
      expect(persona.tools, const ['read', 'grep']);
      expect(persona.spawns, '*');
      expect(persona.models, const ['claude-sonnet']);
      expect(persona.model, 'claude-sonnet');
      expect(persona.thinkingLevel, 'high');
      expect(persona.blocking, isTrue);
      expect(persona.readSummarize, isFalse);
      expect(persona.autoloadSkills, const ['code-review', 'security']);
      expect(persona.source, AgentPersonaSource.project);
      expect(persona.filePath, '/x/reviewer.md');
      expect(persona.systemPrompt, contains('meticulous reviewer'));
      expect(persona.systemPrompt, contains('Be thorough.'));
    });

    test('applies defaults for omitted optional fields', () {
      const content = '''
---
name: minimal
description: Bare persona
---
Body.
''';

      final persona = loader.parsePersona(
        content,
        source: AgentPersonaSource.bundled,
      );

      expect(persona.tools, isEmpty);
      expect(persona.spawns, '');
      expect(persona.models, isEmpty);
      expect(persona.model, isNull);
      expect(persona.thinkingLevel, isNull);
      expect(persona.blocking, isFalse);
      expect(persona.readSummarize, isTrue);
      expect(persona.autoloadSkills, isEmpty);
    });

    test('accepts model as a single string', () {
      const content = '''
---
name: single
description: Single model
model: claude-opus
---
Body.
''';

      final persona = loader.parsePersona(
        content,
        source: AgentPersonaSource.bundled,
      );

      expect(persona.models, const ['claude-opus']);
      expect(persona.model, 'claude-opus');
    });

    test('accepts model as a list', () {
      const content = '''
---
name: multi
description: Multi model
model:
  - claude-opus
  - claude-sonnet
---
Body.
''';

      final persona = loader.parsePersona(
        content,
        source: AgentPersonaSource.bundled,
      );

      expect(persona.models, const ['claude-opus', 'claude-sonnet']);
      expect(persona.model, 'claude-opus');
    });

    test('throws when frontmatter is missing', () {
      const content = 'Just a body with no frontmatter.';

      expect(
        () => loader.parsePersona(content, source: AgentPersonaSource.bundled),
        throwsA(isA<PersonaParseException>()),
      );
    });

    test('throws when the name field is missing', () {
      const content = '''
---
description: No name here
---
Body.
''';

      expect(
        () => loader.parsePersona(content, source: AgentPersonaSource.bundled),
        throwsA(isA<PersonaParseException>()),
      );
    });

    test('throws when the description field is missing', () {
      const content = '''
---
name: nameonly
---
Body.
''';

      expect(
        () => loader.parsePersona(content, source: AgentPersonaSource.bundled),
        throwsA(isA<PersonaParseException>()),
      );
    });
  });

  group('discover', () {
    test('reads project personas tagged as project', () async {
      await writePersona(
        agentsDir(tempDir.path),
        'reviewer.md',
        '---\nname: reviewer\ndescription: Reviews\n---\nBody.\n',
      );

      final personas = await loader.discover(cwd: tempDir.path);

      expect(personas, hasLength(1));
      expect(personas.single.name, 'reviewer');
      expect(personas.single.source, AgentPersonaSource.project);
    });

    test('applies precedence project > user > bundled by name', () async {
      final projectRoot = Directory(
        '${tempDir.path}${Platform.pathSeparator}project',
      );
      final userRoot = Directory(
        '${tempDir.path}${Platform.pathSeparator}home',
      );

      // Same name "reviewer" in project and user; project must win.
      await writePersona(
        agentsDir(projectRoot.path),
        'reviewer.md',
        '---\nname: reviewer\ndescription: Project reviewer\n---\nProject.\n',
      );
      await writePersona(
        agentsDir(userRoot.path),
        'reviewer.md',
        '---\nname: reviewer\ndescription: User reviewer\n---\nUser.\n',
      );
      // A user-only persona that should also surface.
      await writePersona(
        agentsDir(userRoot.path),
        'librarian.md',
        '---\nname: librarian\ndescription: User librarian\n---\nUser.\n',
      );

      final bundled = [
        // Shadowed by both project and user.
        AgentPersona(name: 'reviewer', description: 'Bundled reviewer'),
        // Bundled-only persona that should surface.
        AgentPersona(name: 'oracle', description: 'Bundled oracle'),
      ];

      final personas = await loader.discover(
        cwd: projectRoot.path,
        home: userRoot.path,
        bundled: bundled,
      );

      final byName = {for (final p in personas) p.name: p};

      expect(byName.keys, containsAll(['reviewer', 'librarian', 'oracle']));
      expect(byName['reviewer']!.source, AgentPersonaSource.project);
      expect(byName['reviewer']!.description, 'Project reviewer');
      expect(byName['librarian']!.source, AgentPersonaSource.user);
      expect(byName['oracle']!.source, AgentPersonaSource.bundled);
    });

    test('dedups by name, keeping the highest-precedence persona', () async {
      final projectRoot = Directory(
        '${tempDir.path}${Platform.pathSeparator}p',
      );
      final userRoot = Directory('${tempDir.path}${Platform.pathSeparator}h');

      await writePersona(
        agentsDir(projectRoot.path),
        'dup.md',
        '---\nname: dup\ndescription: Project dup\n---\nP.\n',
      );
      await writePersona(
        agentsDir(userRoot.path),
        'dup.md',
        '---\nname: dup\ndescription: User dup\n---\nU.\n',
      );

      final personas = await loader.discover(
        cwd: projectRoot.path,
        home: userRoot.path,
      );

      expect(personas.where((p) => p.name == 'dup'), hasLength(1));
      expect(personas.single.source, AgentPersonaSource.project);
    });

    test('tolerates a missing .cc/agents directory', () async {
      final personas = await loader.discover(
        cwd: tempDir.path,
        home: '${tempDir.path}${Platform.pathSeparator}nonexistent',
      );

      expect(personas, isEmpty);
    });

    test('skips unparseable files and continues', () async {
      final dir = agentsDir(tempDir.path);
      await writePersona(
        dir,
        'good.md',
        '---\nname: good\ndescription: Valid\n---\nBody.\n',
      );
      await writePersona(dir, 'broken.md', 'no frontmatter here');

      final personas = await loader.discover(cwd: tempDir.path);

      expect(personas, hasLength(1));
      expect(personas.single.name, 'good');
    });

    test('visits files in sorted order for determinism', () async {
      final dir = agentsDir(tempDir.path);
      await writePersona(
        dir,
        'zeta.md',
        '---\nname: zeta\ndescription: Z\n---\nBody.\n',
      );
      await writePersona(
        dir,
        'alpha.md',
        '---\nname: alpha\ndescription: A\n---\nBody.\n',
      );

      final personas = await loader.discover(cwd: tempDir.path);

      expect(personas.map((p) => p.name).toList(), const ['alpha', 'zeta']);
    });
  });

  group('loadFromDir', () {
    test('returns an empty list for a missing directory', () async {
      final personas = await loader.loadFromDir(
        '${tempDir.path}${Platform.pathSeparator}missing',
        AgentPersonaSource.user,
      );

      expect(personas, isEmpty);
    });

    test('loads only .md files tagged with the given source', () async {
      final dir = '${tempDir.path}${Platform.pathSeparator}agents';
      await writePersona(
        dir,
        'a.md',
        '---\nname: a\ndescription: A\n---\nBody.\n',
      );
      await writePersona(dir, 'notes.txt', 'ignored');

      final personas = await loader.loadFromDir(dir, AgentPersonaSource.user);

      expect(personas, hasLength(1));
      expect(personas.single.name, 'a');
      expect(personas.single.source, AgentPersonaSource.user);
    });
  });
}
