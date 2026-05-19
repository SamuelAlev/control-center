import 'dart:io';

import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_infra/src/skills/repo_skill_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _FakeScanner implements SkillScanPort {
  _FakeScanner({this.quarantine = const {}});

  final Set<String> quarantine;
  final List<String> scanned = [];

  @override
  Future<SkillScanResult> scan(
    SkillBundle bundle, {
    required String workspaceId,
    SkillTrustTier trustTier = SkillTrustTier.community,
    bool runLlmReview = true,
  }) async {
    scanned.add(bundle.slug);
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
  late String repos;

  setUp(() {
    root = Directory.systemTemp.createTempSync('catalog_');
    repos = p.join(root.path, 'repos');
    Directory(repos).createSync(recursive: true);
  });
  tearDown(() => root.deleteSync(recursive: true));

  void writeSkill(String repo, String slug, {String? name}) {
    final dir = Directory(p.join(repos, repo, '.agents', 'skills', slug))
      ..createSync(recursive: true);
    File(p.join(dir.path, 'SKILL.md')).writeAsStringSync(
      '---\nname: ${name ?? slug}\ndescription: does $slug\n---\nBody.',
    );
  }

  RepoSkillCatalog catalog([SkillScanPort? scanner]) => RepoSkillCatalog(
    workspaceId: 'ws',
    reposDir: repos,
    scanner: scanner ?? _FakeScanner(),
  );

  test('lists every repo in the space, not just one', () async {
    writeSkill('web-app', 'forms');
    writeSkill('api', 'migrations');

    final all = await catalog().listAll();
    expect(
      all.map((s) => s.qualifiedName).toList()..sort(),
      ['api:migrations', 'web-app:forms'],
    );
  });

  test('resolves a qualified name', () async {
    writeSkill('web-app', 'testing');
    writeSkill('api', 'testing');

    final entry = await catalog().resolve('api:testing');
    expect(entry?.repo, 'api');
    expect(p.isWithin(p.join(repos, 'api'), entry!.path), isTrue);
  });

  test('resolves a bare name when exactly one repo ships it', () async {
    writeSkill('web-app', 'forms');
    writeSkill('api', 'migrations');

    expect((await catalog().resolve('forms'))?.repo, 'web-app');
  });

  test('refuses an ambiguous bare name rather than guessing', () async {
    writeSkill('web-app', 'testing');
    writeSkill('api', 'testing');

    // Two repos' `testing` are different instructions; picking one silently
    // would apply the wrong service's conventions.
    expect(await catalog().resolve('testing'), isNull);
  });

  test('resolves by slug as well as frontmatter name', () async {
    writeSkill('api', 'pull-request', name: 'Open a PR');
    expect((await catalog().resolve('api:pull-request'))?.slug, 'pull-request');
    expect((await catalog().resolve('api:Open a PR'))?.slug, 'pull-request');
  });

  test('an unknown repo or skill resolves to nothing', () async {
    writeSkill('api', 'migrations');
    expect(await catalog().resolve('nope:migrations'), isNull);
    expect(await catalog().resolve('api:nope'), isNull);
    expect(await catalog().resolve('nope'), isNull);
  });

  test('a quarantined skill is neither listed nor resolvable', () async {
    writeSkill('api', 'migrations');
    writeSkill('api', 'evil');
    final scanner = _FakeScanner(quarantine: {'evil'});

    final c = catalog(scanner);
    expect((await c.listAll()).map((s) => s.slug), ['migrations']);
    expect(await c.resolve('api:evil'), isNull);

    final inspected = await c.inspect('api');
    expect(inspected.withheld, ['evil']);
  });

  test('no scanner yields nothing rather than ungated content', () async {
    writeSkill('api', 'migrations');
    final c = RepoSkillCatalog(workspaceId: 'ws', reposDir: repos);
    expect(await c.listAll(), isEmpty);
    expect(await c.resolve('api:migrations'), isNull);
  });

  test('verdicts are memoized across calls', () async {
    writeSkill('api', 'migrations');
    final scanner = _FakeScanner();
    final c = catalog(scanner);

    await c.listAll();
    await c.listAll();
    await c.resolve('api:migrations');

    expect(scanner.scanned, ['migrations']);
  });

  test('a missing repos dir is empty, not an error', () async {
    final c = RepoSkillCatalog(
      workspaceId: 'ws',
      reposDir: p.join(root.path, 'nope'),
      scanner: _FakeScanner(),
    );
    expect(c.repos(), isEmpty);
    expect(await c.listAll(), isEmpty);
  });
}
