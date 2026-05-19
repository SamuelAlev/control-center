import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the arguments passed to [createOnGitHub] so the test can assert the
/// compose form forwarded the draft flag, assignees, and reviewers correctly.
class _RecordingLifecycleRepository implements PrLifecycleRepository {
  String? createdDraftWorkspaceId;
  Map<String, dynamic>? lastCreateOnGitHub;

  @override
  Future<String> createDraft({
    required String workspaceId,
    required String title,
    required String body,
    String? diffSummary,
  }) async {
    createdDraftWorkspaceId = workspaceId;
    return 'draft-1';
  }

  @override
  Future<Map<String, dynamic>> createOnGitHub({
    required String prId,
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
    List<String> assignees = const [],
    List<String> reviewerUsers = const [],
    List<String> reviewerTeams = const [],
  }) async {
    lastCreateOnGitHub = {
      'prId': prId,
      'owner': owner,
      'repo': repo,
      'title': title,
      'body': body,
      'head': head,
      'base': base,
      'draft': draft,
      'assignees': assignees,
      'reviewerUsers': reviewerUsers,
      'reviewerTeams': reviewerTeams,
    };
    return {'number': 42, 'html_url': 'https://github.com/o/r/pull/42'};
  }

  @override
  Future<void> delete(String id) async {}

  @override
  Future<PrGeneration?> getById(String id) async => null;

  @override
  Future<void> updateDraft(
    String prId, {
    String? title,
    String? body,
    String? status,
    int? githubPrNumber,
    String? githubPrUrl,
  }) async {}

  @override
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();
}

/// A fixed active-workspace notifier that skips the prefs/db lookups.
class _FixedActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws-1';
}

void main() {
  Repo repo() => Repo(
        id: 'repo-1',
        name: 'o/r',
        path: '/tmp/r',
        githubOwner: 'o',
        githubRepoName: 'r',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  ProviderContainer makeContainer(_RecordingLifecycleRepository lifecycle) {
    final container = ProviderContainer(
      overrides: [
        prLifecycleRepositoryProvider.overrideWithValue(lifecycle),
        activeRepoProvider.overrideWithValue(repo()),
        activeWorkspaceIdProvider.overrideWith(_FixedActiveWorkspaceId.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('submit forwards branches, assignees and reviewers, draft=false',
      () async {
    final lifecycle = _RecordingLifecycleRepository();
    final container = makeContainer(lifecycle);
    final notifier = container.read(composePrProvider.notifier);

    notifier.setBase('main');
    notifier.setHead('feature/x');
    notifier.setTitle('My change');
    notifier.setBody('Body text');
    notifier.setAssignees(const [
      PrUser(login: 'alice', avatarUrl: ''),
    ]);
    notifier.setReviewers([
      const PrReviewerCandidate(
        kind: ReviewerKind.user,
        key: 'bob',
        label: 'bob',
      ),
      const PrReviewerCandidate(
        kind: ReviewerKind.team,
        key: 'core',
        label: 'core',
      ),
    ]);

    final number = await notifier.submit(asDraft: false);

    expect(number, 42);
    expect(lifecycle.createdDraftWorkspaceId, 'ws-1');
    final call = lifecycle.lastCreateOnGitHub!;
    expect(call['owner'], 'o');
    expect(call['repo'], 'r');
    expect(call['base'], 'main');
    expect(call['head'], 'feature/x');
    expect(call['title'], 'My change');
    expect(call['draft'], false);
    expect(call['assignees'], ['alice']);
    expect(call['reviewerUsers'], ['bob']);
    expect(call['reviewerTeams'], ['core']);
  });

  test('submit passes draft=true for create-as-draft', () async {
    final lifecycle = _RecordingLifecycleRepository();
    final container = makeContainer(lifecycle);
    final notifier = container.read(composePrProvider.notifier);

    notifier.setBase('main');
    notifier.setHead('feature/y');
    notifier.setTitle('Draft change');

    final number = await notifier.submit(asDraft: true);

    expect(number, 42);
    expect(lifecycle.lastCreateOnGitHub!['draft'], true);
  });

  test('submit is a no-op without a title (cannot submit)', () async {
    final lifecycle = _RecordingLifecycleRepository();
    final container = makeContainer(lifecycle);
    final notifier = container.read(composePrProvider.notifier);

    notifier.setBase('main');
    notifier.setHead('feature/z');

    final number = await notifier.submit(asDraft: false);

    expect(number, isNull);
    expect(lifecycle.lastCreateOnGitHub, isNull);
  });
}
