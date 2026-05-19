// A static-only namespace class is the established pattern for CC's pure
// rule/codec tables (mirrors AgentProcessEventCodec, model_fuzzy_search, …).
// ignore_for_file: avoid_classes_with_only_static_members
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// The static-rules version (PRD 23 §Clarifications). Monotonic; bump ONLY on
/// rule-*semantics* changes (never refactors) — §6's staleness check compares a
/// scanned skill's version against this. The first-party skill corpus is the
/// rules regression suite.
const int kSkillRulesVersion = 1;

/// Layer 1 (PRD 23 §3): deterministic, free, execution-free static rules over
/// the fetched bundle bytes. Pure function — no process spawn, no network, no
/// disk. Every finding names the exact pattern, file and line.
///
/// The scanner is inert by construction: this operates only on the in-memory
/// bundle and returns findings; it never runs anything the skill contains.
abstract final class SkillStaticRules {
  /// Scans every file in [bundle] and returns aggregated findings.
  static List<SkillScanFinding> scan(SkillBundle bundle) {
    final findings = <SkillScanFinding>[];
    bundle.files.forEach((path, content) {
      findings.addAll(_scanFile(path, content));
    });
    return findings;
  }

  static List<SkillScanFinding> _scanFile(String path, String content) {
    final findings = <SkillScanFinding>[];

    // Concealment rules run over the whole content (line-agnostic).
    findings.addAll(_concealment(path, content));

    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      final n = i + 1;

      void add(String ruleId, SkillScanVerdict verdict, String message) {
        findings.add(
          SkillScanFinding(
            ruleId: ruleId,
            verdict: verdict,
            message: message,
            file: path,
            line: n,
            snippet: _snippet(line),
          ),
        );
      }

      // curl|bash family — download-and-execute (quarantine).
      if (_curlPipeShell.hasMatch(line)) {
        add(
          'curl_pipe_shell',
          SkillScanVerdict.quarantine,
          'Downloads and pipes a remote script directly into a shell '
              '(curl … | bash).',
        );
      }
      // rm -rf on a dangerous root path (quarantine).
      if (_rmDangerous.hasMatch(line)) {
        add(
          'rm_rf_dangerous',
          SkillScanVerdict.quarantine,
          'Recursive force-delete of a root/home path (rm -rf).',
        );
      }
      // base64/hex decode piped to a shell (quarantine — obfuscated exec).
      if (_decodePipeShell.hasMatch(lower)) {
        add(
          'decode_pipe_shell',
          SkillScanVerdict.quarantine,
          'Decodes an obfuscated blob and executes it.',
        );
      }
      // eval of a command substitution / variable (quarantine).
      if (_evalDynamic.hasMatch(line)) {
        add(
          'eval_dynamic',
          SkillScanVerdict.quarantine,
          'Evaluates dynamically-constructed shell (eval).',
        );
      }
      // chmod +x then execute (warn).
      if (_chmodExec.hasMatch(lower)) {
        add(
          'chmod_exec',
          SkillScanVerdict.warn,
          'Makes a file executable (chmod +x) — verify what it runs.',
        );
      }
      // package-manager global install (warn — capability).
      if (_packageInstall.hasMatch(lower)) {
        add(
          'package_install',
          SkillScanVerdict.warn,
          'Installs a package/tool — a supply-chain surface.',
        );
      }
      // long base64 blob (warn — obfuscation signal).
      if (_base64Blob.hasMatch(line)) {
        add(
          'base64_blob',
          SkillScanVerdict.warn,
          'Contains a long encoded blob (possible hidden payload).',
        );
      }
    }

    // Exfiltration: a secret read AND network egress in the same file
    // (quarantine — the classic exfil shape).
    if (_readsSecret.hasMatch(content) && _networkEgress.hasMatch(content)) {
      findings.add(
        SkillScanFinding(
          ruleId: 'secret_exfiltration',
          verdict: SkillScanVerdict.quarantine,
          message:
              'Reads a secret/credential and performs network egress in '
              'the same file (exfiltration shape).',
          file: path,
        ),
      );
    }
    return findings;
  }

  static List<SkillScanFinding> _concealment(String path, String content) {
    final findings = <SkillScanFinding>[];
    // Zero-width / invisible characters used to hide instructions.
    if (_zeroWidth.hasMatch(content)) {
      findings.add(
        SkillScanFinding(
          ruleId: 'zero_width_chars',
          verdict: SkillScanVerdict.quarantine,
          message:
              'Contains zero-width/invisible characters — a common way to '
              'hide instructions from a human reviewer.',
          file: path,
        ),
      );
    }
    // Bidirectional-override characters (Trojan-Source style).
    if (_bidiOverride.hasMatch(content)) {
      findings.add(
        SkillScanFinding(
          ruleId: 'bidi_override',
          verdict: SkillScanVerdict.quarantine,
          message:
              'Contains bidirectional-override characters that can reorder '
              'visible text (Trojan-Source concealment).',
          file: path,
        ),
      );
    }
    // "ignore previous instructions" prompt-injection family.
    final injMatch = _promptInjection.firstMatch(content);
    if (injMatch != null) {
      final idx = injMatch.start;
      findings.add(
        SkillScanFinding(
          ruleId: 'prompt_injection',
          verdict: SkillScanVerdict.quarantine,
          message:
              'Contains prompt-injection phrasing directed at the agent '
              '("ignore previous instructions" family).',
          file: path,
          line: _lineOf(content, idx),
          snippet: _snippet(injMatch.group(0) ?? ''),
        ),
      );
    }
    // HTML-comment-hidden instructions.
    for (final m in _htmlCommentInstruction.allMatches(content)) {
      findings.add(
        SkillScanFinding(
          ruleId: 'hidden_html_comment',
          verdict: SkillScanVerdict.warn,
          message: 'Instruction-like text hidden inside an HTML comment.',
          file: path,
          line: _lineOf(content, m.start),
          snippet: _snippet(m.group(0) ?? ''),
        ),
      );
    }
    return findings;
  }

  static int _lineOf(String content, int index) =>
      '\n'.allMatches(content.substring(0, index)).length + 1;

  static String _snippet(String s) {
    final trimmed = s.trim();
    return trimmed.length <= 120 ? trimmed : '${trimmed.substring(0, 117)}…';
  }

  // ── Rule patterns ──
  static final RegExp _curlPipeShell = RegExp(
    // Pipe into a shell (any shell, sudo + arbitrary flags between): curl|bash.
    r'(curl|wget)\b[^\n|]*\|\s*(sudo\b[^\n|]*\s+)?(ba|z|da|k)?sh\b'
    // Pipe into a non-sh interpreter: curl|python.
    r'|(curl|wget)\b[^\n|]*\|\s*(sudo\b[^\n|]*\s+)?(python3?|perl|ruby|node|php)\b'
    // Process substitution: bash <(curl …) / python <(curl …).
    r'|(ba|z|da|k)?sh\b[^\n]*<\(\s*(curl|wget)\b'
    r'|(python3?|perl|ruby|node)\b[^\n]*<\(\s*(curl|wget)\b'
    // Command substitution: sh -c "$(curl …)" / eval "$(curl …)".
    r'|(ba|z|da|k)?sh\b[^\n]*-c[^\n]*\$\(\s*(curl|wget)\b'
    r'|\beval\b[^\n]*\$\(\s*(curl|wget)\b',
    caseSensitive: false,
  );
  static final RegExp _rmDangerous = RegExp(
    // rm with a recursive+force flag (any order/case: -rf, -fr, -Rf, -rfv, or
    // --recursive/--force) targeting root, an absolute path (/etc, /*, …), home,
    // or the parent dir. Relative targets (./build) are intentionally NOT
    // flagged (worktree-local deletes are legitimate).
    r'\brm\b[^\n]*?'
    r'(-[a-z]*r[a-z]*f[a-z]*|-[a-z]*f[a-z]*r[a-z]*|--recursive|--force)'
    r'[^\n]*?\s(/|~|\.\.|\$\{?home\}?)',
    caseSensitive: false,
  );
  static final RegExp _decodePipeShell = RegExp(
    // Decode an obfuscated blob then execute it, via a shell or an interpreter,
    // or via an in-language decode+exec.
    r'(base64\s+(-d|--decode)|base32\s+-d|xxd\s+-r|openssl\s+enc\s+-d)'
    r'[^\n|]*\|\s*(sudo\b[^\n|]*\s+)?(ba|z|da)?sh\b'
    r'|(base64\s+(-d|--decode)|xxd\s+-r)[^\n|]*\|\s*(python3?|perl|ruby|node)\b'
    r'|(python3?|perl|ruby)\b[^\n]*(b64decode|base64|atob)[^\n]*'
    r'(exec|eval|system|popen)',
    caseSensitive: false,
  );
  static final RegExp _evalDynamic = RegExp(
    r'\beval\s+["'
    r"'`$(]",
  );
  static final RegExp _chmodExec = RegExp(r'chmod\s+(\+x|[0-7]*7[0-7]*)\b');
  static final RegExp _packageInstall = RegExp(
    r'\b(npm|pnpm|yarn)\s+(i|install|add)\b'
    r'|\bpip3?\s+install\b'
    r'|\b(brew|apt|apt-get|dnf|yum|pacman)\s+(install|-S)\b'
    r'|\b(gem|cargo|go)\s+install\b'
    r'|\buv\s+(pip\s+)?install\b',
  );
  static final RegExp _base64Blob = RegExp(r'[A-Za-z0-9+/]{120,}={0,2}');
  static final RegExp _readsSecret = RegExp(
    r'\$\{?[A-Z0-9_]*(SECRET|TOKEN|KEY|PASSWORD|PASSWD|CREDENTIAL)[A-Z0-9_]*\}?'
    r'|printenv|(^|\s)env(\s|$)|~/\.ssh|\.env\b|\.aws/credentials'
    r'|~/\.netrc|GITHUB_TOKEN|OPENAI_API_KEY|ANTHROPIC_API_KEY',
    caseSensitive: false,
  );
  static final RegExp _networkEgress = RegExp(
    r'\b(curl|wget|nc|netcat|ssh|scp|rsync|http\.client|requests\.(get|post)'
    r'|fetch\(|urllib|Invoke-WebRequest)\b'
    r'|https?://',
    caseSensitive: false,
  );
  // Invisible / non-rendering characters used to hide instructions from a human
  // reviewer. Covers: soft hyphen; Mongolian vowel sep; the zero-width family +
  // LTR/RTL marks; line/paragraph separators; word joiner; BOM; interlinear
  // annotation; variation selectors; AND the Unicode Tags block U+E0000-E007F \u2014
  // the state-of-the-art ASCII-smuggling channel that LLMs decode as text.
  static final RegExp _zeroWidth = RegExp(
    r'[\u00AD\u061C\u180E\u200B-\u200F\u2028\u2029\u202F\u205F\u2060\u2061-\u2064\uFEFF\uFFF9-\uFFFB\uFE00-\uFE0F]'
    r'|[\u{E0000}-\u{E007F}]',
    unicode: true,
  );
  static final RegExp _bidiOverride = RegExp(
    r'[\u202A-\u202E\u2066-\u2069]',
    unicode: true,
  );
  static final RegExp _promptInjection = RegExp(
    r'ignore\s+(all\s+)?(previous|prior|above|earlier)\s+'
    r'(instructions|prompts|context|messages)'
    r'|disregard\s+(the\s+)?(system|previous|above)\s+'
    r'|you\s+are\s+now\s+(a\s+)?(different|new)\s'
    r'|dear\s+(reviewer|scanner|assistant)',
    caseSensitive: false,
  );
  static final RegExp _htmlCommentInstruction = RegExp(
    r'<!--(?:(?!-->).)*?\b(ignore|disregard|system|instruction|prompt|execute'
    r'|run|password|secret)\b(?:(?!-->).)*?-->',
    caseSensitive: false,
    dotAll: true,
  );
}
