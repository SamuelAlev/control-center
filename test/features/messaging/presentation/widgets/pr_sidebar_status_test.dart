import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_status_badge.dart';
import 'package:flutter_test/flutter_test.dart';

PullRequest _pr({required PrState state, bool isDraft = false}) {
  return PullRequest(
    id: 1,
    number: 1,
    title: 't',
    body: '',
    state: state,
    isDraft: isDraft,
    author: null,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    repoFullName: 'o/r',
    htmlUrl: 'url',
  );
}

void main() {
  group('PrSidebarStatus.fromPullRequest', () {
    test('null PR resolves to null (no badge)', () {
      expect(PrSidebarStatus.fromPullRequest(null), isNull);
    });

    test('open + draft flag → draft', () {
      expect(
        PrSidebarStatus.fromPullRequest(
          _pr(state: PrState.open, isDraft: true),
        ),
        PrSidebarStatus.draft,
      );
    });

    test('open, not draft → open', () {
      expect(
        PrSidebarStatus.fromPullRequest(_pr(state: PrState.open)),
        PrSidebarStatus.open,
      );
    });

    test('closed (not merged) → closed', () {
      expect(
        PrSidebarStatus.fromPullRequest(_pr(state: PrState.closed)),
        PrSidebarStatus.closed,
      );
    });

    test('merged → merged', () {
      expect(
        PrSidebarStatus.fromPullRequest(_pr(state: PrState.merged)),
        PrSidebarStatus.merged,
      );
    });

    test('merged wins over a stale draft flag', () {
      // A merged PR is terminal; the draft flag (if somehow still set) must
      // not downgrade it.
      expect(
        PrSidebarStatus.fromPullRequest(
          _pr(state: PrState.merged, isDraft: true),
        ),
        PrSidebarStatus.merged,
      );
    });
  });

  group('PrSidebarStatus visual differentiation', () {
    test('every status maps to a distinct colour', () {
      final colors = PrSidebarStatus.values.map((s) => s.color).toSet();
      expect(colors.length, PrSidebarStatus.values.length);
    });

    test('every status maps to a distinct icon', () {
      final icons = PrSidebarStatus.values.map((s) => s.icon).toSet();
      expect(icons.length, PrSidebarStatus.values.length);
    });
  });
}
