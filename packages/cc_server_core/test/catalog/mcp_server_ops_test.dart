import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/mcp_server_status.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/mcp_server_ops.dart';
import 'package:test/test.dart';

/// The server's MCP token is the owner's: only they read or rotate it, while
/// any member may read the status, which never carries it.
void main() {
  late _Control control;

  setUp(() => control = _Control());

  Future<Map<String, dynamic>> call(
    String op, {
    required String userId,
    Map<String, dynamic> args = const {},
  }) =>
      RepoOpDispatcher(
        registry: RepoOpRegistry(buildMcpServerOps(mcp: control)),
        resolveServerOwner: (id) async => id == 'owner',
      ).call(
        id: 1,
        params: {'op': op, 'args': args},
        deviceId: 'device-1',
        userId: userId,
        sessionCapability: SessionCapability.fullClient,
      );

  Map<String, dynamic> data(Map<String, dynamic> res) =>
      (res['result'] as Map)['data'] as Map<String, dynamic>;

  test('the owner reads and rotates the token', () async {
    expect(data(await call('mcp.token', userId: 'owner')), {
      'token': 'token-1',
    });
    expect(data(await call('mcp.rotateToken', userId: 'owner')), {
      'token': 'token-2',
    });
    expect(control.current, 'token-2');
  });

  test('a member who is not the owner cannot read or rotate it', () async {
    for (final op in [
      'mcp.token',
      'mcp.rotateToken',
      'mcp.start',
      'mcp.stop',
    ]) {
      final res = await call(op, userId: 'member');
      expect(
        (res['error'] as Map)['code'],
        RpcErrorCodes.unauthorized,
        reason: op,
      );
      // The dispatcher's own refusal: no handler ran.
      expect(
        ((res['error'] as Map)['data'] as Map?)?['kind'],
        'server_owner_required',
        reason: op,
      );
      expect('$res', isNot(contains('token-1')), reason: op);
    }
    final res = await call(
      'mcp.setEnabled',
      userId: 'member',
      args: {'enabled': false},
    );
    expect((res['error'] as Map)['code'], RpcErrorCodes.unauthorized);
    expect(control.current, 'token-1');
  });

  test('any member reads the status, which carries no token', () async {
    final status = data(await call('mcp.status', userId: 'member'));
    expect(status, {'running': true, 'port': 9030, 'enabled': true});
  });

  test('there is no way to clear the token', () {
    final names = [for (final op in buildMcpServerOps(mcp: control)) op.name];
    expect(names, isNot(contains('mcp.setToken')));
    expect(names, isNot(contains('mcp.clearToken')));
  });
}

class _Control implements McpServerControl {
  var _n = 1;

  String get current => 'token-$_n';

  @override
  Future<McpServerStatus> status() async =>
      const McpServerStatus(running: true, port: 9030, enabled: true);

  @override
  Future<String> token() async => current;

  @override
  Future<String> rotateToken() async {
    _n++;
    return current;
  }

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setEnabled({required bool enabled}) async {}
}
