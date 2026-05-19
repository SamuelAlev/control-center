
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/domain/notifications/notification_sound.dart';
import 'package:control_center/core/domain/ports/notification_preferences_port.dart';
import 'package:control_center/core/notifications/notification_sound_service.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/notifications_section.dart';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

/// In-memory fake for [NotificationPreferencesPort] with configurable defaults.
class _FakeNotificationPreferences implements NotificationPreferencesPort {
  _FakeNotificationPreferences({
    this.globalEnabled = true,
    this.categoryEnabled = true,
  }) : batchPolicy = BatchDeliveryPolicy.digest2h,
       sound = NotificationSound.ping,
       volume = 1.0,
       quietHours = const QuietHoursConfig(
         enabled: false,
         start: TimeOfDay(hour: 22, minute: 0),
         end: TimeOfDay(hour: 8, minute: 0),
       );

  bool globalEnabled;
  bool categoryEnabled;
  BatchDeliveryPolicy batchPolicy;
  NotificationSound sound;
  double volume;
  QuietHoursConfig quietHours;

  @override
  Future<bool> isGlobalEnabled() async => globalEnabled;

  @override
  Future<void> setGlobalEnabled({required bool enabled}) async {
    globalEnabled = enabled;
  }

  @override
  Future<bool> isCategoryEnabled(NotificationCategory category) async =>
      categoryEnabled;

  @override
  Future<void> setCategoryEnabled(
    NotificationCategory category, {
    required bool enabled,
  }) async {
    categoryEnabled = enabled;
  }

  @override
  Future<BatchDeliveryPolicy> getBatchDeliveryPolicy() async => batchPolicy;

  @override
  Future<void> setBatchDeliveryPolicy(BatchDeliveryPolicy policy) async {
    batchPolicy = policy;
  }

  @override
  Future<NotificationSound> getNotificationSound() async => sound;

  @override
  Future<void> setNotificationSound(NotificationSound sound) async {
    this.sound = sound;
  }

  @override
  Future<double> getVolume() async => volume;

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
  }

  int calendarAlertLeadMinutes = 5;

  @override
  Future<int> getCalendarAlertLeadMinutes() async => calendarAlertLeadMinutes;

  @override
  Future<void> setCalendarAlertLeadMinutes(int minutes) async {
    calendarAlertLeadMinutes = minutes;
  }

  @override
  Future<QuietHoursConfig> getQuietHours() async => quietHours;

  @override
  Future<void> setQuietHours(QuietHoursConfig config) async {
    quietHours = config;
  }
}

/// Minimal fake for [NotificationSoundService] that tracks play calls.
class _FakeNotificationSoundService extends NotificationSoundService {
  NotificationSound? lastPlayedSound;
  double? lastPlayedVolume;
  int playCallCount = 0;

  @override
  Future<void> play(NotificationSound sound, {double volume = 1.0}) async {
    lastPlayedSound = sound;
    lastPlayedVolume = volume;
    playCallCount++;
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

Widget _buildSection({
  _FakeNotificationPreferences? prefs,
  _FakeNotificationSoundService? soundService,
}) {
  final effectivePrefs = prefs ?? _FakeNotificationPreferences();
  final effectiveSound = soundService ?? _FakeNotificationSoundService();

  return testWrap(
    ProviderScope(
      overrides: [
        notificationPreferencesProvider.overrideWith((ref) => effectivePrefs),
        notificationSoundServiceProvider.overrideWith((ref) => effectiveSound),
      ],
      child: const Scaffold(
        body: SingleChildScrollView(child: NotificationsSection()),
      ),
    ),
  );
}

void main() {
  group('NotificationsSection rendering', () {
    testWidgets('renders section header', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.text('NOTIFICATIONS'), findsOneWidget);
    });

    testWidgets('renders global enable toggle', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.text('Enable notifications'), findsOneWidget);
      expect(
        find.text('Show native macOS notifications for events.'),
        findsOneWidget,
      );
      expect(find.byType(CcSwitch), findsWidgets);
    });

    testWidgets('renders category rows when enabled', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byIcon(LucideIcons.bot), findsOneWidget);
      expect(find.byIcon(LucideIcons.ticket), findsOneWidget);
    });

    testWidgets('renders batch policy row', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.text('Delivery schedule'), findsOneWidget);
    });

    testWidgets('renders sound row', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.text('Notification sound'), findsOneWidget);
      expect(
        find.text('Sound played when a notification is shown.'),
        findsOneWidget,
      );
    });

    testWidgets('renders quiet hours row', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.text('Quiet hours'), findsOneWidget);
    });

    testWidgets('renders test sound button', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('volume slider is present', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('has correct switch count', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      // 1 global + 9 category switches (incl. meetingStartsSoon +
      // calendarAuthExpired) + 1 quiet-hours.
      expect(find.byType(CcSwitch), findsNWidgets(11));
    });

    testWidgets('category titles render', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.text('Agent finished'), findsOneWidget);
      expect(find.text('PR published'), findsOneWidget);
      expect(find.text('PR merged'), findsOneWidget);
      expect(find.text('New messages'), findsOneWidget);
      expect(find.text('External PRs'), findsOneWidget);
      expect(find.text('Ticket assigned'), findsWidgets);
      expect(find.text('Ticket status changed'), findsWidgets);
    });
  });

  group('Toggle interactions', () {
    testWidgets('toggling global off calls setGlobalEnabled', (tester) async {
      final prefs = _FakeNotificationPreferences(globalEnabled: true);

      await tester.pumpWidget(_buildSection(prefs: prefs));
      await tester.pump();

      await tester.tap(find.byType(CcSwitch).first);
      await tester.pump();

      expect(prefs.globalEnabled, isFalse);
    });

    testWidgets('toggling a category off calls setCategoryEnabled',
        (tester) async {
      final prefs = _FakeNotificationPreferences(categoryEnabled: true);

      await tester.pumpWidget(_buildSection(prefs: prefs));
      await tester.pump();

      final switches = find.byType(CcSwitch);
      await tester.tap(switches.at(1));
      await tester.pump();

      expect(prefs.categoryEnabled, isFalse);
    });

    testWidgets('toggling quiet hours on calls setQuietHours',
        (tester) async {
      final prefs = _FakeNotificationPreferences();

      await tester.pumpWidget(_buildSection(prefs: prefs));
      await tester.pump();

      final switches = find.byType(CcSwitch);
      await tester.ensureVisible(switches.last);
      await tester.pump();
      await tester.tap(switches.last);
      await tester.pump();

      expect(prefs.quietHours.enabled, isTrue);
    });
  });

  group('Sound test button', () {
    testWidgets('tapping test button calls play', (tester) async {
      final soundService = _FakeNotificationSoundService();

      await tester.pumpWidget(_buildSection(soundService: soundService));
      await tester.pump();

      await tester.ensureVisible(find.text('Test'));
      await tester.pump();
      await tester.tap(find.text('Test'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(soundService.playCallCount, 1);
      expect(soundService.lastPlayedSound, NotificationSound.ping);
    });
  });

  group('Edge cases', () {
    testWidgets('section renders without crashing', (tester) async {
      await tester.pumpWidget(_buildSection());
      await tester.pump();

      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.byType(CcSwitch), findsWidgets);
    });

    testWidgets('section renders when globally disabled', (tester) async {
      final prefs = _FakeNotificationPreferences(globalEnabled: false);

      await tester.pumpWidget(_buildSection(prefs: prefs));
      await tester.pump();

      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Enable notifications'), findsOneWidget);
    });
  });
}
