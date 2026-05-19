import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

CcBlockParseResult? parseWith(CcBlockPlugin plugin, String source) {
  final lines = source.split('\n');
  if (!plugin.canParse(lines[0], lines, 0)) {
    return null;
  }
  return plugin.parse(lines, 0);
}

void main() {
  group('CcThinkingPlugin', () {
    const plugin = CcThinkingPlugin();

    test('id and priority', () {
      expect(plugin.id, 'thinking');
      expect(plugin.priority, 10);
    });

    test('canParse is true for the recognized open tags', () {
      for (final line in [
        '<thinking>',
        '  <thinking> ',
        '<think>',
        '<|thinking|>',
      ]) {
        expect(plugin.canParse(line, [line], 0), isTrue, reason: line);
      }
    });

    test('canParse is false for unrelated lines', () {
      for (final line in [
        '<artifact>',
        '<tool_call>',
        'regular text',
        '</thinking>',
      ]) {
        expect(plugin.canParse(line, [line], 0), isFalse, reason: line);
      }
    });

    test('parses a closed <thinking> block and consumes all lines', () {
      final result = parseWith(
        plugin,
        '<thinking>\nfirst\nsecond\n</thinking>',
      );
      expect(result, isNotNull);
      final node = result!.node as CcThinkingNode;
      expect(node.content, 'first\nsecond');
      expect(node.isCollapsed, isTrue); // collapsed by default once closed
      expect(result.linesConsumed, 4);
    });

    test('parses the <think> tag variant', () {
      final result = parseWith(plugin, '<think>\nshort\n</think>');
      final node = result!.node as CcThinkingNode;
      expect(node.content, 'short');
    });

    test('parses the <|thinking|> sentinel variant', () {
      final result = parseWith(plugin, '<|thinking|>\nsentinel\n<|/thinking|>');
      final node = result!.node as CcThinkingNode;
      expect(node.content, 'sentinel');
    });

    test(
      'unclosed (streaming) block renders not-collapsed and consumes the tail',
      () {
        final result = parseWith(plugin, '<thinking>\npartial reasoning');
        expect(result, isNotNull);
        final node = result!.node as CcThinkingNode;
        expect(node.content, 'partial reasoning');
        expect(node.isCollapsed, isFalse);
        expect(result.linesConsumed, 2);
      },
    );

    test('parse returns null when the opening line is not recognized', () {
      // Directly invoking parse on a non-matching line returns null
      // (canParse would normally gate this).
      expect(plugin.parse(['not a tag'], 0), isNull);
    });

    test('trims surrounding blank lines from content', () {
      final result = parseWith(plugin, '<thinking>\n\nkeep me\n\n</thinking>');
      final node = result!.node as CcThinkingNode;
      expect(node.content, 'keep me');
    });

    test('through CcParser it lands in the AST as a custom block', () {
      final parser = CcParser(plugins: CcPluginSet(const [CcThinkingPlugin()]));
      final blocks = parser.parse('<thinking>\nwhy?\n</thinking>\n\nAfter.');
      expect(blocks, hasLength(2));
      expect(blocks[0], isA<CcThinkingNode>());
      expect((blocks[0] as CcThinkingNode).content, 'why?');
      expect(blocks[1], isA<CcParagraph>());
    });
  });

  group('CcArtifactPlugin', () {
    const plugin = CcArtifactPlugin();

    test('id and priority', () {
      expect(plugin.id, 'artifact');
      expect(plugin.priority, 10);
    });

    test('canParse is true for an artifact open line', () {
      expect(plugin.canParse('<artifact>', ['<artifact>'], 0), isTrue);
      expect(
        plugin.canParse('<artifact identifier="1" type="code">', [
          '<artifact identifier="1" type="code">',
        ], 0),
        isTrue,
      );
    });

    test('canParse is false for non-artifact lines', () {
      expect(plugin.canParse('</artifact>', ['</artifact>'], 0), isFalse);
      expect(plugin.canParse('plain', ['plain'], 0), isFalse);
    });

    test('parses attributes and consumes through the close tag', () {
      final result = parseWith(
        plugin,
        '<artifact identifier="id-7" type="code" title="T" language="dart">'
        '\nline1\nline2\n</artifact>',
      );
      expect(result, isNotNull);
      final node = result!.node as CcArtifactNode;
      expect(node.identifier, 'id-7');
      expect(node.artifactType, 'code');
      expect(node.title, 'T');
      expect(node.language, 'dart');
      expect(node.content, 'line1\nline2');
      // open + line1 + line2 + close = 4 consumed lines.
      expect(result.linesConsumed, 4);
    });

    test('defaults identifier to "" and type to "text" when missing', () {
      final result = parseWith(plugin, '<artifact>\nbody\n</artifact>');
      final node = result!.node as CcArtifactNode;
      expect(node.identifier, '');
      expect(node.artifactType, 'text');
      expect(node.title, isNull);
      expect(node.language, isNull);
      expect(node.content, 'body');
    });

    test('unclosed (streaming) artifact consumes to the end', () {
      final result = parseWith(
        plugin,
        '<artifact type="doc">\nstill streaming',
      );
      final node = result!.node as CcArtifactNode;
      expect(node.artifactType, 'doc');
      expect(node.content, 'still streaming');
      // Consumed every available line.
      expect(result.linesConsumed, 2);
    });

    test('parse returns null when the opening line is not recognized', () {
      expect(plugin.parse(['nope'], 0), isNull);
    });

    test('through CcParser it lands in the AST', () {
      final parser = CcParser(plugins: CcPluginSet(const [CcArtifactPlugin()]));
      final blocks = parser.parse(
        '<artifact identifier="a" type="document">\n# Title\n</artifact>',
      );
      expect(blocks.single, isA<CcArtifactNode>());
      final node = blocks.single as CcArtifactNode;
      expect(node.identifier, 'a');
      expect(node.artifactType, 'document');
      expect(node.content, '# Title');
    });
  });

  group('CcToolCallPlugin', () {
    const plugin = CcToolCallPlugin();

    test('id and priority', () {
      expect(plugin.id, 'tool_call');
      expect(plugin.priority, 10);
    });

    test('canParse is true for a tool_call open line', () {
      expect(plugin.canParse('<tool_call>', ['<tool_call>'], 0), isTrue);
      expect(
        plugin.canParse('<tool_call name="search" id="1">', [
          '<tool_call name="search" id="1">',
        ], 0),
        isTrue,
      );
    });

    test('canParse is false for non-tool_call lines', () {
      expect(plugin.canParse('</tool_call>', ['</tool_call>'], 0), isFalse);
      expect(plugin.canParse('text', ['text'], 0), isFalse);
    });

    test('parses name/id attrs and arguments/result/error sections', () {
      final result = parseWith(
        plugin,
        '<tool_call name="run" id="call-9">\n'
        '<arguments>{"q":"x"}</arguments>\n'
        '<result>ok</result>\n'
        '<error>boom</error>\n'
        '</tool_call>',
      );
      expect(result, isNotNull);
      final node = result!.node as CcToolCallNode;
      expect(node.toolName, 'run');
      expect(node.toolId, 'call-9');
      expect(node.arguments, '{"q":"x"}');
      expect(node.result, 'ok');
      expect(node.errorMessage, 'boom');
      // open + arguments + result + error + close = 5 consumed lines.
      expect(result.linesConsumed, 5);
    });

    test('defaults toolName to "tool" and leaves sections null', () {
      final result = parseWith(plugin, '<tool_call>\nplain body\n</tool_call>');
      final node = result!.node as CcToolCallNode;
      expect(node.toolName, 'tool');
      expect(node.toolId, isNull);
      expect(node.arguments, isNull);
      expect(node.result, isNull);
      expect(node.errorMessage, isNull);
    });

    test('picks the first matching section when several are present', () {
      final result = parseWith(
        plugin,
        '<tool_call name="t">\n'
        '<result>r1</result>\n'
        '<result>r2</result>\n'
        '</tool_call>',
      );
      final node = result!.node as CcToolCallNode;
      expect(node.result, 'r1');
    });

    test('unclosed (streaming) tool_call consumes to the end', () {
      final result = parseWith(
        plugin,
        '<tool_call name="t" id="z">\n<arguments>partial',
      );
      final node = result!.node as CcToolCallNode;
      expect(node.toolName, 't');
      expect(node.toolId, 'z');
      // The section regex requires a closing tag, so a still-streaming,
      // not-yet-closed <arguments> yields null for that section (the rest
      // of the attrs are still resolved).
      expect(node.arguments, isNull);
      expect(result.linesConsumed, 2);
    });

    test('parse returns null when the opening line is not recognized', () {
      expect(plugin.parse(['nope'], 0), isNull);
    });

    test('through CcParser it lands in the AST', () {
      final parser = CcParser(plugins: CcPluginSet(const [CcToolCallPlugin()]));
      final blocks = parser.parse(
        '<tool_call name="get" id="1">\n'
        '<arguments>{"a":1}</arguments>\n'
        '</tool_call>',
      );
      expect(blocks.single, isA<CcToolCallNode>());
      final node = blocks.single as CcToolCallNode;
      expect(node.toolName, 'get');
      expect(node.toolId, '1');
      expect(node.arguments, '{"a":1}');
    });
  });

  group('All three AI plugins together', () {
    test('coexist in one plugin set and each claims its own block', () {
      final parser = CcParser(
        plugins: CcPluginSet(const [
          CcThinkingPlugin(),
          CcArtifactPlugin(),
          CcToolCallPlugin(),
        ]),
      );
      final blocks = parser.parse(
        '<thinking>\nreason\n</thinking>\n\n'
        '<artifact identifier="a" type="code">\ncode\n</artifact>\n\n'
        '<tool_call name="t">\n<arguments>x</arguments>\n</tool_call>',
      );
      expect(blocks, hasLength(3));
      expect(blocks[0], isA<CcThinkingNode>());
      expect(blocks[1], isA<CcArtifactNode>());
      expect(blocks[2], isA<CcToolCallNode>());
    });
  });
}
