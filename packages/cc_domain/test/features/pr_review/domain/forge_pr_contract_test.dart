import 'package:cc_domain/core/domain/entities/repo.dart'
    show splitRepoFullName;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:test/test.dart';

PullRequest _pr(
  int n,
  PrState state, {
  DateTime? mergedAt,
  DateTime? updatedAt,
}) => PullRequest(
  id: n,
  number: n,
  title: 'PR $n',
  body: '',
  state: state,
  isDraft: false,
  author: const PrUser(login: 'me', avatarUrl: ''),
  createdAt: DateTime.utc(2025),
  updatedAt: updatedAt ?? DateTime.utc(2025),
  mergedAt: mergedAt,
  repoFullName: 'o/r',
  htmlUrl: '',
);

void main() {
  group('closedPrOutcomeOf', () {
    test('a still-open PR is unknown, never closed', () {
      // The poller asks about a PR missing from page 1 of a long open list;
      // "closed" here used to publish a closure for a live PR.
      expect(closedPrOutcomeOf(_pr(1, PrState.open)), isNull);
    });

    test('merged and closed map to their outcomes', () {
      expect(closedPrOutcomeOf(_pr(1, PrState.merged)), ClosedPrOutcome.merged);
      expect(closedPrOutcomeOf(_pr(1, PrState.closed)), ClosedPrOutcome.closed);
    });

    test('an absent PR (a 404) is not found', () {
      expect(closedPrOutcomeOf(null), ClosedPrOutcome.notFound);
    });
  });

  test('sortMostRecentlyMergedFirst orders by merge time, then update', () {
    final prs = [
      _pr(1, PrState.merged, mergedAt: DateTime.utc(2025, 1, 2)),
      _pr(2, PrState.merged, updatedAt: DateTime.utc(2025, 3)),
      _pr(3, PrState.merged, mergedAt: DateTime.utc(2025, 2)),
    ];
    sortMostRecentlyMergedFirst(prs);
    expect(prs.map((p) => p.number), [3, 1, 2]);
  });

  group('ForgeCapabilities', () {
    test('round-trips through the wire as one bool per capability', () {
      for (final forge in ForgeHost.values) {
        final caps = capabilitiesOf(forge);
        final back = ForgeCapabilities.fromJson(caps.toJson());
        expect(back.supported, caps.supported, reason: forge.name);
        expect(back.forge, forge);
      }
    });

    test('an unknown wire key is ignored rather than failing', () {
      final caps = ForgeCapabilities.fromJson({
        'forge': 'github',
        'stacks': true,
        'teleportation': true,
      });
      expect(caps.supported, {ForgeCapability.stacks});
    });

    test('every forge that lists branch history is GitLab, GitHub or '
        'Bitbucket, and only GitHub claims merge signals', () {
      expect(capabilitiesOf(ForgeHost.local).supported, isEmpty);
      expect(
        [
          for (final f in ForgeHost.values)
            if (capabilitiesOf(f).has(ForgeCapability.mergeSignals)) f,
        ],
        [ForgeHost.github],
      );
    });
  });

  group('splitRepoFullName', () {
    test('keeps a GitLab nested namespace as the owner', () {
      expect(splitRepoFullName('group/sub/project'), (
        owner: 'group/sub',
        name: 'project',
      ));
      expect(splitRepoFullName('o/r'), (owner: 'o', name: 'r'));
    });

    test('refuses a name with an empty half', () {
      expect(splitRepoFullName('repo'), isNull);
      expect(splitRepoFullName('/repo'), isNull);
      expect(splitRepoFullName('owner/'), isNull);
    });
  });
}
