import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_source_control_tab.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
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
  testWidgets('demo server shows DemoUnavailable, not an RPC error', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        PrSourceControlTab(
          pr: _pr(),
          prRef: (
            workspaceId: 'ws',
            repoFullName: 'helix/evalkit',
            number: 412,
          ),
          onOpenInEditor: (_) {},
        ),
        isDemo: true,
      ),
    );

    expect(find.byType(DemoUnavailable), findsOneWidget);
    expect(find.text('Not available in the demo'), findsOneWidget);
    expect(find.textContaining('Unknown op'), findsNothing);
    expect(find.textContaining('pr.ensureSpace'), findsNothing);
  });
}
