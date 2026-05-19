import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  ToolSegment tool(String name, {Map<String, dynamic>? inputs, String outputs = ''}) =>
      ToolSegment(
        toolName: name,
        toolCallId: 'c',
        inputs: inputs,
        outputs: outputs,
        startedAt: ts,
      );

  group('humanizeToolName', () {
    test('sentence-cases snake_case and strips mcp prefix', () {
      expect(humanizeToolName('create_ticket'), 'Create ticket');
      expect(humanizeToolName('mcp__control-center__search_memory'), 'Search memory');
      expect(humanizeToolName('propose_fact'), 'Propose fact');
    });
  });

  group('shortenPath', () {
    test('keeps short paths', () {
      expect(shortenPath('a.dart'), 'a.dart');
      expect(shortenPath('lib/a.dart'), 'lib/a.dart');
    });

    test('truncates deep paths to last two segments', () {
      expect(shortenPath('lib/features/messaging/x.dart'), '…/messaging/x.dart');
    });

    test('null/empty', () {
      expect(shortenPath(null), isNull);
      expect(shortenPath(''), isNull);
    });
  });

  group('ToolCategory', () {
    test('read/grep/glob/list map to explore', () {
      expect(resolveToolPresentation(tool('Read')).category, ToolCategory.explore);
      expect(resolveToolPresentation(tool('Grep')).category, ToolCategory.explore);
      expect(resolveToolPresentation(tool('Glob')).category, ToolCategory.explore);
      expect(resolveToolPresentation(tool('List')).category, ToolCategory.explore);
    });

    test('edit/write map to edit', () {
      expect(resolveToolPresentation(tool('Edit')).category, ToolCategory.edit);
      expect(resolveToolPresentation(tool('Write')).category, ToolCategory.edit);
      expect(resolveToolPresentation(tool('MultiEdit')).category, ToolCategory.edit);
    });

    test('bash maps to run', () {
      expect(resolveToolPresentation(tool('Bash')).category, ToolCategory.run);
    });

    test('task/agent map to delegate', () {
      expect(resolveToolPresentation(tool('Task')).category, ToolCategory.delegate);
      expect(resolveToolPresentation(tool('Agent')).category, ToolCategory.delegate);
    });

    test('web tools map to fetch', () {
      expect(resolveToolPresentation(tool('WebFetch')).category, ToolCategory.fetch);
      expect(resolveToolPresentation(tool('WebSearch')).category, ToolCategory.fetch);
    });

    test('unknown/mcp/todos map to other', () {
      expect(resolveToolPresentation(tool('mcp__x__custom')).category, ToolCategory.other);
      expect(resolveToolPresentation(tool('TodoWrite')).category, ToolCategory.other);
    });
  });

  group('toolDiffStats', () {
    test('edit returns add/del counts', () {
      final stats = toolDiffStats(tool('Edit', inputs: {
        'file_path': 'x.dart',
        'old_string': 'a\nb',
        'new_string': 'a\nc\nd',
      }));
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
  });
}
