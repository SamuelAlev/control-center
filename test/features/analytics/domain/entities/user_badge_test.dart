import 'package:control_center/features/analytics/domain/entities/user_badge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testThresholds = [1, 10, 50, 250, 1000];

  UserBadgeCategory createCategory({
    String key = 'test_cat',
    String name = 'Test Category',
    String iconName = 'star',
    String unit = 'action',
    String action = 'Do the thing',
    List<int> thresholds = testThresholds,
    String blurb = 'A test badge category.',
  }) {
    return UserBadgeCategory(
      key: key,
      name: name,
      iconName: iconName,
      unit: unit,
      action: action,
      thresholds: thresholds,
      blurb: blurb,
    );
  }

  group('BadgeTier', () {
    group('label', () {
      test('none returns Locked', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.none.label, 'Locked');
      });

      test('beginner returns Beginner', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.beginner.label, 'Beginner');
      });

      test('intermediate returns Intermediate', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.intermediate.label, 'Intermediate');
      });

      test('advanced returns Advanced', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.advanced.label, 'Advanced');
      });

      test('expert returns Expert', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.expert.label, 'Expert');
      });

      test('master returns Master', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.master.label, 'Master');
      });
    });

    group('index0', () {
      test('none returns -1', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.none.index0, -1);
      });

      test('beginner returns 0', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.beginner.index0, 0);
      });

      test('intermediate returns 1', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.intermediate.index0, 1);
      });

      test('advanced returns 2', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.advanced.index0, 2);
      });

      test('expert returns 3', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.expert.index0, 3);
      });

      test('master returns 4', timeout: const Timeout.factor(2), () {
        expect(BadgeTier.master.index0, 4);
      });
    });

    group('color', () {
      test('every tier returns a non-zero color', timeout: const Timeout.factor(2), () {
        for (final tier in BadgeTier.values) {
          expect(tier.color, isNotNull);
        }
      });
    });
  });

  group('UserBadgeCategory', () {
    group('constructor', () {
      test('creates category with all fields', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.key, 'test_cat');
        expect(cat.name, 'Test Category');
        expect(cat.iconName, 'star');
        expect(cat.unit, 'action');
        expect(cat.action, 'Do the thing');
        expect(cat.thresholds, testThresholds);
        expect(cat.blurb, 'A test badge category.');
      });
    });

    group('tierFor', () {
      test('returns none for count below first threshold', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.tierFor(0), BadgeTier.none);
      });

      test('returns beginner at first threshold', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.tierFor(1), BadgeTier.beginner);
      });

      test('returns intermediate at second threshold', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.tierFor(10), BadgeTier.intermediate);
      });

      test('returns advanced at third threshold', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.tierFor(50), BadgeTier.advanced);
      });

      test('returns expert at fourth threshold', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.tierFor(250), BadgeTier.expert);
      });

      test('returns master at fifth threshold', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.tierFor(1000), BadgeTier.master);
      });

      test('returns master above fifth threshold', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.tierFor(5000), BadgeTier.master);
      });

      test('returns beginner between first and second threshold', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.tierFor(5), BadgeTier.beginner);
      });
    });

    group('thresholdFor', () {
      test('returns null for none tier', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.thresholdFor(BadgeTier.none), isNull);
      });

      test('returns correct threshold for each tier', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        expect(cat.thresholdFor(BadgeTier.beginner), 1);
        expect(cat.thresholdFor(BadgeTier.intermediate), 10);
        expect(cat.thresholdFor(BadgeTier.advanced), 50);
        expect(cat.thresholdFor(BadgeTier.expert), 250);
        expect(cat.thresholdFor(BadgeTier.master), 1000);
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', timeout: const Timeout.factor(2), () {
        final c1 = createCategory();
        final c2 = createCategory();
        expect(c1, equals(c2));
      });

      test('== returns false for different key', timeout: const Timeout.factor(2), () {
        final c1 = createCategory(key: 'a');
        final c2 = createCategory(key: 'b');
        expect(c1, isNot(equals(c2)));
      });

      test('== returns false for different thresholds', timeout: const Timeout.factor(2), () {
        final c1 = createCategory(thresholds: [1, 10, 50, 250, 1000]);
        final c2 = createCategory(thresholds: [1, 10, 50, 250, 2000]);
        expect(c1, isNot(equals(c2)));
      });

      test('hashCode matches for equal categories', timeout: const Timeout.factor(2), () {
        final c1 = createCategory();
        final c2 = createCategory();
        expect(c1.hashCode, equals(c2.hashCode));
      });
    });
  });

  group('UserBadge', () {
    test('tier derives from count via category', timeout: const Timeout.factor(2), () {
      final cat = createCategory();
      final badge = UserBadge(category: cat, count: 0);
      expect(badge.tier, BadgeTier.none);
    });

    test('nextTier returns beginner when at none', timeout: const Timeout.factor(2), () {
      final cat = createCategory();
      final badge = UserBadge(category: cat, count: 0);
      expect(badge.nextTier, BadgeTier.beginner);
    });

    test('nextTier returns null when at master', timeout: const Timeout.factor(2), () {
      final cat = createCategory();
      final badge = UserBadge(category: cat, count: 5000);
      expect(badge.nextTier, isNull);
    });

    test('countToNext returns 0 when at master', timeout: const Timeout.factor(2), () {
      final cat = createCategory();
      final badge = UserBadge(category: cat, count: 5000);
      expect(badge.countToNext, 0);
    });

    test('countToNext returns remaining actions', timeout: const Timeout.factor(2), () {
      final cat = createCategory();
      final badge = UserBadge(category: cat, count: 5);
      // At beginner (threshold 1), next is intermediate (threshold 10). Need 10 - 5 = 5
      expect(badge.countToNext, 5);
    });

    test('progressToNext returns 1.0 at master', timeout: const Timeout.factor(2), () {
      final cat = createCategory();
      final badge = UserBadge(category: cat, count: 5000);
      expect(badge.progressToNext, 1.0);
    });

    test('progressToNext returns correct fraction', timeout: const Timeout.factor(2), () {
      final cat = createCategory();
      final badge = UserBadge(category: cat, count: 5);
      // At beginner (start 1), next is intermediate (end 10). (5 - 1) / (10 - 1) = 4/9
      expect(badge.progressToNext, closeTo(4 / 9, 0.001));
    });

    test('progressToNext is 0 at tier start', timeout: const Timeout.factor(2), () {
      final cat = createCategory();
      final badge = UserBadge(category: cat, count: 1);
      // At beginner (threshold 1), next is intermediate (threshold 10).
      // start = thresholdFor(beginner) = 1, end = 10. (1-1)/(10-1) = 0
      expect(badge.progressToNext, closeTo(0.0, 0.001));
    });

    group('== and hashCode', () {
      test('== returns true for same category and count', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        final b1 = UserBadge(category: cat, count: 5);
        final b2 = UserBadge(category: cat, count: 5);
        expect(b1, equals(b2));
      });

      test('== returns false for different count', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        final b1 = UserBadge(category: cat, count: 5);
        final b2 = UserBadge(category: cat, count: 10);
        expect(b1, isNot(equals(b2)));
      });

      test('== returns false for different category', timeout: const Timeout.factor(2), () {
        final cat1 = createCategory(key: 'a');
        final cat2 = createCategory(key: 'b');
        final b1 = UserBadge(category: cat1, count: 5);
        final b2 = UserBadge(category: cat2, count: 5);
        expect(b1, isNot(equals(b2)));
      });

      test('hashCode matches for equal badges', timeout: const Timeout.factor(2), () {
        final cat = createCategory();
        final b1 = UserBadge(category: cat, count: 5);
        final b2 = UserBadge(category: cat, count: 5);
        expect(b1.hashCode, equals(b2.hashCode));
      });
    });
  });

  group('userBadgeCategories', () {
    test('contains exactly 5 categories', timeout: const Timeout.factor(2), () {
      expect(userBadgeCategories, hasLength(5));
    });

    test('each category has 5 thresholds', timeout: const Timeout.factor(2), () {
      for (final cat in userBadgeCategories) {
        expect(cat.thresholds, hasLength(5));
      }
    });

    test('each category has non-empty key and name', timeout: const Timeout.factor(2), () {
      for (final cat in userBadgeCategories) {
        expect(cat.key, isNotEmpty);
        expect(cat.name, isNotEmpty);
      }
    });

    test('thresholds are in non-decreasing order', timeout: const Timeout.factor(2), () {
      for (final cat in userBadgeCategories) {
        for (var i = 1; i < cat.thresholds.length; i++) {
          expect(
            cat.thresholds[i],
            greaterThanOrEqualTo(cat.thresholds[i - 1]),
            reason: '${cat.key} thresholds not non-decreasing at index $i',
          );
        }
      }
    });
  });
}
