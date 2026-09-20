import 'package:cc_infra/src/rigs/host_shell_listeners.dart';
import 'package:test/test.dart';

void main() {
  group('descendantPidsFromPs', () {
    test('includes the root and its children, not a sibling pid', () {
      // pid 10 is the PTY; 11 is a server it spawned; 12 is another space's
      // shell whose parent is init. Scanning 12 would leak that space's
      // listener into this session's panel.
      const ps = '''
        10     1
        11    10
        12     1
        13    11
''';
      final tree = descendantPidsFromPs(ps, 10);
      expect(tree, {10, 11, 13});
      expect(tree.contains(12), isFalse);
    });

    test('an unknown root is only itself', () {
      expect(descendantPidsFromPs('  5  1\n', 99), {99});
    });

    test('a non-positive root is empty', () {
      expect(descendantPidsFromPs('  5  1\n', 0), isEmpty);
    });
  });

  group('parseLsofListen', () {
    const lsof = '''
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
node       11 me     20u  IPv4 0x1      0t0  TCP 127.0.0.1:5173 (LISTEN)
node       11 me     21u  IPv6 0x2      0t0  TCP *:5173 (LISTEN)
python     12 me      4u  IPv4 0x3      0t0  TCP *:3000 (LISTEN)
vite       13 me     12u  IPv4 0x4      0t0  TCP 127.0.0.1:5174 (LISTEN)
''';

    test('keeps a child listener and drops a sibling pid', () {
      final ports = parseLsofListen(lsof, {10, 11, 13});
      expect(ports.map((p) => p.port), [5173, 5174]);
      expect(ports.first.process, 'node');
      expect(ports.any((p) => p.port == 3000), isFalse);
    });

    test('caps at 16 so a scan cannot balloon state', () {
      final many = StringBuffer('COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME\n');
      for (var i = 1; i <= 40; i++) {
        many.writeln('x $i me 1u IPv4 0x1 0t0 TCP 127.0.0.1:${8000 + i} (LISTEN)');
      }
      final tree = {for (var i = 1; i <= 40; i++) i};
      expect(parseLsofListen(many.toString(), tree, cap: 16), hasLength(16));
    });

    test('an empty tree yields nothing', () {
      expect(parseLsofListen(lsof, const {}), isEmpty);
    });
  });
}
