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

  group('spaceRootForOverlay (exec-grant provenance)', () {
    test('reads the space root off a per-agent overlay', () {
      // Both overlay shapes the provisioner creates: with and without a
      // conversation suffix.
      expect(
        spaceRootForOverlay('/data/spaces/s1/agents/dev--conv-1'),
        '/data/spaces/s1',
      );
      expect(
        spaceRootForOverlay('/data/spaces/s1/agents/dev'),
        '/data/spaces/s1',
      );
    });

    test('tolerates a trailing separator', () {
      expect(
        spaceRootForOverlay('/data/spaces/s1/agents/dev--conv-1/'),
        '/data/spaces/s1',
      );
    });

    test('anything that is not an overlay has no space root', () {
      // The caller must not turn an operator-chosen path into implicit exec
      // authority just because it contains a directory called `agents`.
      expect(spaceRootForOverlay('/data/spaces/s1/repos/web-app'), isNull);
      expect(spaceRootForOverlay('/data/spaces/s1'), isNull);
      expect(spaceRootForOverlay('/home/me/project'), isNull);
      expect(spaceRootForOverlay(''), isNull);
      expect(spaceRootForOverlay('/agents/dev'), isNull);
      // Segment boundary: `agentsx` is not the overlay directory.
      expect(spaceRootForOverlay('/data/spaces/s1/agentsx/dev'), isNull);
    });
  });
}
