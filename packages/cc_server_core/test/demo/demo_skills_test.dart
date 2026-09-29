import 'dart:io';

import 'package:cc_domain/features/skills/domain/scanner/installed_skill_status.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/demo/demo_skills.dart';
import 'package:cc_server_core/src/skills/installed_skills_list.dart';
import 'package:test/test.dart';

void main() {
  test(
    'seedDemoSkills writes the Helix skills and pins matching hashes',
    () async {
      final tmp = Directory.systemTemp.createTempSync('demo-skills');
      addTearDown(() => tmp.deleteSync(recursive: true));

      await seedDemoSkills(dataDir: tmp.path, workspaceId: 'ws');

      final bundles = SkillBundleService(
        filesystem: WorkspaceFilesystemService(CcPaths(tmp.path)),
        fetchGitHubSkill:
            ({
              required String owner,
              required String repo,
              required String path,
              String? ref,
            }) async => throw UnsupportedError('unused'),
      );
      final statuses = await bundles.listInstalledStatus('ws');
      expect(statuses.map((s) => s.slug), containsAll(kDemoSkillFiles.keys));
      expect(
        statuses.every((s) => s.lockState == InstalledSkillLockState.managed),
        isTrue,
      );

      final payload = await installedSkillsListPayload(bundles, 'ws');
      final listed = payload['skills'] as List;
      expect(
        listed.map((s) => (s as Map)['slug']),
        containsAll(kDemoSkillFiles.keys),
      );
      expect(
        listed.every(
          (s) => ((s as Map)['content'] as String).contains('name: '),
        ),
        isTrue,
      );

      final review = File('${tmp.path}/ws/skills/review/SKILL.md');
      final original = await review.readAsString();
      expect(original, contains('name: review'));
      await review.writeAsString('kept');
      await seedDemoSkills(dataDir: tmp.path, workspaceId: 'ws');
      expect(await review.readAsString(), 'kept');
      final again = await bundles.listInstalledStatus('ws');
      expect(
        again.singleWhere((s) => s.slug == 'review').lockState,
        InstalledSkillLockState.managed,
      );
    },
  );
}
