import 'package:cc_domain/core/domain/ports/repo_workspace_provisioner_port.dart';
import 'package:test/test.dart';

void main() {
  test('a conversation gets its own overlay next to the bare slug', () {
    expect(agentOverlayDirName('dev', 'conv-1'), 'dev--conv-1');
    expect(agentOverlayDirName('dev', null), 'dev');
  });

  test('an id that is not a plain token never becomes a path segment', () {
    expect(agentOverlayDirName('dev', '../x'), 'dev');
    expect(agentOverlayDirName('dev', 'a/b'), 'dev');
    expect(agentOverlayDirName('dev', ''), 'dev');
  });
}
