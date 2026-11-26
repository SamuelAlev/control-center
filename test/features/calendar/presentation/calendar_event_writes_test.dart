import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_draft.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_event_write_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_composer_layer.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_event_actions.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_event_composer.dart';
import 'package:control_center/features/calendar/presentation/widgets/calendar_header_actions.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const _ws = 'ws-1';
const _account = 'google:ws-1:user-a:a@example.com';

const _primary = CalendarSourceView(
  accountId: _account,
  accountEmail: 'a@example.com',
  id: 'primary',
  summary: 'a@example.com',
  color: null,
  primary: true,
  writable: true,
);

class _Rpc implements RemoteRpcClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Records writes instead of calling the host.
class _Writes extends CalendarEventWriteService {
  _Writes() : super(_Rpc());

  final created = <CalendarEventDraft>[];
  final deleted = <CalendarEvent>[];
  bool fail = false;

  @override
  Future<String> create(String workspaceId, CalendarEventDraft draft) async {
    expect(workspaceId, _ws);
    if (fail) {
      throw StateError('host refused');
    }
    created.add(draft);
    return 'evt-new';
  }

  @override
  Future<void> delete(CalendarEvent event) async => deleted.add(event);
}

class _ClosedComposer extends CalendarComposerNotifier {
  @override
  CalendarSlot? build() => null;
}

class _OpenComposer extends CalendarComposerNotifier {
  _OpenComposer(this._slot);
  final CalendarSlot _slot;
  @override
  CalendarSlot? build() => _slot;
}

final _slot = CalendarSlot(
  start: DateTime(2026, 11, 19, 19),
  end: DateTime(2026, 11, 19, 20, 30),
  allDay: false,
  anchor: Offset.zero,
);

CalendarEvent _event({List<CalendarAttendee> attendees = const []}) =>
    CalendarEvent(
      id: 'evt-1',
      workspaceId: _ws,
      accountId: _account,
      externalEventId: 'g-1',
      calendarId: 'primary',
      title: 'Standup',
      startTime: DateTime.utc(2026, 11, 19, 9),
      endTime: DateTime.utc(2026, 11, 19, 9, 30),
      updatedAt: DateTime.utc(2026, 11, 8),
      attendees: attendees,
    );

/// [child] under a real router (saving and deleting navigate), with the
/// writes recorded by [writes] and [calendars] as the writable set.
Future<GoRouter> _pump(
  WidgetTester tester,
  Widget child, {
  required _Writes writes,
  List<CalendarSourceView>? calendars,
  TextDirection direction = TextDirection.ltr,
  bool composerOpen = true,
}) async {
  final router = GoRouter(
    initialLocation: calendarRoute(_ws),
    routes: [
      GoRoute(path: calendarRoute(workspaceIdParam), builder: (_, _) => child),
      GoRoute(
        path: '${calendarRoute(workspaceIdParam)}/:eventId',
        builder: (_, s) => Text('detail ${s.pathParameters['eventId']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.binding.setSurfaceSize(const Size(900, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        isDemoServerProvider.overrideWith((ref) => false),
        writableCalendarsProvider.overrideWithValue(calendars ?? [_primary]),
        allCalendarsProvider.overrideWithValue(calendars ?? [_primary]),
        calendarEventWriteServiceProvider.overrideWithValue(writes),
        calendarComposerProvider.overrideWith(
          () => composerOpen ? _OpenComposer(_slot) : _ClosedComposer(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          appLocalizationsDelegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: kSupportedAppLocales,
        locale: const Locale('en'),
        builder: (context, routed) => Directionality(
          textDirection: direction,
          child: CcTheme(
            data: CcThemeData.light(),
            child: CcToastScope(
              child: Material(child: routed ?? const SizedBox.shrink()),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  group('composer', () {
    testWidgets('books the drawn span and opens the new event', (tester) async {
      final writes = _Writes();
      final router = await _pump(
        tester,
        CalendarEventComposer(slot: _slot),
        writes: writes,
      );

      await tester.enterText(find.byType(EditableText).first, 'Design review');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      final draft = writes.created.single;
      expect(draft.title, 'Design review');
      expect(draft.accountId, _account);
      expect(draft.calendarId, 'primary');
      expect(draft.start, _slot.start.toUtc());
      expect(draft.end, _slot.end.toUtc());
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        calendarDetailRoute(_ws, 'evt-new'),
      );
    });

    testWidgets('a missing title stays open and says why', (tester) async {
      final writes = _Writes();
      await _pump(tester, CalendarEventComposer(slot: _slot), writes: writes);

      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.calendarComposerTitleRequired), findsOneWidget);
      expect(writes.created, isEmpty);
    });

    testWidgets('a refused booking keeps the card and what was typed', (
      tester,
    ) async {
      final writes = _Writes()..fail = true;
      await _pump(tester, CalendarEventComposer(slot: _slot), writes: writes);

      await tester.enterText(find.byType(EditableText).first, 'Review');
      await tester.tap(find.text(l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.calendarComposerSaveFailed), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
    });

    testWidgets('the new-event button puts the cursor in the title, and '
        'Escape hands focus back to the button', (tester) async {
      await _pump(
        tester,
        const CalendarComposerLayer(
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: CalendarNewEventButton(),
          ),
        ),
        writes: _Writes(),
        composerOpen: false,
      );

      // The pressed button keeps focus; the card asks for it all the same.
      await tester.tap(find.byType(CalendarNewEventButton));
      await tester.pumpAndSettle();
      final title = FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<CcTextField>();
      expect(title?.hintText, l10n.calendarComposerTitleHint);
      tester.testTextInput.enterText('Design review');
      await tester.pump();
      expect(find.text('Design review'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarEventComposer), findsNothing);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<CalendarNewEventButton>(),
        isNotNull,
      );
    });

    testWidgets('lays out right to left', (tester) async {
      await _pump(
        tester,
        CalendarEventComposer(slot: _slot),
        writes: _Writes(),
        direction: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.calendarComposerTitleHint), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('confirms, names the guests, then deletes', (tester) async {
      final writes = _Writes();
      final router = await _pump(
        tester,
        CalendarDeleteEventButton(
          event: _event(
            attendees: const [
              CalendarAttendee(
                email: 'a@example.com',
                self: true,
                organizer: true,
              ),
              CalendarAttendee(email: 'b@example.com'),
            ],
          ),
        ),
        writes: writes,
      );

      await tester.tap(find.bySemanticsLabel(l10n.calendarDeleteEvent));
      await tester.pumpAndSettle();
      expect(find.text(l10n.calendarDeleteConfirmGuests), findsOneWidget);

      await tester.tap(find.text(l10n.calendarDeleteEvent).last);
      await tester.pumpAndSettle();

      expect(writes.deleted.single.id, 'evt-1');
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        calendarRoute(_ws),
      );
    });

    testWidgets('hidden on a calendar the person cannot write to', (
      tester,
    ) async {
      await _pump(
        tester,
        CalendarDeleteEventButton(event: _event()),
        writes: _Writes(),
        calendars: const [],
      );
      expect(find.bySemanticsLabel(l10n.calendarDeleteEvent), findsNothing);
    });
  });

  group('new event button', () {
    test('today starts at the coming quarter hour', () {
      final span = CalendarNewEventButton.defaultSpan(
        DateTime(2026, 11, 8, 23),
        DateTime(2026, 11, 8, 14, 7),
      );
      expect(span.start, DateTime(2026, 11, 8, 14, 15));
      expect(span.end, DateTime(2026, 11, 8, 15, 15));
    });

    test('another day starts at nine', () {
      final span = CalendarNewEventButton.defaultSpan(
        DateTime(2026, 11, 12),
        DateTime(2026, 11, 8, 14, 7),
      );
      expect(span.start, DateTime(2026, 11, 12, 9));
    });
  });
}
