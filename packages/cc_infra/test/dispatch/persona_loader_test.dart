import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/persona/agent_persona.dart';
import 'package:cc_infra/src/dispatch/persona_loader.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [PersonaLoader]: YAML frontmatter parsing, field normalization
/// (list/scalar model field, string→bool coercion), error paths and on-disk
/// discovery (precedence + dedup, tolerant of malformed files).
void main() {
  const loader = PersonaLoader();
  const source = AgentPersonaSource.project;

  group('parsePersona — happy paths', () {
    test('parses a minimal persona with name + description', () {
      const content = '''
---
name: reviewer
description: Reviews PRs
---
You are a careful reviewer.
''';
      final persona = loader.parsePersona(content, source: source);
      expect(persona.name, 'reviewer');
      expect(persona.description, 'Reviews PRs');
      expect(persona.systemPrompt, 'You are a careful reviewer.');
      expect(persona.tools, isEmpty);
      expect(persona.models, isEmpty);
      expect(persona.spawns, '');
      expect(persona.blocking, isFalse);
      expect(persona.readSummarize, isTrue); // default
      expect(persona.source, source);
    });

    test('model accepts a single string and normalizes into models list', () {
      const content = '''
---
name: a
description: d
model: claude-sonnet
---
body
''';
      final persona = loader.parsePersona(content, source: source);
      expect(persona.models, ['claude-sonnet']);
    });

    test('model accepts a list and drops empty entries', () {
      const content = '''
---
name: a
description: d
model:
  - claude-sonnet
  - ""
  - gpt-4o
---
body
''';
      final persona = loader.parsePersona(content, source: source);
      expect(persona.models, ['claude-sonnet', 'gpt-4o']);
    });

    test('tools accepts a list and a single string scalar', () {
      final listPersona = loader.parsePersona('''
---
name: a
description: d
tools:
  - read
  - write
---
body
''', source: source);
      expect(listPersona.tools, ['read', 'write']);

      final scalarPersona = loader.parsePersona('''
---
name: a
description: d
tools: bash
---
body
''', source: source);
      expect(scalarPersona.tools, ['bash']);
    });

    test('autoloadSkills accepts a list', () {
      const content = '''
---
name: a
description: d
autoloadSkills:
  - git
  - review
---
body
''';
      final persona = loader.parsePersona(content, source: source);
      expect(persona.autoloadSkills, ['git', 'review']);
    });

    test('blocking / readSummarize parse bool and string bool forms', () {
      const content = '''
---
name: a
description: d
blocking: true
readSummarize: "false"
---
body
''';
      final persona = loader.parsePersona(content, source: source);
      expect(persona.blocking, isTrue);
      expect(persona.readSummarize, isFalse);
    });

    test('blocking/readSummarize fall back to defaults when absent', () {
      const content = '''
---
name: a
description: d
---
body
''';
      final persona = loader.parsePersona(content, source: source);
      expect(persona.blocking, isFalse);
      expect(persona.readSummarize, isTrue);
    });

    test('spawns and thinkingLevel parse as scalar strings', () {
      const content = '''
---
name: a
description: d
spawns: reviewer
thinkingLevel: high
---
body
''';
      final persona = loader.parsePersona(content, source: source);
      expect(persona.spawns, 'reviewer');
      expect(persona.thinkingLevel, 'high');
    });
  });

  group('parsePersona — error paths', () {
    test('throws when leading fence is missing', () {
      expect(
        () => loader.parsePersona('no frontmatter', source: source),
        throwsA(isA<PersonaParseException>()),
      );
    });

    test('throws when closing fence is missing', () {
      expect(
        () => loader.parsePersona(
          '---\nname: a\ndescription: d\n',
          source: source,
        ),
        throwsA(isA<PersonaParseException>()),
      );
    });

    test('throws when name is missing', () {
      const content = '''
---
description: d
---
body
''';
      expect(
        () => loader.parsePersona(content, source: source),
        throwsA(isA<PersonaParseException>()),
      );
    });

    test('throws when name is empty', () {
      const content = '''
---
name: ""
description: d
---
body
''';
      expect(
        () => loader.parsePersona(content, source: source),
        throwsA(isA<PersonaParseException>()),
      );
    });

    test('throws when description is missing', () {
      const content = '''
---
name: a
---
body
''';
      expect(
        () => loader.parsePersona(content, source: source),
        throwsA(isA<PersonaParseException>()),
      );
    });

    test('throws when frontmatter is a scalar, not a mapping', () {
      const content = '''
---
just-a-string
---
body
''';
      expect(
        () => loader.parsePersona(content, source: source),
        throwsA(isA<PersonaParseException>()),
      );
    });

    test('PersonaParseException includes filePath when provided', () {
      try {
        loader.parsePersona(
          'no frontmatter',
          source: source,
          filePath: '/tmp/x.md',
        );
        fail('expected throw');
      } on PersonaParseException catch (e) {
        expect(e.filePath, '/tmp/x.md');
        expect('$e', contains('/tmp/x.md'));
      }
    });

    test('PersonaParseException.toString omits filePath when null', () {
      const e = PersonaParseException('boom');
      expect('$e', 'PersonaParseException: boom');
    });
  });

  group('discover — on-disk precedence + dedup', () {
    late Directory tempRoot;
    late Directory projectAgentsDir;
    late Directory userAgentsDir;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('persona_loader_test_');
      final projectDir = Directory(p.join(tempRoot.path, 'project'))
        ..createSync();
      final userDir = Directory(p.join(tempRoot.path, 'home'))..createSync();
      projectAgentsDir = Directory(p.join(projectDir.path, '.cc', 'agents'))
        ..createSync(recursive: true);
      userAgentsDir = Directory(p.join(userDir.path, '.cc', 'agents'))
        ..createSync(recursive: true);
    });

    tearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    File writePersona(Directory dir, String name, {String? custom}) {
      final f = File(p.join(dir.path, '$name.md'));
      f.writeAsStringSync(
        custom ??
            '''
---
name: $name
description: $name persona
---
body for $name
''',
      );
      return f;
    }

    test('returns empty when no agent dirs exist', () async {
      final out = await loader.discover(
        cwd: p.join(tempRoot.path, 'empty-project'),
        home: p.join(tempRoot.path, 'empty-home'),
      );
      expect(out, isEmpty);
    });

    test('reads personas from project then home then bundled', () async {
      writePersona(projectAgentsDir, 'alpha');
      writePersona(userAgentsDir, 'beta');
      final out = await loader.discover(
        cwd: projectAgentsDir.parent.parent.path,
        home: userAgentsDir.parent.parent.path,
        bundled: [AgentPersona(name: 'gamma', description: 'bundled')],
      );
      expect(out.map((p) => p.name).toSet(), {'alpha', 'beta', 'gamma'});
      expect(
        out.firstWhere((p) => p.name == 'alpha').source,
        AgentPersonaSource.project,
      );
      expect(
        out.firstWhere((p) => p.name == 'beta').source,
        AgentPersonaSource.user,
      );
      expect(
        out.firstWhere((p) => p.name == 'gamma').source,
        AgentPersonaSource.bundled,
      );
    });

    test('project shadows same-named user persona (first-wins)', () async {
      writePersona(
        projectAgentsDir,
        'shared',
        custom: '''
---
name: shared
description: from project
---
project body
''',
      );
      writePersona(
        userAgentsDir,
        'shared',
        custom: '''
---
name: shared
description: from user
---
user body
''',
      );
      final out = await loader.discover(
        cwd: projectAgentsDir.parent.parent.path,
        home: userAgentsDir.parent.parent.path,
      );
      expect(out.single.name, 'shared');
      expect(out.single.description, 'from project');
      expect(out.single.source, AgentPersonaSource.project);
    });

    test('skips unparseable files but keeps good ones', () async {
      writePersona(projectAgentsDir, 'good');
      File(
        p.join(projectAgentsDir.path, 'broken.md'),
      ).writeAsStringSync('not valid frontmatter at all');
      final out = await loader.discover(
        cwd: projectAgentsDir.parent.parent.path,
        home: p.join(tempRoot.path, 'no-home'),
      );
      expect(out.map((p) => p.name).toList(), ['good']);
    });

    test('only *.md files are read', () async {
      writePersona(projectAgentsDir, 'good');
      File(p.join(projectAgentsDir.path, 'notes.txt')).writeAsStringSync('''
---
name: ignored
description: should not load
---
''');
      final out = await loader.discover(
        cwd: projectAgentsDir.parent.parent.path,
        home: p.join(tempRoot.path, 'no-home'),
      );
      expect(out.map((p) => p.name).toList(), ['good']);
    });

    test('loadFromDir returns empty for a missing directory', () async {
      final out = await loader.loadFromDir(
        p.join(tempRoot.path, 'does-not-exist'),
        AgentPersonaSource.user,
      );
      expect(out, isEmpty);
    });

    test('loadFromDir visits files in sorted order', () async {
      // Write out of order.
      writePersona(projectAgentsDir, 'zebra');
      writePersona(projectAgentsDir, 'apple');
      writePersona(projectAgentsDir, 'mango');
      final out = await loader.loadFromDir(
        projectAgentsDir.path,
        AgentPersonaSource.project,
      );
      expect(out.map((p) => p.name).toList(), ['apple', 'mango', 'zebra']);
    });
  });
}
