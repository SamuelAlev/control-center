import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:crypto/crypto.dart';

/// Skill files the Helix agents already name.
///
/// The product seeder writes the shared ones (`testing`, `implementation`,
/// `refactoring`) for the CEO's specialists. These fill the gaps Ravi, Juno
/// and Wren are assigned, and stand in when that seed did not run. A file
/// that already exists is left as the product wrote it.
const Map<String, String> kDemoSkillFiles = {
  'review': '''---
name: review
description: Review a Helix change for correctness, risk and a concrete alternative
---

# Review

Read the diff before you comment. One blocking note with a specific alternative beats a list of nits. Say what should wait for Thursday's release cut, and what can ship with it.
''',
  'python': '''---
name: python
description: Python for Helix eval harnesses, retrieval and the feature store
---

# Python

Helix services are Python. Match the surrounding style, keep type hints on public functions, and prefer the existing helpers in evalkit over a new abstraction. Call out a dependency add before you take it.
''',
  'testing': '''---
name: testing
description: Tests that fail for a real Helix regression, not for a renamed helper
---

# Testing

Cover the behavior a caller can observe. A test that only asserts a private call sequence will break the next refactor and catch nothing. Name the input, the expected value and which evalkit case it belongs to.
''',
  'triage': '''---
name: triage
description: Sort an incoming Helix report into a reproducible bug, a question or noise
---

# Triage

Decide what the report actually is. A bug needs a failing case. A question needs the doc that already answers it. Noise gets closed with one sentence on why. Do not start a fix from a report you have not reproduced.
''',
  'support': '''---
name: support
description: Answer a Helix user with the smallest next step that unblocks them
---

# Support

Reply with the next step, not a tour of the system. Link the run, the ticket or the doc that settles it. If you do not know, say so and name who does. Juno owns reproduction, Ravi owns review, Wren owns the change.
''',
  'reproduction': '''---
name: reproduction
description: Turn a Helix report into a failing case someone else can run
---

# Reproduction

A report is not a bug until it fails on a command someone else can run. Capture the input, the expected value and the actual one. Prefer a test in evalkit over a prose transcript. If you cannot reproduce it, say what you tried.
''',
  'implementation': '''---
name: implementation
description: The smallest Helix change that does what the ticket asked
---

# Implementation

Read the code that is already there, then change only what the ticket names. Keep the diff inside evalkit's existing helpers. If the ticket is ambiguous, stop and ask instead of inventing a second behavior.
''',
  'refactoring': '''---
name: refactoring
description: Restructure Helix code without changing what callers observe
---

# Refactoring

Move in small steps and leave the tests green after each one. A rename that forces every caller to update is a behavior change, not a cleanup. Do not mix a refactor into a feature diff.
''',
};

/// Writes missing [kDemoSkillFiles] under `<dataDir>/<workspaceId>/skills`
/// and pins every on-disk skill so the settings list reads them as authored.
///
/// The pin is a content hash of the bytes already on disk. It does not scan
/// and it does not rewrite a skill the product seeder already wrote.
Future<void> seedDemoSkills({
  required String dataDir,
  required String workspaceId,
}) async {
  final root = Directory('$dataDir/$workspaceId/skills');
  await root.create(recursive: true);
  for (final entry in kDemoSkillFiles.entries) {
    final dir = Directory('${root.path}/${entry.key}');
    final file = File('${dir.path}/SKILL.md');
    if (file.existsSync()) {
      continue;
    }
    await dir.create(recursive: true);
    await file.writeAsString(entry.value);
  }
  await _pinSkills(root);
}

/// Rolled-up hash of a single `SKILL.md`, matching [SkillBundleService].
String demoSkillFileHash(List<int> bytes) {
  final fileHash = sha256.convert(bytes).toString();
  return sha256.convert(utf8.encode('SKILL.md:$fileHash')).toString();
}

Future<void> _pinSkills(Directory root) async {
  final skills = <String, SkillLockEntry>{};
  final entries = root.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final dir in entries) {
    final file = File('${dir.path}/SKILL.md');
    if (!file.existsSync()) {
      continue;
    }
    final slug = dir.uri.pathSegments.where((s) => s.isNotEmpty).last;
    final bytes = await file.readAsBytes();
    skills[slug] = SkillLockEntry(
      slug: slug,
      source: 'workspace',
      sourceType: SkillOrigin.manual,
      skillPath: 'skills/$slug/SKILL.md',
      computedHash: demoSkillFileHash(bytes),
      trustTier: SkillTrustTier.workspace,
    );
  }
  const encoder = JsonEncoder.withIndent('  ');
  final lock = SkillLock(skills: skills);
  await File(
    '${root.path}/skills-lock.json',
  ).writeAsString('${encoder.convert(lock.toJson())}\n');
}
