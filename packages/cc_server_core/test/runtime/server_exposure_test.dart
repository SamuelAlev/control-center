import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_server_core/src/cc_server_config.dart';
import 'package:cc_server_core/src/runtime/server_exposure.dart';
import 'package:test/test.dart';

void main() {
  CcServerConfig config(List<String> args) => CcServerConfig.resolve([
    '--data-dir',
    '/tmp/cc-exposure',
    ...args,
  ], environment: const {});

  test('a loopback server says so, with its relay and recorded owner', () {
    final line = describeServerExposure(
      config([]),
      ownerUserId: 'user-1',
      hostExecution: HostExecutionPosture.sandboxed,
    );
    expect(line, startsWith('cc_server exposure: '));
    expect(line, contains('bind=loopback (127.0.0.1)'));
    expect(line, contains('tls=off'));
    expect(line, contains('relay=${CcServerConfig.defaultSignalingUrl}'));
    expect(line, contains('tunnel=off'));
    expect(line, contains('owner=recorded (user-1)'));
    expect(line, endsWith(' sandbox=native'));
  });

  test('a network bind without TLS names the plaintext listener', () {
    final line = describeServerExposure(
      config(['--bind', 'any', '--insecure']),
      ownerUserId: 'user-1',
      hostExecution: HostExecutionPosture.sandboxed,
    );
    expect(line, contains('bind=network (0.0.0.0)'));
    expect(line, contains('tls=off (plaintext; a TLS proxy must front it)'));
  });

  test('TLS on, and no owner reads as none', () {
    final line = describeServerExposure(
      config([
        '--bind',
        'any',
        '--tls-cert',
        '/etc/cc/cert.pem',
        '--tls-key',
        '/etc/cc/key.pem',
      ]),
      ownerUserId: null,
      hostExecution: HostExecutionPosture.sandboxed,
    );
    expect(line, contains('tls=on'));
    expect(line, contains('owner=none'));
  });

  test('the sandbox posture is stated, with what it means for members', () {
    String line(HostExecutionPosture posture) => describeServerExposure(
      config([]),
      ownerUserId: 'user-1',
      hostExecution: posture,
    );
    expect(
      line(HostExecutionPosture.offByOwner),
      endsWith(" sandbox=off (members' agents run unconfined on this host)"),
    );
    expect(
      line(HostExecutionPosture.unavailable),
      endsWith(" sandbox=unavailable (only the owner's agent runs start)"),
    );
  });
}
