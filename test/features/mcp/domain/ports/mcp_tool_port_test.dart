import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolDef', () {
    test('constructs with name, description, and inputSchema', () {
      const toolDef = ToolDef(
        name: 'my_tool',
        description: 'Does something useful',
        inputSchema: {
          'type': 'object',
          'properties': {
            'param1': {'type': 'string'},
          },
          'required': ['param1'],
        },
      );

      expect(toolDef.name, 'my_tool');
      expect(toolDef.description, 'Does something useful');
      expect(toolDef.inputSchema['type'], 'object');
    });

    test('toJson serializes all fields', () {
      const toolDef = ToolDef(
        name: 'test_tool',
        description: 'A test tool',
        inputSchema: {'type': 'object', 'properties': {}},
      );

      final json = toolDef.toJson();
      expect(json['name'], 'test_tool');
      expect(json['description'], 'A test tool');
      expect(json['inputSchema'], {'type': 'object', 'properties': {}});
    });
  });

  group('CallResultContent', () {
    test('constructs with type and text', () {
      const content = CallResultContent(type: 'text', text: 'Hello world');
      expect(content.type, 'text');
      expect(content.text, 'Hello world');
    });

    test('toJson serializes all fields', () {
      const content = CallResultContent(type: 'image', text: 'base64data');
      final json = content.toJson();
      expect(json['type'], 'image');
      expect(json['text'], 'base64data');
    });
  });

  group('CallResult', () {
    test('success factory creates non-error result', () {
      final result = CallResult.success('Operation succeeded');
      expect(result.isError, isFalse);
      expect(result.content.length, 1);
      expect(result.content.first.type, 'text');
      expect(result.content.first.text, 'Operation succeeded');
    });

    test('error factory creates error result', () {
      final result = CallResult.error('Something went wrong');
      expect(result.isError, isTrue);
      expect(result.content.length, 1);
      expect(result.content.first.type, 'text');
      expect(result.content.first.text, 'Something went wrong');
    });

    test('constructs with multiple content items', () {
      const result = CallResult(
        content: [
          CallResultContent(type: 'text', text: 'Part 1'),
          CallResultContent(type: 'text', text: 'Part 2'),
        ],
        isError: false,
      );

      expect(result.content.length, 2);
      expect(result.content[0].text, 'Part 1');
      expect(result.content[1].text, 'Part 2');
    });

    test('toJson serializes all fields', () {
      final result = CallResult.success('Done');
      final json = result.toJson();
      expect(json['isError'], isFalse);
      expect(json['content'], isA<List>());
      expect((json['content'] as List).length, 1);
    });

    test('toJson for error result includes isError', () {
      final result = CallResult.error('Failed');
      final json = result.toJson();
      expect(json['isError'], isTrue);
    });
  });

  group('McpTool definition', () {
    test('definition returns ToolDef with tool metadata', () {
      final tool = _FakeTool(
        toolName: 'fake_tool',
        toolDescription: 'A fake tool for testing',
        schema: {'type': 'object', 'properties': {}},
      );

      final def = tool.definition;
      expect(def.name, 'fake_tool');
      expect(def.description, 'A fake tool for testing');
      expect(def.inputSchema, {'type': 'object', 'properties': {}});
    });
  });
}

class _FakeTool extends McpTool {
  _FakeTool({
    required this.toolName,
    required this.toolDescription,
    required this.schema,
  });

  final String toolName;
  final String toolDescription;
  final Map<String, dynamic> schema;

  @override
  String get name => toolName;

  @override
  String get description => toolDescription;

  @override
  Map<String, dynamic> get inputSchema => schema;

  @override
  Future<CallResult> call(Map<String, dynamic> arguments) async {
    return CallResult.success('fake result');
  }

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    return CallResult.success('fake result');
  }
}
