import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_scan_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/cc_infra.dart';

/// MCP tool that creates a new skill file in a workspace.
class CreateSkillTool extends McpTool {
  /// Creates a [CreateSkillTool].
  ///
  /// [scanner] is the lighter create-time gate (PRD 23 §2): Layers 1–2 only, no
  /// Layer-3 LLM review. It is OPTIONAL only so pre-scanner callers/tests still
  /// compile — when null the gate is skipped. When wired it is fail-closed: a
  /// quarantine verdict (or a scanner error) blocks the write.
  CreateSkillTool({
    required WorkspaceFilesystemPort filesystem,
    SkillScanPort? scanner,
  }) : _filesystem = filesystem,
       _scanner = scanner;

  final WorkspaceFilesystemPort _filesystem;
  final SkillScanPort? _scanner;

  @override
  String get name => 'create_skill';
  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.fileWriteOutsideWorktree,
  };

  @override
  String get description =>
      'Creates a new skill in a workspace with the given markdown content.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID to create the skill in.',
      },
      'slug': {
        'type': 'string',
        'description':
            'Unique skill slug (e.g. "code-review", "testing"). '
            'Will be lowercased and hyphenated.',
      },
      'content': {
        'type': 'string',
        'description':
            'Full markdown content for the skill\'s SKILL.md file, '
            'including YAML frontmatter with name and description.',
      },
      'allow_quarantine_override': {
        'type': 'boolean',
        'description':
            'When true, create even if the scan gate returns a quarantine '
            'verdict (an explicit, recorded operator override). Defaults to '
            'false — quarantined content is blocked.',
      },
    },
    'required': ['workspace_id', 'slug', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawSlug = arguments['slug'];
    if (rawSlug is! String) {
      return CallResult.error(
        'Missing or invalid argument: slug (expected string)',
      );
    }
    final rawContent = arguments['content'];
    if (rawContent is! String) {
      return CallResult.error(
        'Missing or invalid argument: content (expected string)',
      );
    }
    final workspaceId = rawWorkspaceId;
    final slug = rawSlug;
    final content = rawContent;
    final allowQuarantineOverride =
        arguments['allow_quarantine_override'] == true;

    // Lighter create-time gate (PRD 23 §2): Layers 1–2 only (no LLM review),
    // over the EXACT bytes about to be written. Fail-closed — a scanner error
    // or a quarantine verdict (without an override) blocks the write.
    final scanner = _scanner;
    SkillScanResult? scanResult;
    if (scanner != null) {
      try {
        scanResult = await scanner.scan(
          SkillBundle.single(slug, content),
          workspaceId: workspaceId,
          trustTier: SkillTrustTier.workspace,
          runLlmReview: false,
        );
      } on Object catch (e) {
        return CallResult.error('create_skill blocked: scan failed: $e');
      }
      if (scanResult.verdict == SkillScanVerdict.quarantine &&
          !allowQuarantineOverride) {
        final findings = scanResult.findings
            .map(
              (f) =>
                  '${f.ruleId} (${f.verdict.wire}) in ${f.file}'
                  '${f.line > 0 ? ':${f.line}' : ''}',
            )
            .join('; ');
        return CallResult.error(
          'create_skill blocked: skill "$slug" was quarantined by the scan '
          'gate: ${findings.isEmpty ? 'no findings recorded' : findings}.',
        );
      }
    }

    await _filesystem.ensureWorkspaceDirs(workspaceId);
    await _filesystem.writeSkillFile(workspaceId, slug, content);

    return CallResult.success(
      jsonEncode({
        'slug': slug,
        'status': 'created',
        if (scanResult != null) 'scan_verdict': scanResult.verdict.wire,
      }),
    );
  }
}
