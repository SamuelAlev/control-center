import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/offline/offline_queue_provider.dart';
import 'package:control_center/features/shell/presentation/widgets/offline_pending_pill.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQueueController extends OfflineQueueController {
  _FakeQueueController(this._count);

  final int _count;

  @override
  int build() => _count;
}

Widget _wrap({required bool online, required int pending}) {
  return ProviderScope(
    overrides: [
      isOnlineProvider.overrideWithValue(online),
      offlineQueueControllerProvider.overrideWith(
        () => _FakeQueueController(pending),
      ),
    ],
    child: CcTheme(
      data: CcThemeData.light(),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: OfflinePendingPill()),
      ),
    ),
  );
}

void main() {
  group('OfflinePendingPill', () {
    testWidgets('collapses while offline with an empty queue (top bar owns '
        'the offline status)', (tester) async {
      await tester.pumpWidget(_wrap(online: false, pending: 0));
      await tester.pump();

      expect(find.text('Offline'), findsNothing);
      expect(find.byIcon(AppIcons.cloudOff), findsNothing);
      expect(
        find.descendant(
          of: find.byType(OfflinePendingPill),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });

    testWidgets('collapses while online with an empty queue', (tester) async {
      await tester.pumpWidget(_wrap(online: true, pending: 0));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(OfflinePendingPill),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
    });

    testWidgets('shows the queued count without offline status while offline', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(online: false, pending: 3));
      await tester.pump();

      expect(find.text('3 pending'), findsOneWidget);
      expect(find.text('Offline'), findsNothing);
      expect(find.byIcon(AppIcons.cloudOff), findsNothing);
      expect(find.byIcon(AppIcons.clock), findsOneWidget);
    });

    testWidgets('shows the flushing count while online', (tester) async {
      await tester.pumpWidget(_wrap(online: true, pending: 2));
      await tester.pump();

      expect(find.text('2 syncing'), findsOneWidget);
      expect(find.byIcon(AppIcons.refreshCw), findsOneWidget);
    });
  });
}
