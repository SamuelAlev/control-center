import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

/// Coverage for the harness-domain value objects, events, enums, and small
/// classes that had no dedicated test.
void main() {
  group('StreamRule', () {
    test('matches when pattern is present', () {
      const rule = StreamRule(pattern: 'TODO', reminder: 'r');
      expect(rule.matches('has a TODO here'), isTrue);
      expect(rule.matches('clean'), isFalse);
    });

    test('works with a RegExp pattern', () {
      final rule = StreamRule(pattern: RegExp(r'\bbug\b'), reminder: 'r');
      expect(rule.matches('this is a bug'), isTrue);
      expect(rule.matches('feature'), isFalse);
    });
  });

  group('HarnessCommandResult', () {
    test('deny factory', () {
      final r = HarnessCommandResult.deny('nope');
      expect(r.denied, isTrue);
      expect(r.denyReason, 'nope');
      expect(r.exitCode, 126);
      expect(r.stderr, 'nope');
      expect(r.ok, isFalse);
    });

    test('ok predicate', () {
      const ok = HarnessCommandResult(exitCode: 0, stdout: 'o', stderr: '');
      expect(ok.ok, isTrue);
      const timedOut = HarnessCommandResult(
        exitCode: 124,
        stdout: '',
        stderr: '',
        timedOut: true,
      );
      expect(timedOut.ok, isFalse);
    });
  });

  group('Advisor', () {
    test('AdvisorSeverity rank', () {
      expect(AdvisorSeverity.nit.rank, lessThan(AdvisorSeverity.concern.rank));
      expect(
        AdvisorSeverity.concern.rank,
        lessThan(AdvisorSeverity.blocker.rank),
      );
    });

    test('AdvisorNote equality + toString', () {
      const a = AdvisorNote('n');
      const b = AdvisorNote('n', severity: AdvisorSeverity.nit);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a == const AdvisorNote('n', severity: AdvisorSeverity.blocker),
        isFalse,
      );
      expect(a.toString(), contains('nit'));
      expect(a.toString(), contains('n'));
    });
  });

  group('AgentLoop events', () {
    test('LoopDone carries a reason', () {
      const e = LoopDone(LoopDoneReason.maxTurns);
      expect(e.reason, LoopDoneReason.maxTurns);
    });

    test('LoopError carries message + code', () {
      const e = LoopError('boom', code: 'x');
      expect(e.message, 'boom');
      expect(e.code, 'x');
    });

    test('LoopCompaction fields', () {
      const e = LoopCompaction(
        summarized: true,
        messagesFolded: 3,
        tokensBefore: 100,
        tokensAfter: 40,
      );
      expect(e.summarized, isTrue);
      expect(e.messagesFolded, 3);
    });

    test('LoopAdvisorNote defaults severity to nit', () {
      const e = LoopAdvisorNote('n');
      expect(e.severity, AdvisorSeverity.nit);
    });

    test('HarnessBudget.isActive', () {
      expect(const HarnessBudget().isActive, isFalse);
      expect(const HarnessBudget(tokenBudget: 100).isActive, isTrue);
      expect(
        const HarnessBudget(timeBudget: Duration(seconds: 1)).isActive,
        isTrue,
      );
    });

    test('AgentLoopConfig defaults', () {
      const c = AgentLoopConfig();
      expect(c.maxTurns, isNull); // no turn ceiling by default
      expect(c.autoApprove, isTrue);
      expect(c.budget.hardStop, isTrue);
      expect(c.cacheEnabled, isTrue);
      expect(harnessControlToolNames, contains('checkpoint'));
    });
  });

  group('HarnessToolResult + HarnessToolContext', () {
    test('success + error factories', () {
      final s = HarnessToolResult.success('ok');
      expect(s.isError, isFalse);
      expect(s.content, 'ok');
      final e = HarnessToolResult.error('bad');
      expect(e.isError, isTrue);
      expect(e.content, 'bad');
    });

    test('HarnessToolContext.withCancel copies', () {
      const ctx = HarnessToolContext(workingDirectory: '/w', agentId: 'a');
      final withCancel = ctx.withCancel(null);
      expect(withCancel.workingDirectory, '/w');
      expect(withCancel.agentId, 'a');
    });

    test('HarnessTool actionClasses default by tier', () {
      expect(FakeTool(ToolApprovalTier.read).actionClasses, isEmpty);
      expect(FakeTool(ToolApprovalTier.write).actionClasses, {
        ActionClass.fileWriteOutsideWorktree,
      });
      expect(FakeTool(ToolApprovalTier.exec).actionClasses, {
        ActionClass.processSpawn,
      });
    });

    test('HarnessTool.toSchema exposes name/description/schema', () {
      final schema = FakeTool(ToolApprovalTier.read).toSchema();
      expect(schema.name, 'fake');
      expect(schema.inputSchema, {'k': 'v'});
    });
  });

  group('effort_mapping', () {
    test('anthropic / openai / google mappings', () {
      for (final e in ReasoningEffort.values) {
        expect(anthropicEffort(e), isNotNull);
        expect(openAiEffort(e), isNotNull);
        expect(googleThinkingLevel(e), isNotNull);
      }
      expect(anthropicEffort(ReasoningEffort.minimal), 'low');
      expect(anthropicEffort(ReasoningEffort.xhigh), 'xhigh');
      expect(openAiEffort(ReasoningEffort.xhigh), 'high');
      expect(openAiEffort(ReasoningEffort.minimal), 'minimal');
      expect(googleThinkingLevel(ReasoningEffort.xhigh), 'high');
    });
  });

  group('harness_providers', () {
    test('metas cover the advertised ids', () {
      for (final id in harnessSupportedProviderIds) {
        expect(harnessProviderMetas, contains(id));
      }
      expect(harnessProviderMetas.length, harnessSupportedProviderIds.length);
    });

    test('supportsOAuth / supportsApiKey flags', () {
      expect(harnessProviderMetas['anthropic']!.supportsOAuth, isTrue);
      expect(harnessProviderMetas['anthropic']!.supportsApiKey, isTrue);
      expect(harnessProviderMetas['openrouter']!.supportsOAuth, isFalse);
      expect(harnessProviderMetas['openrouter']!.supportsApiKey, isTrue);
      // Local/self-hosted endpoints are custom providers, not built-ins.
      expect(harnessProviderMetas.containsKey('ollama'), isFalse);
      expect(harnessProviderMetas.containsKey('lmstudio'), isFalse);
    });
  });

  group('ProviderCredential', () {
    final full = ProviderCredential(
      providerId: 'anthropic',
      method: HarnessAuthMethod.apiKey,
      apiKey: 'k',
      accessToken: 'at',
      refreshToken: 'rt',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(1000),
      accountLabel: 'Personal',
      baseUrl: 'https://x',
      email: 'e@x',
      accountId: 'acc',
      disabledCause: null,
      isActive: true,
    );

    test('fromJson + toJson round-trip + defaults', () {
      final rebuilt = ProviderCredential.fromJson(full.toJson());
      expect(rebuilt.providerId, 'anthropic');
      expect(rebuilt.method, HarnessAuthMethod.apiKey);
      expect(rebuilt.apiKey, 'k');
      expect(rebuilt.expiresAt, DateTime.fromMillisecondsSinceEpoch(1000));
      expect(rebuilt.isActive, isTrue);

      final bare = ProviderCredential.fromJson({'providerId': 'p'});
      expect(bare.method, HarnessAuthMethod.apiKey);
      expect(bare.isActive, isTrue);
      expect(bare.expiresAt, isNull);
    });

    test('identityKey precedence email->accountId->accountLabel', () {
      expect(full.identityKey, 'e@x');
      expect(
        const ProviderCredential(
          providerId: 'p',
          method: HarnessAuthMethod.apiKey,
          accountId: 'a',
        ).identityKey,
        'a',
      );
      expect(
        const ProviderCredential(
          providerId: 'p',
          method: HarnessAuthMethod.apiKey,
          accountLabel: 'l',
        ).identityKey,
        'l',
      );
      expect(
        const ProviderCredential(
          providerId: 'p',
          method: HarnessAuthMethod.none,
        ).identityKey,
        isNull,
      );
    });

    test('secret picks per method', () {
      expect(full.secret, 'k');
      expect(
        const ProviderCredential(
          providerId: 'p',
          method: HarnessAuthMethod.oauth,
          accessToken: 'at',
        ).secret,
        'at',
      );
      expect(
        const ProviderCredential(
          providerId: 'p',
          method: HarnessAuthMethod.none,
        ).secret,
        isNull,
      );
    });

    test('copyWith preserves method + providerId', () {
      final next = full.copyWith(isActive: false, email: 'y@x');
      expect(next.isActive, isFalse);
      expect(next.email, 'y@x');
      expect(next.method, HarnessAuthMethod.apiKey);
      expect(next.providerId, 'anthropic');
    });
  });

  group('HarnessProviderEnabled', () {
    test('wire + fromWire round-trip; unknown -> disabled', () {
      for (final v in HarnessProviderEnabled.values) {
        expect(HarnessProviderEnabled.fromWire(v.wire), v);
      }
      expect(
        HarnessProviderEnabled.fromWire(null),
        HarnessProviderEnabled.disabled,
      );
      expect(
        HarnessProviderEnabled.fromWire('bogus'),
        HarnessProviderEnabled.disabled,
      );
    });
  });

  group('SubagentProfile', () {
    test('SubagentType.fromId defaults to general', () {
      expect(SubagentType.fromId('explore'), SubagentType.explore);
      expect(SubagentType.fromId('plan'), SubagentType.plan);
      expect(SubagentType.fromId(null), SubagentType.general);
      expect(SubagentType.fromId('bogus'), SubagentType.general);
    });

    test('every type has a profile', () {
      for (final t in SubagentType.values) {
        final p = subagentProfileFor(t);
        expect(p.type, t);
        expect(p.allowedTiers, isNotEmpty);
        expect(p.systemPromptAddendum, isNotEmpty);
      }
    });

    test('filterTools keeps only allowed tiers', () {
      final tools = [
        FakeTool(ToolApprovalTier.read),
        FakeTool(ToolApprovalTier.write),
        FakeTool(ToolApprovalTier.exec),
      ];
      final explore = subagentProfileFor(SubagentType.explore);
      expect(explore.filterTools(tools).length, 1);
      expect(
        explore.filterTools(tools).first.approvalTier,
        ToolApprovalTier.read,
      );
    });

    test(
      'buildSystemPrompt appends addendum; empty base starts at the addendum',
      () {
        final p = subagentProfileFor(SubagentType.general);
        expect(p.buildSystemPrompt(''), startsWith(p.systemPromptAddendum));
        expect(p.buildSystemPrompt('base'), contains('base'));
        expect(p.buildSystemPrompt('base'), contains(p.systemPromptAddendum));
      },
    );
  });

  group('Llm provider events', () {
    test('LlmUsage operator + sums', () {
      const a = LlmUsage(
        inputTokens: 1,
        outputTokens: 2,
        cacheReadTokens: 3,
        cacheWriteTokens: 4,
        thoughtTokens: 5,
      );
      const b = LlmUsage(inputTokens: 10, outputTokens: 20);
      final s = a + b;
      expect(s.inputTokens, 11);
      expect(s.outputTokens, 22);
      expect(s.cacheReadTokens, 3);
      expect(s.cacheWriteTokens, 4);
      expect(s.thoughtTokens, 5);
    });

    test('LlmStopReason.fromWire maps both spellings', () {
      expect(LlmStopReason.fromWire('end_turn'), LlmStopReason.endTurn);
      expect(LlmStopReason.fromWire('stop'), LlmStopReason.endTurn);
      expect(LlmStopReason.fromWire('tool_use'), LlmStopReason.toolUse);
      expect(LlmStopReason.fromWire('tool_calls'), LlmStopReason.toolUse);
      expect(LlmStopReason.fromWire('max_tokens'), LlmStopReason.maxTokens);
      expect(LlmStopReason.fromWire('length'), LlmStopReason.maxTokens);
      expect(
        LlmStopReason.fromWire('stop_sequence'),
        LlmStopReason.stopSequence,
      );
      expect(LlmStopReason.fromWire(null), LlmStopReason.unknown);
      expect(LlmStopReason.fromWire('bogus'), LlmStopReason.unknown);
    });

    test('LlmDone + LlmError + LlmCompleteConfig defaults', () {
      const done = LlmDone();
      expect(done.stopReason, LlmStopReason.unknown);
      expect(done.usage, isNull);
      const err = LlmError('m', code: 'c', retryable: true, retryAfterMs: 5);
      expect(err.retryable, isTrue);
      expect(err.retryAfterMs, 5);
      const cfg = LlmCompleteConfig();
      expect(cfg.maxTokens, 8192);
      expect(cfg.cacheEnabled, isTrue);
      final next = cfg.copyWith(model: 'm');
      expect(next.model, 'm');
      expect(next.maxTokens, 8192);
    });
  });
}

/// Minimal [HarnessTool] stub for exercising default actionClasses + toSchema.
class FakeTool extends HarnessTool {
  FakeTool(this.approvalTier);

  @override
  final ToolApprovalTier approvalTier;

  @override
  String get name => 'fake';

  @override
  String get description => 'd';

  @override
  Map<String, dynamic> get inputSchema => const {'k': 'v'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('');
}
