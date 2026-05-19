// Static-only namespace class (mirrors SkillStaticRules / AgentProcessEventCodec).
// ignore_for_file: avoid_classes_with_only_static_members
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// Layer 2 (PRD 23 §3): extracts the capability manifest — what a skill *asks
/// an agent to do* — from the bundle bytes. Pure, deterministic, execution-free
/// (like Layer 1). The manifest is the union across every file so a payload
/// cannot hide in a resource file.
abstract final class SkillCapabilityExtractor {
  /// Extracts the union [SkillCapabilityManifest] over [bundle].
  static SkillCapabilityManifest extract(SkillBundle bundle) {
    var manifest = const SkillCapabilityManifest();
    bundle.files.forEach((path, content) {
      manifest = manifest.merge(_extractFile(content));
    });
    return manifest;
  }

  static SkillCapabilityManifest _extractFile(String content) {
    final lower = content.toLowerCase();
    return SkillCapabilityManifest(
      needsBash: _bash.hasMatch(content) || _bash.hasMatch(lower),
      writesFiles: _writes.hasMatch(content),
      deletesFiles: _deletes.hasMatch(content),
      networkEgress: _network.hasMatch(content),
      readsSecrets: _secrets.hasMatch(content),
      installsPackages: _install.hasMatch(lower),
    );
  }

  static final RegExp _bash = RegExp(
    r'```(bash|sh|shell|zsh|console)\b'
    r'|\brun\s+(the\s+)?(command|shell|script)\b'
    r'|\$\s*[a-z]',
    caseSensitive: false,
  );
  static final RegExp _writes = RegExp(
    r'(^|\s)(cat|tee|echo)\b[^\n]*>{1,2}'
    r'|>{1,2}\s*[\w./~-]+'
    r'|\b(write|create|save)\s+(a\s+|the\s+)?file\b'
    r'|\bWrite\b|\bEdit\b',
    caseSensitive: false,
  );
  static final RegExp _deletes = RegExp(
    r'\brm\s|\bunlink\b|\bdel\s|\bdelete\s+(the\s+)?file',
    caseSensitive: false,
  );
  static final RegExp _network = RegExp(
    r'\b(curl|wget|nc|netcat|ssh|scp|rsync|fetch|urllib|requests\.)\b'
    r'|https?://',
    caseSensitive: false,
  );
  static final RegExp _secrets = RegExp(
    r'\$\{?[A-Z0-9_]*(SECRET|TOKEN|KEY|PASSWORD|CREDENTIAL)[A-Z0-9_]*\}?'
    r'|printenv|~/\.ssh|\.env\b|\.aws/credentials|GITHUB_TOKEN'
    r'|OPENAI_API_KEY|ANTHROPIC_API_KEY',
    caseSensitive: false,
  );
  static final RegExp _install = RegExp(
    r'\b(npm|pnpm|yarn)\s+(i|install|add)\b'
    r'|\bpip3?\s+install\b'
    r'|\b(brew|apt|apt-get|dnf|yum|pacman)\s+(install|-S)\b'
    r'|\b(gem|cargo|go)\s+install\b',
  );
}
