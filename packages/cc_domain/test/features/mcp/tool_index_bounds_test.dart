import 'dart:math' as math;

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/tool_index.dart';
import 'package:test/test.dart';

ToolDef _def(String name, String description, [List<String> keys = const []]) =>
    ToolDef(
      name: name,
      description: description,
      inputSchema: {
        'type': 'object',
        'properties': {for (final k in keys) k: <String, dynamic>{}},
      },
    );

/// [n] tools whose descriptions are [chars] characters of varied words.
List<ToolDef> _tools(int n, int chars) => [
  for (var i = 0; i < n; i++)
    _def('mcp__srv${i % 20}__tool_$i', _text(i, chars), ['path', 'limit']),
];

String _text(int seed, int chars) {
  const words = ['ticket', 'deploy', 'query', 'report', 'issue', 'build'];
  final b = StringBuffer('Tool $seed does things. ');
  var k = seed;
  while (b.length < chars) {
    b.write('${words[k % words.length]}${k % 97} ');
    k = (k * 31 + 7) & 0xffff;
  }
  return b.toString().substring(0, chars);
}

void main() {
  group('what a query costs is bounded', () {
    final index = ToolIndex.build([
      ..._tools(200, 2000),
      _def('find_ticket', 'Find a ticket by its title.'),
    ]);

    test('only the first ${ToolIndex.maxQueryChars} characters are read', () {
      final padded = '${'zz ' * (ToolIndex.maxQueryChars ~/ 3)} ticket';
      expect(ToolIndex.boundQuery(padded), hasLength(ToolIndex.maxQueryChars));
      expect(
        index.search(padded).map((h) => h.name),
        isNot(contains('find_ticket')),
      );
      expect(index.search('find ticket').first.name, 'find_ticket');
    });

    test('only the first ${ToolIndex.maxQueryTerms} distinct terms count', () {
      final filler = [for (var i = 0; i < ToolIndex.maxQueryTerms; i++) 'q$i'];
      expect(
        index.search('${filler.join(' ')} find').map((h) => h.name),
        isNot(contains('find_ticket')),
      );
      expect(
        index.search('find ${filler.join(' ')}').first.name,
        'find_ticket',
      );
    });

    test('a term longer than ${ToolIndex.maxTermChars} characters is '
        'dropped', () {
      final long = 'a' * (ToolIndex.maxTermChars + 1);
      final withLong = ToolIndex.build([_def('t', 'see $long here')]);
      expect(withLong.search(long), isEmpty);
      expect(withLong.search('here').single.name, 't');
    });

    test('a 1 MiB query over 200 tools is cheap', () {
      final query = List.generate(130000, (i) => 'zq$i').join(' ');
      expect(query.length, greaterThan(1000000));
      final stopwatch = Stopwatch()..start();
      index.search(query, limit: 50);
      // Bounded by the term cap, not the clock (918 ms before); loose.
      expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 500)));
    });
  });

  group('what one tool contributes is bounded', () {
    test('a description is indexed and kept up to '
        '${ToolIndex.maxIndexedDescriptionChars} characters', () {
      final tail = 'marker${'x' * 3}';
      final description =
          '${'word ' * (ToolIndex.maxIndexedDescriptionChars ~/ 5)}$tail';
      final index = ToolIndex.build([_def('big', description)]);
      expect(
        index.search('word').single.description.length,
        ToolIndex.maxIndexedDescriptionChars,
      );
      expect(index.search(tail), isEmpty);
    });

    test('at most ${ToolIndex.maxSchemaKeys} argument names, none longer '
        'than a term', () {
      final keys = [
        for (var i = 0; i < 100; i++) 'k${i.toString().padLeft(3, '0')}',
        'k' * (ToolIndex.maxTermChars + 1),
      ];
      final hit = ToolIndex.build([
        _def('many', 'Many args.', keys),
      ]).search('many').single;
      expect(hit.schemaKeys, hasLength(ToolIndex.maxSchemaKeys));
      expect(hit.schemaKeys.first, 'k000');
    });

    test('2,000 tools with 64 KiB descriptions build once and search fast', () {
      final tools = _tools(2000, 64 * 1024);
      final stopwatch = Stopwatch()..start();
      final index = ToolIndex.build(tools);
      final built = stopwatch.elapsed;
      stopwatch.reset();
      final hits = index.search('ticket deploy issue', limit: 25);
      expect(hits, isNotEmpty);
      expect(
        hits.every(
          (h) => h.description.length <= ToolIndex.maxIndexedDescriptionChars,
        ),
        isTrue,
      );
      // Loose: bounds, not the clock, are the contract.
      expect(built, lessThan(const Duration(seconds: 20)));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });
  });

  group('a shared index', () {
    List<ToolDef> set(String description) => [
      _def('read_file', 'Read a file.', ['path']),
      _def('find_ticket', description, ['title']),
    ];

    test('is built once for the same content, whatever the objects', () {
      final before = ToolIndex.builds;
      final first = ToolIndex.shared(set('Find a ticket by title. ${before}a'));
      final second = ToolIndex.shared(
        set('Find a ticket by title. ${before}a'),
      );
      expect(ToolIndex.builds, before + 1);
      expect(second, same(first));
    });

    test('a changed set gets a new index', () {
      final before = ToolIndex.builds;
      final first = ToolIndex.shared(set('Find a ticket. ${before}b'));
      final changed = ToolIndex.shared(
        set('Find a ticket, changed. ${before}b'),
      );
      expect(ToolIndex.builds, before + 2);
      expect(changed, isNot(same(first)));
      expect(changed.search('changed').single.name, 'find_ticket');
      expect(first.search('changed'), isEmpty);
    });

    test('keeps at most ${ToolIndex.maxSharedIndexes}, least recently used '
        'out', () {
      final before = ToolIndex.builds;
      final sets = [
        for (var i = 0; i <= ToolIndex.maxSharedIndexes; i++)
          set('Distinct $before c$i.'),
      ];
      for (final s in sets) {
        ToolIndex.shared(s);
      }
      expect(ToolIndex.builds, before + sets.length);
      // The newest is still there; the oldest was dropped and is rebuilt.
      ToolIndex.shared(sets.last);
      expect(ToolIndex.builds, before + sets.length);
      ToolIndex.shared(sets.first);
      expect(ToolIndex.builds, before + sets.length + 1);
    });
  });

  group('one index holds a bounded total', () {
    test('the share is equal, and whole for a small catalog', () {
      expect(ToolIndex.shareFor(1), ToolIndex.maxToolUnits);
      expect(
        ToolIndex.shareFor(ToolIndex.maxIndexedUnits ~/ ToolIndex.maxToolUnits),
        ToolIndex.maxToolUnits,
      );
      expect(ToolIndex.shareFor(2000), ToolIndex.maxIndexedUnits ~/ 2000);
      expect(ToolIndex.shareFor(ToolIndex.maxIndexedUnits + 1), 0);
    });

    test('random catalogs never exceed the total, nor a tool its share', () {
      final random = math.Random(7);
      for (var round = 0; round < 6; round++) {
        final count = 1 + random.nextInt(3000);
        final tools = [
          for (var i = 0; i < count; i++)
            _def('tool_$i', _text(i, random.nextInt(10000)), [
              for (var k = random.nextInt(80); k > 0; k--)
                'a${'x' * random.nextInt(70)}$k',
            ]),
        ];
        final index = ToolIndex.build(tools);
        final share = ToolIndex.shareFor(count);
        expect(
          index.indexedUnits,
          lessThanOrEqualTo(ToolIndex.maxIndexedUnits),
        );
        expect(index.indexedUnits, lessThanOrEqualTo(count * share));
        for (var i = 0; i < count; i += 1 + count ~/ 40) {
          final hit = index
              .search('tool_$i', limit: count)
              .singleWhere((h) => h.name == 'tool_$i');
          final units =
              hit.description.length +
              hit.schemaKeys.fold<int>(0, (sum, k) => sum + k.length);
          expect(units, lessThanOrEqualTo(share), reason: 'tool_$i');
        }
      }
    });

    test('a tool is found by its name when its share is empty', () {
      final index = ToolIndex.build([
        _def('find_ticket', 'Find a ticket by its title.', ['title']),
        _def('mcp__tracker__close_issue', 'Close an issue.', ['id']),
      ], totalUnits: 0);
      expect(index.indexedUnits, 0);
      final hit = index.search('find_ticket').first;
      expect(hit.name, 'find_ticket');
      expect(hit.description, isEmpty);
      expect(hit.schemaKeys, isEmpty);
      expect(
        index.search('close issue').first.name,
        'mcp__tracker__close_issue',
      );
      expect(index.search('title'), isEmpty);
    });

    test('every tool gets the same share, whatever its position', () {
      const count = 4000;
      final share = ToolIndex.shareFor(count);
      final index = ToolIndex.build([
        for (var i = 0; i < count; i++) _def('tool_$i', _text(1, 2000)),
      ]);
      for (final i in [0, 1, count ~/ 2, count - 2, count - 1]) {
        final hit = index
            .search('tool_$i', limit: count)
            .singleWhere((h) => h.name == 'tool_$i');
        expect(hit.description.length, share, reason: 'tool_$i');
      }
    });

    test('argument names are spent first, then the description', () {
      const count = 4000;
      final share = ToolIndex.shareFor(count);
      final keys = [
        for (var i = 0; i < 20; i++)
          'k${i.toString().padLeft(2, '0')}${'x' * 20}',
      ];
      final keyUnits = keys.fold<int>(0, (sum, k) => sum + k.length);
      final tools = [
        _def('wide', 'Wide tool description.', keys),
        for (var i = 1; i < count; i++) _def('tool_$i', 'x'),
      ];
      final hit = ToolIndex.build(tools).search('wide').single;
      final kept = hit.schemaKeys.fold<int>(0, (sum, k) => sum + k.length);
      expect(kept, lessThanOrEqualTo(share));
      expect(kept, greaterThan(share - keys.first.length));
      expect(keyUnits, greaterThan(share));
      // What the names leave goes to the description's head.
      expect(
        hit.description,
        'Wide tool description.'.substring(0, share - kept),
      );
    });

    test('catalogs that differ only beyond their shares share one index', () {
      const count = 2000;
      final share = ToolIndex.shareFor(count);
      final before = ToolIndex.builds;
      List<ToolDef> catalog(String tail) => [
        for (var i = 0; i < count; i++)
          _def('tool_$i', '${_text(i, share)}$tail $before'),
      ];
      final first = ToolIndex.shared(catalog('beyond one'));
      final second = ToolIndex.shared(catalog('beyond two'));
      expect(second, same(first));
      expect(ToolIndex.builds, before + 1);
      final within = ToolIndex.shared([
        _def('tool_0', 'changed within the share'),
        ...catalog('beyond one').skip(1),
      ]);
      expect(within, isNot(same(first)));
      expect(ToolIndex.builds, before + 2);
    });
  });
}
