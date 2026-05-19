import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/core/theme/design_system_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The PR age helpers. Relative-time FORMATTING is not tested here any more:
/// it moved to the l10n-aware `formatRelativeTime` in
/// `lib/shared/utils/relative_time.dart` (see its own test), which is what
/// every PR surface now calls.
void main() {
  final DateTime now = DateTime(2024, 6, 15, 12);

  CheckRun run({
    DateTime? startedAt,
    DateTime? completedAt,
    required CheckRunStatus status,
  }) => CheckRun(
    name: 'build',
    status: status,
    conclusion: CheckRunConclusion.neutral,
    startedAt: startedAt,
    completedAt: completedAt,
  );

  group('checkRunDuration', () {
    test('is null when the check never reported a start', () {
      expect(
        checkRunDuration(run(status: CheckRunStatus.queued), now: now),
        isNull,
      );
    });

    test('is completedAt - startedAt for a finished check', () {
      final d = checkRunDuration(
        run(
          startedAt: now.subtract(const Duration(minutes: 5)),
          completedAt: now.subtract(const Duration(minutes: 2)),
          status: CheckRunStatus.completed,
        ),
        now: now,
      );
      expect(d, const Duration(minutes: 3));
    });

    test('is the elapsed time so far while the check is still running', () {
      final d = checkRunDuration(
        run(
          startedAt: now.subtract(const Duration(minutes: 4)),
          status: CheckRunStatus.inProgress,
        ),
        now: now,
      );
      expect(d, const Duration(minutes: 4));
    });
  });

  group('ageColor', () {
    const neutral = Color(0xFF8C8578);

    test('is neutral for a null date and for anything under 12 hours', () {
      expect(ageColor(null, now: now, neutral: neutral), neutral);
      expect(
        ageColor(
          now.subtract(const Duration(hours: 11)),
          now: now,
          neutral: neutral,
        ),
        neutral,
      );
    });

    test('warms with age: yellow → orange → red', () {
      expect(
        ageColor(now.subtract(const Duration(days: 1)), now: now),
        DesignSystemPalette.yellow600,
      );
      expect(
        ageColor(now.subtract(const Duration(days: 4)), now: now),
        DesignSystemPalette.orange500,
      );
      expect(
        ageColor(now.subtract(const Duration(days: 9)), now: now),
        DesignSystemPalette.red500,
      );
    });

    test('a future date reads as neutral, never as urgent', () {
      expect(
        ageColor(now.add(const Duration(days: 3)), now: now, neutral: neutral),
        neutral,
      );
    });
  });

  group('isStaleAge', () {
    test('flips past 30 days', () {
      expect(isStaleAge(null, now: now), isFalse);
      expect(
        isStaleAge(now.subtract(const Duration(days: 30)), now: now),
        isFalse,
      );
      expect(
        isStaleAge(now.subtract(const Duration(days: 31)), now: now),
        isTrue,
      );
    });
  });
}
