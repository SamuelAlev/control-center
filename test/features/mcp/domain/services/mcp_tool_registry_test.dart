// ignore_for_file: avoid_dynamic_calls

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockTool extends McpTool {
  _MockTool(this._name);

  final String _name;

  @override
  String get name => _name;

  @override
  String get description => 'A mock tool';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'value': {'type': 'string'},
    },
  };

  @override
  Future<CallResult> call(Map<String, dynamic> arguments) async {
    return CallResult.success('mock result');
  }

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    return CallResult.success('mock result');
  }
}

void main() {
  group('McpToolRegistry', () {
    test('looks up a tool by name', () {
      final tool = _MockTool('test_tool');
      final registry = McpToolRegistry([tool]);

      expect(registry.lookup('test_tool'), tool);
      expect(registry.lookup('nonexistent'), isNull);
    });

    test('lists tool definitions', () {
      final tool1 = _MockTool('tool_a');
      final tool2 = _MockTool('tool_b');
      final registry = McpToolRegistry([tool1, tool2]);

      final definitions = registry.listDefinitions();
      expect(definitions, hasLength(2));
      expect(definitions[0].name, 'tool_a');
      expect(definitions[1].name, 'tool_b');
      expect(definitions[0].toJson()['name'], 'tool_a');
      expect(definitions[0].toJson()['inputSchema'], isA<Map>());
    });

    test('toolNames returns all registered names', () {
      final registry = McpToolRegistry([
        _MockTool('a'),
        _MockTool('b'),
        _MockTool('c'),
      ]);

      expect(registry.toolNames.toList(), ['a', 'b', 'c']);
    });

    test('empty registry has no tools', () {
      final registry = McpToolRegistry([]);
      expect(registry.listDefinitions(), isEmpty);
      expect(registry.lookup('any'), isNull);
    });
  });

  group('CallResult', () {
    test('success factory creates result with isError false', () {
      final result = CallResult.success('hello');
      expect(result.isError, false);
      expect(result.content, hasLength(1));
      expect(result.content.first.type, 'text');
      expect(result.content.first.text, 'hello');
    });

    test('error factory creates result with isError true', () {
      final result = CallResult.error('something went wrong');
      expect(result.isError, true);
      expect(result.content.first.text, 'something went wrong');
    });

    test('toJson serializes correctly', () {
      final result = CallResult.success('ok');
      final json = result.toJson();
      expect(json['isError'], false);
      expect(json['content'], isA<List>());
      expect(json['content'][0]['type'], 'text');
      expect(json['content'][0]['text'], 'ok');
    });
  });

  group('ToolDef', () {
    test('toJson includes all fields', () {
      const def = ToolDef(
        name: 'my_tool',
        description: 'Does something',
        inputSchema: {'type': 'object'},
      );
      final json = def.toJson();
      expect(json['name'], 'my_tool');
      expect(json['description'], 'Does something');
      expect(json['inputSchema'], {'type': 'object'});
    });
  });

  group('McpTool', () {
    test('definition getter creates ToolDef', () {
      final tool = _MockTool('example');
      final def = tool.definition;
      expect(def.name, 'example');
      expect(def.description, 'A mock tool');
      expect(def.inputSchema, isA<Map>());
    });
  });
}
