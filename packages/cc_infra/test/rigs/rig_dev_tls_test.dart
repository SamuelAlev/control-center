@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/rigs/rig_dev_tls.dart';
import 'package:cc_infra/src/rigs/rig_ports.dart';
import 'package:test/test.dart';

/// These tests mint real certificates with the host's openssl and drive a
/// real TLS handshake — that is the point: the material must satisfy
/// BoringSSL (dart:io), not just look like PEM.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cc-devtls-');
  });

  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on Object {
      // Best effort.
    }
  });

  test('mints a CA + wildcard leaf and computes the SPKI fingerprint',
      () async {
    final tls = RigDevTlsMaterial(dataDir: dir.path);
    await tls.ensure();
    expect(tls.isReady, isTrue, reason: 'This host has openssl.');

    // The fingerprint is base64 SHA-256 — 32 bytes.
    final spki = tls.spkiFingerprint;
    expect(spki, isNotNull);
    expect(base64Decode(spki!), hasLength(32));

    // Keys are private to the server user.
    if (!Platform.isWindows) {
      final keyStat = File('${dir.path}/rigs/tls/leaf.key').statSync();
      expect(keyStat.modeString(), 'rw-------');
      final caStat = File('${dir.path}/rigs/tls/ca.key').statSync();
      expect(caStat.modeString(), 'rw-------');
    }

    // The leaf carries the wildcard SANs both dev TLDs need.
    final dump = await Process.run('openssl', [
      'x509', '-in', '${dir.path}/rigs/tls/leaf.pem', '-noout', '-text',
    ]);
    expect('${dump.stdout}', contains('*.test'));
    expect('${dump.stdout}', contains('*.localhost'));
  });

  test('a second ensure loads the existing material rather than re-minting',
      () async {
    final first = RigDevTlsMaterial(dataDir: dir.path);
    await first.ensure();
    final leafBefore =
        File('${dir.path}/rigs/tls/leaf.pem').readAsStringSync();

    final second = RigDevTlsMaterial(dataDir: dir.path);
    await second.ensure();
    expect(second.isReady, isTrue);
    expect(second.spkiFingerprint, first.spkiFingerprint);
    expect(
      File('${dir.path}/rigs/tls/leaf.pem').readAsStringSync(),
      leafBefore,
      reason: 'Re-minting would rotate the key under a pinned fingerprint '
          'baked into already-running browser machines.',
    );
  });

  test('mints under a data dir whose ancestor contains a dot', () async {
    // LibreSSL derives the default -CAcreateserial path by truncating the CA
    // path at its FIRST dot — under /Users/samuel.alev that meant writing
    // /Users/samuel.srl, which is unwritable and killed the sign. The
    // explicit -CAserial keeps the serial inside the tls dir.
    final dotted = Directory('${dir.path}/samuel.alev/data');
    await dotted.create(recursive: true);
    final tls = RigDevTlsMaterial(dataDir: dotted.path);
    await tls.ensure();
    expect(tls.isReady, isTrue);
    expect(
      File('${dir.path}/samuel.srl').existsSync(),
      isFalse,
      reason: 'The serial file must never land at the truncated path.',
    );
  });

  test('a zero-byte leaf from a failed sign is re-minted, not served',
      () async {
    final first = RigDevTlsMaterial(dataDir: dir.path);
    await first.ensure();
    // What a signing failure leaves behind: openssl opens the output file
    // before it can fail, so leaf.pem exists but is empty.
    File('${dir.path}/rigs/tls/leaf.pem').writeAsStringSync('');

    final second = RigDevTlsMaterial(dataDir: dir.path);
    await second.ensure();
    expect(second.isReady, isTrue);
    expect(
      File('${dir.path}/rigs/tls/leaf.pem').lengthSync(),
      greaterThan(0),
      reason: 'An empty leaf must read as "not present" and trigger a '
          're-mint instead of being served forever.',
    );
  });

  test('the router HTTPS lane terminates TLS and routes by Host', () async {
    final tls = RigDevTlsMaterial(dataDir: dir.path);
    await tls.ensure();
    final context = tls.securityContext();
    expect(context, isNotNull);

    // A fake mux capturing the preamble, exactly like the HTTP-lane test.
    final mux = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final preamble = Completer<String>();
    mux.listen((socket) {
      final buffer = <int>[];
      socket.listen((chunk) {
        buffer.addAll(chunk);
        final text = String.fromCharCodes(buffer);
        if (text.contains('\n') && !preamble.isCompleted) {
          preamble.complete(text.split('\n').first);
          socket.add(
            'HTTP/1.1 200 OK\r\ncontent-length: 2\r\n\r\nok'.codeUnits,
          );
        }
      });
    });

    final router = RigDomainRouter(muxPortOf: (_) => mux.port);
    final tlsPort = await router.startTls(context!);
    expect(tlsPort, isNotNull);
    router.setRoute('secure.test', rigId: 'rig1', guestPort: 8443);
    addTearDown(() async {
      await router.dispose();
      await mux.close();
    });

    // The client pins nothing here, so accept the dev cert explicitly — the
    // enclosed browser's equivalent is its SPKI pin list.
    final client = await SecureSocket.connect(
      InternetAddress.loopbackIPv4,
      tlsPort!,
      onBadCertificate: (_) => true,
    );
    client.add('GET / HTTP/1.1\r\nHost: secure.test\r\n\r\n'.codeUnits);
    expect(
      await preamble.future.timeout(const Duration(seconds: 5)),
      '8443',
      reason: 'The handshake terminated here and the Host header picked the '
          'guest port — the whole HTTPS lane in one round trip.',
    );
    await client.close();
  });
}
