import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/widgets/pr_environment_section.dart';
import 'package:control_center/features/environments/providers/environment_pr_providers.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_space_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/active_workspace.dart';
import '../../helpers/test_wrap.dart';
import 'environment_test_support.dart';

final _pr = PullRequest(
  id: 7,
  number: 7,
  title: 'Fix login',
  body: '',
  state: PrState.open,
  isDraft: false,
  author: null,
  createdAt: null,
  updatedAt: null,
  repoFullName: 'acme/shop',
  htmlUrl: '',
);

final _repo = Repo(
  id: 'repo-1',
  name: 'shop',
  path: '/src/shop',
  remoteOwner: 'acme',
  remoteName: 'shop',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  Future<int> pump(
    WidgetTester tester,
    FakeEnvironmentRepository repository, {
    bool tapStart = false,
  }) async {
    var ensured = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          environmentRepositoryProvider.overrideWithValue(repository),
          environmentEndpointsAreRemoteProvider.overrideWithValue(false),
          activeWorkspaceIdOverride(kWorkspace),
          existingPrSpaceIdProvider.overrideWith(
            (ref, _) => Stream<String?>.value(null),
          ),
          reposForWorkspaceProvider.overrideWith(
            (ref, _) => Stream.value([_repo]),
          ),
          prSpaceProvider.overrideWith((ref, _) async {
            ensured++;
            return kSpace;
          }),
          spaceProvisioningStatusProvider.overrideWith(
            (ref, _) => SpaceProvisioningStatus.ready,
          ),
        ],
        child: testWrap(PrEnvironmentSection(workspaceId: kWorkspace, pr: _pr)),
      ),
    );
    await tester.pumpAndSettle();
    if (tapStart) {
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
    }
    return ensured;
  }

  testWidgets('a PR without a space offers Start and provisions nothing', (
    tester,
  ) async {
    final repository = FakeEnvironmentRepository(
      definitions: [definitionRecord()],
    );
    final ensured = await pump(tester, repository);

    expect(find.text('Start'), findsOneWidget);
    expect(ensured, 0);
    expect(repository.calls, isNot(contains('eligible')));
  });

  testWidgets('Start ensures the space, then the environment', (tester) async {
    final repository = FakeEnvironmentRepository(
      definitions: [definitionRecord()],
    );
    final ensured = await pump(tester, repository, tapStart: true);

    expect(ensured, 1);
    expect(repository.calls, contains('ensure'));
    expect(repository.lastDefinitionId, 'def-1');
  });

  testWidgets('a definition with no stack is not offered', (tester) async {
    await pump(
      tester,
      FakeEnvironmentRepository(
        definitions: [
          definitionRecord(
            components: [
              {
                'kind': 'task',
                'id': 'deps',
                'when': ['provision'],
                'command': ['pnpm', 'install'],
              },
            ],
          ),
        ],
      ),
    );
    expect(find.text('Start'), findsNothing);
  });

  group('prEnvironmentPreviewProvider', () {
    ProviderContainer container({bool remote = false, bool ready = true}) {
      final repository = FakeEnvironmentRepository(
        environments: [
          environment(
            status: ready
                ? EnvironmentStatus.ready
                : EnvironmentStatus.starting,
            endpoints: [
              EnvironmentEndpoint(
                role: 'web',
                url: 'http://web.localhost:4100',
                primary: true,
              ),
            ],
          ),
        ],
      );
      final scope = ProviderContainer(
        overrides: [
          environmentRepositoryProvider.overrideWithValue(repository),
          environmentEndpointsAreRemoteProvider.overrideWithValue(remote),
          activeWorkspaceIdOverride(kWorkspace),
          existingPrSpaceIdProvider.overrideWith(
            (ref, _) => Stream<String?>.value(kSpace),
          ),
        ],
      );
      addTearDown(scope.dispose);
      return scope;
    }

    Future<String?> previewUrl(ProviderContainer scope) async {
      final provider = prEnvironmentPreviewProvider(PrSpaceKey.of(_pr));
      final subscription = scope.listen(provider, (_, _) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      return subscription.read()?.url;
    }

    test('names the primary endpoint of a ready environment', () async {
      expect(await previewUrl(container()), 'http://web.localhost:4100');
    });

    test('stays away while it is starting', () async {
      expect(await previewUrl(container(ready: false)), isNull);
    });

    test('stays away on a remote client, which can not resolve it', () async {
      expect(await previewUrl(container(remote: true)), isNull);
    });
  });
}
