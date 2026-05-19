import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Fixtures: custom nodes
// ---------------------------------------------------------------------------

/// A custom block node emitted by [_NotePlugin] and [_PrefixPlugin].
final class _NoteBlock extends CcCustomBlock {
  const _NoteBlock(this.body);

  final String body;

  @override
  String get nodeType => 'test_note';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _NoteBlock && body == other.body;

  @override
  int get hashCode => Object.hash(nodeType, body);
}

/// A custom inline node emitted by [_MentionPlugin].
final class _MentionInline extends CcCustomInline {
  const _MentionInline(this.name);

  final String name;

  @override
  String get nodeType => 'test_mention';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _MentionInline && name == other.name;

  @override
  int get hashCode => Object.hash(nodeType, name);
}

// ---------------------------------------------------------------------------
// Fixtures: plugins
// ---------------------------------------------------------------------------

/// `:::note` fenced block. Returns null (falls through) when unclosed.
final class _NotePlugin extends CcBlockPlugin {
  const _NotePlugin();

  @override
  String get id => 'test_note';

  @override
  int get priority => 5;

  @override
  bool canParse(String line, List<String> lines, int index) =>
      line.trimRight() == ':::note';

  @override
  CcBlockParseResult? parse(List<String> lines, int startIndex) {
    final content = <String>[];
    for (var i = startIndex + 1; i < lines.length; i++) {
      if (lines[i].trimRight() == ':::') {
        return CcBlockParseResult(
          _NoteBlock(content.join('\n')),
          i - startIndex + 1,
        );
      }
      content.add(lines[i]);
    }
    return null; // Unclosed: fall through to core syntax.
  }
}

/// Claims any line starting with [prefix]; configurable id/priority and can
/// decline in [parse] to exercise fall-through.
final class _PrefixPlugin extends CcBlockPlugin {
  const _PrefixPlugin({
    required this.pluginId,
    required this.pluginPriority,
    required this.prefix,
    this.declineParse = false,
  });

  final String pluginId;
  final int pluginPriority;
  final String prefix;
  final bool declineParse;

  @override
  String get id => pluginId;

  @override
  int get priority => pluginPriority;

  @override
  bool canParse(String line, List<String> lines, int index) =>
      line.startsWith(prefix);

  @override
  CcBlockParseResult? parse(List<String> lines, int startIndex) {
    if (declineParse) {
      return null;
    }
    return CcBlockParseResult(_NoteBlock(pluginId), 1);
  }
}

/// `@word` / `!word` mentions; configurable id/priority/label, can decline.
final class _MentionPlugin extends CcInlinePlugin {
  const _MentionPlugin({
    this.pluginId = 'mention',
    this.pluginPriority = 0,
    this.triggers = '@',
    this.label = '',
    this.declineParse = false,
  });

  final String pluginId;
  final int pluginPriority;
  final String triggers;
  final String label;
  final bool declineParse;

  static final RegExp _pattern = RegExp(r'[@!]([A-Za-z0-9_]+)');

  @override
  String get id => pluginId;

  @override
  int get priority => pluginPriority;

  @override
  String get triggerCharacters => triggers;

  @override
  bool canParse(String text, int index) {
    final c = text.codeUnitAt(index);
    return c == 0x40 /* @ */ || c == 0x21 /* ! */;
  }

  @override
  CcInlineParseResult? parse(String text, int startIndex) {
    if (declineParse) {
      return null;
    }
    final m = _pattern.matchAsPrefix(text, startIndex);
    if (m == null) {
      return null;
    }
    return CcInlineParseResult(
      _MentionInline('$label${m.group(1)!}'),
      m.end - startIndex,
    );
  }
}

/// Neither a block nor an inline plugin — must be rejected by [CcPluginSet].
final class _BadPlugin extends CcParserPlugin {
  const _BadPlugin();

  @override
  String get id => 'bad';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CcPluginSet construction', () {
    test('duplicate id throws ArgumentError (same kind)', () {
      expect(
        () => CcPluginSet(const [_NotePlugin(), _NotePlugin()]),
        throwsArgumentError,
      );
    });

    test('duplicate id throws ArgumentError (across block/inline kinds)', () {
      expect(
        () => CcPluginSet(const [
          _PrefixPlugin(pluginId: 'x', pluginPriority: 0, prefix: '!'),
          _MentionPlugin(pluginId: 'x'),
        ]),
        throwsArgumentError,
      );
    });

    test('plugin that is neither block nor inline throws ArgumentError', () {
      expect(() => CcPluginSet(const [_BadPlugin()]), throwsArgumentError);
    });

    test('block plugins are sorted by priority, higher first', () {
      final set = CcPluginSet(const [
        _PrefixPlugin(pluginId: 'low', pluginPriority: -3, prefix: 'a'),
        _PrefixPlugin(pluginId: 'high', pluginPriority: 20, prefix: 'b'),
        _PrefixPlugin(pluginId: 'mid', pluginPriority: 4, prefix: 'c'),
      ]);
      expect(set.blockPlugins.map((p) => p.id).toList(), [
        'high',
        'mid',
        'low',
      ]);
    });

    test('inline plugins are sorted by priority, higher first', () {
      final set = CcPluginSet(const [
        _MentionPlugin(pluginId: 'low', pluginPriority: 1),
        _MentionPlugin(pluginId: 'high', pluginPriority: 9),
      ]);
      expect(set.inlinePlugins.map((p) => p.id).toList(), ['high', 'low']);
    });
  });

  group('CcPluginSet.inlinePluginsFor', () {
    test('single trigger character is indexed', () {
      const plugin = _MentionPlugin();
      final set = CcPluginSet(const [plugin]);
      final hits = set.inlinePluginsFor('@'.codeUnitAt(0));
      expect(hits, isNotNull);
      expect(hits!.single, same(plugin));
    });

    test('multi-char triggerCharacters index the plugin under every unit', () {
      const plugin = _MentionPlugin(triggers: '@!');
      final set = CcPluginSet(const [plugin]);
      expect(set.inlinePluginsFor('@'.codeUnitAt(0))!.single, same(plugin));
      expect(set.inlinePluginsFor('!'.codeUnitAt(0))!.single, same(plugin));
    });

    test('unregistered trigger returns null', () {
      final set = CcPluginSet(const [_MentionPlugin()]);
      expect(set.inlinePluginsFor('%'.codeUnitAt(0)), isNull);
      expect(CcPluginSet.empty.inlinePluginsFor('@'.codeUnitAt(0)), isNull);
    });

    test('shared trigger lists plugins priority-sorted', () {
      final set = CcPluginSet(const [
        _MentionPlugin(pluginId: 'low', pluginPriority: 1),
        _MentionPlugin(pluginId: 'high', pluginPriority: 9),
      ]);
      expect(
        set.inlinePluginsFor('@'.codeUnitAt(0))!.map((p) => p.id).toList(),
        ['high', 'low'],
      );
    });
  });

  group('CcPluginSet identity', () {
    test('withPlugins creates a NEW set and keeps the original intact', () {
      final base = CcPluginSet(const [_NotePlugin()]);
      final grown = base.withPlugins(const [_MentionPlugin()]);
      expect(identical(base, grown), isFalse);
      expect(grown.blockPlugins.single.id, 'test_note');
      expect(grown.inlinePlugins.single.id, 'mention');
      // The original set never gains plugins.
      expect(base.inlinePlugins, isEmpty);
      expect(base.blockPlugins, hasLength(1));
    });

    test('withPlugins applies the same duplicate-id rule', () {
      final base = CcPluginSet(const [_NotePlugin()]);
      expect(
        () => base.withPlugins(const [_NotePlugin()]),
        throwsArgumentError,
      );
    });

    test('empty set is identity-stable', () {
      expect(identical(CcPluginSet.empty, CcPluginSet.empty), isTrue);
      expect(CcPluginSet.empty.blockPlugins, isEmpty);
      expect(CcPluginSet.empty.inlinePlugins, isEmpty);
      // Two factory-built empty sets are distinct instances (identity keying).
      expect(identical(CcPluginSet(const []), CcPluginSet(const [])), isFalse);
    });
  });

  group('block plugins through CcParser', () {
    test('custom block parses into the AST', () {
      final parser = CcParser(plugins: CcPluginSet(const [_NotePlugin()]));
      final blocks = parser.parse(
        ':::note\nhello **world**\n:::\n\nAfter text.',
      );
      expect(blocks, hasLength(2));
      expect(blocks[0], const _NoteBlock('hello **world**'));
      expect((blocks[0] as _NoteBlock).nodeType, 'test_note');
      expect(blocks[1], isA<CcParagraph>());
    });

    test('plugin consumption closes an open paragraph', () {
      final parser = CcParser(plugins: CcPluginSet(const [_NotePlugin()]));
      final blocks = parser.parse('lead text\n:::note\nbody\n:::');
      expect(blocks, hasLength(2));
      final p = blocks[0] as CcParagraph;
      expect((p.children.single as CcText).text, 'lead text');
      expect(blocks[1], const _NoteBlock('body'));
    });

    test('parse() returning null falls through to core syntax', () {
      // Plugin claims '# ' lines in canParse but declines in parse — the core
      // ATX heading syntax must still win.
      final parser = CcParser(
        plugins: CcPluginSet(const [
          _PrefixPlugin(
            pluginId: 'decliner',
            pluginPriority: 50,
            prefix: '# ',
            declineParse: true,
          ),
        ]),
      );
      final blocks = parser.parse('# Hi');
      final heading = blocks.single as CcHeading;
      expect(heading.level, 1);
      expect((heading.children.single as CcText).text, 'Hi');
    });

    test('unclosed note falls through and degrades to paragraph text', () {
      final parser = CcParser(plugins: CcPluginSet(const [_NotePlugin()]));
      final blocks = parser.parse(':::note\nno close fence');
      final p = blocks.single as CcParagraph;
      final text = p.children.whereType<CcText>().map((t) => t.text).join();
      expect(text, contains(':::note'));
      expect(text, contains('no close fence'));
      expect(blocks.whereType<_NoteBlock>(), isEmpty);
    });

    test('block plugins take priority over core syntax', () {
      final parser = CcParser(
        plugins: CcPluginSet(const [
          _PrefixPlugin(pluginId: 'claimer', pluginPriority: 0, prefix: '# '),
        ]),
      );
      final blocks = parser.parse('# Not a heading');
      expect(blocks.single, const _NoteBlock('claimer'));
    });

    test('higher-priority block plugin wins a contested line', () {
      final parser = CcParser(
        plugins: CcPluginSet(const [
          _PrefixPlugin(pluginId: 'low', pluginPriority: 1, prefix: '!!'),
          _PrefixPlugin(pluginId: 'high', pluginPriority: 10, prefix: '!!'),
        ]),
      );
      expect(parser.parse('!!x').single, const _NoteBlock('high'));
    });

    test('declining higher-priority plugin falls through to the next', () {
      final parser = CcParser(
        plugins: CcPluginSet(const [
          _PrefixPlugin(pluginId: 'low', pluginPriority: 1, prefix: '!!'),
          _PrefixPlugin(
            pluginId: 'high',
            pluginPriority: 10,
            prefix: '!!',
            declineParse: true,
          ),
        ]),
      );
      expect(parser.parse('!!x').single, const _NoteBlock('low'));
    });
  });

  group('inline plugins through CcParser', () {
    test('custom inline parses into the AST with surrounding text', () {
      final parser = CcParser(plugins: CcPluginSet(const [_MentionPlugin()]));
      final p = parser.parse('hi @sam done').single as CcParagraph;
      expect(p.children, const [
        CcText('hi '),
        _MentionInline('sam'),
        CcText(' done'),
      ]);
    });

    test('multi-char triggers dispatch on every trigger character', () {
      final parser = CcParser(
        plugins: CcPluginSet(const [_MentionPlugin(triggers: '@!')]),
      );
      final p = parser.parse('ping !ops and @sam now').single as CcParagraph;
      expect(p.children, const [
        CcText('ping '),
        _MentionInline('ops'),
        CcText(' and '),
        _MentionInline('sam'),
        CcText(' now'),
      ]);
    });

    test('parse() returning null falls through, trigger stays literal', () {
      final parser = CcParser(
        plugins: CcPluginSet(const [_MentionPlugin(declineParse: true)]),
      );
      final p = parser.parse('hi @sam done').single as CcParagraph;
      expect(p.children.whereType<_MentionInline>(), isEmpty);
      final text = p.children.whereType<CcText>().map((t) => t.text).join();
      expect(text, 'hi @sam done');
    });

    test('trigger with no matchable content falls through', () {
      final parser = CcParser(plugins: CcPluginSet(const [_MentionPlugin()]));
      final p = parser.parse('trailing @').single as CcParagraph;
      expect(p.children.whereType<_MentionInline>(), isEmpty);
      final text = p.children.whereType<CcText>().map((t) => t.text).join();
      expect(text, 'trailing @');
    });

    test('higher-priority inline plugin wins a shared trigger', () {
      final parser = CcParser(
        plugins: CcPluginSet(const [
          _MentionPlugin(pluginId: 'low', pluginPriority: 1, label: 'L:'),
          _MentionPlugin(pluginId: 'high', pluginPriority: 9, label: 'H:'),
        ]),
      );
      final p = parser.parse('cc @sam').single as CcParagraph;
      expect(p.children.whereType<_MentionInline>().single.name, 'H:sam');
    });

    test('declining higher-priority inline plugin falls through to next', () {
      final parser = CcParser(
        plugins: CcPluginSet(const [
          _MentionPlugin(pluginId: 'low', pluginPriority: 1, label: 'L:'),
          _MentionPlugin(
            pluginId: 'high',
            pluginPriority: 9,
            label: 'H:',
            declineParse: true,
          ),
        ]),
      );
      final p = parser.parse('cc @sam').single as CcParagraph;
      expect(p.children.whereType<_MentionInline>().single.name, 'L:sam');
    });
  });
}
