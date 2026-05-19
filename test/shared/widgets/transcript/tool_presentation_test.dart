import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  ToolSegment tool(
    String name, {
    Map<String, dynamic>? inputs,
    String outputs = '',
  }) => ToolSegment(
    toolName: name,
    toolCallId: 'c',
    inputs: inputs,
    outputs: outputs,
    startedAt: ts,
  );

  group('humanizeToolName', () {
    test('sentence-cases snake_case and strips mcp prefix', () {
      expect(humanizeToolName('create_ticket'), 'Create ticket');
      expect(
        humanizeToolName('mcp__control-center__search_memory'),
        'Search memory',
      );
      expect(humanizeToolName('propose_fact'), 'Propose fact');
    });
  });

  group('shortenPath', () {
    test('keeps short paths', () {
      expect(shortenPath('a.dart'), 'a.dart');
      expect(shortenPath('lib/a.dart'), 'lib/a.dart');
    });

    test('truncates deep paths to last two segments', () {
      expect(
        shortenPath('lib/features/messaging/x.dart'),
        '…/messaging/x.dart',
      );
    });

    test('null/empty', () {
      expect(shortenPath(null), isNull);
      expect(shortenPath(''), isNull);
    });
  });

  group('ToolCategory', () {
    test('read/grep/glob/list map to explore', () {
      expect(
        resolveToolPresentation(tool('Read')).category,
        ToolCategory.explore,
      );
      expect(
        resolveToolPresentation(tool('Grep')).category,
        ToolCategory.explore,
      );
      expect(
        resolveToolPresentation(tool('Glob')).category,
        ToolCategory.explore,
      );
      expect(
        resolveToolPresentation(tool('List')).category,
        ToolCategory.explore,
      );
    });

    test('edit/write map to edit', () {
      expect(resolveToolPresentation(tool('Edit')).category, ToolCategory.edit);
      expect(
        resolveToolPresentation(tool('Write')).category,
        ToolCategory.edit,
      );
      expect(
        resolveToolPresentation(tool('MultiEdit')).category,
        ToolCategory.edit,
      );
    });

    test('bash maps to run', () {
      expect(resolveToolPresentation(tool('Bash')).category, ToolCategory.run);
    });

    test('harness edit/write/read show the file path as subtitle', () {
      expect(
        resolveToolPresentation(
          tool('edit', inputs: {'path': 'lib/x.dart'}),
        ).subtitle,
        'lib/x.dart',
      );
      expect(
        resolveToolPresentation(
          tool('write', inputs: {'path': 'lib/x.dart'}),
        ).subtitle,
        'lib/x.dart',
      );
      expect(
        resolveToolPresentation(
          tool('read', inputs: {'path': 'lib/x.dart'}),
        ).subtitle,
        'lib/x.dart',
      );
    });

    test('batched edit without a top-level path uses the first item path', () {
      final p = resolveToolPresentation(
        tool(
          'edit',
          inputs: {
            'edits': [
              {
                'path': 'lib/features/messaging/x.dart',
                'old_text': 'a',
                'new_text': 'b',
              },
            ],
          },
        ),
      );
      expect(p.subtitle, '…/messaging/x.dart');
    });

    test('task/agent map to delegate', () {
      expect(
        resolveToolPresentation(tool('Task')).category,
        ToolCategory.delegate,
      );
      expect(
        resolveToolPresentation(tool('Agent')).category,
        ToolCategory.delegate,
      );
    });

    test('web tools map to fetch', () {
      expect(
        resolveToolPresentation(tool('WebFetch')).category,
        ToolCategory.fetch,
      );
      expect(
        resolveToolPresentation(tool('WebSearch')).category,
        ToolCategory.fetch,
      );
    });

    test('unknown/mcp/todos map to other', () {
      expect(
        resolveToolPresentation(tool('mcp__x__custom')).category,
        ToolCategory.other,
      );
      expect(
        resolveToolPresentation(tool('TodoWrite')).category,
        ToolCategory.other,
      );
    });
  });

  group('toolDiffStats', () {
    test('edit returns add/del counts', () {
      final stats = toolDiffStats(
        tool(
          'Edit',
          inputs: {
            'file_path': 'x.dart',
            'old_string': 'a\nb',
            'new_string': 'a\nc\nd',
          },
        ),
      );
      expect(stats, isNotNull);
      expect(stats!.adds, 2);
      expect(stats.dels, 1);
    });

    test('non-edit returns null', () {
      expect(toolDiffStats(tool('Read', inputs: {'file_path': 'x'})), isNull);
    });

    test('edit without strings returns null', () {
      expect(toolDiffStats(tool('Edit', inputs: {'file_path': 'x'})), isNull);
    });

    test('harness edit (path/old_text/new_text) returns add/del counts', () {
      final stats = toolDiffStats(
        tool(
          'edit',
          inputs: {'path': 'x.dart', 'old_text': 'a\nb', 'new_text': 'a\nc\nd'},
        ),
      );
      expect(stats, isNotNull);
      expect(stats!.adds, 2);
      expect(stats.dels, 1);
    });

    test('batched edits sum across items', () {
      final stats = toolDiffStats(
        tool(
          'MultiEdit',
          inputs: {
            'file_path': 'x.dart',
            'edits': [
              {'old_string': 'a', 'new_string': 'a\nb'},
              {'old_text': 'c\nd', 'new_text': 'c'},
            ],
          },
        ),
      );
      expect(stats, isNotNull);
      expect(stats!.adds, 1);
      expect(stats.dels, 1);
    });

    test('empty new_text is a valid deletion', () {
      final stats = toolDiffStats(
        tool(
          'edit',
          inputs: {'path': 'x.dart', 'old_text': 'a\nb', 'new_text': ''},
        ),
      );
      expect(stats, isNotNull);
      expect(stats!.adds, 0);
      expect(stats.dels, 2);
    });
  });

  group('toolBodyOpensByDefault', () {
    test('harness edit with old/new text opens', () {
      expect(
        toolBodyOpensByDefault(
          tool(
            'edit',
            inputs: {'path': 'x.dart', 'old_text': 'a', 'new_text': 'b'},
          ),
        ),
        isTrue,
      );
    });

    test('harness write with path/content opens', () {
      expect(
        toolBodyOpensByDefault(
          tool(
            'write',
            inputs: {'path': 'x.dart', 'content': 'void main() {}'},
          ),
        ),
        isTrue,
      );
    });

    test('edit missing the text pair stays closed', () {
      expect(
        toolBodyOpensByDefault(tool('Edit', inputs: {'file_path': 'x.dart'})),
        isFalse,
      );
    });
  });
}
