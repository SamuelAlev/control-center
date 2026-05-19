import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

void main() {
  group('parseJsonConfig', () {
    test('Claude-style mcpServers (stdio)', () {
      final configs = McpConfigDiscovery.parseJsonConfig(
        '{"mcpServers":{"fs":{"command":"npx","args":["-y","@mcp/fs"],'
        '"env":{"ROOT":"/tmp"}}}}',
        source: 'claude:~/.claude.json',
      );
      expect(configs, hasLength(1));
      final fs = configs.single;
      expect(fs.name, 'fs');
      expect(fs.transport, McpTransportKind.stdio);
      expect(fs.command, 'npx');
      expect(fs.args, ['-y', '@mcp/fs']);
      expect(fs.env['ROOT'], '/tmp');
      expect(fs.source, 'claude:~/.claude.json');
    });

    test('VS Code-style servers with explicit http type', () {
      final configs = McpConfigDiscovery.parseJsonConfig(
        '{"servers":{"gh":{"type":"http","url":"https://api.example/mcp"}}}',
        source: 'vscode:.vscode/mcp.json',
      );
      expect(configs.single.transport, McpTransportKind.http);
      expect(configs.single.url, 'https://api.example/mcp');
    });

    test('OpenCode-style mcp with local/remote discriminators', () {
      final configs = McpConfigDiscovery.parseJsonConfig(
        '{"mcp":{"local-one":{"type":"local","command":["bun","run","x.ts"]},'
        '"remote-one":{"type":"remote","url":"https://r.example/mcp"}}}',
        source: 'opencode:opencode.json',
      );
      final byName = {for (final c in configs) c.name: c};
      expect(byName['local-one']!.transport, McpTransportKind.stdio);
      expect(byName['local-one']!.command, 'bun');
      expect(byName['local-one']!.args, ['run', 'x.ts']);
      expect(byName['remote-one']!.transport, McpTransportKind.http);
    });

    test('respects disabled and enabled flags', () {
      final disabled = McpConfigDiscovery.parseJsonConfig(
        '{"mcpServers":{"a":{"command":"x","disabled":true}}}',
        source: 's',
      );
      expect(disabled.single.enabled, isFalse);

      final enabled = McpConfigDiscovery.parseJsonConfig(
        '{"mcpServers":{"a":{"command":"x","enabled":false}}}',
        source: 's',
      );
      expect(enabled.single.enabled, isFalse);
    });

    test('ignores malformed JSON', () {
      expect(
        McpConfigDiscovery.parseJsonConfig('{not json', source: 's'),
        isEmpty,
      );
    });
  });

  group('parseCodexToml', () {
    test('extracts mcp_servers tables', () {
      const toml = '''
[mcp_servers.docs]
command = "uvx"
args = ["mcp-server-docs", "--port", "0"]

[other]
ignored = true
''';
      final configs = McpConfigDiscovery.parseCodexToml(toml, source: 'codex');
      expect(configs, hasLength(1));
      expect(configs.single.name, 'docs');
      expect(configs.single.command, 'uvx');
      expect(configs.single.args, ['mcp-server-docs', '--port', '0']);
    });
  });

  group('discover() merges and lets workspace win', () {
    test('workspace config overrides same-named user config', () async {
      final files = <String, String>{
        '/home/.claude.json':
            '{"mcpServers":{"shared":{"command":"user-cmd"}}}',
        '/ws/.mcp.json': '{"mcpServers":{"shared":{"command":"ws-cmd"}}}',
      };
      final discovery = McpConfigDiscovery(
        homeDir: '/home',
        workspaceDir: '/ws',
        readFile: (path) async => files[path],
      );
      final configs = await discovery.discover();
      final shared = configs.firstWhere((c) => c.name == 'shared');
      expect(shared.command, 'ws-cmd');
    });
  });
}
