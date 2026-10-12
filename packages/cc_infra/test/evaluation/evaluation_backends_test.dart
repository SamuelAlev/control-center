import 'dart:io';

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/evaluation/backends/builtin_evaluation_backend.dart';
import 'package:cc_infra/src/evaluation/backends/claude_cli_evaluation_backend.dart';
import 'package:test/test.dart';

/// An arm must EXECUTE the policy it claims or be refused before any spend.
/// These tests pin the preflight that decides which is which, plus the argv that
/// carries effort/resume to the Claude CLI (report 4A/4B).
void main() {
  final builtin = BuiltinEvaluationBackend(contextWindowTokens: 8192);

  EvaluationEffectiveConfig effective({
    MemoryPolicyMode memory = MemoryPolicyMode.textCurrent,
    SessionContinuityMode session = SessionContinuityMode.fresh,
    McpDiscoveryCacheMode mcp = McpDiscoveryCacheMode.disabled,
    ToolOverlapMode overlap = ToolOverlapMode.serial,
    String? effort,
    SkillExposure? skill,
    String model = 'claude-opus-4-8',
  }) => EvaluationEffectiveConfig(
    adapter: 'builtin',
    providerId: 'anthropic',
    modelId: model,
    effortLevel: effort,
    memoryPolicy: memory,
    sessionContinuity: session,
    mcpDiscoveryCache: mcp,
    toolOverlap: overlap,
    skillExposure: skill,
  );

  group('builtin preflight', () {
    test(
      'the shipped text policy and the masking policies are implementable',
      () {
        expect(builtin.unsupportedReason(effective()), isNull);
        expect(
          builtin.unsupportedReason(
            effective(memory: MemoryPolicyMode.masking),
          ),
          isNull,
        );
        expect(
          builtin.unsupportedReason(
            effective(memory: MemoryPolicyMode.hybridMaskingSummary),
          ),
          isNull,
        );
      },
    );

    test('snapshot compaction is refused without a vision-capable reader', () {
      final reason = builtin.unsupportedReason(
        effective(memory: MemoryPolicyMode.snapshotImages),
      );
      expect(reason, isNotNull);
      expect(reason, contains('vision-capable'));

      final capable = BuiltinEvaluationBackend(
        contextWindowTokens: 8192,
        visionLookup: (qualified) => qualified.contains('opus'),
      );
      expect(
        capable.unsupportedReason(
          effective(memory: MemoryPolicyMode.snapshotImages),
        ),
        isNull,
      );
      // A reader that cannot see images is refused, not rendered pages.
      expect(
        capable.unsupportedReason(
          effective(
            memory: MemoryPolicyMode.snapshotImages,
            model: 'text-only-model',
          ),
        ),
        isNotNull,
      );
    });

    test('Claude-only features are refused on the builtin harness', () {
      expect(
        builtin.unsupportedReason(
          effective(session: SessionContinuityMode.nativeResume),
        ),
        contains('Claude CLI capability'),
      );
      expect(
        builtin.unsupportedReason(
          effective(mcp: McpDiscoveryCacheMode.enabled),
        ),
        contains('MCP discovery cache'),
      );
    });

    test('tool overlap is implementable because read_output opts in', () {
      expect(
        builtin.unsupportedReason(
          effective(overlap: ToolOverlapMode.overlapReadOnly),
        ),
        isNull,
      );
    });
    test('generic builtin rejects skill exposure instead of ignoring it', () {
      for (final exposure in SkillExposure.values) {
        expect(
          builtin.unsupportedReason(effective(skill: exposure)),
          contains('controlled attempt'),
        );
      }
    });
  });

  group('claude preflight', () {
    final claude = ClaudeCliEvaluationBackend();

    test('context policies are refused: Claude owns its own context', () {
      expect(
        claude.unsupportedReason(effective(memory: MemoryPolicyMode.masking)),
        contains('report 4D'),
      );
    });

    test('harness tool scheduling is refused for the CLI', () {
      expect(
        claude.unsupportedReason(
          effective(overlap: ToolOverlapMode.overlapReadOnly),
        ),
        contains('no-op'),
      );
    });

    test(
      'resume is supported, but cache experiments need an MCP configuration',
      () {
        expect(
          claude.unsupportedReason(
            effective(session: SessionContinuityMode.nativeResume),
          ),
          isNull,
        );
        expect(
          claude.unsupportedReason(
            effective(mcp: McpDiscoveryCacheMode.enabled),
          ),
          isNotNull,
        );
      },
    );

    test(
      'empty or unreadable catalogs cannot act as cache interventions',
      () async {
        final dir = await Directory.systemTemp.createTemp('cc-mcp-preflight-');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/mcp.json');
        final backend = ClaudeCliEvaluationBackend(mcpConfigPath: file.path);
        final config = effective(mcp: McpDiscoveryCacheMode.enabled);
        expect(backend.unsupportedReason(config), isNotNull);
        await file.writeAsString('{"mcpServers":{}}');
        expect(backend.unsupportedReason(config), isNotNull);
        await file.writeAsString(
          '{"mcpServers":{"probe":{"command":"probe"}}}',
        );
        expect(backend.unsupportedReason(config), isNull);
      },
    );

    test('an unadvertised effort level is refused, not silently dropped', () {
      expect(claude.unsupportedReason(effective(effort: 'medium')), isNull);
      final narrow = ClaudeCliEvaluationBackend(
        capabilities: ClaudeCliCapabilities.minimal,
      );
      expect(
        narrow.unsupportedReason(effective(effort: 'medium')),
        contains('no --effort value'),
      );
    });
  });
}
