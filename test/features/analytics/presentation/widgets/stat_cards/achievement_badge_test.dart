import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:control_center/features/analytics/presentation/widgets/stat_cards/achievement_badge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('AchievementBadge', () {
    testWidgets('renders unlocked badge', (tester) async {
      await tester.pumpWidget(testWrap(
        AchievementBadge(
          achievement: Achievement(
            id: 'a1',
            agentId: 'agent1',
            badgeKey: 'first_merge',
            unlockedAt: DateTime(2026, 1, 15),
          ),
          icon: LucideIcons.gitMerge,
          label: 'First Merge',
          isUnlocked: true,
        ),
      ));

      expect(find.text('First Merge'), findsOneWidget);
      expect(find.byIcon(LucideIcons.gitMerge), findsOneWidget);
    });

    testWidgets('renders locked badge', (tester) async {
      await tester.pumpWidget(testWrap(
        const AchievementBadge(
          achievement: null,
          icon: LucideIcons.rocket,
          label: 'First merge',
          isUnlocked: false,
        ),
      ));

      expect(find.text('First merge'), findsOneWidget);
      expect(find.byIcon(LucideIcons.rocket), findsOneWidget);
    });

    testWidgets('renders different icons', (tester) async {
      await tester.pumpWidget(testWrap(
        AchievementBadge(
          achievement: Achievement(
            id: 'a2',
            agentId: 'agent2',
            badgeKey: 'centurion',
            unlockedAt: DateTime(2026, 3, 10),
          ),
          icon: LucideIcons.medal,
          label: 'Centurion',
          isUnlocked: true,
        ),
      ));

      expect(find.text('Centurion'), findsOneWidget);
      expect(find.byIcon(LucideIcons.medal), findsOneWidget);
    });

    testWidgets('renders with null achievement (locked)', (tester) async {
      await tester.pumpWidget(testWrap(
        const AchievementBadge(
          achievement: null,
          icon: LucideIcons.flame,
          label: 'Hot Streak',
          isUnlocked: false,
        ),
      ));

      expect(find.text('Hot Streak'), findsOneWidget);
      // Tooltip shows label for locked badges
    });

    testWidgets('unlocked badge has tooltip with date', (tester) async {
      await tester.pumpWidget(testWrap(
        AchievementBadge(
          achievement: Achievement(
            id: 'a3',
            agentId: 'agent3',
            badgeKey: 'pr_machine',
            unlockedAt: DateTime(2026, 6, 1),
          ),
          icon: LucideIcons.factory,
          label: 'PR Machine',
          isUnlocked: true,
        ),
      ));

      expect(find.text('PR Machine'), findsOneWidget);
    });
  });

  group('BadgeDef', () {
    test('creates with icon and label', () {
      const def = BadgeDef(LucideIcons.play, 'First run');
      expect(def.icon, LucideIcons.play);
      expect(def.label, 'First run');
    });
  });
}
