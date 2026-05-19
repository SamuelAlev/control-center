import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
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

  group('resolveToolPresentation', () {
    test('read shows verb and shortened path', () {
      final p = resolveToolPresentation(tool('Read', inputs: {'file_path': 'lib/x.dart'}));
      expect(p.verb, 'Read');
      expect(p.subtitle, 'lib/x.dart');
    });

    test('edit', () {
      final p = resolveToolPresentation(tool('Edit', inputs: {'file_path': 'a/b/c.dart'}));
      expect(p.verb, 'Edit');
      expect(p.subtitle, '…/b/c.dart');
    });

    test('bash uses description over command', () {
      final p = resolveToolPresentation(
        tool('Bash', inputs: {'description': 'run tests', 'command': 'flutter test'}),
      );
      expect(p.verb, 'Bash');
      expect(p.subtitle, 'run tests');
    });

    test('mcp tool gets humanized verb', () {
      final p = resolveToolPresentation(tool('mcp__cc__create_ticket', inputs: {'title': 'x'}));
      expect(p.verb, 'Create ticket');
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
