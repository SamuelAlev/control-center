import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_key_value_pair.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/integrations/mcp_servers/mcp_server_form.dart';
import 'package:flutter_test/flutter_test.dart';

/// The editor's draft: only the picked transport's fields, and write-only
/// values as set/remove, never the stored values it cannot read.
void main() {
  final created = DateTime.utc(2026, 11);

  McpServerDefinition stdioServer() => McpServerDefinition(
    id: 'srv-1',
    workspaceId: 'ws-1',
    name: 'github',
    transport: McpServerTransport.stdio,
    command: 'npx',
    args: const ['-y', 'server-github'],
    envNames: const ['GITHUB_TOKEN', 'LOG_LEVEL', 'OLD'],
    createdAt: created,
    updatedAt: created,
  );

  McpServerDefinition httpServer() => McpServerDefinition(
    id: 'srv-2',
    name: 'linear',
    transport: McpServerTransport.http,
    url: 'https://mcp.example.com/mcp',
    headerNames: const ['Authorization', 'X-Team'],
    createdAt: created,
    updatedAt: created,
  );

  McpServerFormInput input({
    String name = 'github',
    McpServerTransport transport = McpServerTransport.stdio,
    String command = 'npx',
    String argsText = '-y\nserver-github',
    String url = '',
    bool enabled = true,
    McpSecretEdits? env,
    McpSecretEdits? headers,
  }) => McpServerFormInput(
    name: name,
    transport: transport,
    command: command,
    argsText: argsText,
    url: url,
    enabled: enabled,
    env: env ?? McpSecretEdits(const []),
    headers: headers ?? McpSecretEdits(const []),
  );

  test('a stdio edit replaces, removes and adds values by name', () {
    final existing = stdioServer();
    final env = McpSecretEdits(existing.envNames)
      ..replace('GITHUB_TOKEN')
      ..setReplacement('GITHUB_TOKEN', 'ghp_new')
      // Opened but left empty: the stored value stays.
      ..replace('LOG_LEVEL')
      ..remove('OLD')
      ..setAdded(const [
        SettingsKeyValuePair(' NEW_VAR ', 'v1'),
        SettingsKeyValuePair('', 'ignored'),
      ]);

    final draft = buildMcpServerDraft(
      input(argsText: '-y\n\n server-github \r\n', env: env),
      existing: existing,
    );

    expect(draft.id, 'srv-1');
    expect(draft.transport, McpServerTransport.stdio);
    expect(draft.command, 'npx');
    expect(draft.args, ['-y', ' server-github ']);
    expect(draft.url, isNull);
    expect(draft.envSet, {'GITHUB_TOKEN': 'ghp_new', 'NEW_VAR': 'v1'});
    expect(draft.envRemove, {'OLD'});
    expect(draft.headerSet, isEmpty);
    expect(draft.headerRemove, isEmpty);
  });

  test('undo keeps a stored value as it is', () {
    final env = McpSecretEdits(const ['A'])
      ..remove('A')
      ..keep('A');
    final draft = buildMcpServerDraft(input(env: env), existing: stdioServer());
    expect(draft.envSet, isEmpty);
    expect(draft.envRemove, isEmpty);
  });

  test('an http edit sends headers only, removing by name', () {
    final existing = httpServer();
    final headers = McpSecretEdits(existing.headerNames)
      ..remove('X-Team')
      ..setAdded(const [SettingsKeyValuePair('X-Org', 'acme')]);

    final draft = buildMcpServerDraft(
      input(
        name: 'linear',
        transport: McpServerTransport.http,
        command: 'leftover',
        url: ' https://mcp.example.com/v2 ',
        headers: headers,
        env: McpSecretEdits(const [])
          ..setAdded(const [SettingsKeyValuePair('STALE', 'x')]),
      ),
      existing: existing,
    );

    expect(draft.toJson(), {
      'id': 'srv-2',
      'name': 'linear',
      'transport': 'http',
      'args': <String>[],
      'url': 'https://mcp.example.com/v2',
      'enabled': true,
      'env_set': <String, String>{},
      'env_remove': <String>[],
      'header_set': {'X-Org': 'acme'},
      'header_remove': ['X-Team'],
    });
  });

  test('changing transport carries nothing stored over', () {
    final existing = httpServer();
    final headers = McpSecretEdits(existing.headerNames)
      ..remove('X-Team')
      ..replace('Authorization')
      ..setReplacement('Authorization', 'Bearer t');

    final draft = buildMcpServerDraft(
      input(
        name: 'linear',
        transport: McpServerTransport.sse,
        url: 'https://mcp.example.com/sse',
        headers: headers,
      ),
      existing: existing,
    );

    expect(draft.transport, McpServerTransport.sse);
    expect(draft.headerSet, isEmpty);
    expect(draft.headerRemove, isEmpty);
  });

  test('validation uses the server rules', () {
    expect(validateMcpServerForm(input()).isEmpty, isTrue);
    expect(validateMcpServerForm(input(name: 'bad name')).name, isTrue);
    expect(validateMcpServerForm(input(command: '  ')).command, isTrue);
    expect(
      validateMcpServerForm(
        input(transport: McpServerTransport.http, url: 'https://u:p@x.dev'),
      ).url,
      isTrue,
    );
    expect(
      validateMcpServerForm(
        input(
          env: McpSecretEdits(const [])
            ..setAdded(const [SettingsKeyValuePair('1BAD', 'x')]),
        ),
      ).envName,
      '1BAD',
    );
    expect(
      validateMcpServerForm(
        input(
          transport: McpServerTransport.http,
          url: 'https://mcp.example.com',
          headers: McpSecretEdits(const [])
            ..setAdded(const [SettingsKeyValuePair('Host', 'x')]),
        ),
      ).headerName,
      'Host',
    );
  });

  test('the enabled draft changes nothing stored', () {
    final draft = mcpServerEnabledDraft(stdioServer(), enabled: false);
    expect(draft.enabled, isFalse);
    expect(draft.changesLaunch(stdioServer()), isFalse);
    expect(draft.envSet, isEmpty);
    expect(draft.envRemove, isEmpty);
  });
}
