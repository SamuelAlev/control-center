import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/services/json_schema_typescript.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_catalog.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_globals.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/mcp/domain/services/tool_index.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

ScriptToolDescriptor tool(
  String name, {
  String namespace = ScriptToolNamespace.builtin,
  String description = '',
  Map<String, dynamic>? input,
  Map<String, dynamic>? output,
  String? resultNote,
  ToolApprovalTier tier = ToolApprovalTier.read,
  Set<ActionClass> effects = const {},
}) => ScriptToolDescriptor(
  name: name,
  namespace: namespace,
  description: description,
  inputSchema:
      input ?? const {'type': 'object', 'properties': <String, dynamic>{}},
  outputSchema: output,
  resultNote: resultNote,
  tier: tier,
  effects: effects,
);

List<ScriptToolDescriptor> sample() => [
  tool(
    'search',
    description:
        'Search file contents with a regular expression, e.g. `foo.*bar`. '
        'Matches are ranked.',
    resultNote: '{matches: string[]}.',
    input: const {
      'type': 'object',
      'properties': {
        'pattern': {'type': 'string'},
        'path': {'type': 'string'},
      },
      'required': ['pattern'],
    },
  ),
  tool('read', description: 'Read a file from the worktree.'),
  tool(
    'bash',
    description: 'Run a shell command.',
    tier: ToolApprovalTier.exec,
    effects: const {ActionClass.processSpawn},
  ),
  tool(
    'create_ticket',
    namespace: ScriptToolNamespace.controlCenter,
    description: 'Create a ticket in the workspace tracker.',
    tier: ToolApprovalTier.write,
    effects: const {ActionClass.workspaceMutation},
  ),
  tool(
    'list_tickets',
    namespace: ScriptToolNamespace.controlCenter,
    description: 'List tickets with filters.',
  ),
  tool(
    'mcp__github__list-issues',
    namespace: 'github',
    description: 'List issues in a GitHub repository.',
  ),
  tool('class', description: 'A tool with a reserved name.'),
];

void main() {
  group('ScriptCatalog', () {
    test('orders entries by namespace then name, whatever the input order', () {
      final a = ScriptCatalog(sample());
      final b = ScriptCatalog(sample().reversed);
      final names = [for (final e in a.entries) '${e.namespace}/${e.name}'];
      expect(names, [
        'builtin/bash',
        'builtin/class',
        'builtin/read',
        'builtin/search',
        'control-center/create_ticket',
        'control-center/list_tickets',
        'github/mcp__github__list-issues',
      ]);
      expect(
        [for (final e in b.entries) e.name],
        [for (final e in a.entries) e.name],
      );
    });

    test('maps unsafe names to identifiers and finds by either', () {
      final c = ScriptCatalog(sample());
      expect(c.find('class')!.id, '_class');
      expect(c.find('_class')!.name, 'class');
      expect(
        c.find('mcp__github__list-issues')!.id,
        'mcp__github__list_issues',
      );
      expect(
        c.find('mcp__github__list_issues')!.name,
        'mcp__github__list-issues',
      );
      expect(c.find('nope'), isNull);
    });

    test('refuses duplicate names', () {
      expect(
        () => ScriptCatalog([tool('read'), tool('read')]),
        throwsArgumentError,
      );
    });

    test('namespaces carry counts and descriptions', () {
      final c = ScriptCatalog(
        sample(),
        namespaceDescriptions: const {'github': 'GitHub issues and PRs.'},
      );
      expect(
        [for (final n in c.namespaces) n.toJson()],
        [
          {
            'name': 'builtin',
            'description':
                ScriptToolNamespace.firstPartyDescriptions['builtin'],
            'toolCount': 4,
          },
          {
            'name': 'control-center',
            'description':
                ScriptToolNamespace.firstPartyDescriptions['control-center'],
            'toolCount': 2,
          },
          {
            'name': 'github',
            'description': 'GitHub issues and PRs.',
            'toolCount': 1,
          },
        ],
      );
    });

    test('ALL_TOOLS lists id, name, namespace and description', () {
      final all = ScriptCatalog(sample()).allTools();
      expect(all.first, {
        'id': 'bash',
        'name': 'bash',
        'namespace': 'builtin',
        'description': 'Run a shell command.',
      });
      expect(all, hasLength(7));
      expect(() => jsonEncode(all), returnsNormally);
    });

    test('describeTool returns the declaration, schemas, tier and effects', () {
      final c = ScriptCatalog(sample());
      final answer = c.describeTool('create_ticket');
      expect(answer.ok, isTrue);
      final json = answer.toJson()! as Map<String, Object?>;
      expect(json.keys, [
        'id',
        'name',
        'namespace',
        'description',
        'declaration',
        'inputSchema',
        'outputSchema',
        'resultNote',
        'tier',
        'effects',
      ]);
      expect(json['resultNote'], isNull);
      expect(
        (c.describeTool('search').toJson()! as Map)['resultNote'],
        '{matches: string[]}.',
      );
      expect(json['tier'], 'write');
      expect(json['effects'], ['workspaceMutation']);
      expect(json['outputSchema'], isNull);
      expect(
        json['declaration'],
        'declare const tools: { create_ticket(args?: {}): Promise<unknown>; };',
      );
      expect(() => jsonEncode(json), returnsNormally);
      // By identifier as well.
      expect(c.describeTool('_class').ok, isTrue);
    });

    test('an unknown tool answers with the closest names', () {
      final c = ScriptCatalog(sample());
      final answer = c.describeTool('serch');
      expect(answer.ok, isFalse);
      final unknown = answer as ScriptCatalogUnknown;
      expect(unknown.didYouMean.first, 'search');
      expect(
        unknown.message,
        startsWith('Unknown tool "serch". Did you mean: '),
      );
      expect(() => jsonEncode(unknown.toJson()), returnsNormally);
    });

    test('did you mean finds a misspelled identifier and words', () {
      final c = ScriptCatalog(sample());
      expect(c.suggestTools('list_ticket'), contains('list_tickets'));
      expect(c.suggestTools('create ticket'), contains('create_ticket'));
      expect(
        c.suggestTools('mcp__github__list_issue').first,
        'mcp__github__list_issues',
      );
      expect(c.suggestTools(''), isEmpty);
      expect(c.suggestTools('zzzzzzzzzzzz'), isEmpty);
      final none = c.describeTool('zzzzzzzzzzzz') as ScriptCatalogUnknown;
      expect(none.message, contains('searchTools'));
    });

    test('describeNamespace lists its tools or suggests names', () {
      final c = ScriptCatalog(sample());
      final found = c.describeNamespace('control-center');
      expect(found.ok, isTrue);
      final json = found.toJson()! as Map<String, Object?>;
      expect(json['name'], 'control-center');
      expect((json['tools']! as List).length, 2);
      final unknown = c.describeNamespace('githb') as ScriptCatalogUnknown;
      expect(unknown.didYouMean, ['github']);
    });

    test('searchTools ranks with BM25 and filters by namespace', () {
      final c = ScriptCatalog(sample());
      final hits = c.searchTools('ticket tickets');
      expect(hits, isNotEmpty);
      expect(
        hits.map((h) => h['name']).toSet(),
        containsAll(['create_ticket', 'list_tickets']),
      );
      expect(hits.first.keys, [
        'id',
        'name',
        'namespace',
        'summary',
        'signature',
        'score',
      ]);
      expect(
        c.searchTools('issues', namespace: 'github').single['name'],
        'mcp__github__list-issues',
      );
      expect(c.searchTools('ticket', namespace: 'builtin'), isEmpty);
      expect(c.searchTools('ticket', namespace: 'nope'), isEmpty);
      expect(c.searchTools(''), isEmpty);
      expect(c.searchTools('ticket', limit: 1), hasLength(1));
      // Argument names are indexed too.
      expect(c.searchTools('pattern').first['name'], 'search');
    });

    test('a hit carries the first sentence and a one-line signature', () {
      final c = ScriptCatalog(sample());
      final hit = c.searchTools('pattern').first;
      expect(
        hit['summary'],
        'Search file contents with a regular expression, e.g. `foo.*bar`.',
      );
      expect(
        hit['signature'],
        'search(args: { path?: string; pattern: string; })',
      );
      expect(ScriptCatalog.summaryOf('One.\n\nTwo.'), 'One.');
      expect(ScriptCatalog.summaryOf('No stop'), 'No stop');
      final long = ScriptCatalog.summaryOf('x' * 500);
      expect(long, hasLength(ScriptCatalog.maxSummaryChars));
      expect(long, endsWith('…'));
    });

    test('a long argument type signs with the argument names', () {
      final wide = tool(
        'wide',
        input: {
          'type': 'object',
          'properties': {
            for (var i = 0; i < 20; i++)
              'argument_number_$i': {
                'type': 'string',
                'description': 'Not shown in a signature.',
              },
          },
          'required': ['argument_number_0'],
        },
      );
      final c = ScriptCatalog([wide]);
      final signature = c.signatureOf(c.entries.single);
      expect(signature, startsWith('wide(args: { argument_number_0, '));
      expect(signature, contains('argument_number_1?'));
      expect(signature, isNot(contains('Not shown')));
      expect(signature, isNot(contains('\n')));
    });

    test('searchTools clamps its limit', () {
      final many = [
        for (var i = 0; i < 80; i++)
          tool('ticket_tool_$i', description: 'ticket'),
      ];
      final c = ScriptCatalog(many);
      expect(c.searchTools('ticket', limit: 1000), hasLength(50));
      expect(c.searchTools('ticket', limit: 0), hasLength(1));
    });
  });

  group('the script\'s own functions', () {
    test('describeTool answers a global as one, never as a tool', () {
      final c = ScriptCatalog(sample());
      final store = c.describeTool('store').toJson()! as Map<String, Object?>;
      expect(store, {
        'kind': 'global',
        'name': 'store',
        'namespace': 'script',
        'call': 'store(key, value)',
        'summary': ScriptGlobals.byName('store')!.summary,
        'signature': 'store(key: string, value: unknown): void',
        'returns': ScriptGlobals.byName('store')!.returns,
      });
      expect(store, isNot(contains('id')));
      expect(store, isNot(contains('tier')));
      final models = c.describeTool('models').toJson()! as Map<String, Object?>;
      expect(models['kind'], 'global');
      expect(models['namespace'], 'script');
      expect(
        [for (final m in models['members']! as List) (m as Map)['name']],
        ['models.embed', 'models.rank', 'models.classify'],
      );
      expect(
        (c.describeTool('models.rank').toJson()! as Map)['call'],
        'await models.rank(query, candidates, { top })',
      );
      // Not a prefix match: `mod` is no global.
      expect(c.describeTool('mod').ok, isFalse);
      expect(() => jsonEncode(models), returnsNormally);
    });

    test('a tool of the same name wins', () {
      final c = ScriptCatalog([
        tool('store', namespace: 'shop', description: 'Opens a store.'),
      ]);
      final answer = c.describeTool('store').toJson()! as Map<String, Object?>;
      expect(answer['id'], 'store');
      expect(answer['namespace'], 'shop');
      expect(answer, isNot(contains('kind')));
      // Search still finds both, each for what it is.
      final hits = c.searchTools('store keep value key opens', limit: 10);
      expect(
        hits.map((h) => (h['name'], h['namespace'])),
        containsAll([('store', 'shop'), ('store', 'script')]),
      );
    });

    test('searchTools ranks globals with the tools, with the call form as '
        'the signature and no id', () {
      final c = ScriptCatalog(sample());
      final hit = c
          .searchTools('wait milliseconds')
          .firstWhere((h) => h['namespace'] == 'script');
      expect(hit['name'], 'sleep');
      expect(hit['kind'], 'global');
      expect(hit['signature'], 'await sleep(ms)');
      expect(hit, isNot(contains('id')));
      // A namespace filter keeps only its own: `script` only globals,
      // another namespace none of them.
      expect(
        c.searchTools('embed texts', namespace: 'script').map((h) => h['name']),
        contains('models.embed'),
      );
      expect(
        c.searchTools('embed texts', namespace: 'builtin'),
        everyElement(isNot(containsPair('namespace', 'script'))),
      );
      // Suggestions are tools only.
      expect(c.suggestTools('sleep'), isNot(contains('sleep')));
    });

    test('ALL_TOOLS, namespaces and counts stay tools only; '
        'describeNamespace("script") lists the globals', () {
      final c = ScriptCatalog(sample());
      final names = {for (final g in ScriptGlobals.all) g.name};
      expect(
        c.allTools().map((t) => t['name']),
        everyElement(isNot(isIn(names))),
      );
      expect(c.namespaces.map((n) => n.name), isNot(contains('script')));
      expect(c.length, sample().length);
      final script =
          c.describeNamespace('script').toJson()! as Map<String, Object?>;
      expect(script['kind'], 'global');
      expect(
        [for (final g in script['globals']! as List) (g as Map)['name']],
        [for (final g in ScriptGlobals.all) g.name],
      );
      expect(script, isNot(contains('tools')));
      // No tool can be in that namespace (an external server named
      // `script` is `external-script`), so nothing shadows the globals.
    });
  });

  test('no tool is in the script namespace; external servers never take a '
      'reserved one', () {
    expect(
      () => tool('x', namespace: ScriptToolNamespace.script),
      throwsArgumentError,
    );
    for (final reserved in ScriptToolNamespace.reserved) {
      final ns = ScriptToolNamespace.external(reserved);
      expect(ns, 'external-$reserved');
      expect(ScriptToolNamespace.isExternal(ns), isTrue);
    }
    expect(ScriptToolNamespace.external('external-x'), 'external-external-x');
    expect(ScriptToolNamespace.external('github'), 'github');
  });

  test('a server that only looks reserved is prefixed too, and no two names '
      'share a namespace', () {
    const lookAlikes = [
      'Control-Center',
      'CONTROL-CENTER',
      'BUILTIN',
      'Builtin',
      ' script ',
      'Script',
      '\tbuiltin\n',
      'External-x',
      'EXTERNAL-builtin',
      ' external-y',
    ];
    for (final name in lookAlikes) {
      expect(
        ScriptToolNamespace.external(name),
        'external-$name',
        reason: name,
      );
    }
    // Names that stay as they are: not reserved, whatever their case.
    for (final name in ['github', 'Linear', 'control_center', 'externals']) {
      expect(ScriptToolNamespace.external(name), name);
    }
    // Injective over every variant and every name one prefix away from it.
    final names = <String>{
      ...lookAlikes,
      ...ScriptToolNamespace.reserved,
      'github',
      'control_center',
      'externals',
      for (final name in [...lookAlikes, ...ScriptToolNamespace.reserved])
        'external-$name',
      for (final name in [...lookAlikes, ...ScriptToolNamespace.reserved])
        'External-$name',
    };
    final namespaces = <String, String>{};
    for (final name in names) {
      final ns = ScriptToolNamespace.external(name);
      expect(namespaces[ns], isNull, reason: '$name and ${namespaces[ns]}');
      namespaces[ns] = name;
      expect(ScriptToolNamespace.isExternal(ns), isTrue, reason: name);
    }
  });

  group('ALL_TOOLS is bounded whatever the catalog', () {
    test('a small catalog keeps every description whole', () {
      final tools = [
        for (var i = 0; i < 170; i++)
          tool('tool_$i', description: 'Ticket tool $i. ${'x' * 2048}'),
      ];
      final all = {
        for (final entry in ScriptCatalog(tools).allTools())
          entry['name']: entry['description'],
      };
      for (final t in tools) {
        expect(all[t.name], t.description, reason: t.name);
      }
    });

    test('a large catalog shares the total equally and cuts with …', () {
      const count = 2000;
      final share = ScriptCatalog.allToolsShare(count);
      final tools = [
        for (var i = 0; i < count; i++)
          tool(
            'mcp__srv__tool_$i',
            namespace: 'srv',
            description: '${'d' * 2048} $i',
          ),
      ];
      final catalog = ScriptCatalog(tools);
      final all = catalog.allTools();
      var units = 0;
      final byName = {for (final entry in all) entry['name']: entry};
      // Every position in the catalog gets the same share.
      for (final entry in [all.first, all[1], all[count ~/ 2], all.last]) {
        expect(
          (entry['description']! as String).length,
          share,
          reason: '${entry['name']}',
        );
      }
      for (final i in [0, 1, count ~/ 2, count - 1]) {
        final entry = byName['mcp__srv__tool_$i']!;
        final description = entry['description']! as String;
        expect(description.length, share, reason: '$i');
        expect(description, endsWith('…'));
        // The rest of the entry is whole.
        expect(entry['name'], 'mcp__srv__tool_$i');
        expect(entry['namespace'], 'srv');
        expect(entry['id'], isNotEmpty);
      }
      for (final entry in all) {
        units += (entry['description']! as String).length;
      }
      expect(
        units,
        lessThanOrEqualTo(ScriptCatalog.maxAllToolsDescriptionUnits),
      );
      // describeTool still has the whole description.
      final described =
          catalog.describeTool('mcp__srv__tool_7').toJson()! as Map;
      expect(described['description'], tools[7].description);
    });

    test('a cut never splits a surrogate pair', () {
      expect(ScriptCatalog.cutTo('ab😀cd', 4), 'ab…');
      expect(ScriptCatalog.cutTo('abc😀d', 4), 'abc…');
      expect(ScriptCatalog.cutTo('abcd', 4), 'abcd');
      expect(ScriptCatalog.cutTo('abcd', 0), '');
    });
  });

  test('the globals are found in a catalog of 5,000 tools', () {
    final tools = [
      for (var i = 0; i < 5000; i++)
        tool('tool_$i', description: 'Ticket tool $i. ${'word ' * 400}'),
    ];
    final hits = ScriptCatalog(tools).searchTools('store');
    expect(
      hits.any((h) => h['kind'] == ScriptGlobals.kind && h['name'] == 'store'),
      isTrue,
    );
  });

  group('lookups are bounded whatever the input', () {
    ScriptToolDescriptor enumTool(int n) => tool(
      'mcp__big__pick',
      namespace: 'big',
      description: 'Pick a ticket kind.',
      input: {
        'type': 'object',
        'properties': {
          'kind': {
            'type': 'string',
            'enum': [for (var i = 0; i < n; i++) 'value_$i'],
          },
        },
        'required': ['kind'],
      },
    );

    test('two scripts with the same tool set build one index; a changed '
        'set builds a new one', () {
      List<ScriptToolDescriptor> tools(String extra) => [
        for (var i = 0; i < 50; i++)
          tool('tool_$i', description: 'Ticket tool $i. $extra'),
      ];
      final before = ToolIndex.builds;
      // Each script builds its own catalog from fresh descriptors.
      ScriptCatalog(tools('same')).searchTools('ticket');
      ScriptCatalog(tools('same')).searchTools('ticket');
      ScriptCatalog(tools('same')).describeTool('tool_1x');
      expect(ToolIndex.builds, before + 1);
      ScriptCatalog(tools('changed')).searchTools('ticket');
      expect(ToolIndex.builds, before + 2);
    });

    test('a signature and a declaration are rendered once per catalog', () {
      final c = ScriptCatalog(sample());
      final entry = c.entries.first;
      expect(c.signatureOf(entry), same(c.signatureOf(entry)));
      expect(c.declarationOf(entry), same(c.declarationOf(entry)));
    });

    test('a 64,000-value enum is truncated, by the budget, in every '
        'answer', () {
      final c = ScriptCatalog([enumTool(64000)]);
      final stopwatch = Stopwatch()..start();
      final hit = c.searchTools('ticket').single;
      expect(hit['signature'], 'mcp__big__pick(args: { kind })');
      final described =
          c.describeTool('mcp__big__pick').toJson()! as Map<String, Object?>;
      expect(
        described['declaration'],
        contains(JsonSchemaTypeScript.truncated),
      );
      for (var i = 0; i < 20; i++) {
        c.searchTools('ticket');
      }
      // 6.4 s per hit before; loose.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });

    test('an unknown name of 1 MiB is answered from names alone, and '
        'echoed cut', () {
      final c = ScriptCatalog([
        for (var i = 0; i < 200; i++)
          tool('tool_$i', description: 'Ticket tool $i.'),
      ]);
      final name = List.generate(130000, (i) => 'zq$i').join(' ');
      final stopwatch = Stopwatch()..start();
      final answer = c.describeTool(name) as ScriptCatalogUnknown;
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
      expect(answer.echoed.length, ScriptCatalogUnknown.maxEchoChars + 1);
      expect(answer.message.length, lessThan(1000));
      expect((answer.toJson()! as Map)['requested'], answer.echoed);
      // Names only: a word of a description suggests nothing.
      expect(c.suggestTools('ticket'), isEmpty);
      expect(c.suggestTools('tool_1x'), contains('tool_1'));
    });

    test('a 1 MiB search over 200 tools is cheap', () {
      final c = ScriptCatalog([
        for (var i = 0; i < 200; i++)
          tool('tool_$i', description: 'Ticket tool $i.'),
      ]);
      c.searchTools('ticket');
      final query = List.generate(130000, (i) => 'zq$i').join(' ');
      final stopwatch = Stopwatch()..start();
      c.searchTools(query, limit: 50);
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
    });
  });
}
