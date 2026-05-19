import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/activity_formatting.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsEn();

  UserActivityDto entry(String action, {String? targetId}) => UserActivityDto(
    id: 'x',
    workspaceId: 'ws-1',
    userId: 'u-1',
    action: action,
    targetType: 'x',
    targetId: targetId,
    createdAt: DateTime(2026),
  );

  group('describeActivity special cases', () {
    test('full-sentence overrides for compound actions', () {
      expect(
        describeActivity(l10n, entry('fs.persistLogo')),
        'Saved the workspace logo',
      );
      expect(
        describeActivity(l10n, entry('members.setRole', targetId: 'u-7')),
        'Changed a member\'s role · u-7',
      );
      expect(
        describeActivity(l10n, entry('weather.refreshNow')),
        'Refreshed the weather forecast',
      );
      expect(
        describeActivity(l10n, entry('takeover.begin')),
        'Took over the session',
      );
      expect(
        describeActivity(l10n, entry('worktree.commitAndPush')),
        'Committed and pushed',
      );
      expect(
        describeActivity(l10n, entry('server.backupNow')),
        'Backed up the server data',
      );
      expect(
        describeActivity(l10n, entry('space_read.markSpaceRead')),
        'Marked the space as read',
      );
    });
  });

  group('describeActivity verb × domain expansion', () {
    test('maps compound verbs through their first camel segment', () {
      expect(
        describeActivity(l10n, entry('repos.addFromPath', targetId: '/tmp/x')),
        'Added repository · /tmp/x',
      );
      expect(
        describeActivity(l10n, entry('pr_review.mergePullRequest')),
        'Merged review',
      );
      expect(
        describeActivity(l10n, entry('terminal.spawn')),
        'Started terminal',
      );
      expect(
        describeActivity(l10n, entry('newsfeed.refreshAll')),
        'Refreshed feed',
      );
      expect(
        describeActivity(l10n, entry('pipeline.retry', targetId: 'r-1')),
        'Retried pipeline · r-1',
      );
      expect(
        describeActivity(l10n, entry('skills.sourceInstall')),
        'Installed skill',
      );
    });

    test('keeps legacy whole-verb actions working', () {
      expect(
        describeActivity(l10n, entry('agents.upsert', targetId: 'ceo')),
        'Updated agent · ceo',
      );
      expect(describeActivity(l10n, entry('members.invite')), 'Invited member');
      expect(
        describeActivity(l10n, entry('tickets.create', targetId: 'T-9')),
        'Created ticket · T-9',
      );
      expect(
        describeActivity(l10n, entry('skills.delete', targetId: 'pdf')),
        'Deleted skill · pdf',
      );
    });
  });

  group('describeActivity fallback', () {
    test('humanizes an unknown verb instead of echoing the raw op', () {
      expect(
        describeActivity(l10n, entry('fleet.workerHeartbeat')),
        'Worker heartbeat',
      );
      expect(
        describeActivity(l10n, entry('weather.frobNow', targetId: 'x')),
        'Frob now · x',
      );
    });

    test('returns the raw action only when it has no domain.verb shape', () {
      expect(describeActivity(l10n, entry('orphan')), 'orphan');
    });
  });
}
