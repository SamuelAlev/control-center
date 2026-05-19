import 'package:control_center/shared/widgets/github_user_hover_target.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not wrap a GitHub App bot in a hover region', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: GitHubUserHoverTarget(
          login: 'renovate[bot]',
          child: Text('avatar'),
        ),
      ),
    );

    expect(find.byType(MouseRegion), findsNothing);
    expect(find.text('avatar'), findsOneWidget);
  });

  testWidgets('does not wrap dependabot or actions bots either', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            GitHubUserHoverTarget(
              login: 'dependabot[bot]',
              child: Text('dependabot'),
            ),
            GitHubUserHoverTarget(
              login: 'github-actions[bot]',
              child: Text('actions'),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(MouseRegion), findsNothing);
  });

  testWidgets('wraps a human login in a hover region', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: GitHubUserHoverTarget(login: 'octocat', child: Text('avatar')),
      ),
    );

    expect(find.byType(MouseRegion), findsOneWidget);
    expect(find.text('avatar'), findsOneWidget);
  });
}
