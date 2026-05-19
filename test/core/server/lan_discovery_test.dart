import 'package:control_center/core/server/lan_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const baseTxt = <String, String>{
    'sid': 'srv-1234',
    'fp': 'deadbeefdeadbeef',
    'name': 'My Server',
    'tls': '1',
  };

  group('discoveredFrom', () {
    test('builds a server from full records, preferring the resolved IP', () {
      final server = discoveredFrom(
        instance: 'My Server._ccserver._tcp.local',
        target: 'devbox.local',
        port: 9800,
        txt: baseTxt,
        resolvedIp: '192.168.1.10',
      );
      expect(
        server,
        const DiscoveredServer(
          name: 'My Server',
          host: '192.168.1.10',
          port: 9800,
          serverId: 'srv-1234',
          fingerprintPrefix: 'deadbeefdeadbeef',
          tls: true,
        ),
      );
    });

    test('falls back to the SRV target when no IP resolved', () {
      final server = discoveredFrom(
        instance: 'My Server._ccserver._tcp.local',
        target: 'devbox.local.',
        port: 9800,
        txt: baseTxt,
      );
      // The trailing FQDN dot is stripped.
      expect(server?.host, 'devbox.local');
    });

    test('falls back to the instance label when TXT has no name', () {
      final txt = Map<String, String>.from(baseTxt)..remove('name');
      final server = discoveredFrom(
        instance: 'Basement Mac._ccserver._tcp.local',
        target: 'devbox.local',
        port: 9800,
        txt: txt,
      );
      expect(server?.name, 'Basement Mac');
    });

    test('rejects advertisements without a server id', () {
      expect(
        discoveredFrom(
          instance: 'x._ccserver._tcp.local',
          target: 'devbox.local',
          port: 9800,
          txt: const <String, String>{'name': 'No sid here'},
        ),
        isNull,
      );
      expect(
        discoveredFrom(
          instance: 'x._ccserver._tcp.local',
          target: 'devbox.local',
          port: 9800,
          txt: const <String, String>{'sid': '   '},
        ),
        isNull,
      );
    });

    test('rejects invalid ports and empty hosts', () {
      expect(
        discoveredFrom(
          instance: 'x._ccserver._tcp.local',
          target: 'devbox.local',
          port: 0,
          txt: baseTxt,
        ),
        isNull,
      );
      expect(
        discoveredFrom(
          instance: 'x._ccserver._tcp.local',
          target: 'devbox.local',
          port: 70000,
          txt: baseTxt,
        ),
        isNull,
      );
      expect(
        discoveredFrom(
          instance: 'x._ccserver._tcp.local',
          target: '',
          port: 9800,
          txt: baseTxt,
        ),
        isNull,
      );
    });

    test('parses tls flag strictly and defaults missing fp to empty', () {
      DiscoveredServer? withTxt(Map<String, String> txt) => discoveredFrom(
        instance: 'x._ccserver._tcp.local',
        target: 'devbox.local',
        port: 9800,
        txt: txt,
      );
      expect(withTxt(const {'sid': 'a', 'tls': '1'})?.tls, isTrue);
      expect(withTxt(const {'sid': 'a', 'tls': '0'})?.tls, isFalse);
      expect(withTxt(const {'sid': 'a'})?.tls, isFalse);
      expect(withTxt(const {'sid': 'a', 'tls': 'yes'})?.tls, isFalse);
      expect(withTxt(const {'sid': 'a'})?.fingerprintPrefix, isEmpty);
    });
  });

  group('instanceLabelOf', () {
    test('strips the service-type suffix, case-insensitively', () {
      expect(instanceLabelOf('My Server._ccserver._tcp.local'), 'My Server');
      expect(instanceLabelOf('My Server._CCSERVER._TCP.LOCAL'), 'My Server');
    });

    test('returns unrecognized names unchanged', () {
      expect(
        instanceLabelOf('printer._ipp._tcp.local'),
        'printer._ipp._tcp.local',
      );
      expect(instanceLabelOf(''), '');
    });
  });

  group('parseTxtEntries', () {
    test('splits newline-joined key=value entries', () {
      expect(
        parseTxtEntries('sid=abc\nfp=deadbeef\nname=My Server\ntls=1\n'),
        const <String, String>{
          'sid': 'abc',
          'fp': 'deadbeef',
          'name': 'My Server',
          'tls': '1',
        },
      );
    });

    test('keeps = characters inside values and empty values', () {
      expect(parseTxtEntries('name=a=b\nempty=\nflag'), const <String, String>{
        'name': 'a=b',
        'empty': '',
        'flag': '',
      });
    });

    test('later duplicates win and blank lines are ignored', () {
      expect(
        parseTxtEntries('sid=first\n\nsid=second\n'),
        const <String, String>{'sid': 'second'},
      );
      expect(parseTxtEntries(''), isEmpty);
    });
  });

  group('DiscoveredServer', () {
    const a = DiscoveredServer(
      name: 'My Server',
      host: '192.168.1.10',
      port: 9800,
      serverId: 'srv-1',
      fingerprintPrefix: 'deadbeef',
      tls: false,
    );

    test('equal values are == with matching hashCodes', () {
      const b = DiscoveredServer(
        name: 'My Server',
        host: '192.168.1.10',
        port: 9800,
        serverId: 'srv-1',
        fingerprintPrefix: 'deadbeef',
        tls: false,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('any differing field breaks equality', () {
      const differing = DiscoveredServer(
        name: 'My Server',
        host: '192.168.1.10',
        port: 9801,
        serverId: 'srv-1',
        fingerprintPrefix: 'deadbeef',
        tls: false,
      );
      expect(a, isNot(differing));
    });
  });
}
