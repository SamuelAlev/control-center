import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:test/test.dart';

/// Covers the SkillScanVerdict / SkillTrustTier enums and their wire round
/// trips, the SkillScanFinding codec, the SkillCapabilityManifest merge + wire
/// projection, the SkillBundle factory, and the SkillScanResult tighten logic.
void main() {
  group('SkillScanVerdict', () {
    test('wire names are stable', () {
      expect(SkillScanVerdict.pass.wire, 'pass');
      expect(SkillScanVerdict.warn.wire, 'warn');
      expect(SkillScanVerdict.quarantine.wire, 'quarantine');
    });

    test('severity orders pass < warn < quarantine', () {
      expect(
        SkillScanVerdict.pass.severity,
        lessThan(SkillScanVerdict.warn.severity),
      );
      expect(
        SkillScanVerdict.warn.severity,
        lessThan(SkillScanVerdict.quarantine.severity),
      );
    });

    test('installable is false only for quarantine', () {
      expect(SkillScanVerdict.pass.installable, isTrue);
      expect(SkillScanVerdict.warn.installable, isTrue);
      expect(SkillScanVerdict.quarantine.installable, isFalse);
    });

    test('fromWire parses known wire names', () {
      expect(SkillScanVerdict.fromWire('pass'), SkillScanVerdict.pass);
      expect(SkillScanVerdict.fromWire('warn'), SkillScanVerdict.warn);
      expect(
        SkillScanVerdict.fromWire('quarantine'),
        SkillScanVerdict.quarantine,
      );
    });

    test('fromWire fails closed to quarantine on unknown input', () {
      expect(SkillScanVerdict.fromWire('bogus'), SkillScanVerdict.quarantine);
    });

    test('tighten returns the more severe verdict', () {
      expect(
        SkillScanVerdict.tighten(SkillScanVerdict.pass, SkillScanVerdict.warn),
        SkillScanVerdict.warn,
      );
      expect(
        SkillScanVerdict.tighten(
          SkillScanVerdict.quarantine,
          SkillScanVerdict.pass,
        ),
        SkillScanVerdict.quarantine,
        reason: 'a static quarantine cannot be loosened by an LLM pass',
      );
      expect(
        SkillScanVerdict.tighten(SkillScanVerdict.warn, SkillScanVerdict.warn),
        SkillScanVerdict.warn,
      );
    });
  });

  group('SkillTrustTier', () {
    test('wire names are stable', () {
      expect(SkillTrustTier.firstParty.wire, 'firstParty');
      expect(SkillTrustTier.workspace.wire, 'workspace');
      expect(SkillTrustTier.verified.wire, 'verified');
      expect(SkillTrustTier.community.wire, 'community');
    });

    test('fromWire parses known wire names', () {
      expect(SkillTrustTier.fromWire('firstParty'), SkillTrustTier.firstParty);
      expect(SkillTrustTier.fromWire('community'), SkillTrustTier.community);
    });

    test('fromWire defaults to community for null or unknown input', () {
      expect(SkillTrustTier.fromWire(null), SkillTrustTier.community);
      expect(SkillTrustTier.fromWire('nope'), SkillTrustTier.community);
    });
  });

  group('SkillScanFinding', () {
    const finding = SkillScanFinding(
      ruleId: 'curl_pipe_bash',
      verdict: SkillScanVerdict.quarantine,
      message: 'pipes curl into bash',
      file: 'scripts/run.sh',
      line: 12,
      snippet: 'curl ... | bash',
    );

    test('round-trips every field through the constructor', () {
      expect(finding.ruleId, 'curl_pipe_bash');
      expect(finding.verdict, SkillScanVerdict.quarantine);
      expect(finding.message, 'pipes curl into bash');
      expect(finding.file, 'scripts/run.sh');
      expect(finding.line, 12);
      expect(finding.snippet, 'curl ... | bash');
    });

    test('defaults line to 0 and snippet to empty', () {
      const f = SkillScanFinding(
        ruleId: 'r',
        verdict: SkillScanVerdict.warn,
        message: 'm',
        file: 'f',
      );
      expect(f.line, 0);
      expect(f.snippet, '');
    });

    test('toJson serializes every field using the verdict wire name', () {
      expect(finding.toJson(), {
        'ruleId': 'curl_pipe_bash',
        'verdict': 'quarantine',
        'message': 'pipes curl into bash',
        'file': 'scripts/run.sh',
        'line': 12,
        'snippet': 'curl ... | bash',
      });
    });

    test('fromJson round-trips a serialized finding', () {
      final decoded = SkillScanFinding.fromJson(finding.toJson());
      expect(decoded.ruleId, finding.ruleId);
      expect(decoded.verdict, finding.verdict);
      expect(decoded.message, finding.message);
      expect(decoded.file, finding.file);
      expect(decoded.line, finding.line);
      expect(decoded.snippet, finding.snippet);
    });

    test('fromJson tolerates missing/wrong-typed fields with defaults', () {
      final decoded = SkillScanFinding.fromJson(const <String, dynamic>{});
      expect(decoded.ruleId, '');
      expect(
        decoded.verdict,
        SkillScanVerdict.warn,
        reason: 'absent verdict wire defaults to warn',
      );
      expect(decoded.message, '');
      expect(decoded.file, '');
      expect(decoded.line, 0);
      expect(decoded.snippet, '');
    });

    test('fromJson falls closed to quarantine for an unknown verdict wire', () {
      final decoded = SkillScanFinding.fromJson(const {
        'ruleId': 'r',
        'verdict': 'unknown-kind',
        'message': 'm',
        'file': 'f',
      });
      expect(decoded.verdict, SkillScanVerdict.quarantine);
    });

    test('fromJson coerces a numeric line value', () {
      final decoded = SkillScanFinding.fromJson(const {'line': 7.0});
      expect(decoded.line, 7);
    });
  });

  group('SkillCapabilityManifest', () {
    test('defaults every capability to false', () {
      const m = SkillCapabilityManifest();
      expect(m.needsBash, isFalse);
      expect(m.writesFiles, isFalse);
      expect(m.deletesFiles, isFalse);
      expect(m.networkEgress, isFalse);
      expect(m.readsSecrets, isFalse);
      expect(m.installsPackages, isFalse);
      expect(m.requiredActionClassWires, isEmpty);
      expect(m.labels, isEmpty);
    });

    test(
      'requiredActionClassWires maps each capability to its action wire',
      () {
        const m = SkillCapabilityManifest(
          needsBash: true,
          writesFiles: true,
          deletesFiles: true,
          networkEgress: true,
          readsSecrets: true,
          installsPackages: true,
        );
        expect(m.requiredActionClassWires, [
          'processSpawn',
          'fileWriteOutsideWorktree',
          'fileDelete',
          'networkEgress',
          'secretAccess',
          'packageInstall',
        ]);
      },
    );

    test('labels lists the enabled capabilities', () {
      const m = SkillCapabilityManifest(
        needsBash: true,
        installsPackages: true,
        writesFiles: true,
        deletesFiles: true,
        networkEgress: true,
        readsSecrets: true,
      );
      expect(m.labels, [
        'Bash',
        'package installs',
        'file writes',
        'file deletes',
        'network egress',
        'secret access',
      ]);
    });

    test('toJson + fromJson round-trip a populated manifest', () {
      const m = SkillCapabilityManifest(
        needsBash: true,
        writesFiles: true,
        readsSecrets: true,
      );
      final decoded = SkillCapabilityManifest.fromJson(m.toJson());
      expect(decoded.needsBash, isTrue);
      expect(decoded.writesFiles, isTrue);
      expect(decoded.readsSecrets, isTrue);
      expect(decoded.deletesFiles, isFalse);
    });

    test('fromJson tolerates an empty map', () {
      final decoded = SkillCapabilityManifest.fromJson(
        const <String, dynamic>{},
      );
      expect(decoded.needsBash, isFalse);
      expect(decoded.installsPackages, isFalse);
    });

    test('merge unions two manifests (never narrows)', () {
      const a = SkillCapabilityManifest(needsBash: true, readsSecrets: true);
      const b = SkillCapabilityManifest(
        writesFiles: true,
        installsPackages: true,
      );
      final merged = a.merge(b);
      expect(merged.needsBash, isTrue);
      expect(merged.readsSecrets, isTrue);
      expect(merged.writesFiles, isTrue);
      expect(merged.installsPackages, isTrue);
      expect(merged.deletesFiles, isFalse);
      expect(merged.networkEgress, isFalse);
    });

    test('merge is idempotent with an empty manifest', () {
      const a = SkillCapabilityManifest(needsBash: true);
      expect(a.merge(const SkillCapabilityManifest()).needsBash, isTrue);
    });

    test('toJsonString serializes to a JSON string', () {
      const m = SkillCapabilityManifest(needsBash: true);
      expect(m.toJsonString(), contains('"needsBash":true'));
    });
  });

  group('SkillBundle', () {
    test('a populated bundle carries its files map', () {
      const bundle = SkillBundle(
        slug: 'my-skill',
        files: {'SKILL.md': '# x', 'README.md': 'y'},
      );
      expect(bundle.slug, 'my-skill');
      expect(bundle.files['SKILL.md'], '# x');
      expect(bundle.files['README.md'], 'y');
    });

    test('single creates a one-file bundle of just SKILL.md', () {
      final bundle = SkillBundle.single('slug', 'body');
      expect(bundle.slug, 'slug');
      expect(bundle.files, {'SKILL.md': 'body'});
    });
  });

  group('SkillScanResult', () {
    const finding = SkillScanFinding(
      ruleId: 'curl_pipe_bash',
      verdict: SkillScanVerdict.quarantine,
      message: 'm',
      file: 'f',
    );
    const manifest = SkillCapabilityManifest(needsBash: true);
    const result = SkillScanResult(
      verdict: SkillScanVerdict.warn,
      findings: [finding],
      manifest: manifest,
      rulesVersion: 7,
    );

    test('round-trips every field', () {
      expect(result.verdict, SkillScanVerdict.warn);
      expect(result.findings, [finding]);
      expect(result.manifest, manifest);
      expect(result.rulesVersion, 7);
      expect(
        result.llmReviewed,
        isFalse,
        reason: 'default before Layer 3 LLM review',
      );
    });

    test('findingsJsonString serializes findings to a JSON array string', () {
      expect(
        result.findingsJsonString(),
        contains('"ruleId":"curl_pipe_bash"'),
      );
    });

    test('tightenedTo tightens the verdict and merges extra findings', () {
      final tightened = result.tightenedTo(
        SkillScanVerdict.quarantine,
        extraFindings: const [
          SkillScanFinding(
            ruleId: 'r2',
            verdict: SkillScanVerdict.warn,
            message: 'm2',
            file: 'f2',
          ),
        ],
      );
      expect(
        tightened.verdict,
        SkillScanVerdict.quarantine,
        reason: 'a warn result tightened to quarantine',
      );
      expect(tightened.findings.length, 2);
      expect(tightened.findings.first.ruleId, 'curl_pipe_bash');
      expect(tightened.findings.last.ruleId, 'r2');
      expect(tightened.manifest, same(manifest));
      expect(tightened.rulesVersion, 7);
      expect(
        tightened.llmReviewed,
        isTrue,
        reason: 'a tightened result was reviewed',
      );
    });

    test('tightenedTo cannot loosen a quarantine result', () {
      const blocked = SkillScanResult(
        verdict: SkillScanVerdict.quarantine,
        findings: [],
        manifest: manifest,
        rulesVersion: 1,
      );
      final tightened = blocked.tightenedTo(SkillScanVerdict.pass);
      expect(
        tightened.verdict,
        SkillScanVerdict.quarantine,
        reason: 'a static quarantine survives an LLM pass',
      );
    });

    test('tightenedTo defaults to no extra findings and llmReviewed true', () {
      final tightened = result.tightenedTo(SkillScanVerdict.warn);
      expect(tightened.findings.length, 1);
      expect(tightened.llmReviewed, isTrue);
    });
  });
}
