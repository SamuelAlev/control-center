@TestOn('browser')
library;

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/remote_control/domain/services/pairing_payload.dart';
import 'package:cc_remote/app_connection.dart';
import 'package:cc_remote/pairing/pairing_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ConnectionDescriptor _descriptor({
  String serverId = 'server-one',
  String fingerprint = 'fingerprint-one',
  int port = 1,
}) => ConnectionDescriptor(
  serverId: serverId,
  serverName: 'Trusted server',
  fingerprint: fingerprint,
  paths: [LoopbackPath(port: port)],
);

PairingRecord _record({
  String serverId = 'server-one',
  String fingerprint = 'fingerprint-one',
  String deviceId = 'phone-one',
  String psk = 'paired-secret',
  int port = 1,
}) => PairingRecord.fromPayload(
  PairingPayload(
    descriptor: _descriptor(
      serverId: serverId,
      fingerprint: fingerprint,
      port: port,
    ),
    deviceId: deviceId,
    psk: psk,
    expiresAt: DateTime.utc(2020),
  ),
);

String _fragment(PairingRecord record) =>
    '#${PairingPayload(descriptor: record.descriptor, deviceId: record.deviceId, psk: record.psk, expiresAt: record.expiresAt).encode()}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = PairingStore();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PairingStore.captureBootFragment('');
    await store.clear();
  });
  tearDown(() async {
    PairingStore.captureBootFragment('');
    await store.clear();
  });

  test(
    'a repeated, expired QR resumes the saved credential and descriptor',
    () async {
      final saved = _record(port: 1);
      await store.save(saved);
      PairingStore.captureBootFragment(_fragment(_record(port: 2)));

      final session = RemoteSession();
      addTearDown(session.dispose);
      final connecting = session.uiState.firstWhere(
        (state) => state.status == RemoteStatus.connecting,
      );
      await session.start();
      await connecting;

      expect(session.pendingPairingRecord, isNull);
      expect((await store.load())!.descriptor.paths, saved.descriptor.paths);
    },
  );

  test(
    'a changed fingerprint needs confirmation and leaves the pin intact',
    () async {
      final saved = _record();
      await store.save(saved);
      PairingStore.captureBootFragment(
        _fragment(_record(fingerprint: 'untrusted-fingerprint')),
      );

      final session = RemoteSession();
      addTearDown(session.dispose);
      await session.start();

      expect(session.currentUiState.status, RemoteStatus.pendingPairing);
      expect(
        session.pendingPairingRecord!.descriptor.fingerprint,
        'untrusted-fingerprint',
      );
      expect((await store.load())!.pinnedFingerprint, saved.pinnedFingerprint);
    },
  );

  test('a changed server, device or secret is not an existing pairing', () {
    final saved = _record();
    expect(saved.matchesConfirmedOffer(_record(serverId: 'other')), isFalse);
    expect(saved.matchesConfirmedOffer(_record(deviceId: 'other')), isFalse);
    expect(saved.matchesConfirmedOffer(_record(psk: 'other')), isFalse);
    expect(saved.matchesConfirmedOffer(_record(fingerprint: 'other')), isFalse);
    expect(saved.matchesConfirmedOffer(_record(port: 2)), isTrue);
    expect(
      saved
          .copyWith(pinnedFingerprint: 'different')
          .matchesConfirmedOffer(saved),
      isFalse,
    );
  });
}
