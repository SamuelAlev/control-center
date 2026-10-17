import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/notification_feed_visibility.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/push/web_push_repository.dart';
import 'package:cc_server_core/src/push/web_push_service.dart';
import 'package:cc_server_core/src/push/web_push_transport.dart';
import 'package:test/test.dart';
import 'package:webpush_encryption/webpush_encryption.dart';

import 'helpers/test_database.dart';

class _RecordingTransport extends WebPushTransport {
  _RecordingTransport([
    this.response = PushDeliveryResult.delivered,
    this.releasePreparation,
  ]);
  final PushDeliveryResult response;
  final Future<void>? releasePreparation;
  final enteredPreparation = Completer<void>();
  final reachedSend = Completer<void>();
  int attempts = 0;
  int delivered = 0;

  @override
  Future<PushDeliveryResult> send({
    required PushSubscriptionRecord subscription,
    required VapidIdentity vapid,
    required Uint8List payload,
    Future<bool> Function()? maySend,
  }) async {
    attempts++;
    enteredPreparation.complete();
    if (releasePreparation != null) {
      await releasePreparation;
    }
    final authorized = await maySend!();
    if (authorized) {
      delivered++;
    }
    reachedSend.complete();
    return authorized ? response : PushDeliveryResult.unavailable;
  }
}

void main() {
  late Directory temporary;
  late GlobalDatabase database;
  late WebPushRepository repository;
  late WebPushService service;

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('cc-webpush-test-');
    database = createTestGlobalDatabase();
    repository = WebPushRepository(FileSecretsStore(dataDir: temporary.path));
    service = WebPushService(
      repository: repository,
      devices: database.pairedDeviceDao,
      workspaceExists: (_) async => true,
      isMember: (_, _) async => true,
      canViewNotification: (_, _) async => true,
      ownerUserId: 'alice',
      viewerLogin: (_) async => '',
      vapid: (await VapidIdentity.generate()).identity,
    );
    for (final (id, user, status) in [
      ('device-a', 'alice', PairedDeviceStatus.active),
      ('device-b', 'bob', PairedDeviceStatus.active),
      ('device-revoked', 'alice', PairedDeviceStatus.revoked),
    ]) {
      await database.pairedDeviceDao.upsert(
        PairedDevicesTableCompanion(
          id: Value(id),
          userId: Value(user),
          label: Value(id),
          pskRef: const Value('file'),
          status: Value(status),
        ),
      );
    }
  });

  tearDown(() async {
    await service.dispose();
    await database.close();
    await temporary.delete(recursive: true);
  });

  test(
    'subscription persisted for authenticated device only; never returned',
    () async {
      final keys = (await WebPushKeySet.newKeyPair()).publicKey;
      await expectLater(
        service.register(
          userId: 'bob',
          deviceId: 'device-a',
          endpoint: 'https://fcm.googleapis.com/fcm/send/secret',
          p256dh: keys.p256dh,
          auth: keys.auth,
          categories: {'newMessage'},
          quiet: false,
        ),
        throwsStateError,
      );
      await expectLater(
        service.status('alice', 'device-revoked'),
        throwsStateError,
      );
      await expectLater(
        service.register(
          userId: 'alice',
          deviceId: 'device-a',
          endpoint: 'https://localhost/private',
          p256dh: keys.p256dh,
          auth: keys.auth,
          categories: {'newMessage'},
          quiet: false,
        ),
        throwsFormatException,
      );
      expect(await repository.read('device-a'), isNull);
      final result = await service.register(
        userId: 'alice',
        deviceId: 'device-a',
        endpoint: 'https://fcm.googleapis.com/fcm/send/secret',
        p256dh: keys.p256dh,
        auth: keys.auth,
        categories: {'newMessage'},
        quiet: false,
      );
      expect(result['enabled'], isTrue);
      expect(result.toString(), isNot(contains('/secret')));
      expect(
        (await repository.read('device-a'))?.endpoint,
        'https://fcm.googleapis.com/fcm/send/secret',
      );
    },
  );

  test(
    'server-owned subscription can be revoked without another device authority',
    () async {
      const endpoint = 'https://fcm.googleapis.com/fcm/send/opaque-token';
      await repository.save(
        'device-a',
        const PushSubscriptionRecord(
          endpoint: 'https://fcm.googleapis.com/fcm/send/opaque-token',
          p256dh: 'opaque-p256dh',
          auth: 'opaque-auth',
          categories: {'newMessage'},
          quiet: false,
        ),
      );
      final result = await service.status('alice', 'device-a');
      expect(result['enabled'], isTrue);
      expect(result.toString(), isNot(contains(endpoint)));
      expect(result.toString(), isNot(contains('opaque-auth')));
      await service.remove('alice', 'device-a');
      expect(await repository.read('device-a'), isNull);
      await repository.save(
        'device-b',
        const PushSubscriptionRecord(
          endpoint: 'https://fcm.googleapis.com/fcm/send/other',
          p256dh: 'opaque-p256dh',
          auth: 'opaque-auth',
          categories: {'newMessage'},
          quiet: false,
        ),
      );
      await service.revokeDevice('device-a');
      expect(await repository.read('device-b'), isNotNull);
    },
  );
  test(
    'membership revoked during encryption prevents the provider POST',
    () async {
      final transport = _RecordingTransport();
      var membershipReads = 0;
      final scoped = WebPushService(
        repository: repository,
        devices: database.pairedDeviceDao,
        workspaceExists: (_) async => true,
        isMember: (_, _) async => ++membershipReads == 1,
        canViewNotification: (_, _) async => true,
        ownerUserId: 'alice',
        viewerLogin: (_) async => '',
        vapid: (await VapidIdentity.generate()).identity,
        transport: transport,
      );
      await repository.save(
        'device-a',
        const PushSubscriptionRecord(
          endpoint: 'https://fcm.googleapis.com/fcm/send/private',
          p256dh: 'opaque',
          auth: 'opaque',
          categories: {'agentAwaitingInput'},
          quiet: false,
        ),
      );
      scoped.onRecorded(
        NotificationFeedItem(
          id: 'notice-1',
          workspaceId: 'workspace-1',
          method: 'notifications/agent_awaiting_input',
          params: const {'workspace_id': 'workspace-1', 'space_id': 'space-1'},
          createdAt: DateTime.now(),
        ),
      );
      await transport.reachedSend.future;
      await scoped.dispose();
      expect(membershipReads, 2);
      expect(transport.delivered, 0);
    },
  );
  test(
    'member without a linked repo or space grant never reaches transport',
    () async {
      await repository.save(
        'device-a',
        const PushSubscriptionRecord(
          endpoint: 'https://fcm.googleapis.com/fcm/send/private',
          p256dh: 'opaque',
          auth: 'opaque',
          categories: {'agentAwaitingInput'},
          quiet: false,
        ),
      );
      for (final params in [
        const {'repo_owner': 'Acme', 'repo_name': 'private'},
        const {'space_id': 'space-private'},
      ]) {
        final transport = _RecordingTransport();
        final checked = Completer<void>();
        final scoped = WebPushService(
          repository: repository,
          devices: database.pairedDeviceDao,
          workspaceExists: (_) async => true,
          isMember: (_, _) async => true,
          canViewNotification: (item, userId) async {
            final visible = await filterNotificationFeedItems(
              workspaceId: 'workspace-1',
              userId: userId,
              items: [item],
              isMember: true,
              repoIdsByCoordinate: const {'acme/private': 'repo-private'},
              readableRepoIds: const {},
              canReadSpace: (_) async => false,
            );
            checked.complete();
            return visible.isNotEmpty;
          },
          ownerUserId: 'alice',
          viewerLogin: (_) async => '',
          vapid: (await VapidIdentity.generate()).identity,
          transport: transport,
        );
        scoped.onRecorded(
          NotificationFeedItem(
            id: 'hidden-${params.keys.first}',
            workspaceId: 'workspace-1',
            method: 'notifications/agent_awaiting_input',
            params: params,
            createdAt: DateTime.now(),
          ),
        );
        await checked.future;
        await scoped.dispose();
        expect(transport.attempts, 0, reason: '$params');
        expect(transport.delivered, 0, reason: '$params');
      }
    },
  );

  test(
    'revoking a linked repo grant during preparation prevents POST',
    () async {
      final releasePreparation = Completer<void>();
      final transport = _RecordingTransport(
        PushDeliveryResult.delivered,
        releasePreparation.future,
      );
      final grants = <String>{'repo-private'};
      var visibilityReads = 0;
      final scoped = WebPushService(
        repository: repository,
        devices: database.pairedDeviceDao,
        workspaceExists: (_) async => true,
        isMember: (_, _) async => true,
        canViewNotification: (item, userId) async {
          visibilityReads++;
          return (await filterNotificationFeedItems(
            workspaceId: 'workspace-1',
            userId: userId,
            items: [item],
            isMember: true,
            repoIdsByCoordinate: const {'acme/private': 'repo-private'},
            readableRepoIds: grants,
            canReadSpace: (_) async => grants.contains('repo-private'),
          )).isNotEmpty;
        },
        ownerUserId: 'alice',
        viewerLogin: (_) async => '',
        vapid: (await VapidIdentity.generate()).identity,
        transport: transport,
      );
      await repository.save(
        'device-a',
        const PushSubscriptionRecord(
          endpoint: 'https://fcm.googleapis.com/fcm/send/private',
          p256dh: 'opaque',
          auth: 'opaque',
          categories: {'agentAwaitingInput'},
          quiet: false,
        ),
      );
      scoped.onRecorded(
        NotificationFeedItem(
          id: 'grant-revoked',
          workspaceId: 'workspace-1',
          method: 'notifications/agent_awaiting_input',
          params: const {
            'repo_id': 'repo-private',
            'space_id': 'space-private',
          },
          createdAt: DateTime.now(),
        ),
      );
      await transport.enteredPreparation.future;
      grants.clear();
      releasePreparation.complete();
      await transport.reachedSend.future;
      await scoped.dispose();
      expect(visibilityReads, 2);
      expect(transport.attempts, 1);
      expect(transport.delivered, 0);
    },
  );

  test('visible linked repo and space event still reaches provider', () async {
    final transport = _RecordingTransport();
    var visibilityReads = 0;
    final scoped = WebPushService(
      repository: repository,
      devices: database.pairedDeviceDao,
      workspaceExists: (_) async => true,
      isMember: (_, _) async => true,
      canViewNotification: (item, userId) async {
        visibilityReads++;
        return (await filterNotificationFeedItems(
          workspaceId: 'workspace-1',
          userId: userId,
          items: [item],
          isMember: true,
          repoIdsByCoordinate: const {'acme/private': 'repo-private'},
          readableRepoIds: const {'repo-private'},
          canReadSpace: (_) async => true,
        )).isNotEmpty;
      },
      ownerUserId: 'alice',
      viewerLogin: (_) async => '',
      vapid: (await VapidIdentity.generate()).identity,
      transport: transport,
    );
    await repository.save(
      'device-a',
      const PushSubscriptionRecord(
        endpoint: 'https://fcm.googleapis.com/fcm/send/private',
        p256dh: 'opaque',
        auth: 'opaque',
        categories: {'agentAwaitingInput'},
        quiet: false,
      ),
    );
    scoped.onRecorded(
      NotificationFeedItem(
        id: 'grant-allowed',
        workspaceId: 'workspace-1',
        method: 'notifications/agent_awaiting_input',
        params: const {'repo_id': 'repo-private', 'space_id': 'space-private'},
        createdAt: DateTime.now(),
      ),
    );
    await transport.reachedSend.future;
    await scoped.dispose();
    expect(visibilityReads, 2);
    expect(transport.attempts, 1);
    expect(transport.delivered, 1);
  });

  test(
    'expired provider subscription is deleted after HTTP 410 or 404',
    () async {
      final transport = _RecordingTransport(PushDeliveryResult.expired);
      final scoped = WebPushService(
        repository: repository,
        devices: database.pairedDeviceDao,
        workspaceExists: (_) async => true,
        isMember: (_, _) async => true,
        canViewNotification: (_, _) async => true,
        ownerUserId: 'alice',
        viewerLogin: (_) async => '',
        vapid: (await VapidIdentity.generate()).identity,
        transport: transport,
      );
      await repository.save(
        'device-a',
        const PushSubscriptionRecord(
          endpoint: 'https://fcm.googleapis.com/fcm/send/expired',
          p256dh: 'opaque',
          auth: 'opaque',
          categories: {'agentAwaitingInput'},
          quiet: false,
        ),
      );
      scoped.onRecorded(
        NotificationFeedItem(
          id: 'notice-2',
          workspaceId: 'workspace-1',
          method: 'notifications/agent_awaiting_input',
          params: const {'workspace_id': 'workspace-1'},
          createdAt: DateTime.now(),
        ),
      );
      await transport.reachedSend.future;
      await scoped.dispose();
      expect(await repository.read('device-a'), isNull);
    },
  );
}
