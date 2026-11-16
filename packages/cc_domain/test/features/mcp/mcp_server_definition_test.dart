import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:test/test.dart';

final _t = DateTime.utc(2026, 11, 16, 10, 30, 15);

McpServerDefinition _def({
  String name = 'linear',
  McpServerTransport transport = McpServerTransport.http,
  String? command,
  String? url = 'https://mcp.example.com/mcp',
  List<String> envNames = const [],
  List<String> headerNames = const [],
}) => McpServerDefinition(
  id: 'id-1',
  workspaceId: 'ws-1',
  name: name,
  transport: transport,
  command: command,
  url: url,
  envNames: envNames,
  headerNames: headerNames,
  createdAt: _t,
  updatedAt: _t,
);

Matcher _refused(String code) => throwsA(
  isA<McpServerDefinitionException>().having((e) => e.code, 'code', code),
);

void main() {
  group('McpServerDefinition', () {
    test('round-trips through the wire, timestamps at stored precision', () {
      final def = McpServerDefinition(
        id: 'id-1',
        workspaceId: 'ws-1',
        name: 'local',
        transport: McpServerTransport.stdio,
        command: 'npx',
        args: const ['-y', 'some-mcp'],
        envNames: const ['B', 'A', 'A'],
        createdAt: DateTime(2026, 11, 16, 11, 0, 0, 123),
        updatedAt: _t,
      );
      expect(def.envNames, ['A', 'B']);
      expect(def.createdAt.isUtc, isTrue);
      expect(def.createdAt.millisecond, 0);
      expect(McpServerDefinition.fromJson(def.toJson()), def);
    });

    test('refuses names that would not make a short tool namespace', () {
      expect(() => _def(name: 'has space'), _refused('mcp_server.invalid_name'));
      expect(() => _def(name: 'a' * 25), _refused('mcp_server.invalid_name'));
      expect(() => _def(name: '-lead'), _refused('mcp_server.invalid_name'));
      expect(_def(name: 'a' * 24).name, hasLength(24));
    });

    test('a remote server needs an http(s) URL with no credentials in it', () {
      expect(() => _def(url: null), _refused('mcp_server.invalid_url'));
      expect(() => _def(url: 'ftp://x'), _refused('mcp_server.invalid_url'));
      expect(
        () => _def(url: 'https://user:pw@example.com'),
        _refused('mcp_server.invalid_url'),
      );
    });

    test('refuses headers the transport owns and duplicates by case', () {
      expect(
        () => _def(headerNames: const ['Host']),
        _refused('mcp_server.invalid_header'),
      );
      expect(
        () => _def(headerNames: const ['Mcp-Session-Id']),
        _refused('mcp_server.invalid_header'),
      );
      expect(
        () => _def(headerNames: const ['X-Key', 'x-key']),
        _refused('mcp_server.invalid_header'),
      );
    });

    test('a stdio server needs a command and takes no URL or headers', () {
      expect(
        () => _def(transport: McpServerTransport.stdio, url: null),
        _refused('mcp_server.invalid_command'),
      );
      expect(
        () => _def(transport: McpServerTransport.stdio, command: 'x'),
        _refused('mcp_server.invalid_transport'),
      );
      expect(
        () => _def(
          transport: McpServerTransport.stdio,
          command: 'x',
          url: null,
          envNames: const ['1BAD'],
        ),
        _refused('mcp_server.invalid_env'),
      );
    });

    test('approval counts only for the current owner', () {
      final def = _def().copyWith(hostApprovedBy: 'owner');
      expect(def.isHostApprovedBy('owner'), isTrue);
      expect(def.isHostApprovedBy('someone-else'), isFalse);
      expect(def.isHostApprovedBy(null), isFalse);
      expect(def.copyWith(clearHostApproval: true).hostApprovedBy, isNull);
    });
  });

  group('McpServerDraft', () {
    final previous = _def(headerNames: const ['Authorization', 'X-Org']);

    McpServerDefinition apply(McpServerDraft draft) => draft.toDefinition(
      id: 'id-1',
      workspaceId: 'ws-1',
      previous: previous,
      createdBy: 'u',
      hostApprovedBy: null,
      now: _t,
    );

    test('keeps names it does not mention, adds and removes the rest', () {
      final def = apply(
        McpServerDraft(
          id: 'id-1',
          name: 'linear',
          transport: McpServerTransport.http,
          url: 'https://mcp.example.com/mcp',
          headerSet: const {'X-New': 'v'},
          headerRemove: const {'x-org'},
        ),
      );
      expect(def.headerNames, ['Authorization', 'X-New']);
    });

    test('a name both written and removed is written', () {
      final def = apply(
        McpServerDraft(
          id: 'id-1',
          name: 'linear',
          transport: McpServerTransport.http,
          url: 'https://mcp.example.com/mcp',
          headerSet: const {'x-org': ''},
          headerRemove: const {'X-Org'},
        ),
      );
      expect(def.headerNames, ['Authorization', 'x-org']);
    });

    test('a change of transport carries no old names over', () {
      final def = apply(
        McpServerDraft(
          id: 'id-1',
          name: 'linear',
          transport: McpServerTransport.stdio,
          command: 'run-it',
          envSet: const {'TOKEN': 'v'},
        ),
      );
      expect(def.headerNames, isEmpty);
      expect(def.url, isNull);
      expect(def.envNames, ['TOKEN']);
    });

    test('a header value cannot smuggle another header', () {
      expect(
        () => apply(
          McpServerDraft(
            name: 'linear',
            transport: McpServerTransport.http,
            url: 'https://mcp.example.com/mcp',
            headerSet: const {'X-A': 'v\r\nHost: evil'},
          ),
        ),
        _refused('mcp_server.invalid_header'),
      );
    });

    test('only the enabled flag leaves the launch unchanged', () {
      McpServerDraft draft({bool enabled = true, String url = ''}) =>
          McpServerDraft(
            id: 'id-1',
            name: 'linear',
            transport: McpServerTransport.http,
            url: url.isEmpty ? 'https://mcp.example.com/mcp' : url,
            enabled: enabled,
          );
      expect(draft(enabled: false).changesLaunch(previous), isFalse);
      expect(
        draft(url: 'https://other.example.com').changesLaunch(previous),
        isTrue,
      );
      expect(
        McpServerDraft(
          id: 'id-1',
          name: 'linear',
          transport: McpServerTransport.http,
          url: 'https://mcp.example.com/mcp',
          headerRemove: const {'AUTHORIZATION'},
        ).changesLaunch(previous),
        isTrue,
      );
    });

    test('reads the RPC arguments it writes', () {
      final draft = McpServerDraft(
        name: 'local',
        transport: McpServerTransport.stdio,
        command: 'x',
        args: const ['--a'],
        envSet: const {'K': 'v'},
        envRemove: const {'OLD'},
      );
      final back = McpServerDraft.fromJson(draft.toJson());
      expect(back.envSet, {'K': 'v'});
      expect(back.envRemove, {'OLD'});
      expect(back.args, ['--a']);
      expect(
        () => McpServerDraft.fromJson({
          'name': 'x',
          'transport': 'carrier-pigeon',
        }),
        _refused('mcp_server.invalid_transport'),
      );
    });
  });
}
