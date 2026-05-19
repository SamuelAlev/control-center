import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:test/test.dart';

/// Coverage for the multi-axis review taxonomy value objects (PRD 18 §7):
/// the [ReviewAxis] and [ReviewAxisVerdict] enums, plus the [ReviewAxisResult]
/// entity. These are pure value objects with no IO.
void main() {
  group('ReviewAxis', () {
    test('wireName maps each axis to its stable storage name', () {
      expect(ReviewAxis.correctness.wireName, 'correctness');
      expect(ReviewAxis.security.wireName, 'security');
      expect(ReviewAxis.testGap.wireName, 'test_gap');
      expect(ReviewAxis.performance.wireName, 'performance');
      expect(ReviewAxis.visual.wireName, 'visual');
      expect(ReviewAxis.apiContract.wireName, 'api_contract');
    });

    test('isDeterministic is true only for the computation axes', () {
      expect(ReviewAxis.performance.isDeterministic, isTrue);
      expect(ReviewAxis.visual.isDeterministic, isTrue);
      expect(ReviewAxis.apiContract.isDeterministic, isTrue);

      expect(ReviewAxis.correctness.isDeterministic, isFalse);
      expect(ReviewAxis.security.isDeterministic, isFalse);
      expect(ReviewAxis.testGap.isDeterministic, isFalse);
    });

    test('fromName parses the wire name of each axis', () {
      for (final axis in ReviewAxis.values) {
        expect(ReviewAxis.fromName(axis.wireName), axis);
      }
    });

    test('fromName parses the dart name of each axis', () {
      expect(ReviewAxis.fromName('testGap'), ReviewAxis.testGap);
      expect(ReviewAxis.fromName('apiContract'), ReviewAxis.apiContract);
    });

    test('fromName returns null for an unrecognized name', () {
      expect(ReviewAxis.fromName('unknown'), isNull);
    });

    test('fromName returns null for a null input', () {
      expect(ReviewAxis.fromName(null), isNull);
    });
  });

  group('ReviewAxisVerdict', () {
    test('wireName is the dart enum name', () {
      for (final v in ReviewAxisVerdict.values) {
        expect(v.wireName, v.name);
      }
    });

    test('fromName parses each verdict name', () {
      for (final v in ReviewAxisVerdict.values) {
        expect(ReviewAxisVerdict.fromName(v.name), v);
      }
    });

    test(
      'fromName defaults to unavailable for a null or unrecognized name',
      () {
        expect(ReviewAxisVerdict.fromName(null), ReviewAxisVerdict.unavailable);
        expect(
          ReviewAxisVerdict.fromName('totally-bogus'),
          ReviewAxisVerdict.unavailable,
        );
      },
    );

    test('clearsGate is true only for pass and warn', () {
      expect(ReviewAxisVerdict.pass.clearsGate, isTrue);
      expect(ReviewAxisVerdict.warn.clearsGate, isTrue);

      expect(ReviewAxisVerdict.fail.clearsGate, isFalse);
      expect(ReviewAxisVerdict.partial.clearsGate, isFalse);
      expect(ReviewAxisVerdict.unavailable.clearsGate, isFalse);
    });
  });

  group('ReviewAxisResult', () {
    const base = ReviewAxisResult(
      axis: ReviewAxis.security,
      verdict: ReviewAxisVerdict.fail,
      findingsCount: 3,
      gated: true,
      confidence: 0.9,
      note: 'sql-injection risk',
    );

    test('construction round-trips every field', () {
      expect(base.axis, ReviewAxis.security);
      expect(base.verdict, ReviewAxisVerdict.fail);
      expect(base.findingsCount, 3);
      expect(base.gated, isTrue);
      expect(base.confidence, 0.9);
      expect(base.note, 'sql-injection risk');
    });

    test('blocks is true when gated and not clearing the gate', () {
      expect(base.blocks, isTrue);
    });

    test('blocks is false when the axis is not gated', () {
      const ungated = ReviewAxisResult(
        axis: ReviewAxis.security,
        verdict: ReviewAxisVerdict.fail,
        findingsCount: 1,
        gated: false,
        confidence: 0.9,
      );
      expect(ungated.blocks, isFalse);
    });

    test('blocks is false when gated but the verdict clears the gate', () {
      const passing = ReviewAxisResult(
        axis: ReviewAxis.security,
        verdict: ReviewAxisVerdict.pass,
        findingsCount: 0,
        gated: true,
        confidence: 0.9,
      );
      expect(passing.blocks, isFalse);
    });

    test('note defaults to an empty string', () {
      const r = ReviewAxisResult(
        axis: ReviewAxis.correctness,
        verdict: ReviewAxisVerdict.pass,
        findingsCount: 0,
        gated: false,
        confidence: 1.0,
      );
      expect(r.note, '');
    });

    group('fromJson', () {
      test('round-trips a full result via toJson', () {
        final json = base.toJson();
        // The note is non-empty so it is serialized.
        expect(json['axis'], 'security');
        expect(json['verdict'], 'fail');
        expect(json['findingsCount'], 3);
        expect(json['gated'], isTrue);
        expect(json['confidence'], 0.9);
        expect(json['note'], 'sql-injection risk');

        expect(ReviewAxisResult.fromJson(json), base);
      });

      test('falls back to correctness when axis is missing or unknown', () {
        final r = ReviewAxisResult.fromJson({
          'verdict': 'pass',
          'findingsCount': 0,
          'gated': false,
          'confidence': 1.0,
        });
        expect(r.axis, ReviewAxis.correctness);
      });

      test('falls back to unavailable when verdict is unknown', () {
        final r = ReviewAxisResult.fromJson({
          'axis': 'security',
          'verdict': 'bogus',
        });
        expect(r.verdict, ReviewAxisVerdict.unavailable);
      });

      test('defaults findingsCount to 0 and gated to false when absent', () {
        final r = ReviewAxisResult.fromJson({'axis': 'security'});
        expect(r.findingsCount, 0);
        expect(r.gated, isFalse);
      });

      test('defaults confidence to 1.0 and clamps out-of-range values', () {
        final missing = ReviewAxisResult.fromJson({'axis': 'security'});
        expect(missing.confidence, 1.0);

        final tooHigh = ReviewAxisResult.fromJson({
          'axis': 'security',
          'confidence': 5.0,
        });
        expect(tooHigh.confidence, 1.0);

        final tooLow = ReviewAxisResult.fromJson({
          'axis': 'security',
          'confidence': -0.5,
        });
        expect(tooLow.confidence, 0.0);
      });

      test('defaults note to an empty string when absent', () {
        final r = ReviewAxisResult.fromJson({'axis': 'security'});
        expect(r.note, '');
      });

      test('omits the note key when note is empty', () {
        const empty = ReviewAxisResult(
          axis: ReviewAxis.correctness,
          verdict: ReviewAxisVerdict.pass,
          findingsCount: 0,
          gated: false,
          confidence: 1.0,
        );
        expect(empty.toJson().containsKey('note'), isFalse);
      });
    });

    group('copyWith', () {
      test('overrides only the supplied fields', () {
        final next = base.copyWith(
          verdict: ReviewAxisVerdict.pass,
          findingsCount: 0,
        );
        expect(next.verdict, ReviewAxisVerdict.pass);
        expect(next.findingsCount, 0);
        // The axis is never editable through copyWith.
        expect(next.axis, base.axis);
        expect(next.gated, base.gated);
        expect(next.confidence, base.confidence);
        expect(next.note, base.note);
      });

      test('with no arguments returns an equal instance', () {
        expect(base.copyWith(), base);
      });
    });

    group('equality', () {
      test('equal instances are equal by value and hash', () {
        const other = ReviewAxisResult(
          axis: ReviewAxis.security,
          verdict: ReviewAxisVerdict.fail,
          findingsCount: 3,
          gated: true,
          confidence: 0.9,
          note: 'sql-injection risk',
        );
        expect(base, other);
        expect(base.hashCode, other.hashCode);
      });

      test('differ in any field to be unequal', () {
        ReviewAxisResult mutate(
          ReviewAxisResult Function(ReviewAxisResult) f,
        ) => f(base);

        expect(
          mutate(
            (r) => ReviewAxisResult(
              axis: ReviewAxis.correctness,
              verdict: r.verdict,
              findingsCount: r.findingsCount,
              gated: r.gated,
              confidence: r.confidence,
              note: r.note,
            ),
          ),
          isNot(base),
        );
        expect(base.copyWith(confidence: 0.5), isNot(base));
        expect(base.copyWith(note: 'other'), isNot(base));
        expect(base.copyWith(gated: false), isNot(base));
        expect(base.copyWith(findingsCount: 9), isNot(base));
        expect(base.copyWith(verdict: ReviewAxisVerdict.pass), isNot(base));
      });

      test('is not equal to an unrelated object', () {
        expect(base, isNot('not a result'));
      });
    });
  });
}
