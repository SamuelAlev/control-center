import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/evals/domain/entities/skill_evaluation_campaign.dart';
import 'package:test/test.dart';

final _created = DateTime.utc(2026, 10, 11, 12, 34, 56, 789);

SkillEvaluationCampaign _campaign({
  SkillEvaluationComparison comparison = SkillEvaluationComparison.absent,
  String? baselineHash,
}) => SkillEvaluationCampaign(
  id: 'campaign-1',
  workspaceId: 'ws-1',
  skillKey: 'repo:repo-1:.claude/skills/review',
  skillSlug: 'review',
  skillHash: 'sha256-candidate',
  baselineHash: baselineHash,
  repoId: 'repo-1',
  corpusId: 'utility',
  providerId: 'provider',
  modelId: 'model',
  configurationHash: 'sha256-configuration',
  comparison: comparison,
  status: SkillEvaluationCampaignStatus.queued,
  repetitions: 3,
  budgetMicros: 1000000,
  plannedAttempts: 48,
  completedAttempts: 0,
  createdAt: _created,
  actor: const UserPrincipal('user-1'),
  triggeredBy: 'manual',
  configuration: {'tools': ['read', {'policy': 'deny'}]},
);

void main() {
  test('strict statuses, comparisons and actors reject unknown wire values', () {
    final json = _campaign().toJson();
    expect(() => SkillEvaluationCampaign.fromJson({...json, 'status': 'success'}),
        throwsFormatException);
    expect(() => SkillEvaluationCampaign.fromJson({...json, 'comparison': 'other'}),
        throwsFormatException);
    expect(() => SkillEvaluationCampaign.fromJson({...json, 'actor': 'device:1'}),
        throwsFormatException);
    expect(() => _campaign(comparison: SkillEvaluationComparison.previous),
        throwsArgumentError);
  });

  test('campaign lifecycle round trips full JSON with unknown costs and partial report', () {
    final queued = _campaign();
    expect(queued.isTerminal, isFalse);
    final running = queued.copyWith(
      status: SkillEvaluationCampaignStatus.running,
      startedAt: _created.add(const Duration(seconds: 1)),
      completedAttempts: 1,
      report: {'tasks': [{'pass': true}], 'estimatedCost': null},
    );
    final interrupted = running.copyWith(
      status: SkillEvaluationCampaignStatus.interrupted,
      staleReason: 'revision_changed',
      finishedAt: _created.add(const Duration(seconds: 5)),
    );
    expect(interrupted.isTerminal, isTrue);
    expect(interrupted.spentMicros, isNull);
    final restored = SkillEvaluationCampaign.fromJson(
      jsonDecode(jsonEncode(interrupted.toJson())) as Map<String, dynamic>,
    );
    expect(restored, interrupted);
    expect(restored.hashCode, interrupted.hashCode);
    expect(restored.report, {'tasks': [{'pass': true}], 'estimatedCost': null});
    expect(restored.copyWith(status: SkillEvaluationCampaignStatus.completed).staleReason,
        'revision_changed');
    expect(restored.copyWith(clearStaleReason: true).staleReason, isNull);
    expect(restored.copyWith(clearReport: true).report, isNull);
  });

  test('nested caller collections and JSON projections cannot mutate a campaign', () {
    final nested = <String, dynamic>{'events': <dynamic>[<String, dynamic>{'load': true}]};
    final campaign = SkillEvaluationCampaign.fromJson({
      ..._campaign().toJson(), 'configuration': nested,
    });
    (nested['events'] as List).clear();
    expect((campaign.configuration['events'] as List), hasLength(1));
    expect(() => (campaign.configuration['events'] as List).clear(),
        throwsUnsupportedError);
    final projected = campaign.toJson();
    (projected['configuration'] as Map)['events'] = [];
    expect((campaign.configuration['events'] as List), hasLength(1));
    expect(() => SkillEvaluationCampaign.fromJson({
      ...campaign.toJson(), 'configuration': {'bad': double.nan},
    }), throwsFormatException);
  });

  test('attempt and policy round trips with stable attribution', () {
    final attempt = SkillEvaluationAttemptRecord(
      id: 'attempt-1', workspaceId: 'ws-1', campaignId: 'campaign-1',
      taskId: 'task-1', armId: 'treatment', repetition: 2, ordinal: 8,
      evidence: {'events': [{'tool': 'read', 'result': null}]},
      createdAt: _created,
    );
    final policy = SkillEvaluationPolicy(
      workspaceId: 'ws-1', skillKey: 'workspace:review', enabled: true,
      actor: const AgentPrincipal('agent-1'),
      configuration: {'corpusId': 'utility', 'budgetMicros': 900000},
      updatedAt: _created,
    );
    expect(SkillEvaluationAttemptRecord.fromJson(attempt.toJson()), attempt);
    expect(SkillEvaluationPolicy.fromJson(policy.toJson()), policy);
    expect(policy.toJson()['actor'], 'agent:agent-1');
    expect(policy.hashCode, SkillEvaluationPolicy.fromJson(policy.toJson()).hashCode);
    expect(() => SkillEvaluationAttemptRecord.fromJson({
      ...attempt.toJson(), 'ordinal': -1,
    }), throwsArgumentError);
  });
}
