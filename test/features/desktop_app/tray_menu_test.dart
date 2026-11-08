import 'dart:ui';

import 'package:cc_rpc/cc_rpc.dart' show ServerConnectionPhase;
import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_menu.dart';
import 'package:control_center/features/desktop_app/providers/desktop_app_preferences.dart';
import 'package:control_center/features/desktop_app/providers/tray_status_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  const waiting = [
    TrayAttentionSpace(spaceId: 's1', name: 'Checkout', openQuestions: 2),
    TrayAttentionSpace(spaceId: 's2', name: '', openQuestions: 1),
  ];

  group('trayConnectionOf', () {
    test('maps every phase', () {
      expect(trayConnectionOf(null), TrayConnection.online);
      for (final phase in ServerConnectionPhase.values) {
        final expected = switch (phase) {
          ServerConnectionPhase.connected => TrayConnection.online,
          ServerConnectionPhase.connecting ||
          ServerConnectionPhase.reconnecting => TrayConnection.connecting,
          _ => TrayConnection.offline,
        };
        expect(trayConnectionOf(phase), expected, reason: '$phase');
      }
    });
  });

  group('TrayStatus', () {
    test('counts questions and approvals as needing the operator', () {
      const status = TrayStatus(
        connection: TrayConnection.online,
        workspaceId: 'w',
        attention: waiting,
        approvals: 2,
      );
      expect(status.questions, 3);
      expect(status.needsYou, 5);
      expect(status.tone, TrayIconTone.attention);
    });

    test('offline outranks attention', () {
      const status = TrayStatus(
        connection: TrayConnection.offline,
        attention: waiting,
      );
      expect(status.tone, TrayIconTone.offline);
    });

    test('a quiet workspace is the plain glyph', () {
      const status = TrayStatus(connection: TrayConnection.connecting);
      expect(status.tone, TrayIconTone.normal);
    });

    test('compares by value', () {
      expect(
        const TrayStatus(
          connection: TrayConnection.online,
          attention: [
            TrayAttentionSpace(spaceId: 'a', name: 'A', openQuestions: 1),
          ],
        ),
        TrayStatus(
          connection: TrayConnection.online,
          attention: [
            // A fresh list (not the const one above) with equal contents.
            const TrayAttentionSpace(spaceId: 'a', name: 'A', openQuestions: 1),
          ].toList(),
        ),
      );
    });
  });

  group('trayStatusSummary', () {
    test('says the connection when it is down', () {
      expect(
        trayStatusSummary(
          const TrayStatus(connection: TrayConnection.offline),
          l10n,
        ),
        l10n.trayStatusOffline,
      );
      expect(
        trayStatusSummary(
          const TrayStatus(connection: TrayConnection.connecting),
          l10n,
        ),
        l10n.trayStatusReconnecting,
      );
    });

    test('joins what waits with what works', () {
      expect(
        trayStatusSummary(
          const TrayStatus(
            connection: TrayConnection.online,
            attention: waiting,
            workingSpaces: 2,
          ),
          l10n,
        ),
        '3 need you · 2 working',
      );
    });

    test('is all quiet with nothing going on', () {
      expect(
        trayStatusSummary(
          const TrayStatus(connection: TrayConnection.online),
          l10n,
        ),
        l10n.trayStatusAllQuiet,
      );
    });
  });

  group('trayIconSpecFor', () {
    test('badges the waiting count only while online', () {
      const online = TrayStatus(
        connection: TrayConnection.online,
        attention: waiting,
      );
      expect(trayIconSpecFor(online, l10n).badge, '3');
      expect(
        trayIconSpecFor(online, l10n).tooltip,
        'Control Center · 3 need you',
      );

      const offline = TrayStatus(
        connection: TrayConnection.offline,
        attention: waiting,
      );
      expect(trayIconSpecFor(offline, l10n).badge, isNull);
    });
  });

  group('trayMenuFor', () {
    test('lists waiting spaces and approvals above the app commands', () {
      final menu = trayMenuFor(
        const TrayStatus(
          connection: TrayConnection.online,
          workspaceId: 'w',
          attention: waiting,
          approvals: 1,
        ),
        l10n,
      );
      final actions = menu.whereType<TrayMenuAction>().toList();
      expect(actions.map((a) => a.id), [
        '${TrayMenuIds.spacePrefix}s1',
        '${TrayMenuIds.spacePrefix}s2',
        TrayMenuIds.inbox,
        TrayMenuIds.open,
        TrayMenuIds.settings,
        TrayMenuIds.quit,
      ]);
      expect(actions[0].label, 'Checkout · 2 questions');
      // An unnamed space still gets a label.
      expect(actions[1].label, '${l10n.spaceLabel} · 1 question');
      expect(menu.first, isA<TrayMenuCaption>());
    });

    test('is just the commands when nothing waits', () {
      final menu = trayMenuFor(
        const TrayStatus(connection: TrayConnection.online),
        l10n,
      );
      expect(menu.whereType<TrayMenuAction>().map((a) => a.id), [
        TrayMenuIds.open,
        TrayMenuIds.settings,
        TrayMenuIds.quit,
      ]);
    });

    test('caps the space lines', () {
      final menu = trayMenuFor(
        TrayStatus(
          connection: TrayConnection.online,
          attention: [
            for (var i = 0; i < 9; i++)
              TrayAttentionSpace(spaceId: '$i', name: 'S$i', openQuestions: 1),
          ],
        ),
        l10n,
      );
      final spaces = menu.whereType<TrayMenuAction>().where(
        (a) => a.id.startsWith(TrayMenuIds.spacePrefix),
      );
      expect(spaces, hasLength(5));
    });
  });

  test('only Windows and Linux ask before the first hide', () {
    expect(asksBeforeFirstHide(TargetPlatform.macOS), isFalse);
    expect(asksBeforeFirstHide(TargetPlatform.windows), isTrue);
    expect(asksBeforeFirstHide(TargetPlatform.linux), isTrue);
  });
}
