import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/calendar_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/messaging_events.dart';
import 'package:control_center/core/domain/events/pr_events.dart';
import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/domain/notifications/notification_sound.dart';
import 'package:control_center/core/domain/ports/notification_port.dart';
import 'package:control_center/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/notifications/notification_event_mapper.dart';
import 'package:control_center/core/notifications/notification_service.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_notifier/local_notifier.dart';


// ── Fakes ──────────────────────────────────────────────────────────────
class _FakeLocalNotification extends LocalNotification {
  _FakeLocalNotification({required super.title, super.body}) : super();

  @override
  Future<void> show() async {}
}

class _FakeSoundService implements NotificationSoundService {
  @override
  Future<void> play(NotificationSound sound, {double volume = 1.0}) async {}
  @override
  Future<void> stop() async {}
  @override
  void dispose() {}
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
  @override
  Future<BatchDeliveryPolicy> getBatchDeliveryPolicy() async =>
      BatchDeliveryPolicy.realtime;

  @override
  Future<void> setBatchDeliveryPolicy(BatchDeliveryPolicy policy) async {}

  @override
  Future<QuietHoursConfig> getQuietHours() async =>
      const QuietHoursConfig(
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

/// Captures notifications shown by [NotificationPort.show].
class _RecordingNotificationPort implements NotificationPort {
  final List<AppNotification> shown = [];
  bool Function(String route)? routeActiveOverride;

  @override
  void show(AppNotification notification) {
    shown.add(notification);
  }

  @override
  void dispose() {}
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('LocalNotificationService', () {
    late _FakePreferences prefs;
    late List<String> navigatedRoutes;
    late List<String> activeRoutes;
    late List<AppNotification> shownNotifications;

    setUp(() async {
      prefs = _FakePreferences();
      navigatedRoutes = [];
      activeRoutes = [];
      shownNotifications = [];
    });

    LocalNotificationService createService() {
      return LocalNotificationService(
        preferences: prefs,
        onNavigate: navigatedRoutes.add,
        isRouteActive: (route) => activeRoutes.contains(route),
        soundService: _FakeSoundService(),
        localNotificationFactory: ({required String title, required String body}) {
          final n = _FakeLocalNotification(title: title, body: body);
          shownNotifications.add(AppNotification(
            category: NotificationCategory.agentRunCompleted,
            title: title,
            body: body,
            route: '',
            workspaceId: null,
          ));
          return n;
        },
      );
    }

    test('shows notification when enabled and not on target route', () async {
      final service = createService();
      service.show(const AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Test',
        body: 'Body',
        route: '/chat/123',
        workspaceId: 'w1',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(shownNotifications, hasLength(1));
      expect(shownNotifications.first.title, 'Test');
      service.dispose();
    });

    test('suppresses notification when global is disabled', () async {
      prefs._globalEnabled = false;
      final service = createService();
      service.show(const AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Test',
        body: 'Body',
        route: '/chat/123',
        workspaceId: 'w1',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(shownNotifications, isEmpty);
      service.dispose();
    });

    test('suppresses notification when category is disabled', () async {
      await prefs.setCategoryEnabled(
        NotificationCategory.agentRunCompleted,
        enabled: false,
      );
      final service = createService();
      service.show(const AppNotification(
        category: NotificationCategory.agentRunCompleted,
        title: 'Test',
        body: 'Body',
        route: '/chat/123',
        workspaceId: 'w1',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(shownNotifications, isEmpty);
      service.dispose();
    });
  });

  group('NotificationEventMapper', () {
    late DomainEventBus eventBus;
    late _RecordingNotificationPort port;
    late NotificationEventMapper mapper;

    setUp(() {
      eventBus = DomainEventBus();
      port = _RecordingNotificationPort();

      // The mapper tests use the recording port directly via NotificationEventMapper.

      // But for mapper tests, we use the recording port directly.
      mapper = NotificationEventMapper(
        eventBus: eventBus,
        notificationPort: port,
        localizations: AppLocalizationsEn.new,
      );
    });

    tearDown(() {
      mapper.dispose();
      eventBus.dispose();
    });

    test('maps AgentRunCompleted to notification', () async {
      eventBus.publish(AgentRunCompleted(
        agentId: 'a1',
        workspaceId: 'w1',
        conversationId: 'c1',
        occurredAt: DateTime.now(),
      ));

      // Allow stream to propagate.
      await Future<void>.delayed(Duration.zero);

      expect(port.shown, hasLength(1));
      expect(port.shown.first.category, NotificationCategory.agentRunCompleted);
      expect(port.shown.first.title, 'Agent finished');
      expect(port.shown.first.workspaceId, 'w1');
    });

    test('ignores AgentRunCompleted without conversationId', () async {
      eventBus.publish(AgentRunCompleted(
        agentId: 'a1',
        workspaceId: 'w1',
        conversationId: null,
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, isEmpty);
    });

    test('maps PullRequestPublished to notification', () async {
      eventBus.publish(PullRequestPublished(
        prId: 'pr1',
        workspaceId: 'w1',
        repoOwner: 'acme',
        repoName: 'widgets',
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, hasLength(1));
      expect(port.shown.first.category, NotificationCategory.pullRequestPublished);
      expect(port.shown.first.body, 'acme/widgets');
      expect(port.shown.first.workspaceId, 'w1');
    });

    test('maps MeetingStartingSoon to a meetingStartsSoon notification',
        () async {
      eventBus.publish(MeetingStartingSoon(
        workspaceId: 'w1',
        eventId: 'evt-1',
        title: 'Standup',
        startTime: DateTime.now().add(const Duration(minutes: 5)),
        meetingUrl: 'https://meet.google.com/x',
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, hasLength(1));
      expect(port.shown.first.category, NotificationCategory.meetingStartsSoon);
      expect(port.shown.first.body, 'Standup');
      expect(port.shown.first.route, '/calendar/evt-1');
      expect(port.shown.first.workspaceId, 'w1');
    });

    test('maps CalendarAuthExpired to a calendarAuthExpired notification',
        () async {
      eventBus.publish(CalendarAuthExpired(
        workspaceId: 'w1',
        accountEmail: 'me@example.com',
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, hasLength(1));
      expect(
        port.shown.first.category,
        NotificationCategory.calendarAuthExpired,
      );
      expect(port.shown.first.body, contains('me@example.com'));
      expect(port.shown.first.route, '/calendar');
      expect(port.shown.first.workspaceId, 'w1');
    });

    test('CalendarAuthExpired with no email uses the generic body', () async {
      eventBus.publish(CalendarAuthExpired(
        workspaceId: 'w1',
        accountEmail: '',
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, hasLength(1));
      expect(port.shown.first.body, isNotEmpty);
    });

    test('maps PrMerged to notification', () async {
      eventBus.publish(PrMerged(
        prId: 'pr1',
        workspaceId: 'w1',
        agentId: 'a1',
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, hasLength(1));
      expect(port.shown.first.category, NotificationCategory.prMerged);
    });

    test('maps MessageReceived from agent to notification', () async {
      eventBus.publish(MessageReceived(
        channelId: 'ch1',
        messageId: 'm1',
        senderName: 'Bot',
        contentPreview: 'Hello world',
        isAgentMessage: true,
        workspaceId: 'w1',
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, hasLength(1));
      expect(port.shown.first.category, NotificationCategory.newMessage);
      expect(port.shown.first.title, 'Bot');
      expect(port.shown.first.workspaceId, 'w1');
    });

    test('ignores MessageReceived from user', () async {
      eventBus.publish(MessageReceived(
        channelId: 'ch1',
        messageId: 'm1',
        senderName: 'You',
        contentPreview: 'Hi',
        isAgentMessage: false,
        workspaceId: 'w1',
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, isEmpty);
    });

    test('maps ExternalPrDetected to notification', () async {
      eventBus.publish(ExternalPrDetected(
        repoOwner: 'acme',
        repoName: 'lib',
        prNumber: 42,
        prTitle: 'Fix bug',
        author: 'jane',
        workspaceId: null,
        occurredAt: DateTime.now(),
      ));

      await Future<void>.delayed(Duration.zero);

      expect(port.shown, hasLength(1));
      expect(port.shown.first.category, NotificationCategory.externalPr);
      expect(port.shown.first.title, 'New PR to review');
      // External-PR polling is cross-workspace: no owning workspace, so it is
      // excluded from any workspace's scoped dashboard feed.
      expect(port.shown.first.workspaceId, isNull);
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
      await prefs.setCategoryEnabled(NotificationCategory.newMessage, enabled: false);
      expect(await prefs.isCategoryEnabled(NotificationCategory.newMessage), isFalse);
      expect(await prefs.isCategoryEnabled(NotificationCategory.prMerged), isTrue);
    });
  });
}
