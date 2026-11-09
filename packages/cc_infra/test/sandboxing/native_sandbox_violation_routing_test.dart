import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_infra/src/sandboxing/native_sandbox_adapter.dart';
import 'package:cc_infra/src/sandboxing/violation_monitor.dart';
import 'package:test/test.dart';

/// Two concurrent runs used to share one `_activeSession` field, so every
/// host-wide denial — and the exec-grant offer it triggers — went to the run
/// that started last.
void main() {
  final roots = {
    'agent-a::c1::chat': ['/work/a'],
    'agent-b::c2::chat': ['/work/b'],
  };
  List<String> rootsOf(String id) => roots[id] ?? const [];

  String? route(SandboxViolation v, Map<String, int> live) =>
      NativeSandboxAdapter.routeViolation(v, livePids: live, rootsOf: rootsOf);

  const both = {'agent-a::c1::chat': 100, 'agent-b::c2::chat': 200};

  test('the denied pid picks its own session', () {
    const v = SandboxViolation(
      action: 'network-outbound',
      target: 'x',
      pid: 100,
    );
    expect(route(v, both), 'agent-a::c1::chat');
  });

  test('a path inside exactly one session goes to that session', () {
    const v = SandboxViolation(
      action: 'process-exec*',
      target: '/work/b/node_modules/.bin/husky',
    );
    expect(route(v, both), 'agent-b::c2::chat');
  });

  test('an unattributable denial with two live runs goes nowhere', () {
    const v = SandboxViolation(
      action: 'network-outbound',
      target: 'evil.example',
    );
    expect(route(v, both), isNull);
  });

  test('with one live run, that run gets it', () {
    const v = SandboxViolation(
      action: 'network-outbound',
      target: 'evil.example',
    );
    expect(route(v, const {'agent-a::c1::chat': 100}), 'agent-a::c1::chat');
  });

  test('no live run, no session', () {
    const v = SandboxViolation(action: 'file-read*', target: '/work/a/x');
    expect(route(v, const {}), isNull);
  });

  test('the macOS log line carries the denied pid', () {
    final parsed = SandboxViolationMonitor.parseLogLine(
      '{"eventMessage":"Sandbox: claude(4242) deny(1) file-read-data /etc/x"}',
    );
    expect(parsed?.violation.pid, 4242);
    expect(parsed?.violation.target, '/etc/x');
  });
}
