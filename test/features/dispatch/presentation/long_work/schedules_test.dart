import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/dispatch/presentation/settings/schedule_limits_section.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_page.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedules_list.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'long_work_harness.dart';

void main() {
  late FakeWakeRuleRepository repo;

  setUp(() => repo = FakeWakeRuleRepository());

  AppLocalizations l10n(WidgetTester tester, Type type) =>
      AppLocalizations.of(tester.element(find.byType(type)));

  final spaceOverrides = [
    workspaceSpacesProvider.overrideWith(
      (ref, ws) => Stream.value([
        Space(id: 'sp-1', name: 'Ops', createdAt: t0, updatedAt: t0),
      ]),
    ),
    spaceConversationsProvider.overrideWith(
      (ref, spaceId) => Stream.value([
        Conversation(
          id: 'conv-1',
          workspaceId: kTestWorkspaceId,
          spaceId: 'sp-1',
          title: 'Releases',
          createdAt: t0,
          updatedAt: t0,
        ),
      ]),
    ),
  ];

  Future<void> pumpList(WidgetTester tester, {TextDirection? dir}) =>
      pumpLongWork(
        tester,
        // The screen puts the button in its header, above the list.
        const Column(
          children: [
            NewScheduleButton(workspaceId: kTestWorkspaceId),
            Expanded(child: SchedulesList(workspaceId: kTestWorkspaceId)),
          ],
        ),
        overrides: [
          ...longWorkOverrides(rules: repo),
          ...spaceOverrides,
        ],
        textDirection: dir,
        settle: repo.rules != null,
      );

  Future<void> pumpPage(WidgetTester tester) => pumpLongWork(
    tester,
    const SchedulePage(workspaceId: kTestWorkspaceId, ruleId: 'rule-1'),
    overrides: longWorkOverrides(rules: repo),
  );

  group('cron preview', () {
    test("upcomingFires keeps the server's times still ahead", () {
      final rule = ruleFixture(
        trigger: 'cron:0 9 * * *',
        triggerKind: 'cron',
        nextFires: [
          DateTime.utc(2026, 11, 20, 8),
          DateTime.utc(2026, 11, 21, 8),
          DateTime.utc(2026, 11, 22, 8),
        ],
      );
      expect(upcomingFires(rule, DateTime.utc(2026, 11, 20, 12)), [
        DateTime.utc(2026, 11, 21, 8),
        DateTime.utc(2026, 11, 22, 8),
      ]);
      expect(upcomingFires(ruleFixture(), DateTime.utc(2026, 11, 20)), []);
    });
  });

  group('list', () {
    testWidgets('loading', (tester) async {
      repo.rules = null;
      await pumpList(tester);
      expect(find.byType(CcSpinner), findsOneWidget);
    });

    testWidgets('empty offers a new schedule', (tester) async {
      await pumpList(tester);
      final l = l10n(tester, SchedulesList);
      expect(find.text(l.schedulesEmpty), findsOneWidget);
      expect(find.text(l.scheduleNew), findsWidgets);
    });

    testWidgets('refused shows the sentence', (tester) async {
      repo.watchError = refusal('mystery_kind');
      await pumpList(tester);
      expect(find.textContaining('mystery_kind'), findsOneWidget);
    });

    testWidgets('populated rows: trigger, owner, cron fires, groups', (
      tester,
    ) async {
      repo.rules = [
        ruleFixture(),
        ruleFixture(
          id: 'rule-2',
          trigger: 'cron:0 9 * * *',
          triggerKind: 'cron',
          timeZone: 'Europe/Berlin',
          // The server's times; the past one is dropped.
          nextFires: [
            DateTime.now().toUtc().subtract(const Duration(hours: 1)),
            later,
          ],
        ),
        ruleFixture(id: 'rule-3', status: WakeRuleStatus.paused),
      ];
      await pumpList(tester);
      final l = l10n(tester, SchedulesList);
      expect(find.text(l.scheduleTriggerEvery('2h')), findsNWidgets(2));
      expect(
        find.text(l.scheduleTriggerCron('0 9 * * *', 'Europe/Berlin')),
        findsOneWidget,
      );
      expect(find.textContaining(l.scheduleOwnedBy('Sam')), findsWidgets);
      expect(find.textContaining('Next: '), findsOneWidget);
      expect(
        find.text(
          l.scheduleNextFires(
            workTimeLabel(tester.element(find.byType(SchedulesList)), later),
          ),
        ),
        findsOneWidget,
      );
      expect(find.textContaining(l.scheduleStatusPaused), findsWidgets);
    });

    testWidgets('right to left lays the list out without errors', (
      tester,
    ) async {
      repo.rules = [ruleFixture()];
      await pumpList(tester, dir: TextDirection.rtl);
      expect(tester.takeException(), isNull);
    });

    testWidgets("the dialog previews a cron with the server's answer", (
      tester,
    ) async {
      final fire = later;
      repo.preview = [fire];
      await pumpList(tester);
      final l = l10n(tester, SchedulesList);
      await tester.tap(find.text(l.scheduleNew).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.scheduleWhenEvery));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.scheduleWhenCron).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('schedule-zone')),
          matching: find.byType(EditableText),
        ),
        'Europe/Berlin',
      );
      // Typing asks nothing until the debounce has passed.
      await tester.pump();
      expect(repo.previews, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(repo.previews, ['0 9 * * 1-5@Europe/Berlin']);
      expect(
        find.text(
          l.scheduleNextFires(
            workTimeLabel(tester.element(find.byType(SchedulesList)), fire),
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets("the dialog's zone shows its error on the server's verdict "
        'and clears it when corrected', (tester) async {
      repo.unknownZones = {'Europe/Berln'};
      await pumpList(tester);
      final l = l10n(tester, SchedulesList);
      await tester.tap(find.text(l.scheduleNew).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.scheduleWhenEvery));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.scheduleWhenCron).last);
      await tester.pumpAndSettle();
      final zone = find.descendant(
        of: find.byKey(const ValueKey('schedule-zone')),
        matching: find.byType(EditableText),
      );
      await tester.enterText(zone, 'Europe/Berln');
      await tester.pump();
      // Well shaped: no error until the server answers.
      expect(find.text(l.scheduleZoneInvalid), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(l.scheduleZoneInvalid), findsOneWidget);
      await tester.enterText(zone, 'Europe/Berlin');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(l.scheduleZoneInvalid), findsNothing);
      // A malformed name fails at once, without asking.
      final asked = repo.previews.length;
      await tester.enterText(zone, 'Europe//');
      await tester.pump();
      expect(find.text(l.scheduleZoneInvalid), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(repo.previews, hasLength(asked));
    });

    testWidgets('create sends wakeRules.create with the draft', (tester) async {
      await pumpList(tester);
      final l = l10n(tester, SchedulesList);
      await tester.tap(find.text(l.scheduleNew).first);
      await tester.pumpAndSettle();
      for (final (hint, choice) in [
        (l.scheduleSpaceHint, 'Ops'),
        (l.scheduleConversationHint, 'Releases'),
        (l.scheduleAgentHint, 'Ada'),
      ]) {
        await tester.tap(find.text(hint));
        await tester.pumpAndSettle();
        await tester.tap(find.text(choice).last);
        await tester.pumpAndSettle();
      }
      await tester.enterText(
        find.byKey(const ValueKey('schedule-duration')),
        '2h',
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(CcTextArea),
          matching: find.byType(EditableText),
        ),
        'Check the release notes',
      );
      await tester.pumpAndSettle();

      repo.error = refusal('mystery_kind');
      await tester.tap(find.text(l.scheduleCreate));
      await tester.pumpAndSettle();
      expect(find.textContaining('mystery_kind'), findsOneWidget);

      repo.error = null;
      await tester.tap(find.text(l.scheduleCreate));
      await tester.pumpAndSettle();
      expect(repo.calls.last, 'create:$kTestWorkspaceId');
      expect(repo.draft?.when, 'every:2h');
      expect(repo.draft?.agentId, 'agent-2');
      expect(repo.draft?.conversationId, 'conv-1');
      expect(find.byType(CcDialog), findsNothing);
    });
  });

  group('page', () {
    testWidgets('not found', (tester) async {
      await pumpPage(tester);
      expect(
        find.text(l10n(tester, SchedulePage).scheduleNotFound),
        findsOneWidget,
      );
    });

    testWidgets("a cron rule's facts show the server's next fires, past "
        'ones dropped', (tester) async {
      repo.rules = [
        ruleFixture(
          trigger: 'cron:0 9 * * *',
          triggerKind: 'cron',
          timeZone: 'Europe/Berlin',
          nextFires: [
            DateTime.now().toUtc().subtract(const Duration(hours: 1)),
            later,
          ],
        ),
      ];
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      expect(find.text(l.scheduleFactNextFires), findsOneWidget);
      expect(
        find.text(
          workTimeLabel(tester.element(find.byType(SchedulePage)), later),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pause, delete with confirmation', (tester) async {
      repo.rules = [ruleFixture()];
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      await tester.tap(find.text(l.schedulePause));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.scheduleDelete));
      await tester.pumpAndSettle();
      expect(find.text(l.scheduleDeleteTitle), findsOneWidget);
      await tester.tap(find.text(l.scheduleDelete).last);
      await tester.pumpAndSettle();
      expect(repo.calls, [
        'pause:$kTestWorkspaceId:rule-1',
        'delete:$kTestWorkspaceId:rule-1',
      ]);
    });

    testWidgets('resume and extend are the owner\'s', (tester) async {
      repo.rules = [
        ruleFixture(status: WakeRuleStatus.paused, canChange: false),
      ];
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      for (final label in [l.scheduleResume, l.scheduleExtend]) {
        final button = tester.widget<CcButton>(
          find.ancestor(of: find.text(label), matching: find.byType(CcButton)),
        );
        expect(button.onPressed, isNull, reason: label);
      }
      expect(
        find.byWidgetPredicate(
          (w) => w is WorkTip && w.message == l.scheduleOwnerOnly,
        ),
        findsNWidgets(2),
      );
    });

    testWidgets('extend sends wakeRules.update with the new end', (
      tester,
    ) async {
      repo.rules = [ruleFixture()];
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      await tester.tap(find.text(l.scheduleExtend));
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(CcDialog),
              matching: find.byType(EditableText),
            )
            .first,
        '5',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.scheduleExtend).last);
      await tester.pumpAndSettle();
      expect(repo.calls, ['update:rule-1:max=null:cap=null:expires=true']);
    });

    testWidgets('the rule\'s own wakes and runs, paged by the server', (
      tester,
    ) async {
      repo.rules = [ruleFixture()];
      repo.runPages = {
        null: (
          wakes: [
            WakeRuleRunView(
              wakeId: 'w-3',
              reason: 'schedule',
              state: 'delivered',
              dueAt: t0,
              createdAt: t0,
              run: WakeRuleRunFactsView(
                id: 'run-3',
                status: 'completed',
                costMicros: 1250000,
                startedAt: t0,
                endedAt: t0,
              ),
            ),
            WakeRuleRunView(
              wakeId: 'w-2',
              reason: 'watch',
              state: 'skipped',
              stateReason: 'rule_folded',
              eventKind: 'pr_checks',
              status: 'failed',
              subject: 'acme/shop-ui#12',
              events: 3,
              dueAt: t0,
              createdAt: t0,
            ),
            WakeRuleRunView(
              wakeId: 'w-1',
              reason: 'schedule',
              state: 'teleported',
              stateReason: 'mystery_reason',
              dueAt: t0,
              createdAt: t0,
            ),
          ],
          nextCursor: 'c-2',
        ),
        'c-2': (
          wakes: [
            WakeRuleRunView(
              wakeId: 'w-0',
              reason: 'limit_reset',
              state: 'expired',
              dueAt: t0,
              createdAt: t0,
            ),
          ],
          nextCursor: null,
        ),
      };
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      expect(repo.runCalls, ['rule-1:']);
      expect(
        find.text(
          l.scheduleWakeLine(
            l.scheduleWakeReasonSchedule,
            l.scheduleWakeStateDelivered,
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.text(l.scheduleRunLine(l.scheduleRunCompleted, r'$1.25')),
        findsOneWidget,
      );
      expect(find.text(l.goalOpenConversation), findsOneWidget);
      expect(find.text(l.wakeKindRuleFolded), findsOneWidget);
      expect(
        find.textContaining('pr_checks · failed · acme/shop-ui#12'),
        findsOneWidget,
      );
      expect(find.textContaining(l.scheduleWakeEvents(3)), findsOneWidget);
      // A state and a reason this version does not name show as themselves.
      expect(find.text('teleported'), findsOneWidget);
      expect(find.text('mystery_reason'), findsOneWidget);

      await tester.tap(find.text(l.scheduleWakesOlder));
      await tester.pumpAndSettle();
      expect(repo.runCalls, ['rule-1:', 'rule-1:c-2']);
      expect(
        find.text(
          l.scheduleWakeLine(
            l.scheduleWakeReasonLimitReset,
            l.scheduleWakeStateExpired,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(l.scheduleWakesOlder), findsNothing);
      expect(repo.calls, isEmpty);
    });

    testWidgets('no wakes yet', (tester) async {
      repo.rules = [ruleFixture()];
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      expect(find.text(l.scheduleWakesNone), findsOneWidget);
    });

    testWidgets('a refused read of the wakes shows its sentence', (
      tester,
    ) async {
      repo.rules = [ruleFixture()];
      repo.runsError = refusal('mystery_kind');
      await pumpPage(tester);
      expect(find.textContaining('mystery_kind'), findsOneWidget);
    });

    testWidgets('right to left lays the page out without errors', (
      tester,
    ) async {
      repo.rules = [ruleFixture()];
      repo.runPages = {
        null: (
          wakes: [
            WakeRuleRunView(
              wakeId: 'w-1',
              reason: 'schedule',
              state: 'delivered',
              dueAt: t0,
              createdAt: t0,
              run: WakeRuleRunFactsView(
                id: 'run-1',
                status: 'running',
                costMicros: 0,
                startedAt: t0,
              ),
            ),
          ],
          nextCursor: 'c-2',
        ),
      };
      await pumpLongWork(
        tester,
        const SchedulePage(workspaceId: kTestWorkspaceId, ruleId: 'rule-1'),
        overrides: longWorkOverrides(rules: repo),
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SchedulePage), findsOneWidget);
    });

    testWidgets('a chained rule shows its chain and links its root', (
      tester,
    ) async {
      repo.rules = [
        ruleFixture(
          rootRuleId: 'rule-0',
          lineageRunsLeft: 7,
          lineageEndsAt: later,
          noteAuthor: WakeRuleOrigin.agent,
        ),
      ];
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      expect(find.text(l.scheduleFactChain), findsOneWidget);
      expect(find.textContaining('7 runs left'), findsOneWidget);
      expect(find.text(l.scheduleOpenChainRoot), findsOneWidget);
      expect(find.text(l.scheduleExtend), findsNothing);
      expect(find.text(l.scheduleNoteByAgent), findsOneWidget);
    });
  });

  group('limits section', () {
    testWidgets("the zone shows its error on the server's verdict, Save is "
        'off meanwhile, and both clear when corrected', (tester) async {
      repo.unknownZones = {'Europe/Berln'};
      await pumpLongWork(
        tester,
        ScheduleLimitsSection(
          workspaceId: kTestWorkspaceId,
          limits: WakeRuleLimits(),
          canEdit: true,
        ),
        overrides: longWorkOverrides(rules: repo),
      );
      final l = l10n(tester, ScheduleLimitsSection);
      CcButton save() => tester.widget<CcButton>(
        find.ancestor(of: find.text(l.save), matching: find.byType(CcButton)),
      );
      final zone = find.byType(EditableText).last;
      await tester.enterText(zone, 'Europe/Berln');
      await tester.pump();
      expect(find.text(l.scheduleZoneInvalid), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(l.scheduleZoneInvalid), findsOneWidget);
      expect(save().onPressed, isNull);
      expect(repo.previews, contains('@Europe/Berln'));
      await tester.enterText(zone, 'Europe/Berlin');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text(l.scheduleZoneInvalid), findsNothing);
      expect(save().onPressed, isNotNull);
    });
  });

  group('chain spend', () {
    testWidgets('a chain\'s first schedule says its spend covers the chain', (
      tester,
    ) async {
      repo.rules = [
        ruleFixture(),
        ruleFixture(
          id: 'rule-2',
          rootRuleId: 'rule-1',
          lineageRunsLeft: 16,
          lineageEndsAt: later,
        ),
      ];
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      expect(
        find.text(l.scheduleSpentWithChain(r'$0.75', r'$10.00')),
        findsOneWidget,
      );
      await pumpLongWork(
        tester,
        const SchedulePage(workspaceId: kTestWorkspaceId, ruleId: 'rule-1'),
        overrides: longWorkOverrides(rules: repo),
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a schedule with no chain shows the plain figure', (
      tester,
    ) async {
      repo.rules = [ruleFixture()];
      await pumpPage(tester);
      final l = l10n(tester, SchedulePage);
      expect(find.text(l.goalCardMoney(r'$0.75', r'$10.00')), findsOneWidget);
      expect(find.textContaining('chain'), findsNothing);
    });
  });
}
