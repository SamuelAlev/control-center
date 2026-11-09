import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/connection/server_descriptor_service.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:test/test.dart';

/// A public demo binds 0.0.0.0 inside its container; its descriptor must not
/// hand anonymous visitors the host's private interface addresses.
void main() {
  Future<ServerIdentity> identity() async {
    final seed = await ServerIdentityCrypto.generateSeed();
    final public = await ServerIdentityCrypto.publicKeyFromSeed(seed);
    return ServerIdentity(
      serverId: 'descriptor-test',
      seedB64: seed,
      publicKeyB64: public,
      fingerprint: ServerIdentityCrypto.fingerprintOf(public),
      relayRoom: RemoteControlCrypto.generateRoomCode(),
      relayOwnerToken: RemoteControlCrypto.generatePsk(),
      serverName: 'Descriptor test',
    );
  }

  final config = CcServerConfig.resolve(
    const ['--bind', 'any', '--port', '9030'],
    environment: const {'CC_SERVER_PUBLIC_URL': 'wss://demo.example.com/rpc'},
  );

  test('a demo descriptor carries no LAN paths', () async {
    final descriptor = await ServerDescriptorService(
      config: config,
      identity: await identity(),
      isDemo: true,
    ).describe();
    expect(descriptor.paths.whereType<LanPath>(), isEmpty);
    expect(descriptor.paths.whereType<WssPath>(), hasLength(1));
    expect(descriptor.isDemo, isTrue);
  });

  test('a regular server bound to any still advertises LAN paths', () async {
    final interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    final hasLan = interfaces.any((i) => i.addresses.any((a) => !a.isLoopback));
    final descriptor = await ServerDescriptorService(
      config: config,
      identity: await identity(),
    ).describe();
    expect(
      descriptor.paths.whereType<LanPath>(),
      hasLan ? isNotEmpty : isEmpty,
    );
  });
}
