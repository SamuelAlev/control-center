import 'package:cc_domain/features/pr_review/domain/repositories/open_pr_list_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/repo_access_banner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

InaccessibleRepo _repo(String fullName, {required String reason}) =>
    InaccessibleRepo(repoId: fullName, repoFullName: fullName, reason: reason);

void main() {
  testWidgets('stays out of the way while every repo is reachable', (
    tester,
  ) async {
    await tester.pumpWidget(testWrap(const RepoAccessBanner(repos: [])));
    expect(find.byType(CcAlert), findsNothing);
  });

  testWidgets('names a missing app install as the fix', (tester) async {
    await tester.pumpWidget(
      testWrap(
        RepoAccessBanner(repos: [_repo('acme/app', reason: 'not_found')]),
      ),
    );
    expect(find.byType(CcAlert), findsOneWidget);
    expect(
      find.text(
        "The server's GitHub credential can't see acme/app. If a repository "
        'belongs to an organization, install the GitHub App there or connect '
        'a token that has access.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tells the operator to resume a suspended installation', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        RepoAccessBanner(
          repos: [
            _repo(
              'SuspendedOrg/suspended-repo',
              reason: InaccessibleRepo.installationSuspended,
            ),
          ],
        ),
      ),
    );
    expect(find.text('GitHub App installation suspended'), findsOneWidget);
    expect(
      find.text(
        'Showing last known data for SuspendedOrg/suspended-repo. Resume the '
        'installation on GitHub, or connect a token that has access.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows both notices when the causes mix', (tester) async {
    await tester.pumpWidget(
      testWrap(
        RepoAccessBanner(
          repos: [
            _repo(
              'SuspendedOrg/suspended-repo',
              reason: InaccessibleRepo.installationSuspended,
            ),
            _repo('acme/app', reason: 'not_found'),
          ],
        ),
      ),
    );
    expect(find.byType(CcAlert), findsNWidgets(2));
    expect(find.text('GitHub App installation suspended'), findsOneWidget);
    expect(find.text('A repository can\'t be accessed'), findsOneWidget);
  });
}
