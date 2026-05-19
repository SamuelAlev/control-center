// A minimal but real MCP server speaking newline-delimited JSON-RPC over
// stdio. Spawned by stdio_transport_test.dart to prove the client can connect
// to, list tools from, and call a genuine external stdio MCP server.
//
// Run: dart run test/fixtures/fake_stdio_mcp_server.dart
import 'dart:convert';
import 'dart:io';

void main() {
  stdin
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          return;
        }
        final request = jsonDecode(trimmed) as Map<String, dynamic>;
        final method = request['method'] as String?;
        final id = request['id'];

        switch (method) {
          case 'initialize':
            _send({
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'protocolVersion': '2025-06-18',
                'serverInfo': {'name': 'fake-stdio', 'version': '1.0.0'},
                'capabilities': {
                  'tools': {'listChanged': true},
                },
              },
            });
          case 'notifications/initialized':
            // No response to notifications.
            break;
          case 'tools/list':
            _send({
              'jsonrpc': '2.0',
              'id': id,
              'result': {
                'tools': [
                  {
                    'name': 'echo',
                    'description': 'Echoes the provided text back.',
                    'inputSchema': {
                      'type': 'object',
                      'properties': {
                        'text': {'type': 'string'},
                      },
                      'required': ['text'],
                    },
                  },
                  {
                    'name': 'add',
                    'description': 'Adds two numbers.',
                    'inputSchema': {
                      'type': 'object',
                      'properties': {
                        'a': {'type': 'number'},
                        'b': {'type': 'number'},
                      },
                    },
                  },
                ],
              },
            });
          case 'tools/call':
            final params = request['params'] as Map<String, dynamic>;
            final name = params['name'];
            final args = (params['arguments'] as Map?) ?? const {};
            if (name == 'echo') {
              _send({
                'jsonrpc': '2.0',
                'id': id,
                'result': {
                  'content': [
                    {'type': 'text', 'text': '${args['text']}'},
                  ],
                  'isError': false,
                },
              });
            } else if (name == 'add') {
              final sum = (args['a'] as num) + (args['b'] as num);
              _send({
                'jsonrpc': '2.0',
                'id': id,
                'result': {
                  'content': [
                    {'type': 'text', 'text': '$sum'},
                  ],
                  'isError': false,
                },
              });
            } else {
              _send({
                'jsonrpc': '2.0',
                'id': id,
                'error': {'code': -32602, 'message': 'unknown tool: $name'},
              });
            }
          default:
            _send({
              'jsonrpc': '2.0',
              'id': id,
              'error': {'code': -32601, 'message': 'method not found: $method'},
            });
        }
      });
}

void _send(Map<String, dynamic> message) {
  stdout.write('${jsonEncode(message)}\n');
}
