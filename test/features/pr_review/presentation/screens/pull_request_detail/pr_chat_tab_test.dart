import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_chat_tab.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_wrap.dart';

PullRequest _pr() {
  return PullRequest(
    id: 412,
    number: 412,
    title: 'Cap eval-run token budget per model family',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    repoFullName: 'helix/evalkit',
    htmlUrl: 'https://example.invalid/helix/evalkit/pull/412',
  );
}

void main() {
  testWidgets('a missing demo space is empty, not an Unknown-op error', (
    tester,
  ) async {
    final pr = _pr();
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            prSpaceProvider.overrideWith((ref, _) async {
              throw const PrSpaceUnavailable();
            }),
          ],
          child: PrChatTab(pr: pr),
        ),
        isDemo: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select a conversation'), findsOneWidget);
    expect(find.textContaining('Unknown op'), findsNothing);
    expect(find.textContaining('pr.ensureSpace'), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('a real failure still offers retry', (tester) async {
    final pr = _pr();
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            prSpaceProvider.overrideWith((ref, _) async {
              throw StateError('boom');
            }),
          ],
          child: PrChatTab(pr: pr),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });
}
