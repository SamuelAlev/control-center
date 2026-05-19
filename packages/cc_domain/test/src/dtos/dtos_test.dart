import 'package:cc_domain/core/domain/value_objects/agent_role.dart'
    show AgentRole;
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart'
    show ActionPolicyRule;
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart'
    show ActionDecision, ActionScopeType;
import 'package:cc_domain/features/weather/domain/entities/weather_snapshot.dart'
    show WeatherCondition, WeatherSnapshot;
import 'package:cc_domain/src/dtos/dtos.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:test/test.dart';

/// Round-trip coverage for every wire DTO in the RPC surface. Each DTO is
/// constructed via `fromJson` against a fully-populated payload, then re-encoded
/// via `toJson`; the canonical field round-trip must be lossless. The default /
/// fallback paths (`??` coercions for missing scalars, enum `.fromName`
/// fallbacks) are exercised by a parallel empty-payload parse.
void main() {
  group('McpToolResult', () {
    test('fromEnvelope decodes a JSON text payload', () {
      final r = McpToolResult.fromEnvelope({
        'content': [
          {'type': 'text', 'text': '{"k": 1}'},
        ],
        'isError': false,
      });
      expect(r.isError, isFalse);
      expect(r.text, '{"k": 1}');
      expect(r.json, {'k': 1});
      expect(r.asMap, {'k': 1});
      expect(r.ensureOk(), same(r));
    });

    test('fromEnvelope handles non-JSON text and missing content', () {
      final r = McpToolResult.fromEnvelope({
        'content': [
          {'type': 'text', 'text': 'not json'},
        ],
      });
      expect(r.text, 'not json');
      expect(r.json, isNull);
      expect(r.asMap, isNull);
      expect(r.isError, isFalse);
    });

    test('fromEnvelope with empty content list', () {
      final r = McpToolResult.fromEnvelope({'content': <Object>[]});
      expect(r.text, '');
      expect(r.json, isNull);
    });

    test('fromEnvelope with content first not a map', () {
      final r = McpToolResult.fromEnvelope({
        'content': ['plain'],
      });
      expect(r.text, '');
    });

    test('ensureOk throws RemoteToolException on error', () {
      final r = McpToolResult.fromEnvelope({
        'content': [
          {'type': 'text', 'text': 'boom'},
        ],
        'isError': true,
      });
      expect(r.ensureOk, throwsA(isA<RemoteToolException>()));
    });

    test('RemoteToolException toString', () {
      expect(RemoteToolException('x').toString(), 'RemoteToolException: x');
    });
  });

  group('WorkspaceDto', () {
    test('round-trips with all fields', () {
      final json = {
        'id': 'w1',
        'name': 'WS',
        'logo_path': '/l',
        'owner_user_id': 'u1',
        'secret_exclude_globs': ['a', 'b'],
        'review_concurrency': 4,
        'deleted_at': '2025-01-02T00:00:00',
        'created_at': '2025-01-01T00:00:00',
        'updated_at': '2025-01-03T00:00:00',
      };
      final dto = WorkspaceDto.fromJson(json);
      expect(dto.id, 'w1');
      expect(dto.name, 'WS');
      expect(dto.logoPath, '/l');
      expect(dto.ownerUserId, 'u1');
      expect(dto.secretExcludeGlobs, ['a', 'b']);
      expect(dto.reviewConcurrency, 4);
      expect(dto.deletedAt, DateTime(2025, 1, 2));
      expect(dto.createdAt, DateTime(2025, 1, 1));
      expect(dto.updatedAt, DateTime(2025, 1, 3));
      final out = dto.toJson();
      expect(out['id'], 'w1');
      expect(out['secret_exclude_globs'], ['a', 'b']);
      expect(out['review_concurrency'], 4);
      expect(out['deleted_at'], '2025-01-02T00:00:00.000');
    });

    test('falls back to defaults on empty payload', () {
      final dto = WorkspaceDto.fromJson({'id': 'w', 'name': 'n'});
      expect(dto.secretExcludeGlobs, isEmpty);
      expect(dto.reviewConcurrency, isNull);
      expect(dto.deletedAt, isNull);
      final out = dto.toJson();
      expect(out.containsKey('logo_path'), isFalse);
      expect(out.containsKey('review_concurrency'), isFalse);
      expect(out['secret_exclude_globs'], isEmpty);
    });

    test('treats non-string timestamps as null', () {
      final dto = WorkspaceDto.fromJson({
        'id': 'w',
        'name': 'n',
        'created_at': 123,
      });
      expect(dto.createdAt, isNull);
    });
  });

  group('TicketDto', () {
    final full = {
      'ticket_id': 't1',
      'key': 'CC-1',
      'title': 'T',
      'status': 'open',
      'priority': 'high',
      'provider': 'github',
      'assignee': 'a',
      'assignee_type': 'user',
      'created_by_type': 'user',
      'created_by_id': 'u',
      'url': '/u',
      'workspace_id': 'w',
      'description': 'd',
      'raw_status': 'OPEN',
      'labels': ['x'],
      'parent_ticket_id': 'p',
      'project_id': 'pr',
      'assigned_team_id': 'tm',
      'delegated_by_agent_id': 'ag',
      'space_id': 'c',
      'error_message': 'e',
      'linked_pr_ids': ['1'],
      'metadata': {'m': 1},
      'version': 7,
      'origin_kind': 'manual',
      'created_at': 'ca',
      'started_at': 'sa',
      'blocked_at': 'ba',
      'cancelled_at': 'xa',
      'completed_at': 'oa',
      'finished_at': 'fa',
      'updated_at': 'ua',
    };

    test('round-trips all fields', () {
      final dto = TicketDto.fromJson(full);
      expect(dto.id, 't1');
      expect(dto.metadata, {'m': 1});
      expect(dto.version, 7);
      expect(dto.linkedPrIds, ['1']);
      final out = dto.toJson();
      expect(out['ticket_id'], 't1');
      expect(out['metadata'], {'m': 1});
      expect(out['version'], 7);
    });

    test('falls back to defaults on minimal payload', () {
      final dto = TicketDto.fromJson({'ticket_id': 't'});
      expect(dto.key, '');
      expect(dto.labels, isEmpty);
      expect(dto.linkedPrIds, isEmpty);
      expect(dto.metadata, isEmpty);
      expect(dto.version, 0);
    });
  });

  group('AgentDto', () {
    test('round-trips all fields', () {
      final dto = AgentDto.fromJson({
        'id': 'a1',
        'name': 'A',
        'title': 'T',
        'agent_md_path': '/p',
        'workspace_id': 'w',
        'skills': ['s1'],
        'reports_to': 'r',
        'persona': 'p',
        'system_prompt': 'sp',
        'adapter_id': 'ad',
        'model_id': 'm',
        'strict_mode': true,
        'effort': 'high',
        'context_size': 100,
        'role': 'leader',
        'capabilities': {'k': 1},
        'monthly_budget_cents': 5,
        'silence_timeout_minutes': 10,
        'max_concurrent_tasks': 3,
        'visibility': 'private',
        'lifecycle_status': 'dormant',
        'budget_policy_id': 'bp',
        'runtime_profile_id': 'rp',
        'created_at': 'ca',
      });
      expect(dto.skills, ['s1']);
      expect(dto.capabilities, {'k': 1});
      expect(dto.strictMode, isTrue);
      expect(dto.maxConcurrentTasks, 3);
      expect(dto.visibility, 'private');
      final out = dto.toJson();
      expect(out['capabilities'], {'k': 1});
      expect(out['strict_mode'], isTrue);
    });

    test('defaults', () {
      final dto = AgentDto.fromJson({'id': 'a'});
      expect(dto.skills, isEmpty);
      expect(dto.strictMode, isFalse);
      expect(dto.maxConcurrentTasks, 1);
      expect(dto.visibility, 'workspace');
      expect(dto.lifecycleStatus, 'active');
    });
  });

  group('RepoDto', () {
    test('round-trip + defaults', () {
      final dto = RepoDto.fromJson({
        'id': 'r',
        'name': 'n',
        'path': '/p',
        'forge': 'gitlab',
        'remote_owner': 'group/subgroup',
        'remote_name': 'repo',
        'created_at': 'c',
        'updated_at': 'u',
      });
      expect(dto.forge, 'gitlab');
      expect(dto.remoteOwner, 'group/subgroup');
      expect(dto.remoteName, 'repo');
      final out = dto.toJson();
      expect(out['forge'], 'gitlab');
      expect(out['remote_owner'], 'group/subgroup');
      expect(out['remote_name'], 'repo');
      expect(RepoDto.fromJson({'id': 'r'}).name, '');
    });

    test('a repo with no forge on the wire reads as GitHub', () {
      // The overwhelmingly common case, and the value the column defaults to.
      expect(RepoDto.fromJson({'id': 'r'}).forge, 'github');
    });
  });

  group('SpaceDto', () {
    test('round-trip', () {
      final dto = SpaceDto.fromJson({
        'id': 'c',
        'name': 'n',
        'workspace_id': 'w',
        'mode': 'pair',
        'provisioning_status': 'ready',
        'pipeline_run_id': 'pr',
        'origin': 'agent',
        'archived_at': '2025-01-03T00:00:00',
        'created_at': '2025-01-01T00:00:00',
        'updated_at': '2025-01-02T00:00:00',
      });
      expect(dto.mode, 'pair');
      expect(dto.createdAt, DateTime(2025, 1, 1));
      expect(dto.archivedAt, DateTime(2025, 1, 3));
      final out = dto.toJson();
      expect(out['mode'], 'pair');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['archived_at'], '2025-01-03T00:00:00.000');
    });

    test('defaults omit nulls', () {
      final out = SpaceDto.fromJson({
        'id': 'c',
        'name': 'n',
        'workspace_id': 'w',
      }).toJson();
      expect(out.containsKey('mode'), isFalse);
      expect(out.containsKey('created_at'), isFalse);
      expect(out.containsKey('archived_at'), isFalse);
    });

    test('a missing archived_at reads as not archived (older servers)', () {
      final dto = SpaceDto.fromJson({
        'id': 'c',
        'name': 'n',
        'workspace_id': 'w',
      });
      expect(dto.archivedAt, isNull);
    });

    test('non-string timestamp -> null', () {
      final dto = SpaceDto.fromJson({
        'id': 'c',
        'name': 'n',
        'workspace_id': 'w',
        'created_at': 5,
      });
      expect(dto.createdAt, isNull);
    });
  });

  group('MessageDto', () {
    test('round-trip', () {
      final dto = MessageDto.fromJson({
        'id': 'm',
        'content': 'c',
        'sender_id': 's',
        'sender_type': 'agent',
        'message_type': 'text',
        'metadata': {'k': 1},
        'space_id': 'ch',
        'parent_message_id': 'p',
        'compacted': true,
        'created_at': '2025-01-01T00:00:00',
      });
      expect(dto.metadata, {'k': 1});
      expect(dto.compacted, isTrue);
      final out = dto.toJson();
      expect(out['metadata'], {'k': 1});
      expect(out['compacted'], isTrue);
    });

    test('compacted omitted when false; minimal defaults', () {
      final dto = MessageDto.fromJson({'id': 'm'});
      expect(dto.content, '');
      expect(dto.compacted, isFalse);
      expect(dto.createdAt, isNull);
      final out = dto.toJson();
      expect(out.containsKey('compacted'), isFalse);
      expect(out.containsKey('metadata'), isFalse);
    });
  });

  group('SpaceParticipantDto', () {
    test('round-trip + defaults', () {
      final dto = SpaceParticipantDto.fromJson({
        'id': 'i',
        'space_id': 'c',
        'principal_id': 'p',
        'participant_type': 'user',
        'role': 'owner',
        'joined_at': '2025-01-01T00:00:00',
        'last_read_at': '2025-01-02T00:00:00',
      });
      expect(dto.participantType, 'user');
      expect(dto.joinedAt, DateTime(2025, 1, 1));
      final out = dto.toJson();
      expect(out['participant_type'], 'user');
      final d2 = SpaceParticipantDto.fromJson({'id': 'i'});
      expect(d2.participantType, 'agent');
    });
  });

  group('UserDto', () {
    test('round-trip + defaults', () {
      final dto = UserDto.fromJson({
        'id': 'u',
        'handle': 'h',
        'display_name': 'D',
        'email': 'e',
        'avatar_ref': 'a',
        'git_author_name': 'g',
        'git_author_email': 'ge',
        'created_at': '2025-01-01T00:00:00',
      });
      expect(dto.email, 'e');
      expect(dto.createdAt, DateTime(2025, 1, 1));
      expect(UserDto.fromJson({'id': 'u'}).handle, '');
    });
  });

  group('WorkspaceMemberDto', () {
    test('round-trip + defaults', () {
      final dto = WorkspaceMemberDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'user_id': 'u',
        'role': 'admin',
        'invited_by': 'b',
        'joined_at': '2025-01-01T00:00:00',
      });
      expect(dto.role, 'admin');
      expect(WorkspaceMemberDto.fromJson({'id': 'i'}).role, 'guest');
    });
  });

  group('WorkspaceInviteDto', () {
    test('round-trip + defaults', () {
      final dto = WorkspaceInviteDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'role': 'member',
        'repo_grants': {'r': 'read'},
        'created_by': 'b',
        'created_at': '2025-01-01T00:00:00',
        'expires_at': '2025-01-02T00:00:00',
        'used_at': '2025-01-03T00:00:00',
        'used_by': 'u',
        'revoked_at': '2025-01-04T00:00:00',
      });
      expect(dto.repoGrants, {'r': 'read'});
      expect(dto.expiresAt, DateTime(2025, 1, 2));
      final d = WorkspaceInviteDto.fromJson({'id': 'i'});
      expect(d.repoGrants, isEmpty);
      expect(d.role, 'guest');
    });
  });

  group('UserActivityDto', () {
    test('round-trip + defaults', () {
      final dto = UserActivityDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'user_id': 'u',
        'action': 'login',
        'target_type': 'ticket',
        'target_id': 't',
        'device_id': 'd',
        'created_at': '2025-01-01T00:00:00',
      });
      expect(dto.action, 'login');
      expect(UserActivityDto.fromJson({'id': 'i'}).action, '');
    });
  });

  group('FeedDto', () {
    test('round-trip + defaults', () {
      final dto = FeedDto.fromJson({
        'id': 'f',
        'name': 'n',
        'url': 'u',
        'description': 'd',
        'icon_url': 'i',
        'user_agent': 'ua',
        'enabled': false,
        'last_fetched_at': '2025-01-01T00:00:00',
        'last_error': 'e',
      });
      expect(dto.enabled, isFalse);
      expect(dto.lastFetchedAt, DateTime(2025, 1, 1));
      expect(
        FeedDto.fromJson({'id': 'f', 'name': 'n', 'url': 'u'}).enabled,
        isTrue,
      );
    });
  });

  group('ArticleDto', () {
    test('round-trip with summary fallback and publishedAt alt key', () {
      final dto = ArticleDto.fromJson({
        'id': 'a',
        'feed_id': 'f',
        'title': 't',
        'url': 'u',
        'image_url': 'i',
        'description': 'desc',
        'author': 'au',
        'publishedAt': '2025-01-01T00:00:00',
        'is_read': true,
        'is_saved': true,
      });
      expect(dto.summary, 'desc');
      expect(dto.publishedAt, DateTime(2025, 1, 1));
      expect(dto.isRead, isTrue);
    });

    test('uses published_at when publishedAt absent', () {
      final dto = ArticleDto.fromJson({
        'id': 'a',
        'feed_id': 'f',
        'title': 't',
        'published_at': '2025-02-01T00:00:00',
      });
      expect(dto.publishedAt, DateTime(2025, 2, 1));
      expect(dto.summary, isNull);
    });
  });

  group('SpaceReadDto', () {
    test('round-trip', () {
      final dto = SpaceReadDto.fromJson({
        'space_id': 'c',
        'last_read_at': 'x',
      });
      expect(dto.spaceId, 'c');
      final out = dto.toJson();
      expect(out['last_read_at'], 'x');
      final d2 = SpaceReadDto.fromJson({});
      expect(d2.spaceId, '');
      final out2 = d2.toJson();
      expect(out2.containsKey('last_read_at'), isFalse);
    });
  });

  group('MemoryDomainDto', () {
    test('round-trip', () {
      final dto = MemoryDomainDto.fromJson({
        'id': 'm',
        'workspace_id': 'w',
        'name': 'n',
        'label': 'l',
        'description': 'd',
        'created_by_role': 'leader',
        'created_at': 'c',
      });
      expect(dto.label, 'l');
      expect(dto.toJson()['created_by_role'], 'leader');
      final d2 = MemoryDomainDto.fromJson({'id': 'm'});
      expect(d2.createdByRole, '');
      expect(d2.toJson().containsKey('description'), isFalse);
    });
  });

  group('MemoryAccessGrantDto', () {
    test('round-trip', () {
      final dto = MemoryAccessGrantDto.fromJson({
        'workspace_id': 'w',
        'agent_role': 'leader',
        'memory_domain': 'd',
        'permission': 'read',
      });
      expect(dto.permission, 'read');
      expect(MemoryAccessGrantDto.fromJson({}).agentRole, '');
    });
  });

  group('AgentWorkingMemoryDto', () {
    test('round-trip', () {
      final dto = AgentWorkingMemoryDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'agent_id': 'a',
        'content': 'c',
        'updated_at': 'u',
      });
      expect(dto.content, 'c');
      expect(dto.toJson()['updated_at'], 'u');
      expect(AgentWorkingMemoryDto.fromJson({'id': 'i'}).content, '');
    });
  });

  group('ReviewSpaceAssociationDto', () {
    test('round-trip', () {
      final dto = ReviewSpaceAssociationDto.fromJson({
        'id': 'i',
        'space_id': 'c',
        'workspace_id': 'w',
        'pr_external_id': 'n',
        'pr_number': 5,
        'repo_full_name': 'o/r',
        'status': 'open',
        'created_at': 'ca',
        'updated_at': 'ua',
      });
      expect(dto.prNumber, 5);
      expect(ReviewSpaceAssociationDto.fromJson({'id': 'i'}).prNumber, 0);
    });
  });

  group('MemoryPolicyDto', () {
    test('round-trip', () {
      final dto = MemoryPolicyDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'domain': 'd',
        'rule': 'r',
        'source_fact_ids': ['1'],
        'required_role': 'leader',
        'active': false,
        'created_at': 'c',
        'updated_at': 'u',
      });
      expect(dto.sourceFactIds, ['1']);
      expect(dto.active, isFalse);
      final d2 = MemoryPolicyDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'domain': 'd',
        'rule': 'r',
      });
      expect(d2.active, isTrue);
      expect(d2.sourceFactIds, isEmpty);
    });
  });

  group('ProviderPolicyDto', () {
    test('round-trip + defaults', () {
      final dto = ProviderPolicyDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'action': 'provider.use',
        'resource': '*',
        'effect': 'allow',
        'layer': 'system',
      });
      expect(dto.effect, 'allow');
      expect(dto.layer, 'system');
      final d2 = ProviderPolicyDto.fromJson({'id': 'i', 'workspace_id': 'w'});
      expect(d2.action, 'provider.use');
      expect(d2.resource, '*');
      expect(d2.effect, 'deny');
      expect(d2.layer, 'workspace');
    });
  });

  group('ActionPolicyRuleDto', () {
    test('round-trip + toEntity + fromEntity', () {
      final json = {
        'id': 'i',
        'workspace_id': 'w',
        'scope_type': 'agent',
        'scope_id': 'a',
        'decision': 'allow',
        'action_class': 'gitCommit',
        'command_prefix': null,
        'provenance': 'remembered',
        'created_by': 'u',
        'created_at': '2025-01-01T00:00:00',
        'updated_at': '2025-01-02T00:00:00',
      };
      final dto = ActionPolicyRuleDto.fromJson(json);
      expect(dto.scopeType, 'agent');
      expect(dto.decision, 'allow');
      final out = dto.toJson();
      expect(out['action_class'], 'gitCommit');

      final entity = dto.toEntity(workspaceId: 'w2', now: DateTime(2025, 1, 3));
      expect(entity.workspaceId, 'w2');
      expect(entity.scopeType, ActionScopeType.agent);
      expect(entity.decision, ActionDecision.allow);
      expect(entity.actionClass, ActionClass.gitCommit);
      expect(entity.createdAt, DateTime(2025, 1, 1));
      expect(entity.updatedAt, DateTime(2025, 1, 2));

      // toEntity falls back to epoch when timestamp missing / unparseable
      final bare = ActionPolicyRuleDto(
        id: 'x',
        workspaceId: 'w',
        scopeType: 'workspace',
        scopeId: '',
        decision: 'prompt',
        commandPrefix: 'git',
      );
      final bareEntity = bare.toEntity();
      expect(bareEntity.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
      final bad = ActionPolicyRuleDto(
        id: 'x',
        workspaceId: 'w',
        scopeType: 'workspace',
        scopeId: '',
        decision: 'prompt',
        commandPrefix: 'git',
        createdAt: 'nope',
        updatedAt: 'nope',
      );
      expect(bad.toEntity().updatedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('fromEntity', () {
      final e = ActionPolicyRule(
        id: 'i',
        workspaceId: 'w',
        scopeType: ActionScopeType.agent,
        scopeId: 'a',
        decision: ActionDecision.allow,
        actionClass: ActionClass.gitCommit,
        provenance: 'remembered',
        createdBy: 'u',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      final dto = ActionPolicyRuleDto.fromEntity(e);
      expect(dto.scopeType, 'agent');
      expect(dto.actionClass, 'gitCommit');
      expect(dto.createdAt, DateTime(2025, 1, 1).toIso8601String());
    });

    test('fromJson defaults', () {
      final d = ActionPolicyRuleDto.fromJson({});
      expect(d.scopeType, 'workspace');
      expect(d.decision, 'prompt');
      expect(d.provenance, 'user');
    });
  });

  group('CostSummaryDto', () {
    test('round-trip + defaults', () {
      final dto = CostSummaryDto.fromJson({
        'total_usd': 1.5,
        'request_count': 9,
        'window_start': 's',
        'next_reset_at': 'r',
        'by_provider': {'a': 1.0},
        'by_model': {'m': 2.0},
      });
      expect(dto.totalUsd, 1.5);
      expect(dto.byProvider, {'a': 1.0});
      final d = CostSummaryDto.fromJson({});
      expect(d.totalUsd, 0);
      expect(d.requestCount, 0);
      expect(d.byProvider, isEmpty);
    });
  });

  group('AgentRunLogDto', () {
    test('round-trips all fields', () {
      final dto = AgentRunLogDto.fromJson({
        'id': 'r',
        'agent_id': 'a',
        'workspace_id': 'w',
        'conversation_id': 'cv',
        'ticket_id': 't',
        'space_id': 'c',
        'started_at': 's',
        'completed_at': 'cp',
        'status': 'completed',
        'summary': 'su',
        'adapter': 'ad',
        'model_id': 'm',
        'pid': 5,
        'log_path': '/l',
        'input_tokens': 1,
        'output_tokens': 2,
        'thought_tokens': 3,
        'cached_read_tokens': 4,
        'cached_write_tokens': 6,
        'estimated_cost_cents': 7,
        'child_cost_cents': 8,
        'agent_role': 'main',
        'duration_ms': 100,
        'time_to_first_token_ms': 50,
        'liveness': 'healthy',
        'error_family': 'none',
        'last_output_at': 'lo',
        'continuation_summary': 'cs',
        'context_snapshot_json': '{}',
        'pipeline_run_id': 'pr',
        'pipeline_step_id': 'psr',
        'error_code': 'ec',
        'expected_output_schema': {'type': 'object'},
        'output_contract_mode': 'permissive',
        'output_json': {'k': 1},
        'output_rejections': 2,
        'retry_of_run_id': 'rr',
        'retry_attempt': 3,
        'parent_run_id': 'prn',
      });
      expect(dto.pid, 5);
      expect(dto.expectedOutputSchema, {'type': 'object'});
      expect(dto.outputJson, {'k': 1});
      expect(dto.parentRunId, 'prn');
      final out = dto.toJson();
      expect(out['expected_output_schema'], {'type': 'object'});
      expect(out['output_rejections'], 2);
    });

    test('defaults', () {
      final d = AgentRunLogDto.fromJson({'id': 'r'});
      expect(d.status, 'pending');
      expect(d.inputTokens, 0);
      expect(d.outputContractMode, 'strict');
      expect(d.retryAttempt, 0);
      expect(d.expectedOutputSchema, isNull);
      expect(d.outputJson, isNull);
    });
  });

  group('IsolatedRepoDto', () {
    test('round-trip + defaults', () {
      final dto = IsolatedRepoDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'space_id': 'c',
        'repo_id': 'r',
        'path': '/p',
        'branch': 'b',
        'backend': 'rift',
        'source_path': '/s',
        'ticket_id': 't',
        'created_at': 'ca',
      });
      expect(dto.backend, 'rift');
      expect(IsolatedRepoDto.fromJson({'id': 'i'}).backend, '');
    });
  });

  group('MemoryFactDto', () {
    test('round-trip + defaults', () {
      final dto = MemoryFactDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'domain': 'd',
        'topic': 't',
        'content': 'c',
        'source_observation_ids': ['1'],
        'confidence': 0.5,
        'superseded_by': 's',
        'authored_by_agent_id': 'a',
        'authored_by_role': 'leader',
        'memory_type': 'decision',
        'veracity': 'inferred',
        'mention_count': 3,
        'created_at': 'ca',
        'updated_at': 'ua',
      });
      expect(dto.confidence, 0.5);
      expect(dto.memoryType, 'decision');
      final d = MemoryFactDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'domain': 'd',
        'topic': 't',
        'content': 'c',
      });
      expect(d.confidence, 1.0);
      expect(d.memoryType, 'fact');
      expect(d.mentionCount, 1);
    });
  });

  group('VoiceProfileDto', () {
    test('round-trip + defaults', () {
      final dto = VoiceProfileDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'display_name': 'd',
        'embedding': [0.1, 0.2],
        'sample_count': 5,
        'created_at': 'c',
        'updated_at': 'u',
      });
      expect(dto.embedding, [0.1, 0.2]);
      expect(
        VoiceProfileDto.fromJson({
          'id': 'i',
          'workspace_id': 'w',
          'display_name': 'd',
        }).sampleCount,
        1,
      );
    });
  });

  group('ProjectDto', () {
    test('round-trip + defaults', () {
      final dto = ProjectDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'name': 'n',
        'description': 'd',
        'color': 'blue',
        'status': 'archived',
        'created_at': 'ca',
        'updated_at': 'ua',
      });
      expect(dto.color, 'blue');
      final d = ProjectDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'name': 'n',
      });
      expect(d.color, 'gray');
      expect(d.status, 'active');
      expect(d.createdAt, '');
    });
  });

  group('TicketLinkDto', () {
    test('round-trip', () {
      final dto = TicketLinkDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'source_ticket_id': 's',
        'target_ticket_id': 't',
        'type': 'blocks',
        'created_at': 'ca',
      });
      expect(dto.type, 'blocks');
      expect(TicketLinkDto.fromJson({'id': 'i'}).type, '');
    });
  });

  group('PipelineRunDto', () {
    test('round-trip + defaults', () {
      final dto = PipelineRunDto.fromJson({
        'id': 'i',
        'template_id': 't',
        'workspace_id': 'w',
        'status': 'running',
        'state': {'k': 1},
        'trigger_event_type': 'e',
        'trigger_payload': {'p': 2},
        'dedup_key': 'd',
        'started_at': 's',
        'finished_at': 'f',
        'active_ms': 10,
        'last_resumed_at': 'lr',
        'error_message': 'em',
        'error_stack_trace': 'est',
        'parent_pipeline_run_id': 'ppr',
        'parent_step_id': 'psi',
        'template_version': 3,
        'total_cost_cents': 4,
        'total_tokens': 5,
        'dry_run': true,
      });
      expect(dto.state, {'k': 1});
      expect(dto.triggerPayload, {'p': 2});
      expect(dto.dryRun, isTrue);
      expect(dto.templateVersion, 3);
      final d = PipelineRunDto.fromJson({
        'id': 'i',
        'template_id': 't',
        'workspace_id': 'w',
        'status': 'r',
        'started_at': 's',
      });
      expect(d.state, isEmpty);
      expect(d.templateVersion, 1);
    });

    test('constructor default for null state', () {
      final dto = PipelineRunDto(
        id: 'i',
        templateId: 't',
        workspaceId: 'w',
        status: 'r',
        startedAt: 's',
      );
      expect(dto.state, isEmpty);
    });
  });

  group('PipelineStepRunDto', () {
    test('round-trip + defaults', () {
      final dto = PipelineStepRunDto.fromJson({
        'id': 'i',
        'pipeline_run_id': 'pr',
        'step_id': 's',
        'status': 'succeeded',
        'input_json': '{}',
        'output_json': '{}',
        'space_id': 'c',
        'error_message': 'e',
        'branch_index': 1,
        'attempt_count': 2,
        'prior_attempts': [
          {
            'status': 'failed',
            'started_at': '2025-06-01T09:00:00.000',
            'finished_at': '2025-06-01T09:04:00.000',
            'error_message': 'boom',
          },
        ],
        'started_at': 's',
        'finished_at': 'f',
      });
      expect(dto.branchIndex, 1);
      expect(dto.attemptCount, 2);
      expect(dto.priorAttempts, hasLength(1));
      expect(dto.priorAttempts.single['error_message'], 'boom');
      // The wire shape round-trips the archive untouched.
      expect(dto.toJson()['prior_attempts'], dto.priorAttempts);
      final d = PipelineStepRunDto.fromJson({'id': 'i'});
      expect(d.status, 'pending');
      expect(d.attemptCount, 0);
      expect(d.branchIndex, isNull);
      expect(d.priorAttempts, isEmpty);
      // No tries, no key: the wire stays lean for the never-retried majority.
      expect(d.toJson().containsKey('prior_attempts'), isFalse);
    });
  });

  group('PipelineTemplateDto', () {
    test('round-trip + defaults', () {
      final dto = PipelineTemplateDto.fromJson({
        'template_id': 't',
        'workspace_id': 'w',
        'name': 'n',
        'description': 'd',
        'steps': [
          {'id': 's'},
        ],
        'inputs': [
          {'id': 'i'},
        ],
        'is_built_in': true,
        'is_enabled': false,
        'version': 4,
      });
      expect(dto.steps.first, {'id': 's'});
      expect(dto.isBuiltIn, isTrue);
      expect(dto.version, 4);
      final d = PipelineTemplateDto.fromJson({
        'template_id': 't',
        'workspace_id': 'w',
      });
      expect(d.steps, isEmpty);
      expect(d.version, 1);
    });
  });

  group('PipelineTriggerDto', () {
    test('round-trip + defaults', () {
      final dto = PipelineTriggerDto.fromJson({
        'id': 'i',
        'event_type': 'e',
        'template_id': 't',
        'workspace_id': 'w',
        'enabled': true,
        'cron_expression': '* * * * *',
        'timezone': 'UTC',
        'next_run_at': 'nr',
        'webhook_token': 'wt',
        'event_filters': {'a': 1},
        'match': {'b': 2},
        'last_fired_at': 'lf',
        'catch_up_policy': 'skip',
        'created_at': 'ca',
      });
      expect(dto.eventFilters, {'a': 1});
      expect(dto.catchUpPolicy, 'skip');
      final d = PipelineTriggerDto.fromJson({
        'id': 'i',
        'event_type': 'e',
        'template_id': 't',
        'workspace_id': 'w',
        'created_at': 'c',
      });
      expect(d.eventFilters, isEmpty);
      expect(d.catchUpPolicy, 'catchUpLatestOnly');
    });
  });

  group('TeamDto', () {
    test('round-trip', () {
      final dto = TeamDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'name': 'n',
        'description': 'd',
        'leader_id': 'l',
        'instructions': 'in',
        'created_at': 'ca',
      });
      expect(dto.leaderId, 'l');
      final d = TeamDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'name': 'n',
        'created_at': 'c',
      });
      final out = d.toJson();
      expect(out.containsKey('description'), isFalse);
    });
  });

  group('TeamMemberDto', () {
    test('round-trip', () {
      final dto = TeamMemberDto.fromJson({
        'team_id': 't',
        'agent_id': 'a',
        'role': 'leader',
      });
      expect(dto.role, 'leader');
      expect(TeamMemberDto.fromJson({}).role, 'member');
    });
  });

  group('OrchestrationDto', () {
    test('round-trip + defaults', () {
      final dto = OrchestrationDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'proposal_json': '{"a":1}',
        'parent_ticket_id': 'pt',
        'space_id': 'c',
        'orchestrator_agent_id': 'oa',
        'status': 'approved',
        'revision': 2,
        'approved_revision': 1,
        'pipeline_template_id': 'ptt',
        'pipeline_run_id': 'pr',
        'team_id': 't',
        'project_id': 'p',
        'estimated_cost_cents': 10,
        'max_cost_cents': 20,
        'hired_agent_ids': ['a'],
        'error_message': 'e',
        'created_at': 'ca',
        'updated_at': 'ua',
        'completed_at': 'cp',
      });
      expect(dto.revision, 2);
      expect(dto.approvedRevision, 1);
      expect(dto.hiredAgentIds, ['a']);
      final d = OrchestrationDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'created_at': 'c',
        'updated_at': 'u',
      });
      expect(d.status, 'proposed');
      expect(d.revision, 1);
      expect(d.proposalJson, '{}');
    });
  });

  group('PrUserDto', () {
    test('round-trip', () {
      final dto = PrUserDto.fromJson({
        'login': 'l',
        'avatar_url': 'a',
        'name': 'Ada',
      });
      expect(dto.login, 'l');
      expect(dto.name, 'Ada');
      expect(PrUserDto.fromJson({}).login, '');
      expect(PrUserDto.fromJson({}).name, isNull);
    });
  });

  group('ReactionGroupDto', () {
    test('round-trip', () {
      final dto = ReactionGroupDto.fromJson({
        'content': '+1',
        'count': 3,
        'user_reacted': true,
        'usernames': ['a', 'b'],
      });
      expect(dto.count, 3);
      expect(dto.userReacted, isTrue);
      final d = ReactionGroupDto.fromJson({'content': 'x'});
      expect(d.count, 0);
    });
  });

  group('PullRequestDto', () {
    test('round-trips nested DTOs', () {
      final dto = PullRequestDto.fromJson({
        'id': 1,
        'number': 2,
        'title': 't',
        'body': 'b',
        'state': 'open',
        'is_draft': true,
        'repo_full_name': 'o/r',
        'html_url': 'u',
        'author': {'login': 'l', 'avatar_url': 'a'},
        'created_at': 'ca',
        'updated_at': 'ua',
        'merged_at': 'ma',
        'external_id': 'n',
        'head_sha': 'hs',
        'base_ref': 'br',
        'base_sha': 'bs',
        'head_ref': 'hr',
        'requested_reviewers': [
          {'login': 'r1', 'avatar_url': ''},
        ],
        'assignees': [
          {'login': 'a1', 'avatar_url': ''},
        ],
        'reviewed_by_me': true,
        'reactions': [
          {'content': '+1', 'count': 1, 'user_reacted': false, 'usernames': []},
        ],
        'body_html': '<p>',
        'changed_files': 5,
        'commits_count': 3,
        'additions': 10,
        'deletions': 2,
        'comments_count': 1,
        'checks_status': 'success',
        'mergeable_state': 'clean',
      });
      expect(dto.author?.login, 'l');
      expect(dto.requestedReviewers.first.login, 'r1');
      expect(dto.reactions.first.count, 1);
      expect(dto.checksStatus, 'success');
      final out = dto.toJson();
      expect((out['author'] as Map)['login'], 'l');
    });

    test('defaults', () {
      final d = PullRequestDto.fromJson({});
      expect(d.id, 0);
      expect(d.state, 'open');
      expect(d.checksStatus, 'none');
      expect(d.author, isNull);
    });
  });

  group('PrFileDto', () {
    test('round-trip', () {
      final dto = PrFileDto.fromJson({
        'filename': 'f',
        'status': 'added',
        'additions': 1,
        'deletions': 2,
        'patch': '@@',
        'previous_filename': 'pf',
        'viewer_viewed_state': 'VIEWED',
      });
      expect(dto.status, 'added');
      expect(dto.previousFilename, 'pf');
      final d = PrFileDto.fromJson({'filename': 'f'});
      expect(d.status, 'modified');
      expect(d.viewerViewedState, 'UNVIEWED');
    });
  });

  group('PrCommitDto', () {
    test('round-trip', () {
      final dto = PrCommitDto.fromJson({
        'sha': 's',
        'message': 'm',
        'author': {'login': 'l', 'avatar_url': 'a'},
        'date': 'd',
      });
      expect(dto.author?.login, 'l');
      final d = PrCommitDto.fromJson({});
      expect(d.sha, '');
    });
  });

  group('PrReviewSubmissionDto', () {
    test('round-trip', () {
      final dto = PrReviewSubmissionDto.fromJson({
        'id': 42,
        'state': 'approved',
        'author': {'login': 'l', 'avatar_url': 'a'},
        'body': 'b',
        'submitted_at': '2026-07-01T12:00:00.000Z',
      });
      expect(dto.id, 42);
      expect(dto.state, 'approved');
      expect(dto.author?.login, 'l');
      expect(dto.submittedAt, '2026-07-01T12:00:00.000Z');
      final d = PrReviewSubmissionDto.fromJson({});
      expect(d.state, 'commented');
      expect(d.id, 0);
      expect(d.submittedAt, isNull);
    });
  });

  group('PrTimelineEventDto', () {
    test('round-trip', () {
      final dto = PrTimelineEventDto.fromJson({
        'kind': 'reviewRequested',
        'actor': {'login': 'alice', 'avatar_url': 'a'},
        'reviewer_name': 'bob',
        'reviewer_is_team': true,
        'reviewer_avatar_url': 'https://avatars/bob',
        'created_at': '2026-07-01T12:00:00.000Z',
      });
      expect(dto.kind, 'reviewRequested');
      expect(dto.actor?.login, 'alice');
      expect(dto.reviewerName, 'bob');
      expect(dto.reviewerIsTeam, isTrue);
      expect(dto.reviewerAvatarUrl, 'https://avatars/bob');
      expect(dto.createdAt, '2026-07-01T12:00:00.000Z');

      final out = dto.toJson();
      expect(out['kind'], 'reviewRequested');
      expect((out['actor'] as Map)['login'], 'alice');
      expect(out['reviewer_name'], 'bob');
      expect(out['reviewer_is_team'], isTrue);
      expect(out['reviewer_avatar_url'], 'https://avatars/bob');
      expect(out['created_at'], '2026-07-01T12:00:00.000Z');

      final d = PrTimelineEventDto.fromJson({});
      expect(d.kind, '');
      expect(d.actor, isNull);
      expect(d.reviewerIsTeam, isFalse);
      expect(d.toJson().containsKey('created_at'), isFalse);
    });
  });

  group('PrCodeReviewCommentDto', () {
    test('round-trip', () {
      final dto = PrCodeReviewCommentDto.fromJson({
        'id': 1,
        'body': 'b',
        'path': 'p',
        'user': {'login': 'l', 'avatar_url': 'a'},
        'position': 2,
        'review_id': 9,
        'created_at': 'c',
        'side': 'LEFT',
        'in_reply_to_id': 3,
        'start_line': 4,
        'diff_hunk': '@@',
        'line': 5,
        'original_line': 6,
        'reactions': [
          {'content': '+1', 'count': 1, 'user_reacted': false, 'usernames': []},
        ],
      });
      expect(dto.side, 'LEFT');
      expect(dto.line, 5);
      expect(dto.user?.login, 'l');
      expect(dto.reactions.first.count, 1);
      final d = PrCodeReviewCommentDto.fromJson({'id': 0});
      expect(d.side, 'RIGHT');
      expect(d.diffHunk, '');
    });
  });

  group('IssueCommentDto', () {
    test('round-trip', () {
      final dto = IssueCommentDto.fromJson({
        'id': 1,
        'body': 'b',
        'user': {'login': 'l', 'avatar_url': 'a'},
        'created_at': 'c',
        'reactions': [
          {
            'content': '-1',
            'count': 2,
            'user_reacted': true,
            'usernames': ['x'],
          },
        ],
      });
      expect(dto.user?.login, 'l');
      expect(dto.reactions.first.userReacted, isTrue);
      final d = IssueCommentDto.fromJson({});
      expect(d.body, '');
    });
  });

  group('CheckRunDto', () {
    test('round-trip', () {
      final dto = CheckRunDto.fromJson({
        'name': 'n',
        'status': 'completed',
        'conclusion': 'success',
        'html_url': 'u',
        'completed_at': 'c',
        'output': 'o',
        'workflow_name': 'w',
        'check_suite_id': 7,
      });
      expect(dto.conclusion, 'success');
      expect(dto.checkSuiteId, 7);
      final d = CheckRunDto.fromJson({});
      expect(d.status, 'queued');
      expect(d.conclusion, isNull);
    });
  });

  group('PrReviewerDto', () {
    test('user kind round-trip', () {
      final dto = PrReviewerDto.fromJson({
        'kind': 'user',
        'is_code_owner': true,
        'state': 'approved',
        'user': {'login': 'l', 'avatar_url': 'a'},
        'reviewed_by': {'login': 'rb', 'avatar_url': 'a'},
      });
      expect(dto.isCodeOwner, isTrue);
      expect(dto.user?.login, 'l');
      expect(dto.reviewedBy?.login, 'rb');
      final out = dto.toJson();
      // name/slug only emitted for team kind
      expect(out.containsKey('name'), isFalse);
    });

    test('team kind emits name/slug', () {
      final dto = PrReviewerDto.fromJson({
        'kind': 'team',
        'is_code_owner': false,
        'state': 'pending',
        'name': 'N',
        'slug': 'S',
      });
      final out = dto.toJson();
      expect(out['name'], 'N');
      expect(out['slug'], 'S');
    });

    test('defaults', () {
      final d = PrReviewerDto.fromJson({});
      expect(d.kind, 'user');
      expect(d.state, 'pending');
    });
  });

  group('PrReviewerCandidateDto', () {
    test('round-trip', () {
      final dto = PrReviewerCandidateDto.fromJson({
        'kind': 'team',
        'key': 'k',
        'label': 'l',
        'avatar_url': 'a',
      });
      expect(dto.kind, 'team');
      final d = PrReviewerCandidateDto.fromJson({});
      expect(d.kind, 'user');
      expect(d.toJson().containsKey('avatar_url'), isFalse);
    });
  });

  group('PrPreviewDto', () {
    test('round-trip', () {
      final dto = PrPreviewDto.fromJson({
        'title': 't',
        'state': 'closed',
        'is_draft': true,
        'is_merged': true,
        'html_url': 'u',
      });
      expect(dto.isMerged, isTrue);
      final d = PrPreviewDto.fromJson({});
      expect(d.state, 'open');
    });
  });

  group('CommitPreviewDto', () {
    test('round-trip', () {
      final dto = CommitPreviewDto.fromJson({'title': 't', 'short_sha': 's'});
      expect(dto.shortSha, 's');
      expect(CommitPreviewDto.fromJson({}).title, '');
    });
  });

  group('CalendarAttendeeDto', () {
    test('round-trip', () {
      final dto = CalendarAttendeeDto.fromJson({
        'email': 'e',
        'display_name': 'd',
        'response_status': 'accepted',
        'self': true,
        'organizer': true,
      });
      expect(dto.organizer, isTrue);
      final d = CalendarAttendeeDto.fromJson({});
      expect(d.self, isFalse);
    });
  });

  group('CalendarEventDto', () {
    test('round-trip nested', () {
      final dto = CalendarEventDto.fromJson({
        'id': 'i',
        'account_id': 'a',
        'external_event_id': 'e',
        'calendar_id': 'c',
        'title': 't',
        'start_time': 's',
        'end_time': 'e2',
        'updated_at': 'u',
        'description': 'd',
        'location': 'l',
        'meeting_url': 'm',
        'recurring_event_id': 'r',
        'alerted_at': 'al',
        'is_all_day': true,
        'status': 'tentative',
        'attendees': [
          {
            'email': 'e',
            'display_name': 'd',
            'response_status': 'accepted',
            'self': false,
            'organizer': true,
          },
        ],
      });
      expect(dto.attendees.first.organizer, isTrue);
      expect(dto.isAllDay, isTrue);
      final d = CalendarEventDto.fromJson({'id': 'i'});
      expect(d.status, 'confirmed');
      expect(d.attendees, isEmpty);
    });
  });

  group('CalendarAccountDto', () {
    test('round-trip', () {
      final dto = CalendarAccountDto.fromJson({
        'id': 'i',
        'provider_id': 'google',
        'account_email': 'e',
        'display_name': 'd',
        'last_synced_at': 'l',
        'auth_expired_at': 'a',
      });
      expect(dto.providerId, 'google');
      expect(CalendarAccountDto.fromJson({'id': 'i'}).providerId, 'google');
    });
  });

  group('CalendarSourceDto', () {
    test('round-trip', () {
      final dto = CalendarSourceDto.fromJson({
        'account_id': 'a',
        'id': 'i',
        'summary': 's',
        'primary': true,
        'writable': true,
        'background_color': '#fff',
      });
      expect(dto.primary, isTrue);
      final d = CalendarSourceDto.fromJson({'id': 'i'});
      expect(d.primary, isFalse);
      expect(d.writable, isFalse);
    });
  });

  group('PrGenerationDto', () {
    test('round-trip', () {
      final dto = PrGenerationDto.fromJson({
        'id': 'i',
        'workspace_id': 'w',
        'status': 'published',
        'created_at': 'ca',
        'updated_at': 'ua',
        'title': 't',
        'body': 'b',
        'branch': 'br',
      });
      expect(dto.status, 'published');
      final d = PrGenerationDto.fromJson({'id': 'i'});
      expect(d.status, 'draft');
    });
  });

  group('ActivityEntryDto', () {
    test('round-trip', () {
      final dto = ActivityEntryDto.fromJson({
        'id': 'i',
        'actor_type': 'agent',
        'action': 'run_completed',
        'entity_type': 'run',
        'created_at': 'ca',
        'actor_id': 'a',
        'entity_id': 'e',
        'details': 'd',
        'run_id': 'r',
      });
      expect(dto.runId, 'r');
      final d = ActivityEntryDto.fromJson({'id': 'i'});
      expect(d.actorType, '');
    });
  });

  group('WeatherSnapshotDto', () {
    test('round-trip + entity bridge', () {
      final dto = WeatherSnapshotDto.fromJson({
        'latitude': 1.0,
        'longitude': 2.0,
        'condition': 'rain',
        'is_day': false,
        'temperature_celsius': 18.5,
        'wind_speed_kmh': 5.0,
        'observed_at': '2025-01-01T00:00:00',
        'location_label': 'here',
        'sunrise': '2025-01-01T06:00:00',
        'sunset': '2025-01-01T18:00:00',
      });
      expect(dto.condition, 'rain');
      final out = dto.toJson();
      expect(out['condition'], 'rain');
      final entity = dto.toEntity();
      expect(entity.condition, WeatherCondition.rain);
      expect(entity.sunrise, DateTime(2025, 1, 1, 6));
      expect(entity.sunset, DateTime(2025, 1, 1, 18));
    });

    test('toEntity falls back on bad/absent values', () {
      final bad = WeatherSnapshotDto(
        latitude: 0,
        longitude: 0,
        condition: 'unknown_bucket',
        isDay: true,
        temperatureCelsius: 0,
        windSpeedKmh: 0,
        observedAt: null,
      );
      final e = bad.toEntity();
      expect(e.condition, WeatherCondition.clouds);
      expect(e.observedAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(e.sunrise, isNull);

      final badTime = WeatherSnapshotDto(
        latitude: 0,
        longitude: 0,
        condition: 'clear',
        isDay: true,
        temperatureCelsius: 0,
        windSpeedKmh: 0,
        observedAt: 'nope',
        sunrise: 'nope',
      );
      final e2 = badTime.toEntity();
      expect(e2.observedAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(e2.sunrise, isNull);
    });

    test('fromEntity round-trips', () {
      final s = WeatherSnapshot(
        latitude: 1,
        longitude: 2,
        condition: WeatherCondition.clear,
        isDay: true,
        temperatureCelsius: 20,
        windSpeedKmh: 3,
        observedAt: DateTime(2025, 1, 1),
        locationLabel: 'L',
        sunrise: DateTime(2025, 1, 1, 6),
        sunset: null,
      );
      final dto = WeatherSnapshotDto.fromEntity(s);
      expect(dto.condition, 'clear');
      expect(dto.observedAt, DateTime(2025, 1, 1).toIso8601String());
      expect(dto.sunrise, DateTime(2025, 1, 1, 6).toIso8601String());
      expect(dto.sunset, isNull);
    });

    test('defaults on empty payload', () {
      final d = WeatherSnapshotDto.fromJson({});
      expect(d.latitude, 0);
      expect(d.isDay, isTrue);
      expect(d.condition, '');
      final out = d.toJson();
      expect(out.containsKey('observed_at'), isFalse);
      expect(out.containsKey('location_label'), isFalse);
    });
  });

  // Exercises the toJson() populated-nullable-field branches (the `if (x != null)`
  // and `?nullable` spread-if-null true-paths) for every DTO. The earlier groups
  // parse via fromJson + assert field values, but never call toJson on a fully
  // populated instance, so those branches stay uncovered.
  group('toJson populated round-trips', () {
    test('UserDto emits nullable fields', () {
      final out = UserDto.fromJson(const {
        'id': 'u',
        'handle': 'h',
        'display_name': 'D',
        'email': 'e',
        'avatar_ref': 'a',
        'git_author_name': 'g',
        'git_author_email': 'ge',
        'created_at': '2025-01-01T00:00:00.000',
      }).toJson();
      expect(out['email'], 'e');
      expect(out['avatar_ref'], 'a');
      expect(out['git_author_name'], 'g');
      expect(out['git_author_email'], 'ge');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
    });

    test('WorkspaceMemberDto emits invited_by + joined_at', () {
      final out = WorkspaceMemberDto.fromJson(const {
        'id': 'i',
        'workspace_id': 'w',
        'user_id': 'u',
        'role': 'admin',
        'invited_by': 'b',
        'joined_at': '2025-01-01T00:00:00.000',
      }).toJson();
      expect(out['invited_by'], 'b');
      expect(out['joined_at'], '2025-01-01T00:00:00.000');
    });

    test('WorkspaceInviteDto emits all nullable timestamps', () {
      final out = WorkspaceInviteDto.fromJson(const {
        'id': 'i',
        'workspace_id': 'w',
        'role': 'member',
        'repo_grants': {'r': 'read'},
        'created_by': 'b',
        'created_at': '2025-01-01T00:00:00.000',
        'expires_at': '2025-01-02T00:00:00.000',
        'used_at': '2025-01-03T00:00:00.000',
        'used_by': 'u',
        'revoked_at': '2025-01-04T00:00:00.000',
      }).toJson();
      expect(out['created_by'], 'b');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['expires_at'], '2025-01-02T00:00:00.000');
      expect(out['used_at'], '2025-01-03T00:00:00.000');
      expect(out['used_by'], 'u');
      expect(out['revoked_at'], '2025-01-04T00:00:00.000');
    });

    test('UserActivityDto emits target/device/created', () {
      final out = UserActivityDto.fromJson(const {
        'id': 'i',
        'workspace_id': 'w',
        'user_id': 'u',
        'action': 'login',
        'target_type': 'ticket',
        'target_id': 't',
        'device_id': 'd',
        'created_at': '2025-01-01T00:00:00.000',
      }).toJson();
      expect(out['target_type'], 'ticket');
      expect(out['target_id'], 't');
      expect(out['device_id'], 'd');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
    });

    test('FeedDto emits nullable scalars + timestamps', () {
      final out = FeedDto.fromJson(const {
        'id': 'f',
        'name': 'n',
        'url': 'u',
        'description': 'd',
        'icon_url': 'i',
        'user_agent': 'ua',
        'enabled': false,
        'last_fetched_at': '2025-01-01T00:00:00.000',
        'last_error': 'err',
      }).toJson();
      expect(out['description'], 'd');
      expect(out['icon_url'], 'i');
      expect(out['user_agent'], 'ua');
      expect(out['enabled'], false);
      expect(out['last_fetched_at'], '2025-01-01T00:00:00.000');
      expect(out['last_error'], 'err');
    });

    test('ArticleDto emits nullable fields + published_at', () {
      final out = ArticleDto.fromJson(const {
        'id': 'a',
        'feed_id': 'f',
        'title': 't',
        'url': 'u',
        'image_url': 'i',
        'summary': 's',
        'author': 'au',
        'published_at': '2025-01-01T00:00:00.000',
        'is_read': true,
        'is_saved': true,
      }).toJson();
      expect(out['url'], 'u');
      expect(out['image_url'], 'i');
      expect(out['summary'], 's');
      expect(out['author'], 'au');
      expect(out['published_at'], '2025-01-01T00:00:00.000');
      expect(out['is_read'], true);
      expect(out['is_saved'], true);
    });

    test('MemoryAccessGrantDto round-trips', () {
      final out = MemoryAccessGrantDto(
        workspaceId: 'w',
        agentRole: 'main',
        memoryDomain: 'd',
        permission: 'read',
      ).toJson();
      expect(out['workspace_id'], 'w');
      expect(out['agent_role'], 'main');
      expect(out['memory_domain'], 'd');
      expect(out['permission'], 'read');
    });

    test('MemoryDomainDto emits description + created_at', () {
      final out = MemoryDomainDto.fromJson(const {
        'id': 'm',
        'workspace_id': 'w',
        'name': 'n',
        'label': 'l',
        'description': 'desc',
        'created_by_role': 'main',
        'created_at': '2025-01-01T00:00:00.000',
      }).toJson();
      expect(out['description'], 'desc');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
    });

    test('AgentWorkingMemoryDto emits updated_at', () {
      final out = AgentWorkingMemoryDto.fromJson(const {
        'id': 'a',
        'workspace_id': 'w',
        'agent_id': 'ag',
        'content': 'c',
        'updated_at': '2025-01-01T00:00:00.000',
      }).toJson();
      expect(out['updated_at'], '2025-01-01T00:00:00.000');
    });

    test('ReviewSpaceAssociationDto emits created_at + updated_at', () {
      final out = ReviewSpaceAssociationDto.fromJson(const {
        'id': 'r',
        'space_id': 'c',
        'workspace_id': 'w',
        'pr_external_id': 'n',
        'pr_number': 7,
        'repo_full_name': 'repo',
        'status': 'open',
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-02T00:00:00.000',
      }).toJson();
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['updated_at'], '2025-01-02T00:00:00.000');
    });

    test('MemoryPolicyDto emits nullable fields', () {
      final out = MemoryPolicyDto.fromJson(const {
        'id': 'p',
        'workspace_id': 'w',
        'domain': 'd',
        'rule': 'r',
        'source_fact_ids': ['f1'],
        'required_role': 'main',
        'active': true,
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-02T00:00:00.000',
      }).toJson();
      expect(out['required_role'], 'main');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['updated_at'], '2025-01-02T00:00:00.000');
    });

    test('ProviderPolicyDto round-trips', () {
      final out = ProviderPolicyDto(
        id: 'p',
        workspaceId: 'w',
        action: 'provider.use',
        resource: '*',
        effect: 'allow',
        layer: 'workspace',
      ).toJson();
      expect(out['action'], 'provider.use');
      expect(out['resource'], '*');
      expect(out['effect'], 'allow');
      expect(out['layer'], 'workspace');
    });

    test('ActionPolicyRuleDto emits nullable fields', () {
      final out = ActionPolicyRuleDto.fromJson(const {
        'id': 'r',
        'workspace_id': 'w',
        'scope_type': 'workspace',
        'scope_id': 's',
        'decision': 'prompt',
        'action_class': 'gitCommit',
        'provenance': 'user',
        'created_by': 'b',
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-02T00:00:00.000',
      }).toJson();
      expect(out['action_class'], 'gitCommit');
      expect(out['created_by'], 'b');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['updated_at'], '2025-01-02T00:00:00.000');
    });

    test('CostSummaryDto emits nullable timestamps + maps', () {
      final out = CostSummaryDto(
        totalUsd: 1.5,
        requestCount: 3,
        windowStart: '2025-01-01T00:00:00.000',
        nextResetAt: '2025-01-02T00:00:00.000',
        byProvider: {'a': 1.0},
        byModel: {'m': 2.0},
      ).toJson();
      expect(out['window_start'], '2025-01-01T00:00:00.000');
      expect(out['next_reset_at'], '2025-01-02T00:00:00.000');
      expect(out['by_provider'], {'a': 1.0});
      expect(out['by_model'], {'m': 2.0});
    });

    test('AgentRunLogDto emits every nullable field', () {
      final out = AgentRunLogDto.fromJson(const {
        'id': 'r',
        'agent_id': 'a',
        'workspace_id': 'w',
        'conversation_id': 'c',
        'ticket_id': 't',
        'space_id': 'ch',
        'started_at': '2025-01-01T00:00:00.000',
        'completed_at': '2025-01-02T00:00:00.000',
        'status': 'completed',
        'summary': 's',
        'adapter': 'ad',
        'model_id': 'm',
        'pid': 1,
        'log_path': '/p',
        'input_tokens': 10,
        'output_tokens': 20,
        'thought_tokens': 30,
        'cached_read_tokens': 40,
        'cached_write_tokens': 50,
        'estimated_cost_cents': 60,
        'child_cost_cents': 70,
        'agent_role': 'main',
        'duration_ms': 100,
        'time_to_first_token_ms': 5,
        'liveness': 'alive',
        'error_family': 'none',
        'last_output_at': '2025-01-03T00:00:00.000',
        'continuation_summary': 'cs',
        'context_snapshot_json': '{}',
        'pipeline_run_id': 'pr',
        'pipeline_step_id': 'psr',
        'error_code': 'E1',
        'expected_output_schema': {'type': 'object'},
        'output_contract_mode': 'strict',
        'output_json': {'k': 'v'},
        'output_rejections': 1,
        'retry_of_run_id': 'rr',
        'retry_attempt': 2,
        'parent_run_id': 'pr2',
      }).toJson();
      expect(out['workspace_id'], 'w');
      expect(out['completed_at'], '2025-01-02T00:00:00.000');
      expect(out['pid'], 1);
      expect(out['agent_role'], 'main');
      expect(out['error_code'], 'E1');
      expect(out['expected_output_schema'], {'type': 'object'});
      expect(out['output_json'], {'k': 'v'});
      expect(out['parent_run_id'], 'pr2');
    });

    test('IsolatedRepoDto emits ticket_id + created_at', () {
      final out = IsolatedRepoDto.fromJson(const {
        'id': 'i',
        'workspace_id': 'w',
        'space_id': 'c',
        'repo_id': 'r',
        'path': '/p',
        'branch': 'b',
        'backend': 'rift',
        'source_path': '/s',
        'ticket_id': 't',
        'created_at': '2025-01-01T00:00:00.000',
      }).toJson();
      expect(out['ticket_id'], 't');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
    });

    test('MemoryFactDto emits nullable fields', () {
      final out = MemoryFactDto.fromJson(const {
        'id': 'f',
        'workspace_id': 'w',
        'domain': 'd',
        'topic': 't',
        'content': 'c',
        'source_observation_ids': ['o'],
        'confidence': 0.5,
        'superseded_by': 's',
        'authored_by_agent_id': 'a',
        'authored_by_role': 'main',
        'memory_type': 'fact',
        'veracity': 'stated',
        'mention_count': 2,
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-02T00:00:00.000',
      }).toJson();
      expect(out['superseded_by'], 's');
      expect(out['authored_by_agent_id'], 'a');
      expect(out['authored_by_role'], 'main');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['updated_at'], '2025-01-02T00:00:00.000');
    });

    test('VoiceProfileDto emits created_at + updated_at', () {
      final out = VoiceProfileDto.fromJson(const {
        'id': 'v',
        'workspace_id': 'w',
        'display_name': 'd',
        'embedding': [0.1, 0.2],
        'sample_count': 3,
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-02T00:00:00.000',
      }).toJson();
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['updated_at'], '2025-01-02T00:00:00.000');
    });

    test('ProjectDto emits description', () {
      final out = ProjectDto.fromJson(const {
        'id': 'p',
        'workspace_id': 'w',
        'name': 'n',
        'description': 'desc',
        'color': 'blue',
        'status': 'active',
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-02T00:00:00.000',
      }).toJson();
      expect(out['description'], 'desc');
    });

    test('TicketLinkDto round-trips', () {
      final out = TicketLinkDto(
        id: 'l',
        workspaceId: 'w',
        sourceTicketId: 's',
        targetTicketId: 't',
        type: 'blocks',
        createdAt: '2025-01-01T00:00:00.000',
      ).toJson();
      expect(out['source_ticket_id'], 's');
      expect(out['target_ticket_id'], 't');
      expect(out['type'], 'blocks');
    });

    test('PipelineRunDto emits nullable fields', () {
      final out = PipelineRunDto.fromJson(const {
        'id': 'r',
        'template_id': 't',
        'workspace_id': 'w',
        'status': 'running',
        'state': {'k': 'v'},
        'trigger_event_type': 'evt',
        'trigger_payload': {'p': 1},
        'dedup_key': 'd',
        'started_at': '2025-01-01T00:00:00.000',
        'finished_at': '2025-01-02T00:00:00.000',
        'active_ms': 100,
        'last_resumed_at': '2025-01-03T00:00:00.000',
        'error_message': 'e',
        'error_stack_trace': 'st',
        'parent_pipeline_run_id': 'pr',
        'parent_step_id': 'ps',
        'template_version': 2,
        'total_cost_cents': 5,
        'total_tokens': 6,
        'dry_run': true,
      }).toJson();
      expect(out['trigger_event_type'], 'evt');
      expect(out['trigger_payload'], {'p': 1});
      expect(out['dedup_key'], 'd');
      expect(out['finished_at'], '2025-01-02T00:00:00.000');
      expect(out['last_resumed_at'], '2025-01-03T00:00:00.000');
      expect(out['error_message'], 'e');
      expect(out['error_stack_trace'], 'st');
      expect(out['parent_pipeline_run_id'], 'pr');
      expect(out['parent_step_id'], 'ps');
    });

    test('PipelineStepRunDto emits nullable fields', () {
      final out = PipelineStepRunDto.fromJson(const {
        'id': 's',
        'pipeline_run_id': 'r',
        'step_id': 'st',
        'status': 'completed',
        'input_json': '{}',
        'output_json': '{"k":1}',
        'space_id': 'c',
        'error_message': 'e',
        'branch_index': 0,
        'attempt_count': 1,
        'started_at': '2025-01-01T00:00:00.000',
        'finished_at': '2025-01-02T00:00:00.000',
      }).toJson();
      expect(out['input_json'], '{}');
      expect(out['output_json'], '{"k":1}');
      expect(out['space_id'], 'c');
      expect(out['error_message'], 'e');
      expect(out['branch_index'], 0);
      expect(out['finished_at'], '2025-01-02T00:00:00.000');
    });

    test('PipelineTemplateDto emits description', () {
      final out = PipelineTemplateDto.fromJson(const {
        'template_id': 't',
        'workspace_id': 'w',
        'name': 'n',
        'description': 'desc',
        'steps': [
          {'id': 's1'},
        ],
        'inputs': [
          {'id': 'i1'},
        ],
        'is_built_in': true,
        'is_enabled': false,
        'version': 3,
      }).toJson();
      expect(out['description'], 'desc');
      expect(out['is_built_in'], true);
      expect(out['is_enabled'], false);
      expect(out['version'], 3);
    });

    test('PipelineTriggerDto emits nullable schedule fields', () {
      final out = PipelineTriggerDto.fromJson(const {
        'id': 'tg',
        'event_type': 'e',
        'template_id': 't',
        'workspace_id': 'w',
        'enabled': true,
        'cron_expression': '0 * * * *',
        'timezone': 'UTC',
        'next_run_at': '2025-01-01T00:00:00.000',
        'webhook_token': 'tok',
        'event_filters': {'a': 'b'},
        'match': {'k': 'v'},
        'last_fired_at': '2025-01-02T00:00:00.000',
        'catch_up_policy': 'skip',
        'created_at': '2025-01-03T00:00:00.000',
      }).toJson();
      expect(out['cron_expression'], '0 * * * *');
      expect(out['timezone'], 'UTC');
      expect(out['next_run_at'], '2025-01-01T00:00:00.000');
      expect(out['webhook_token'], 'tok');
      expect(out['last_fired_at'], '2025-01-02T00:00:00.000');
      expect(out['catch_up_policy'], 'skip');
    });

    test('TeamDto emits nullable fields', () {
      final out = TeamDto.fromJson(const {
        'id': 't',
        'workspace_id': 'w',
        'name': 'n',
        'description': 'd',
        'leader_id': 'l',
        'instructions': 'i',
        'created_at': '2025-01-01T00:00:00.000',
      }).toJson();
      expect(out['description'], 'd');
      expect(out['leader_id'], 'l');
      expect(out['instructions'], 'i');
    });

    test('TeamMemberDto round-trips', () {
      final out = TeamMemberDto(
        teamId: 't',
        agentId: 'a',
        role: 'leader',
      ).toJson();
      expect(out['team_id'], 't');
      expect(out['agent_id'], 'a');
      expect(out['role'], 'leader');
    });

    test('OrchestrationDto emits nullable fields', () {
      final out = OrchestrationDto.fromJson(const {
        'id': 'o',
        'workspace_id': 'w',
        'proposal_json': '{}',
        'parent_ticket_id': 'pt',
        'space_id': 'c',
        'orchestrator_agent_id': 'oa',
        'status': 'approved',
        'revision': 2,
        'approved_revision': 1,
        'pipeline_template_id': 'pt',
        'pipeline_run_id': 'pr',
        'team_id': 't',
        'project_id': 'p',
        'estimated_cost_cents': 100,
        'max_cost_cents': 200,
        'hired_agent_ids': ['a1'],
        'error_message': 'e',
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-02T00:00:00.000',
        'completed_at': '2025-01-03T00:00:00.000',
      }).toJson();
      expect(out['parent_ticket_id'], 'pt');
      expect(out['orchestrator_agent_id'], 'oa');
      expect(out['approved_revision'], 1);
      expect(out['pipeline_template_id'], 'pt');
      expect(out['pipeline_run_id'], 'pr');
      expect(out['team_id'], 't');
      expect(out['project_id'], 'p');
      expect(out['estimated_cost_cents'], 100);
      expect(out['max_cost_cents'], 200);
      expect(out['error_message'], 'e');
      expect(out['completed_at'], '2025-01-03T00:00:00.000');
    });

    test('PrUserDto round-trips', () {
      final out = PrUserDto(login: 'l', avatarUrl: 'a', name: 'Ada').toJson();
      expect(out['login'], 'l');
      expect(out['avatar_url'], 'a');
      expect(out['name'], 'Ada');
      expect(
        PrUserDto(login: 'l', avatarUrl: 'a').toJson().containsKey('name'),
        isFalse,
      );
    });

    test('ReactionGroupDto round-trips', () {
      final out = ReactionGroupDto(
        content: '+1',
        count: 2,
        userReacted: true,
        usernames: ['a', 'b'],
      ).toJson();
      expect(out['content'], '+1');
      expect(out['count'], 2);
      expect(out['user_reacted'], true);
      expect(out['usernames'], ['a', 'b']);
    });

    test('PullRequestDto emits author/reviewers/reactions/body_html', () {
      final out = PullRequestDto.fromJson(const {
        'id': 1,
        'number': 2,
        'title': 't',
        'body': 'b',
        'state': 'open',
        'is_draft': false,
        'repo_full_name': 'r',
        'html_url': 'u',
        'author': {'login': 'al', 'avatar_url': 'aa'},
        'created_at': '2025-01-01T00:00:00.000',
        'updated_at': '2025-01-02T00:00:00.000',
        'merged_at': '2025-01-03T00:00:00.000',
        'external_id': 'n',
        'head_sha': 'h',
        'base_ref': 'br',
        'base_sha': 'bs',
        'head_ref': 'hr',
        'requested_reviewers': [
          {'login': 'rv1', 'avatar_url': 'a'},
        ],
        'assignees': [
          {'login': 'as1', 'avatar_url': 'a'},
        ],
        'reviewed_by_me': true,
        'reactions': [
          {'content': '+1', 'count': 1, 'user_reacted': true},
        ],
        'body_html': '<p>',
        'changed_files': 3,
        'commits_count': 4,
        'additions': 5,
        'deletions': 6,
        'comments_count': 7,
        'checks_status': 'success',
        'mergeable_state': 'clean',
      }).toJson();
      expect((out['author'] as Map)['login'], 'al');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['merged_at'], '2025-01-03T00:00:00.000');
      expect(out['body_html'], '<p>');
      expect((out['requested_reviewers'] as List).length, 1);
      expect((out['assignees'] as List).length, 1);
      expect((out['reactions'] as List).length, 1);
    });

    test('PrFileDto emits previous_filename', () {
      final out = PrFileDto(
        filename: 'f',
        status: 'added',
        additions: 1,
        deletions: 2,
        patch: 'p',
        previousFilename: 'old',
        viewerViewedState: 'VIEWED',
      ).toJson();
      expect(out['previous_filename'], 'old');
      expect(out['viewer_viewed_state'], 'VIEWED');
    });

    test('PrCommitDto emits author + date', () {
      final out = PrCommitDto.fromJson(const {
        'sha': 's',
        'message': 'm',
        'author': {'login': 'l', 'avatar_url': 'a'},
        'date': '2025-01-01T00:00:00.000',
      }).toJson();
      expect((out['author'] as Map)['login'], 'l');
      expect(out['date'], '2025-01-01T00:00:00.000');
    });

    test('PrReviewSubmissionDto emits author', () {
      final out = PrReviewSubmissionDto.fromJson(const {
        'state': 'approved',
        'author': {'login': 'l', 'avatar_url': 'a'},
        'body': 'b',
      }).toJson();
      expect(out['state'], 'approved');
      expect((out['author'] as Map)['login'], 'l');
    });

    test('PrCodeReviewCommentDto emits nullable fields', () {
      final out = PrCodeReviewCommentDto.fromJson(const {
        'id': 1,
        'body': 'b',
        'path': 'p',
        'user': {'login': 'l', 'avatar_url': 'a'},
        'position': 2,
        'created_at': '2025-01-01T00:00:00.000',
        'side': 'LEFT',
        'in_reply_to_id': 3,
        'start_line': 4,
        'diff_hunk': 'dh',
        'line': 5,
        'original_line': 6,
        'reactions': [
          {'content': '+1', 'count': 1},
        ],
      }).toJson();
      expect((out['user'] as Map)['login'], 'l');
      expect(out['position'], 2);
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect(out['in_reply_to_id'], 3);
      expect(out['start_line'], 4);
      expect(out['line'], 5);
      expect(out['original_line'], 6);
      expect((out['reactions'] as List).length, 1);
    });

    test('IssueCommentDto emits user/created/reactions', () {
      final out = IssueCommentDto.fromJson(const {
        'id': 1,
        'body': 'b',
        'user': {'login': 'l', 'avatar_url': 'a'},
        'created_at': '2025-01-01T00:00:00.000',
        'reactions': [
          {'content': '+1', 'count': 1},
        ],
      }).toJson();
      expect((out['user'] as Map)['login'], 'l');
      expect(out['created_at'], '2025-01-01T00:00:00.000');
      expect((out['reactions'] as List).length, 1);
    });

    test('CheckRunDto emits nullable fields', () {
      final out = CheckRunDto.fromJson(const {
        'name': 'n',
        'status': 'completed',
        'conclusion': 'success',
        'html_url': 'u',
        'completed_at': '2025-01-01T00:00:00.000',
        'output': 'o',
        'workflow_name': 'wf',
        'check_suite_id': 9,
      }).toJson();
      expect(out['conclusion'], 'success');
      expect(out['completed_at'], '2025-01-01T00:00:00.000');
      expect(out['workflow_name'], 'wf');
      expect(out['check_suite_id'], 9);
    });

    test('PrReviewerDto emits user/reviewed_by for team', () {
      final out = PrReviewerDto.fromJson(const {
        'kind': 'team',
        'is_code_owner': true,
        'state': 'approved',
        'user': {'login': 'l', 'avatar_url': 'a'},
        'name': 'Team',
        'slug': 'slug',
        'avatar_url': 'https://t/team',
        'reviewed_by': {'login': 'rb', 'avatar_url': 'a'},
      }).toJson();
      expect(out['kind'], 'team');
      expect(out['name'], 'Team');
      expect(out['slug'], 'slug');
      expect(out['avatar_url'], 'https://t/team');
      expect((out['user'] as Map)['login'], 'l');
      expect((out['reviewed_by'] as Map)['login'], 'rb');
    });

    test('PrReviewerCandidateDto emits avatar_url', () {
      final out = PrReviewerCandidateDto(
        kind: 'user',
        key: 'k',
        label: 'l',
        avatarUrl: 'a',
      ).toJson();
      expect(out['avatar_url'], 'a');
    });

    test('PrPreviewDto round-trips', () {
      final out = PrPreviewDto(
        title: 't',
        state: 'open',
        isDraft: true,
        isMerged: false,
        htmlUrl: 'u',
      ).toJson();
      expect(out['is_draft'], true);
      expect(out['is_merged'], false);
    });

    test('CommitPreviewDto round-trips', () {
      final out = CommitPreviewDto(title: 't', shortSha: 's').toJson();
      expect(out['short_sha'], 's');
    });

    test('CalendarAttendeeDto emits nullable fields', () {
      final out = CalendarAttendeeDto(
        email: 'e',
        displayName: 'd',
        responseStatus: 'accepted',
        self: true,
        organizer: true,
      ).toJson();
      expect(out['display_name'], 'd');
      expect(out['response_status'], 'accepted');
    });

    test('CalendarEventDto emits nullable fields + attendees', () {
      final out = CalendarEventDto.fromJson(const {
        'id': 'e',
        'account_id': 'a',
        'external_event_id': 'x',
        'calendar_id': 'c',
        'title': 't',
        'start_time': '2025-01-01T09:00:00.000',
        'end_time': '2025-01-01T10:00:00.000',
        'updated_at': '2025-01-01T00:00:00.000',
        'description': 'd',
        'location': 'l',
        'meeting_url': 'm',
        'recurring_event_id': 'r',
        'alerted_at': '2025-01-01T08:00:00.000',
        'is_all_day': false,
        'status': 'tentative',
        'attendees': [
          {'email': 'a@b.com', 'response_status': 'accepted'},
        ],
      }).toJson();
      expect(out['description'], 'd');
      expect(out['location'], 'l');
      expect(out['meeting_url'], 'm');
      expect(out['recurring_event_id'], 'r');
      expect(out['alerted_at'], '2025-01-01T08:00:00.000');
      expect((out['attendees'] as List).length, 1);
    });

    test('CalendarAccountDto emits nullable timestamps', () {
      final out = CalendarAccountDto(
        id: 'a',
        providerId: 'google',
        accountEmail: 'e',
        displayName: 'd',
        lastSyncedAt: '2025-01-01T00:00:00.000',
        authExpiredAt: '2025-01-02T00:00:00.000',
      ).toJson();
      expect(out['display_name'], 'd');
      expect(out['last_synced_at'], '2025-01-01T00:00:00.000');
      expect(out['auth_expired_at'], '2025-01-02T00:00:00.000');
    });

    test('CalendarSourceDto emits background_color', () {
      final out = CalendarSourceDto(
        accountId: 'a',
        id: 'c',
        summary: 's',
        primary: true,
        writable: false,
        backgroundColor: '#ff0000',
      ).toJson();
      expect(out['background_color'], '#ff0000');
    });

    test('PrGenerationDto emits nullable fields', () {
      final out = PrGenerationDto(
        id: 'p',
        workspaceId: 'w',
        status: 'published',
        createdAt: '2025-01-01T00:00:00.000',
        updatedAt: '2025-01-02T00:00:00.000',
        title: 't',
        body: 'b',
        branch: 'br',
      ).toJson();
      expect(out['title'], 't');
      expect(out['body'], 'b');
      expect(out['branch'], 'br');
    });

    test('ActivityEntryDto emits nullable fields', () {
      final out = ActivityEntryDto(
        id: 'a',
        actorType: 'agent',
        action: 'run_completed',
        entityType: 'run',
        createdAt: '2025-01-01T00:00:00.000',
        actorId: 'ag',
        entityId: 'e',
        details: 'd',
        runId: 'r',
      ).toJson();
      expect(out['actor_id'], 'ag');
      expect(out['entity_id'], 'e');
      expect(out['details'], 'd');
      expect(out['run_id'], 'r');
    });

    test('WeatherSnapshotDto emits optional location + sun times', () {
      final out = WeatherSnapshotDto(
        latitude: 1.0,
        longitude: 2.0,
        condition: 'sunny',
        isDay: true,
        temperatureCelsius: 20.5,
        windSpeedKmh: 5.0,
        observedAt: '2025-01-01T00:00:00.000',
        locationLabel: 'Somewhere',
        sunrise: '2025-01-01T06:00:00.000',
        sunset: '2025-01-01T18:00:00.000',
      ).toJson();
      expect(out['location_label'], 'Somewhere');
      expect(out['sunrise'], '2025-01-01T06:00:00.000');
      expect(out['sunset'], '2025-01-01T18:00:00.000');
    });
  });

  // Sanity: AgentRole import path compiles & is usable.
  test('AgentRole import resolves', () {
    expect(AgentRole.values, isNotEmpty);
  });
}
