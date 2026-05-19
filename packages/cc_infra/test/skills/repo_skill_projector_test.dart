import 'dart:io';

import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_infra/src/skills/repo_skill_projector.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A scanner that passes everything except the slugs named in [quarantine],
/// and throws for the slugs named in [explode].
class _FakeScanner implements SkillScanPort {
  _FakeScanner({this.quarantine = const {}, this.explode = const {}});

  final Set<String> quarantine;
  final Set<String> explode;
  final List<String> scanned = [];

  @override
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  }) async {
    scanned.add(bundle.slug);
    if (explode.contains(bundle.slug)) {
      throw StateError('scanner exploded');
    }
    return SkillScanResult(
      verdict: quarantine.contains(bundle.slug)
          ? SkillScanVerdict.quarantine
          : SkillScanVerdict.pass,
      findings: const [],
      manifest: const SkillCapabilityManifest(),
      rulesVersion: 1,
    );
  }
}

void main() {
  late Directory root;
  late String overlay;
  late String repos;

  setUp(() {
    root = Directory.systemTemp.createTempSync('projector_');
    overlay = p.join(root.path, 'agents', 'engineer');
    repos = p.join(root.path, 'repos');
    Directory(overlay).createSync(recursive: true);
    Directory(repos).createSync(recursive: true);
  });
  tearDown(() => root.deleteSync(recursive: true));

  void writeSkill(String repo, String skillsDir, String slug, {String? name}) {
    final dir = Directory(p.join(repos, repo, skillsDir, slug))
      ..createSync(recursive: true);
    File(p.join(dir.path, 'SKILL.md')).writeAsStringSync(
      '---\nname: ${name ?? slug}\ndescription: does $slug\n---\nBody.',
    );
  }

  RepoSkillProjector projector(SkillScanPort? scanner) => RepoSkillProjector(
    workspaceId: 'ws1',
    overlayDir: overlay,
    reposDir: repos,
    scanner: scanner,
  );

  List<String> linkedSlugs(String dir) {
    final target = Directory(p.join(overlay, dir));
    if (!target.existsSync()) {
      return [];
    }
    return target
        .listSync(followLinks: false)
        .map((e) => p.basename(e.path))
        .toList()
      ..sort();
  }

  test('projects only the active repo', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    writeSkill('web-app', '.agents/skills', 'routing');
    writeSkill('api', '.agents/skills', 'migrations');

    final result = await projector(_FakeScanner()).project('web-app');

    expect(result.repo, 'web-app');
    expect(result.skills.map((s) => s.name).toList()..sort(), [
      'forms',
      'routing',
    ]);
    expect(linkedSlugs('.claude/skills'), ['forms', 'routing']);
    expect(linkedSlugs('.opencode/skills'), ['forms', 'routing']);
  });

  test('a swap removes the previous repo entirely', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    writeSkill('api', '.agents/skills', 'migrations');

    final proj = projector(_FakeScanner());
    await proj.project('web-app');
    final second = await proj.project('api');

    expect(second.skills.map((s) => s.name), ['migrations']);
    expect(linkedSlugs('.claude/skills'), [
      'migrations',
    ], reason: 'the previous repo must not linger');
    expect(proj.projectedRepo, 'api');
  });

  test('a null active repo clears the projection', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    final proj = projector(_FakeScanner());
    await proj.project('web-app');

    final cleared = await proj.project(null);
    expect(cleared.skills, isEmpty);
    expect(cleared.repo, isNull);
    expect(linkedSlugs('.claude/skills'), isEmpty);
    expect(proj.projectedRepo, isNull);
  });

  test('re-projecting the same repo is idempotent', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    final proj = projector(_FakeScanner());
    await proj.project('web-app');
    final again = await proj.project('web-app');

    expect(again.skills.map((s) => s.name), ['forms']);
    expect(linkedSlugs('.claude/skills'), ['forms']);
  });

  test('a quarantined skill never lands on disk', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    writeSkill('web-app', '.agents/skills', 'evil');

    final result = await projector(
      _FakeScanner(quarantine: {'evil'}),
    ).project('web-app');

    expect(result.skills.map((s) => s.name), ['forms']);
    expect(result.quarantined, ['evil']);
    expect(linkedSlugs('.claude/skills'), ['forms']);
    expect(result.announcement, contains('Withheld by the skill scanner'));
  });

  test(
    'a scanner error withholds the skill rather than admitting it',
    () async {
      writeSkill('web-app', '.agents/skills', 'forms');
      writeSkill('web-app', '.agents/skills', 'boom');

      final result = await projector(
        _FakeScanner(explode: {'boom'}),
      ).project('web-app');

      expect(result.skills.map((s) => s.name), ['forms']);
      expect(result.quarantined, ['boom']);
    },
  );

  test('no scanner projects nothing at all', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    final result = await projector(null).project('web-app');
    expect(result.skills, isEmpty);
    expect(linkedSlugs('.claude/skills'), isEmpty);
  });

  test('verdicts are memoized across swaps', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    writeSkill('api', '.agents/skills', 'migrations');
    final scanner = _FakeScanner();
    final proj = projector(scanner);

    await proj.project('web-app');
    await proj.project('api');
    await proj.project('web-app');

    expect(scanner.scanned, [
      'forms',
      'migrations',
    ], reason: 'unchanged files must not be re-scanned on every switch');
  });

  test('never writes into .agents/skills', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    await projector(_FakeScanner()).project('web-app');
    // That path is a symlink to the agent's global config dir in a real
    // overlay; writing there would leak across every space.
    expect(Directory(p.join(overlay, '.agents')).existsSync(), isFalse);
  });

  test('a missing worktree clears rather than throwing', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    final proj = projector(_FakeScanner());
    await proj.project('web-app');

    final result = await proj.project('does-not-exist');
    expect(result.skills, isEmpty);
    expect(linkedSlugs('.claude/skills'), isEmpty);
  });

  test('discovers .claude/skills as well as .agents/skills', () async {
    writeSkill('api', '.claude/skills', 'migrations');
    final result = await projector(_FakeScanner()).project('api');
    expect(result.skills.map((s) => s.name), ['migrations']);
  });

  test('a real directory in the projected dir is left alone', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    final owned = Directory(p.join(overlay, '.claude', 'skills', 'hand-made'))
      ..createSync(recursive: true);
    File(
      p.join(owned.path, 'SKILL.md'),
    ).writeAsStringSync('---\nname: x\n---\n');

    await projector(_FakeScanner()).project('web-app');
    expect(linkedSlugs('.claude/skills'), ['forms', 'hand-made']);
  });

  test('the projected path is addressable from the overlay', () async {
    writeSkill('web-app', '.agents/skills', 'forms');
    final result = await projector(_FakeScanner()).project('web-app');
    final path = result.skills.single.path;
    expect(p.isWithin(overlay, path), isTrue);
    expect(File(path).existsSync(), isTrue);
  });

  group('composed AGENTS.md (the Codex lane)', () {
    late Directory agentConfig;

    setUp(() {
      agentConfig = Directory.systemTemp.createTempSync('agent_cfg_');
      File(
        p.join(agentConfig.path, 'AGENTS.md'),
      ).writeAsStringSync('# engineer\nAgent profile body.');
      // As the provisioner leaves it: a symlink to the agent's global profile.
      Link(
        p.join(overlay, 'AGENTS.md'),
      ).createSync(p.join(agentConfig.path, 'AGENTS.md'));
    });
    tearDown(() => agentConfig.deleteSync(recursive: true));

    String overlayAgentsMd() =>
        File(p.join(overlay, 'AGENTS.md')).readAsStringSync();

    test('keeps the profile and adds the repo section', () async {
      writeSkill('web-app', '.agents/skills', 'forms');
      File(
        p.join(repos, 'web-app', 'AGENTS.md'),
      ).writeAsStringSync('Repo house rules.');

      await projector(_FakeScanner()).project('web-app');

      final text = overlayAgentsMd();
      expect(text, contains('Agent profile body.'));
      expect(text, contains('Active repository: web-app'));
      expect(text, contains('Repo house rules.'));
      expect(text, contains('forms'));
    });

    test('is a real file, not the symlink', () async {
      writeSkill('web-app', '.agents/skills', 'forms');
      await projector(_FakeScanner()).project('web-app');
      expect(
        FileSystemEntity.isLinkSync(p.join(overlay, 'AGENTS.md')),
        isFalse,
      );
      // The agent's global profile must not have been written through.
      expect(
        File(p.join(agentConfig.path, 'AGENTS.md')).readAsStringSync(),
        '# engineer\nAgent profile body.',
      );
    });

    test('a swap replaces the section instead of compounding', () async {
      writeSkill('web-app', '.agents/skills', 'forms');
      writeSkill('api', '.agents/skills', 'migrations');
      final proj = projector(_FakeScanner());

      await proj.project('web-app');
      await proj.project('api');

      final text = overlayAgentsMd();
      expect(text, contains('Active repository: api'));
      expect(text, isNot(contains('web-app')));
      expect(text, isNot(contains('forms')));
      expect(
        'Agent profile body.'.allMatches(text).length,
        1,
        reason: 'the profile must appear once, not once per switch',
      );
    });

    test('clearing leaves the profile alone', () async {
      writeSkill('web-app', '.agents/skills', 'forms');
      final proj = projector(_FakeScanner());
      await proj.project('web-app');
      await proj.project(null);

      final text = overlayAgentsMd();
      expect(text, contains('Agent profile body.'));
      expect(text, isNot(contains('Active repository')));
    });

    test(
      'falls back to the repo CLAUDE.md when there is no AGENTS.md',
      () async {
        writeSkill('api', '.agents/skills', 'migrations');
        File(
          p.join(repos, 'api', 'CLAUDE.md'),
        ).writeAsStringSync('Claude-flavoured rules.');

        await projector(_FakeScanner()).project('api');
        expect(overlayAgentsMd(), contains('Claude-flavoured rules.'));
      },
    );

    test('never overwrites an AGENTS.md it does not own', () async {
      // If the "overlay" were ever the agent's own config dir, this name holds
      // the agent's real profile and clobbering it loses it for every space.
      File(p.join(overlay, 'AGENTS.md')).deleteSync();
      File(
        p.join(overlay, 'AGENTS.md'),
      ).writeAsStringSync('Someone else owns this.');
      writeSkill('web-app', '.agents/skills', 'forms');

      await projector(_FakeScanner()).project('web-app');
      expect(overlayAgentsMd(), 'Someone else owns this.');
    });

    test('a huge repo AGENTS.md is truncated', () async {
      writeSkill('api', '.agents/skills', 'migrations');
      File(p.join(repos, 'api', 'AGENTS.md')).writeAsStringSync('x' * 40000);

      await projector(_FakeScanner()).project('api');
      final text = overlayAgentsMd();
      expect(text, contains('…(truncated)'));
      expect(text.length, lessThan(30000));
    });
  });

  test('the announcement supersedes the previous repo', () async {
    writeSkill('api', '.agents/skills', 'migrations');
    final result = await projector(_FakeScanner()).project('api');
    expect(result.announcement, contains('repos/api'));
    expect(result.announcement, contains('no longer apply'));
    expect(result.announcement, contains('migrations'));
  });
}
