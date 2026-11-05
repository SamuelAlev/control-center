import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:cc_domain/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/notifications/desktop_notification_delivery.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/core/notifications/notification_service.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ──────────────────────────────────────────────────────────────
/// Captures the OS-level delivery calls made by [LocalNotificationService].
class _FakeDelivery implements DesktopNotificationDelivery {
  final List<
    ({
      String id,
      String title,
      String body,
      String route,
      bool timeSensitive,
      String? approvalId,
    })
  >
  shown = [];
  final List<String> removed = [];
  int permissionRequests = 0;

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
    bool timeSensitive = false,
    String? approvalId,
  }) async {
    shown.add((
      id: id,
      title: title,
      body: body,
      route: route,
      timeSensitive: timeSensitive,
      approvalId: approvalId,
    ));
  }

  @override
  Future<void> remove(String id) async => removed.add(id);

  @override
  void dispose() {}
}

class _FakeSoundService implements NotificationSoundService {
  @override
  Future<void> play(NotificationSound sound, {double volume = 1.0}) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class _FakePreferences implements NotificationPreferencesPort {
  bool _globalEnabled = true;
  final Set<NotificationCategory> _disabled = {};

  @override
  Future<bool> isGlobalEnabled() async => _globalEnabled;

  @override
  Future<void> setGlobalEnabled({required bool enabled}) async =>
      _globalEnabled = enabled;
  @override
  Future<bool> isCategoryEnabled(NotificationCategory cat) async =>
      !_disabled.contains(cat);

  @override
  Future<void> setCategoryEnabled(
    NotificationCategory cat, {
    required bool enabled,
  }) {
    if (enabled) {
      _disabled.remove(cat);
    } else {
      _disabled.add(cat);
    }
    return Future.value();
  }

  final Set<String> _mutedRepos = {};

  @override
  Future<Set<String>> getMutedRepos() async => _mutedRepos;

  @override
  Future<void> setRepoMuted(String repoFullName, {required bool muted}) async {
    if (muted) {
      _mutedRepos.add(repoFullName.toLowerCase());
    } else {
      _mutedRepos.remove(repoFullName.toLowerCase());
    }
  }

  @override
  Future<BatchDeliveryPolicy> getBatchDeliveryPolicy() async =>
      BatchDeliveryPolicy.realtime;

  @override
  Future<void> setBatchDeliveryPolicy(BatchDeliveryPolicy policy) async {}

  @override
  Future<QuietHoursConfig> getQuietHours() async => const QuietHoursConfig(
    enabled: false,
    start: TimeOfDay(hour: 22, minute: 0),
    end: TimeOfDay(hour: 8, minute: 0),
  );

  @override
  Future<void> setQuietHours(QuietHoursConfig config) async {}

  @override
  Future<NotificationSound> getNotificationSound() async =>
      NotificationSound.ping;

  @override
  Future<void> setNotificationSound(NotificationSound sound) async {}

  @override
  Future<double> getVolume() async => 1.0;

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<int> getCalendarAlertLeadMinutes() async => 5;

  @override
  Future<void> setCalendarAlertLeadMinutes(int minutes) async {}
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('LocalNotificationService', () {
    late _FakePreferences prefs;
    late List<String> activeRoutes;
    late _FakeDelivery delivery;

    setUp(() async {
      prefs = _FakePreferences();
      activeRoutes = [];
      delivery = _FakeDelivery();
    });

    LocalNotificationService createService({
      bool appFocused = true,
      String? activeSpaceId,
      bool focusBlocking = false,
    }) {
      return LocalNotificationService(
        preferences: prefs,
        delivery: delivery,
        isRouteActive: (route) => activeRoutes.contains(route),
        soundService: _FakeSoundService(),
        isSpaceActive: (spaceId) => spaceId == activeSpaceId,
        isAppFocused: () => appFocused,
        isFocusBlocking: () => focusBlocking,
      );
    }

    AppNotification awaiting(String kind, {String waitId = 'cf_1'}) =>
        mapNotificationFrame('notifications/agent_awaiting_input', {
          'workspace_id': 'w1',
          'space_id': 'sp-1',
          'wait_id': waitId,
          'kind': kind,
          'agent_name': 'engineer',
          'summary': 'Push to a Git remote',
        }, l10n: lookupAppLocalizations(const Locale('en')))!;

    test(
      'an approval is time-sensitive, keyed by its wait and answerable',
      () async {
        final service = createService(appFocused: false);
        service.show(awaiting('approval'));
        await Future<void>.delayed(Duration.zero);
        final shown = delivery.shown.single;
        expect(shown.id, 'wait-cf_1');
        expect(shown.timeSensitive, isTrue);
        expect(shown.approvalId, 'cf_1');
        service.dispose();
      },
    );

    test('a question is time-sensitive but offers no approval', () async {
      final service = createService(appFocused: false);
      service.show(awaiting('question', waitId: 'msg-1'));
      await Future<void>.delayed(Duration.zero);
      final shown = delivery.shown.single;
      expect(shown.id, 'wait-msg-1');
      expect(shown.timeSensitive, isTrue);
      expect(shown.approvalId, isNull);
      service.dispose();
    });

    test(
      'an ordinary notification is neither time-sensitive nor answerable',
      () async {
        final service = createService(appFocused: false);
        service.show(
          const AppNotification(
            category: NotificationCategory.agentRunCompleted,
            title: 'Done',
            body: '',
            route: '/x',
            workspaceId: 'w1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        final shown = delivery.shown.single;
        expect(shown.id, startsWith('agentRunCompleted-'));
        expect(shown.timeSensitive, isFalse);
        expect(shown.approvalId, isNull);
        service.dispose();
      },
    );

    test('withdraw removes the wait\'s notification by its identifier', () {
      final service = createService()
        ..withdraw(NotificationWait(id: 'cf_9', kind: AgentInputKind.approval));
      expect(delivery.removed, ['wait-cf_9']);
      service.dispose();
    });

    test('a focus session that blocks notifications silences them', () async {
      final service = createService(appFocused: false, focusBlocking: true);
      service.show(awaiting('approval'));
      await Future<void>.delayed(Duration.zero);
      expect(delivery.shown, isEmpty);
      service.dispose();
    });

    test('a focus session with blocking off lets them through', () async {
      final service = createService(appFocused: false);
      service.show(awaiting('approval'));
      await Future<void>.delayed(Duration.zero);
      expect(delivery.shown, hasLength(1));
      service.dispose();
    });

    test('shows notification when enabled and not on target route', () async {
      final service = createService();
      service.show(
        const AppNotification(
          category: NotificationCategory.agentRunCompleted,
          title: 'Test',
          body: 'Body',
          route: '/chat/123',
          workspaceId: 'w1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(delivery.shown, hasLength(1));
      expect(delivery.shown.first.title, 'Test');
      expect(delivery.shown.first.route, '/chat/123');
      service.dispose();
    });

    test('suppresses notification when global is disabled', () async {
      prefs._globalEnabled = false;
      final service = createService();
      service.show(
        const AppNotification(
          category: NotificationCategory.agentRunCompleted,
          title: 'Test',
          body: 'Body',
          route: '/chat/123',
          workspaceId: 'w1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(delivery.shown, isEmpty);
      service.dispose();
    });

    test('suppresses notification when category is disabled', () async {
      await prefs.setCategoryEnabled(
        NotificationCategory.agentRunCompleted,
        enabled: false,
      );
      final service = createService();
      service.show(
        const AppNotification(
          category: NotificationCategory.agentRunCompleted,
          title: 'Test',
          body: 'Body',
          route: '/chat/123',
          workspaceId: 'w1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(delivery.shown, isEmpty);
      service.dispose();
    });

    test('suppresses notification when already on the target route', () async {
      activeRoutes.add('/chat/123');
      final service = createService();
      service.show(
        const AppNotification(
          category: NotificationCategory.agentRunCompleted,
          title: 'Test',
          body: 'Body',
          route: '/chat/123',
          workspaceId: 'w1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(delivery.shown, isEmpty);
      service.dispose();
    });

    test(
      'still notifies on the target route when the app is NOT focused',
      () async {
        // "I am already looking at it" requires actually looking. A conversation
        // left open behind another app is not being read, so the message is
        // exactly the news the banner exists to carry.
        activeRoutes.add('/chat/123');
        final service = createService(appFocused: false);
        service.show(
          const AppNotification(
            category: NotificationCategory.newMessage,
            title: 'Ada',
            body: 'ping',
            route: '/chat/123',
            workspaceId: 'w1',
            spaceId: 'sp-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(delivery.shown, hasLength(1));
        service.dispose();
      },
    );

    test('suppresses a message in the space I am focused on', () async {
      activeRoutes.add('/chat/123');
      final service = createService(activeSpaceId: 'sp-1');
      service.show(
        const AppNotification(
          category: NotificationCategory.newMessage,
          title: 'Ada',
          body: 'ping',
          route: '/chat/123',
          workspaceId: 'w1',
          spaceId: 'sp-1',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(delivery.shown, isEmpty);
      service.dispose();
    });

    test(
      'a policy block notifies in the active space, unlike its approval card',
      () async {
        final l10n = lookupAppLocalizations(const Locale('en'));
        const params = {
          'workspace_id': 'w1',
          'space_id': 'sp-1',
          'agent_name': 'Ada',
          'summary': 'git push origin main',
          'reason': 'A workspace rule denies this push.',
        };
        final blocked = mapNotificationFrame(
          'notifications/agent_action_blocked',
          params,
          l10n: l10n,
        )!;
        activeRoutes.add(blocked.route);
        final service = createService(activeSpaceId: 'sp-1');
        service.show(blocked);
        await Future<void>.delayed(Duration.zero);
        expect(delivery.shown.single.route, blocked.route);
        expect(delivery.shown.single.body, contains(params['reason']));

        service.show(
          mapNotificationFrame('notifications/agent_awaiting_input', {
            ...params,
            'kind': 'approval',
          }, l10n: l10n)!,
        );
        await Future<void>.delayed(Duration.zero);
        expect(
          delivery.shown,
          hasLength(1),
          reason: 'The pending approval is already visible in this space.',
        );
        service.dispose();
      },
    );

    test(
      'notifies for a message in a DIFFERENT space on the same route',
      () async {
        activeRoutes.add('/chat/123');
        final service = createService(activeSpaceId: 'sp-other');
        service.show(
          const AppNotification(
            category: NotificationCategory.newMessage,
            title: 'Ada',
            body: 'ping',
            route: '/chat/123',
            workspaceId: 'w1',
            spaceId: 'sp-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        expect(delivery.shown, hasLength(1));
        service.dispose();
      },
    );
  });

  group('MacOsChannelNotificationDelivery', () {
    const channelName = 'com.controlcenter/notifications';
    late List<MethodCall> nativeCalls;
    late List<String> navigated;
    late List<(String, bool)> answered;

    MacOsChannelNotificationDelivery createDelivery() =>
        MacOsChannelNotificationDelivery(
          onNavigate: navigated.add,
          onApproval: (id, {required approved}) => answered.add((id, approved)),
          actionLabels: () => (approve: 'Approve', deny: 'Deny'),
        );

    Future<void> sendFromNative(String method, Map<String, Object?> args) =>
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              channelName,
              const StandardMethodCodec().encodeMethodCall(
                MethodCall(method, args),
              ),
              (_) {},
            );

    setUp(() {
      nativeCalls = [];
      navigated = [];
      answered = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), (
            call,
          ) async {
            nativeCalls.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(channelName), null);
    });

    test('forwards id/title/body/route to the native notify call', () async {
      final delivery = createDelivery();
      await delivery.show(
        id: 'meetingStartsSoon-0',
        title: 'Meeting starting soon',
        body: 'Standup',
        route: '/calendar/evt-1',
      );

      expect(nativeCalls, hasLength(1));
      expect(nativeCalls.first.method, 'notify');
      final args = nativeCalls.first.arguments as Map;
      expect(args['identifier'], 'meetingStartsSoon-0');
      expect(args['title'], 'Meeting starting soon');
      expect(args['body'], 'Standup');
      expect(args['route'], '/calendar/evt-1');
      expect(args['timeSensitive'], isFalse);
      expect(args.containsKey('approvalId'), isFalse);
      delivery.dispose();
    });

    test('an approval carries its id, button titles and urgency', () async {
      final delivery = createDelivery();
      await delivery.show(
        id: 'wait-cf_1',
        title: 'engineer needs your approval',
        body: 'Push',
        route: '/w',
        timeSensitive: true,
        approvalId: 'cf_1',
      );

      final args = nativeCalls.single.arguments as Map;
      expect(args['timeSensitive'], isTrue);
      expect(args['approvalId'], 'cf_1');
      expect(args['approveLabel'], 'Approve');
      expect(args['denyLabel'], 'Deny');
      delivery.dispose();
    });

    test('remove withdraws by identifier', () async {
      final delivery = createDelivery();
      await delivery.remove('wait-cf_1');

      expect(nativeCalls.single.method, 'remove');
      expect((nativeCalls.single.arguments as Map)['identifier'], 'wait-cf_1');
      delivery.dispose();
    });

    test('routes a native click back through onNavigate', () async {
      final delivery = createDelivery();
      await sendFromNative('onNotificationClick', {'route': '/calendar/evt-1'});

      expect(navigated, ['/calendar/evt-1']);
      delivery.dispose();
    });

    test('routes Approve and Deny buttons to the approval handler', () async {
      final delivery = createDelivery();
      await sendFromNative('onNotificationAction', {
        'action': 'approve',
        'approvalId': 'cf_1',
      });
      await sendFromNative('onNotificationAction', {
        'action': 'deny',
        'approvalId': 'cf_2',
      });
      await sendFromNative('onNotificationAction', {
        'action': 'snooze',
        'approvalId': 'cf_3',
      });
      await sendFromNative('onNotificationAction', {'action': 'approve'});

      expect(answered, [('cf_1', true), ('cf_2', false)]);
      expect(navigated, isEmpty);
      delivery.dispose();
    });
  });

  group('NotificationPreferencesPort', () {
    test('_FakePreferences defaults to all enabled', () async {
      final prefs = _FakePreferences();
      expect(await prefs.isGlobalEnabled(), isTrue);
      for (final cat in NotificationCategory.values) {
        expect(await prefs.isCategoryEnabled(cat), isTrue);
      }
    });

    test('disabling a category is reflected', () async {
      final prefs = _FakePreferences();
      await prefs.setCategoryEnabled(
        NotificationCategory.newMessage,
        enabled: false,
      );
      expect(
        await prefs.isCategoryEnabled(NotificationCategory.newMessage),
        isFalse,
      );
      expect(
        await prefs.isCategoryEnabled(NotificationCategory.prMerged),
        isTrue,
      );
    });
  });
}
