import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_catalog.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_globals.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:test/test.dart';

ScriptToolDescriptor tool(
  String name, {
  String namespace = ScriptToolNamespace.builtin,
  String description = 'Does a thing.',
  String? resultNote,
  int properties = 1,
}) => ScriptToolDescriptor(
  name: name,
  namespace: namespace,
  description: description,
  resultNote: resultNote,
  inputSchema: {
    'type': 'object',
    'properties': {
      for (var i = 0; i < properties; i++)
        'argument_$i': {'type': 'string', 'description': 'Argument $i.'},
    },
    'required': ['argument_0'],
  },
);

List<ScriptToolDescriptor> surface() => [
  tool('read', resultNote: 'Text: numbered lines.'),
  tool('search', resultNote: '{matches: {path: string}[]}.'),
  tool('lsp', resultNote: 'Text: a symbol per line.'),
  for (var i = 0; i < 60; i++)
    tool(
      'cc_tool_$i',
      namespace: ScriptToolNamespace.controlCenter,
      properties: 6,
      description: 'Control Center tool number $i, which does something.',
    ),
];

const Set<String> direct = {'read', 'search', 'write'};

void main() {
  group('ReplToolDescription.build', () {
    test('the intro says what a script is, when to write one and how a call '
        'behaves, in that order', () {
      final intro = ReplToolDescription.intro;
      final what = intro.indexOf('JavaScript, run as the body of an async');
      final when = intro.indexOf('Write a script for many calls');
      final how = intro.indexOf('`await tools.<name>({...})` takes one');
      final lookUp = intro.indexOf('A tool that is not one of your direct');
      expect([what, when, how, lookUp], everyElement(isNonNegative));
      expect(what < when && when < how && how < lookUp, isTrue);
      expect(intro, contains('Never wrap one direct tool call in a script.'));
      // The limits a script cannot see coming otherwise, stated from
      // CodeModeLimits so they cannot drift.
      expect(
        intro,
        contains(
          'one of more than ${CodeModeLimits.maxNestedResultItems} values '
          'arrives as text',
        ),
      );
      expect(
        intro,
        contains(
          'Arguments hold at most ${CodeModeLimits.maxCallArgumentItems} '
          'values, a command '
          '${GuardDecision.maxActionNameBytes ~/ 1024} KiB',
        ),
      );
      for (final fact in [
        'Promise.allSettled',
        'one pending when the script returns may never run',
        'waits for the person',
        'Each script starts clean',
        '`store(key, v)`',
        'Plain JavaScript',
        'unless its exact call shape was already shown to you',
        'Never guess a name or an argument.',
        '`ALL_TOOLS`',
        '`describeNamespace(name)`',
      ]) {
        expect(intro, contains(fact));
      }
      // No declarations: the description names no tool of the catalog.
      expect(intro, isNot(contains('declare const tools')));
    });

    test('the script functions are listed from their table, objects once, '
        'with how to look one up', () {
      expect(
        ReplToolDescription.intro,
        contains(
          'Not tools: `text`, `image`, `store`, `load`, `sleep`, '
          '`setTimeout`, `clearTimeout`, `limits`, `exit`, `models.*` '
          "(more: `describeNamespace('script')`); `describeTool(name)` "
          'explains one.',
        ),
      );
      expect(ScriptGlobals.listedNames(), isNot(contains('models.embed')));
      // The description is pinned at its size: a global added later is
      // found through the pointer, not named here.
      for (final g in ScriptGlobals.all) {
        final listed = g.name.contains('.')
            ? '`${g.name.split('.').first}.*`'
            : '`${g.name}`';
        expect(
          ReplToolDescription.intro,
          g.listed ? contains(listed) : isNot(contains(listed)),
          reason: g.name,
        );
      }
    });

    test('lists the result note of each direct tool a script may call, in '
        'catalog order, and nothing for any other tool', () {
      final text = ReplToolDescription.build(
        ScriptCatalog(surface()),
        directToolNames: direct,
      );
      expect(
        text,
        contains(
          '${ReplToolDescription.directResultsHeading}\n'
          '- read: Text: numbered lines.\n'
          '- search: {matches: {path: string}[]}.\n\n',
        ),
      );
      // `lsp` has a note but is not direct; `write` is direct but not in
      // the catalog.
      expect(text, isNot(contains('- lsp:')));
      expect(text, isNot(contains('- write:')));
      expect(text, isNot(contains('cc_tool_')));
    });

    test('without direct tools there is no result section', () {
      final text = ReplToolDescription.build(ScriptCatalog(surface()));
      expect(text, isNot(contains(ReplToolDescription.directResultsHeading)));
    });

    test('counts the first-party namespaces from the catalog', () {
      final text = ReplToolDescription.build(
        ScriptCatalog(surface()),
        directToolNames: direct,
      );
      final builtin = ScriptToolNamespace
          .firstPartyDescriptions[ScriptToolNamespace.builtin]!;
      final cc = ScriptToolNamespace
          .firstPartyDescriptions[ScriptToolNamespace.controlCenter]!;
      expect(
        text,
        contains(
          '${ReplToolDescription.namespacesHeading}\n'
          '- builtin (3 tools): $builtin\n'
          '- control-center (60 tools): $cc\n'
          '${ReplToolDescription.externalToolsLine}\n\n'
          '${ReplToolDescription.sideEffectsLine}',
        ),
      );
      expect(text, endsWith(ReplToolDescription.sideEffectsLine));
      // A tool added to the registry is counted, with nobody editing text.
      final more = ReplToolDescription.build(
        ScriptCatalog([
          ...surface(),
          tool('cc_new', namespace: ScriptToolNamespace.controlCenter),
        ]),
        directToolNames: direct,
      );
      expect(more, contains('- control-center (61 tools): '));
    });

    test('is byte-identical for the same tools in any order', () {
      String build(Iterable<ScriptToolDescriptor> tools) =>
          ReplToolDescription.build(
            ScriptCatalog(tools),
            directToolNames: direct,
          );
      final forward = build(surface());
      expect(build(surface().reversed), forward);
      expect(build([...surface().skip(30), ...surface().take(30)]), forward);
    });

    test('is unchanged when an external server connects', () {
      final before = ReplToolDescription.build(
        ScriptCatalog(surface()),
        directToolNames: direct,
      );
      final after = ReplToolDescription.build(
        ScriptCatalog(
          [
            ...surface(),
            tool('mcp__github__list_issues', namespace: 'github'),
            tool(
              'mcp__github__create_pr',
              namespace: 'github',
              resultNote: 'JSON.',
            ),
          ],
          namespaceDescriptions: const {'github': 'GitHub.'},
        ),
        directToolNames: {...direct, 'mcp__github__create_pr'},
      );
      expect(after, before);
      expect(after, isNot(contains('github')));
      expect(after, contains(ReplToolDescription.externalToolsLine));
    });

    test('a note is one line', () {
      final text = ReplToolDescription.build(
        ScriptCatalog([tool('read', resultNote: 'Text:\n  numbered   lines.')]),
        directToolNames: direct,
      );
      expect(text, contains('- read: Text: numbered lines.\n'));
    });

    test('definitionBytes is the encoded name, description and schema', () {
      final text = ReplToolDescription.build(ScriptCatalog(surface()));
      expect(
        ReplToolDescription.definitionBytes(text),
        greaterThan(text.length),
      );
      expect(
        ReplToolDescription.definitionBytes('${text}x'),
        ReplToolDescription.definitionBytes(text) + 1,
      );
    });
  });

  group('ReplToolDescription.inputSchema', () {
    test('has code, the required description and the two clamped knobs', () {
      final schema = ReplToolDescription.inputSchema();
      final properties = schema['properties'] as Map<String, dynamic>;
      expect(properties.keys.toSet(), {
        'code',
        'description',
        'timeout_ms',
        'max_output_tokens',
      });
      expect(schema['required'], ['code', 'description']);
      expect((properties['timeout_ms'] as Map)['maximum'], 1500000);
      expect((properties['max_output_tokens'] as Map)['maximum'], 50000);
      expect(ReplToolDescription.inputSchema(), schema);
    });
  });

  group('ReplArguments.parse', () {
    test('reads a valid call', () {
      final a = ReplArguments.parse(const {
        'code': 'return 1',
        'description': ' Count things ',
        'timeout_ms': 5000,
        'max_output_tokens': 2000.0,
      });
      expect(a.error, isNull);
      expect(a.code, 'return 1');
      expect(a.description, 'Count things');
      expect(a.timeoutMs, 5000);
      expect(a.maxOutputTokens, 2000);
    });

    test('refuses missing code or description and non-integer knobs', () {
      expect(ReplArguments.parse(const {'description': 'x'}).error, isNotNull);
      expect(
        ReplArguments.parse(const {'code': ' ', 'description': 'x'}).error,
        isNotNull,
      );
      expect(
        ReplArguments.parse(const {'code': '1'}).error,
        'Missing or invalid argument: description',
      );
      expect(
        ReplArguments.parse(const {
          'code': '1',
          'description': 'x',
          'timeout_ms': '5s',
        }).error,
        isNotNull,
      );
      expect(
        ReplArguments.parse(const {
          'code': '1',
          'description': 'x',
          'max_output_tokens': 1.5,
        }).error,
        isNotNull,
      );
    });
  });
}
