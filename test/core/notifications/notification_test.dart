import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/notifications/notification_sound.dart';
import 'package:cc_domain/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/notifications/desktop_notification_delivery.dart';
import 'package:control_center/core/notifications/notification_service.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ──────────────────────────────────────────────────────────────
/// Captures the OS-level delivery calls made by [LocalNotificationService].
class _FakeDelivery implements DesktopNotificationDelivery {
  final List<({String id, String title, String body, String route})> shown = [];
  int permissionRequests = 0;

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> show({
    required String id,
    required String title,
    required String body,
    required String route,
  }) async {
    shown.add((id: id, title: title, body: body, route: route));
  }

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
  Future<void> setRepoMuted(
    String repoFullName, {
    required bool muted,
  }) async {
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
    }) {
      return LocalNotificationService(
        preferences: prefs,
        delivery: delivery,
        isRouteActive: (route) => activeRoutes.contains(route),
        soundService: _FakeSoundService(),
        isSpaceActive: (spaceId) => spaceId == activeSpaceId,
        isAppFocused: () => appFocused,
      );
    }

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

    test('still notifies on the target route when the app is NOT focused',
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
    });

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

    test('notifies for a message in a DIFFERENT space on the same route',
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
    });
  });

  group('MacOsChannelNotificationDelivery', () {
    const channelName = 'com.controlcenter/notifications';
    late List<MethodCall> nativeCalls;
    late List<String> navigated;

    setUp(() {
      nativeCalls = [];
      navigated = [];
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
      final delivery = MacOsChannelNotificationDelivery(
        onNavigate: navigated.add,
      );
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
      delivery.dispose();
    });

    test('routes a native click back through onNavigate', () async {
      final delivery = MacOsChannelNotificationDelivery(
        onNavigate: navigated.add,
      );

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channelName,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onNotificationClick', {
                'route': '/calendar/evt-1',
              }),
            ),
            (_) {},
          );

      expect(navigated, ['/calendar/evt-1']);
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
