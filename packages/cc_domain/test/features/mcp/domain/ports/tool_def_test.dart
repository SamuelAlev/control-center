import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:test/test.dart';

/// A `tools/list` entry carries `_meta` only when the server set some, so
/// every entry without it keeps the bytes it always had.
void main() {
  const schema = {'type': 'object', 'properties': <String, dynamic>{}};

  test('without meta, the entry is name, description and schema only', () {
    for (final def in [
      const ToolDef(name: 'a', description: 'A.', inputSchema: schema),
      const ToolDef(
        name: 'a',
        description: 'A.',
        inputSchema: schema,
        meta: {},
      ),
    ]) {
      expect(def.toJson().keys, ['name', 'description', 'inputSchema']);
      expect(
        jsonEncode(def.toJson()),
        '{"name":"a","description":"A.","inputSchema":'
        '{"type":"object","properties":{}}}',
      );
    }
  });

  test('with meta, the entry carries it as _meta, last', () {
    const def = ToolDef(
      name: 'a',
      description: 'A.',
      inputSchema: schema,
      meta: {'anthropic/alwaysLoad': true},
    );
    expect(def.toJson().keys, ['name', 'description', 'inputSchema', '_meta']);
    expect(def.toJson()['_meta'], {'anthropic/alwaysLoad': true});
  });
}
