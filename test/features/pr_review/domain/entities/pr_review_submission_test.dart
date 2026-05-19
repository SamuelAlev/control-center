import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const author = PrUser(login: 'reviewer', avatarUrl: 'https://avat.ar/r');

  PrReviewSubmission createSubmission({
    PrReviewSubmissionState state = PrReviewSubmissionState.approved,
    PrUser? authorParam,
    String body = 'LGTM!',
  }) {
    return PrReviewSubmission(
      state: state,
      author: authorParam ?? author,
      body: body,
    );
  }

  group('PrReviewSubmission constructor', () {
    test('creates instance with all fields', () {
      const submission = PrReviewSubmission(
        state: PrReviewSubmissionState.changesRequested,
        author: author,
        body: 'Please fix the following issues',
      );
      expect(submission.state, PrReviewSubmissionState.changesRequested);
      expect(submission.author, author);
      expect(submission.body, 'Please fix the following issues');
    });

    test('allows nullable author', () {
      const submission = PrReviewSubmission(
        state: PrReviewSubmissionState.commented,
        author: null,
        body: 'Nice work',
      );
      expect(submission.author, isNull);
    });

    test('is const constructable', () {
      const submission = PrReviewSubmission(
        state: PrReviewSubmissionState.approved,
        author: null,
        body: '',
      );
      expect(submission.state, PrReviewSubmissionState.approved);
      expect(submission.body, '');
    });
  });

  group('PrReviewSubmission == and hashCode', () {
    test('identical submissions are equal', () {
      final a = createSubmission();
      final b = createSubmission();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different state makes unequal', () {
      final a = createSubmission(state: PrReviewSubmissionState.approved);
      final b = createSubmission(state: PrReviewSubmissionState.changesRequested);
      expect(a, isNot(equals(b)));
    });

    test('different author makes unequal', () {
      final a = createSubmission(authorParam: const PrUser(login: 'a', avatarUrl: ''));
      final b = createSubmission(authorParam: const PrUser(login: 'b', avatarUrl: ''));
      expect(a, isNot(equals(b)));
    });

    test('different body makes unequal', () {
      final a = createSubmission(body: 'Good');
      final b = createSubmission(body: 'Bad');
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = createSubmission();
      expect(a, equals(a));
    });
  });

  group('PrReviewSubmissionState', () {
    test('all enum values are distinct', () {
      expect(PrReviewSubmissionState.values.length, 4);
      expect(PrReviewSubmissionState.values.toSet().length, 4);
    });

    test('individual values', () {
      expect(PrReviewSubmissionState.approved, isA<PrReviewSubmissionState>());
      expect(PrReviewSubmissionState.changesRequested, isA<PrReviewSubmissionState>());
      expect(PrReviewSubmissionState.commented, isA<PrReviewSubmissionState>());
      expect(PrReviewSubmissionState.pending, isA<PrReviewSubmissionState>());
    });
  });
}
