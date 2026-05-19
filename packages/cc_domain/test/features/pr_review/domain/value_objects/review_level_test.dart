import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:test/test.dart';

void main() {
  group('ReviewLevel', () {
    test('round-trips every level through its wire name', () {
      for (final level in ReviewLevel.values) {
        expect(ReviewLevel.fromWire(level.wireName), level);
      }
    });

    test('parses case-insensitively and ignores surrounding space', () {
      expect(ReviewLevel.fromWire('  THOROUGH '), ReviewLevel.thorough);
    });

    test('returns null for an unknown or absent value', () {
      // Null rather than a default, so a caller validating client input can
      // reject a bad value instead of silently reviewing at some other depth.
      expect(ReviewLevel.fromWire(null), isNull);
      expect(ReviewLevel.fromWire('exhaustive'), isNull);
      expect(ReviewLevel.fromWire(''), isNull);
    });

    test('defaults to balanced', () {
      // Load-bearing: every path that cannot name a level resolves here, and
      // balanced is what every review ran as before levels existed.
      expect(ReviewLevel.defaultLevel, ReviewLevel.balanced);
    });
  });

  group('ReviewLevelProfile', () {
    test('light demotes minor and below', () {
      final light = ReviewLevel.light.profile;
      expect(light.demotes(ReviewFindingSeverity.minor), isTrue);
      expect(light.demotes(ReviewFindingSeverity.trivial), isTrue);
      expect(light.demotes(ReviewFindingSeverity.info), isTrue);
    });

    test('balanced demotes only trivial and info', () {
      final balanced = ReviewLevel.balanced.profile;
      expect(balanced.demotes(ReviewFindingSeverity.minor), isFalse);
      expect(balanced.demotes(ReviewFindingSeverity.trivial), isTrue);
      expect(balanced.demotes(ReviewFindingSeverity.info), isTrue);
    });

    test('thorough demotes nothing', () {
      final thorough = ReviewLevel.thorough.profile;
      for (final s in ReviewFindingSeverity.values) {
        expect(thorough.demotes(s), isFalse, reason: s.name);
      }
    });

    test('no level ever demotes critical or major', () {
      // The verdict is computed from these. A reporting dial that could hide
      // them would be a reporting dial that changes whether a PR ships.
      for (final level in ReviewLevel.values) {
        expect(level.profile.demotes(ReviewFindingSeverity.critical), isFalse);
        expect(level.profile.demotes(ReviewFindingSeverity.major), isFalse);
      }
    });

    test('a low-confidence finding is demoted even at its severity', () {
      // A confidence field nothing reads is a field the reviewer fills in
      // carelessly. Gating is what makes it mean something.
      final balanced = ReviewLevel.balanced.profile;
      expect(
        balanced.demotes(ReviewFindingSeverity.minor, confidence: 0.9),
        isFalse,
      );
      expect(
        balanced.demotes(ReviewFindingSeverity.minor, confidence: 0.4),
        isTrue,
      );
    });

    test('confidence floors tighten as the level gets lighter', () {
      expect(
        ReviewLevel.light.profile.confidenceFloor,
        greaterThan(ReviewLevel.balanced.profile.confidenceFloor),
      );
      expect(
        ReviewLevel.balanced.profile.confidenceFloor,
        greaterThan(ReviewLevel.thorough.profile.confidenceFloor),
      );
    });

    test('confidence never demotes critical or major', () {
      // "I am only 40% sure this leaks credentials" is still worth a minute.
      for (final level in ReviewLevel.values) {
        expect(
          level.profile.demotes(
            ReviewFindingSeverity.critical,
            confidence: 0.01,
          ),
          isFalse,
          reason: level.name,
        );
        expect(
          level.profile.demotes(ReviewFindingSeverity.major, confidence: 0.01),
          isFalse,
          reason: level.name,
        );
      }
    });

    test('omitting confidence asks only the severity question', () {
      expect(
        ReviewLevel.balanced.profile.demotes(ReviewFindingSeverity.minor),
        isFalse,
      );
    });

    test('every level carries a non-empty reporting brief', () {
      for (final level in ReviewLevel.values) {
        expect(level.profile.reportingBrief.trim(), isNotEmpty);
        expect(level.profile.level, level);
      }
    });
  });
}
