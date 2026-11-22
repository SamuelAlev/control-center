import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/core/notifications/rpc_notification_mapper.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRpcClient implements RemoteRpcClient {
  _FakeRpcClient(this.notifications);

  @override
  final Stream<JsonRpcNotification> notifications;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('FakeRpcClient.${invocation.memberName}');
}

class _RecordingPort implements NotificationPort {
  final shown = <AppNotification>[];

  @override
  void show(AppNotification notification) => shown.add(notification);

  @override
  void withdraw(NotificationWait wait) {}

  @override
  void dispose() {}
}

void main() {
  late StreamController<JsonRpcNotification> frames;
  late _RecordingPort port;
  late RpcNotificationMapper mapper;

  setUp(() {
    frames = StreamController<JsonRpcNotification>.broadcast();
    port = _RecordingPort();
    mapper = RpcNotificationMapper(
      client: _FakeRpcClient(frames.stream),
      notificationPort: port,
      localizations: AppLocalizationsEn.new,
      activeWorkspaceId: () => 'ws',
    );
  });

  tearDown(() async {
    mapper.dispose();
    await frames.close();
  });

  Future<void> send(String method, Map<String, dynamic> params) async {
    frames.add(JsonRpcNotification(method: method, params: params));
    await Future<void>.delayed(Duration.zero);
  }

  test('a new message marked notify and not quiet toasts as before', () async {
    await send('notifications/message_received', {
      'workspace_id': 'ws',
      'space_id': 'sp',
      'sender_name': 'Ada',
      'content_preview': 'Done with the branch',
      'notification_kind': 'notify',
      'quiet': false,
    });
    expect(port.shown, hasLength(1));
    expect(port.shown.single.title, 'Ada');
  });

  test(
    'a frame without the quiet field is not quiet, whatever its kind',
    () async {
      await send('notifications/message_received', {
        'workspace_id': 'ws',
        'space_id': 'sp',
        'sender_name': 'Ada',
        'content_preview': 'Done',
        'notification_kind': 'notify',
      });
      expect(port.shown, hasLength(1));
    },
  );

  test('a terminal goal_settled marked quiet is bell-only: no toast', () async {
    await send('notifications/goal_settled', {
      'workspace_id': 'ws',
      'goal_id': 'g1',
      'status': 'completed',
      'notification_kind': 'notify',
      'quiet': true,
    });
    expect(port.shown, isEmpty);
  });

  test('a goal paused for a person alerts', () async {
    await send('notifications/goal_settled', {
      'workspace_id': 'ws',
      'goal_id': 'g1',
      'status': 'paused',
      'hold': 'person',
      'notification_kind': 'question',
      'quiet': false,
    });
    expect(port.shown, hasLength(1));
    expect(port.shown.single.category, NotificationCategory.agentAwaitingInput);
    expect(
      port.shown.single.presentation,
      NotificationPresentation.notification,
    );
  });
}
