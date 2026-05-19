import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CcThinkingNode', () {
    test('construction stores content and defaults isCollapsed to true', () {
      const node = CcThinkingNode(content: 'because reasons');
      expect(node.content, 'because reasons');
      expect(node.isCollapsed, isTrue);
    });

    test('construction honors an explicit isCollapsed', () {
      const node = CcThinkingNode(
        content: 'open reasoning',
        isCollapsed: false,
      );
      expect(node.isCollapsed, isFalse);
    });

    test('nodeType is "thinking"', () {
      expect(const CcThinkingNode(content: 'x').nodeType, 'thinking');
    });

    test('is a CcCustomBlock (open extension point)', () {
      expect(const CcThinkingNode(content: 'x'), isA<CcCustomBlock>());
    });

    test('equals by content and isCollapsed', () {
      expect(
        const CcThinkingNode(content: 'a', isCollapsed: true),
        const CcThinkingNode(content: 'a', isCollapsed: true),
      );
    });

    test('differs when content differs', () {
      expect(
        const CcThinkingNode(content: 'a'),
        isNot(equals(const CcThinkingNode(content: 'b'))),
      );
    });

    test('differs when isCollapsed differs', () {
      expect(
        const CcThinkingNode(content: 'a', isCollapsed: true),
        isNot(equals(const CcThinkingNode(content: 'a', isCollapsed: false))),
      );
    });

    test('hashCode agrees for equal nodes', () {
      const a = CcThinkingNode(content: 'a', isCollapsed: true);
      const b = CcThinkingNode(content: 'a', isCollapsed: true);
      expect(a.hashCode, b.hashCode);
    });

    test('does not equal an unrelated type', () {
      expect(const CcThinkingNode(content: 'x'), isNot(equals(Object())));
    });

    test('identical instances are equal (identity fast path)', () {
      const node = CcThinkingNode(content: 'x');
      expect(node, equals(node));
    });
  });

  group('CcArtifactNode', () {
    test(
      'construction stores required fields and defaults optionals to null',
      () {
        const node = CcArtifactNode(
          identifier: 'id1',
          artifactType: 'code',
          content: 'print(1)',
        );
        expect(node.identifier, 'id1');
        expect(node.artifactType, 'code');
        expect(node.content, 'print(1)');
        expect(node.title, isNull);
        expect(node.language, isNull);
      },
    );

    test('construction stores optional title and language', () {
      const node = CcArtifactNode(
        identifier: 'id1',
        artifactType: 'document',
        content: '# Hi',
        title: 'Greetings',
        language: 'markdown',
      );
      expect(node.title, 'Greetings');
      expect(node.language, 'markdown');
    });

    test('nodeType is "artifact"', () {
      expect(
        const CcArtifactNode(
          identifier: 'i',
          artifactType: 't',
          content: 'c',
        ).nodeType,
        'artifact',
      );
    });

    test('equals when every field matches', () {
      expect(
        const CcArtifactNode(
          identifier: 'i',
          artifactType: 't',
          content: 'c',
          title: 'T',
          language: 'L',
        ),
        const CcArtifactNode(
          identifier: 'i',
          artifactType: 't',
          content: 'c',
          title: 'T',
          language: 'L',
        ),
      );
    });

    test('differs when any field differs', () {
      const base = CcArtifactNode(
        identifier: 'i',
        artifactType: 't',
        content: 'c',
        title: 'T',
        language: 'L',
      );
      expect(
        base,
        isNot(
          equals(
            const CcArtifactNode(
              identifier: 'other',
              artifactType: 't',
              content: 'c',
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcArtifactNode(
              identifier: 'i',
              artifactType: 'other',
              content: 'c',
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcArtifactNode(
              identifier: 'i',
              artifactType: 't',
              content: 'other',
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcArtifactNode(
              identifier: 'i',
              artifactType: 't',
              content: 'c',
              title: 'other',
              language: 'L',
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcArtifactNode(
              identifier: 'i',
              artifactType: 't',
              content: 'c',
              title: 'T',
              language: 'other',
            ),
          ),
        ),
      );
    });

    test('hashCode agrees for equal nodes', () {
      const a = CcArtifactNode(
        identifier: 'i',
        artifactType: 't',
        content: 'c',
        title: 'T',
        language: 'L',
      );
      const b = CcArtifactNode(
        identifier: 'i',
        artifactType: 't',
        content: 'c',
        title: 'T',
        language: 'L',
      );
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CcToolCallNode', () {
    test(
      'construction stores required name and defaults optionals to null',
      () {
        const node = CcToolCallNode(toolName: 'search');
        expect(node.toolName, 'search');
        expect(node.toolId, isNull);
        expect(node.arguments, isNull);
        expect(node.result, isNull);
        expect(node.errorMessage, isNull);
      },
    );

    test('construction stores all fields', () {
      const node = CcToolCallNode(
        toolName: 'run',
        toolId: 'call-42',
        arguments: '{"q":"x"}',
        result: 'ok',
        errorMessage: 'boom',
      );
      expect(node.toolId, 'call-42');
      expect(node.arguments, '{"q":"x"}');
      expect(node.result, 'ok');
      expect(node.errorMessage, 'boom');
    });

    test('nodeType is "tool_call"', () {
      expect(const CcToolCallNode(toolName: 'x').nodeType, 'tool_call');
    });

    test('equals when every field matches', () {
      expect(
        const CcToolCallNode(
          toolName: 'run',
          toolId: '1',
          arguments: 'a',
          result: 'r',
          errorMessage: 'e',
        ),
        const CcToolCallNode(
          toolName: 'run',
          toolId: '1',
          arguments: 'a',
          result: 'r',
          errorMessage: 'e',
        ),
      );
    });

    test('differs when any field differs', () {
      const base = CcToolCallNode(
        toolName: 'run',
        toolId: '1',
        arguments: 'a',
        result: 'r',
        errorMessage: 'e',
      );
      expect(
        base,
        isNot(equals(const CcToolCallNode(toolName: 'other', toolId: '1'))),
      );
      expect(
        base,
        isNot(equals(const CcToolCallNode(toolName: 'run', toolId: 'other'))),
      );
      expect(
        base,
        isNot(
          equals(
            const CcToolCallNode(
              toolName: 'run',
              toolId: '1',
              arguments: 'other',
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcToolCallNode(
              toolName: 'run',
              toolId: '1',
              arguments: 'a',
              result: 'other',
            ),
          ),
        ),
      );
      expect(
        base,
        isNot(
          equals(
            const CcToolCallNode(
              toolName: 'run',
              toolId: '1',
              arguments: 'a',
              result: 'r',
              errorMessage: 'other',
            ),
          ),
        ),
      );
    });

    test('hashCode agrees for equal nodes', () {
      const a = CcToolCallNode(
        toolName: 'run',
        toolId: '1',
        arguments: 'a',
        result: 'r',
        errorMessage: 'e',
      );
      const b = CcToolCallNode(
        toolName: 'run',
        toolId: '1',
        arguments: 'a',
        result: 'r',
        errorMessage: 'e',
      );
      expect(a.hashCode, b.hashCode);
    });

    test('null vs empty string arguments differ', () {
      expect(
        const CcToolCallNode(toolName: 't', arguments: null),
        isNot(equals(const CcToolCallNode(toolName: 't', arguments: ''))),
      );
    });
  });
}
