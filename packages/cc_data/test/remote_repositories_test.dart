import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/review_channel_association.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/providers/vcs_provider.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_domain/features/ticketing/domain/entities/project.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// A tiny in-process host that answers the catalog ops/queries the remote
/// repositories call — enough to prove the adapters round-trip end to end
/// (encode request → decode response → parse DTOs) without a real server.
class _FakeHost {
  _FakeHost(this.channel) {
    channel.incoming.listen(_onFrame);
  }

  final RemoteRpcChannelPort channel;
  final List<Map<String, dynamic>> sentMessages = [];
  final List<Map<String, dynamic>> sentAgents = [];
  final List<Map<String, dynamic>> sentWorkingMemories = [];
  final List<Map<String, dynamic>> sentRepos = [];
  final List<Map<String, dynamic>> sentReadCursors = [];
  final List<Map<String, dynamic>> sentMemoryDomains = [];
  final List<Map<String, dynamic>> sentGrants = [];
  final List<Map<String, dynamic>> sentFacts = [];
  final List<Map<String, dynamic>> sentPolicies = [];
  final List<Map<String, dynamic>> sentReviewChannels = [];
  final List<Map<String, dynamic>> sentRunLogs = [];
  final List<Map<String, dynamic>> sentIsolatedRepos = [];
  final List<Map<String, dynamic>> sentVoiceProfiles = [];
  final List<Map<String, dynamic>> sentProjects = [];
  final List<Map<String, dynamic>> sentTickets = [];
  final List<Map<String, dynamic>> sentTicketCollaborators = [];
  final List<Map<String, dynamic>> sentCalendarMeetingOps = [];
  final List<Map<String, dynamic>> sentTicketLinks = [];
  final List<Map<String, dynamic>> sentPipelineRuns = [];
  final List<Map<String, dynamic>> sentPipelineStepRuns = [];
  final List<Map<String, dynamic>> sentTemplates = [];
  final List<Map<String, dynamic>> sentTriggers = [];
  final List<Map<String, dynamic>> sentTeams = [];
  final List<Map<String, dynamic>> sentTeamMembers = [];
  final List<Map<String, dynamic>> sentOrchestrations = [];
  final List<Map<String, dynamic>> sentMessagingMutations = [];
  final List<Map<String, dynamic>> sentWorkspaces = [];
  final List<Map<String, dynamic>> sentWorkspaceRepoLinks = [];
  final List<Map<String, dynamic>> sentPrReviewOps = [];
  final List<Map<String, dynamic>> sentRecordingOps = [];

  void _onFrame(Map<String, dynamic> frame) {
    final id = frame['id'];
    final method = frame['method'] as String?;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};

    switch (method) {
      case 'initialize':
        _reply(id, {'capabilities': <String, dynamic>{}});
      case RpcMethods.listWorkspaces:
        _reply(id, {
          'workspaces': [
            {'id': 'ws1', 'name': 'Alpha'},
            {'id': 'ws2', 'name': 'Beta'},
          ],
        });
      case RpcMethods.repoCall:
        _repoCall(id, params);
      case RpcMethods.subscribe:
        _subscribe(id, params);
      case RpcMethods.unsubscribe:
        _reply(id, {'ok': true});
      default:
        _reply(id, <String, dynamic>{});
    }
  }

  void _repoCall(dynamic id, Map<String, dynamic> params) {
    final op = params['op'] as String;
    final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
    switch (op) {
      case 'tickets.list':
        _replyData(id, op, {
          'tickets': [_ticketJson('t1', 'First'), _ticketJson('t2', 'Second')],
        });
      case 'tickets.get':
        _replyData(id, op, {
          'ticket': _ticketJson(args['ticket_id'] as String, 'First'),
        });
      case 'tickets.assign':
        _replyData(id, op, {
          'ticket': _ticketJson(
            args['ticket_id'] as String,
            'First',
            assignee: args['agent_id'] as String?,
          ),
        });
      case 'tickets.insert':
      case 'tickets.delete':
        sentTickets.add({'op': op, ...args});
        _replyData(id, op, {'ok': true});
      case 'tickets.update':
        sentTickets.add({'op': op, ...args});
        // A sentinel expected_version forces an optimistic-lock rejection so
        // the client's conflict mapping can be exercised.
        if (args['expected_version'] == 999) {
          _replyError(id, RpcErrorCodes.conflict, 'stale version');
        } else {
          _replyData(id, op, {'ok': true});
        }
      case 'tickets.addCollaborator':
      case 'tickets.removeCollaborator':
        sentTicketCollaborators.add({'op': op, ...args});
        _replyData(id, op, {'ok': true});
      case 'tickets.getCollaborators':
        _replyData(id, op, {
          'collaborators': [
            _collaboratorJson('tc1', args['ticket_id'] as String, 'a1'),
          ],
        });
      case 'calendar.linkMeetingToEvent':
      case 'calendar.unlinkMeeting':
      case 'meeting.updateTitle':
        sentCalendarMeetingOps.add({'op': op, ...args});
        _replyData(id, op, {'ok': true});
      case 'meeting.startRecording':
        sentRecordingOps.add({'op': op, ...args});
        // The server mints the meeting id and returns it.
        _replyData(id, op, {'ok': true, 'meeting_id': 'm-fake'});
      case 'meeting.ingestAudio':
      case 'meeting.stopRecording':
        sentRecordingOps.add({'op': op, ...args});
        _replyData(id, op, {'ok': true});
      case 'agents.get':
        _replyData(id, op, {
          'agent': _agentJson(args['agent_id'] as String, 'Ada'),
        });
      case 'agents.findByName':
        _replyData(id, op, {'agent': _agentJson('a1', args['name'] as String)});
      case 'agents.upsert':
        sentAgents.add(args);
        _replyData(id, op, {'ok': true});
      case 'agents.delete':
        sentAgents.add(args);
        _replyData(id, op, {'ok': true});
      case 'agent_working_memory.getByAgent':
        _replyData(id, op, {
          'memory': _workingMemoryJson('wm1', args['agent_id'] as String),
        });
      case 'agent_working_memory.upsert':
        sentWorkingMemories.add(args);
        _replyData(id, op, {'ok': true});
      case 'repos.get':
        _replyData(id, op, {
          'repo': _repoJson(args['repo_id'] as String, 'cc'),
        });
      case 'repos.upsert':
        sentRepos.add(args);
        _replyData(id, op, {'repo_id': 'r-new'});
      case 'repos.delete':
        sentRepos.add(args);
        _replyData(id, op, {'ok': true});
      case 'messaging.listChannels':
        _replyData(id, op, {
          'channels': [_channelJson('c1', 'general')],
        });
      case 'messaging.getMessages':
        _replyData(id, op, {
          'messages': [
            _messageJson('m1', args['channel_id'] as String? ?? 'c1'),
          ],
        });
      case 'messaging.sendMessage':
        sentMessages.add(args);
        _replyData(id, op, {'message_id': 'm-new'});
      case 'messaging.getMessageById':
        _replyData(id, op, {
          'message': _messageJson(args['message_id'] as String, 'c1'),
        });
      case 'messaging.channelExists':
        _replyData(id, op, {'exists': true});
      case 'messaging.getParticipants':
        _replyData(id, op, {
          'participants': [
            _participantJson('p1', args['channel_id'] as String? ?? 'c1', 'user'),
          ],
        });
      case 'messaging.setChannelMode':
      case 'messaging.addParticipant':
      case 'messaging.updateMessage':
      case 'messaging.deleteChannel':
      case 'messaging.clearChannelMessages':
      case 'messaging.removeParticipant':
        sentMessagingMutations.add({'op': op, ...args});
        _replyData(id, op, {'ok': true});
      case 'messaging.openDm':
        sentMessagingMutations.add({'op': op, ...args});
        _replyData(id, op, {'channel': _channelJson('dm-1', 'DM')});
      case 'messaging.createGroup':
        sentMessagingMutations.add({'op': op, ...args});
        _replyData(id, op, {
          'channel': _channelJson('grp-1', args['name'] as String),
        });
      case 'workspace.upsert':
        sentWorkspaces.add(args);
        _replyData(id, op, {'workspace_id': 'ws-new'});
      case 'workspace.delete':
        sentWorkspaces.add(args);
        _replyData(id, op, {'ok': true});
      case 'workspace.setReposForWorkspace':
      case 'workspace.linkRepoToWorkspace':
      case 'workspace.unlinkRepoFromWorkspace':
        sentWorkspaceRepoLinks.add({'op': op, ...args});
        _replyData(id, op, {'ok': true});
      case 'workspace.isRepoLinkedToWorkspace':
        _replyData(id, op, {'linked': true});
      case 'newsfeed.listArticles':
        _replyData(id, op, {
          'articles': [_articleJson('a1', 'Headline')],
        });
      case 'newsfeed.setArticleRead':
      case 'newsfeed.setArticleSaved':
      case 'newsfeed.refreshAll':
      case 'newsfeed.refreshFeed':
      case 'newsfeed.setFeedEnabled':
      case 'newsfeed.deleteFeed':
      case 'newsfeed.markAllRead':
        _replyData(id, op, {'ok': true});
      case 'newsfeed.addFeed':
        _replyData(id, op, {'feed': _feedJson('f1', 'My Feed')});
      case 'channel_read.markChannelRead':
        sentReadCursors.add(args);
        _replyData(id, op, {'ok': true});
      case 'memory_domain.getByWorkspace':
        _replyData(id, op, {
          'domains': [_memoryDomainJson('d1', 'architecture')],
        });
      case 'memory_domain.findByName':
        _replyData(id, op, {
          'domain': _memoryDomainJson('d1', args['name'] as String),
        });
      case 'memory_domain.upsert':
        sentMemoryDomains.add(args);
        _replyData(id, op, {'ok': true});
      case 'memory_access_grant.getByWorkspace':
        _replyData(id, op, {
          'grants': [_memoryAccessGrantJson('coder', 'docs', 'read')],
        });
      case 'memory_access_grant.upsert':
      case 'memory_access_grant.upsertAll':
        sentGrants.add(args);
        _replyData(id, op, {'ok': true});
      case 'memory_fact.getByWorkspace':
        _replyData(id, op, {
          'facts': [_factJson('mf1', 'preferences'), _factJson('mf2', 'codebase')],
        });
      case 'memory_fact.getById':
        _replyData(id, op, {
          'fact': _factJson(args['fact_id'] as String, 'preferences'),
        });
      case 'memory_fact.getActiveByTopic':
        _replyData(id, op, {
          'facts': [_factJson('mf1', 'preferences')],
        });
      case 'memory_fact.getByAuthor':
        _replyData(id, op, {
          'facts': [_factJson('mf1', 'preferences', author: args['agent_id'] as String?)],
        });
      case 'memory_fact.search':
        _replyData(id, op, {
          'facts': [_factJson('mf1', 'preferences')],
        });
      case 'memory_fact.upsert':
        sentFacts.add(args);
        _replyData(id, op, {'ok': true});
      case 'memory_fact.delete':
        sentFacts.add(args);
        _replyData(id, op, {'ok': true});
      case 'memory_policy.getByWorkspace':
        _replyData(id, op, {
          'policies': [_policyJson('p1', 'coding')],
        });
      case 'memory_policy.getById':
        _replyData(id, op, {
          'policy': _policyJson(args['id'] as String, 'coding'),
        });
      case 'memory_policy.getActiveByWorkspace':
        _replyData(id, op, {
          'policies': [_policyJson('p1', args['domain'] as String? ?? 'coding')],
        });
      case 'memory_policy.upsert':
        sentPolicies.add(args);
        _replyData(id, op, {'ok': true});
      case 'memory_policy.delete':
        sentPolicies.add(args);
        _replyData(id, op, {'ok': true});
      case 'review_channel.create':
        sentReviewChannels.add(args);
        _replyData(id, op, {
          'association': _reviewChannelJson(
            'rc-new',
            args['channel_id'] as String,
            prNodeId: args['pr_node_id'] as String,
            prNumber: (args['pr_number'] as num).toInt(),
            repoFullName: args['repo_full_name'] as String,
          ),
        });
      case 'review_channel.updateStatus':
        sentReviewChannels.add(args);
        _replyData(id, op, {'ok': true});
      case 'agent_run_log.get':
        _replyData(id, op, {'log': _runLogJson(args['id'] as String, 'a1')});
      case 'agent_run_log.activeRunForAgent':
        _replyData(id, op, {
          'log': _runLogJson('rl-active', args['agent_id'] as String),
        });
      case 'agent_run_log.forPipelineRun':
        _replyData(id, op, {
          'logs': [_runLogJson('rl1', 'a1', pipelineRunId: args['pipeline_run_id'] as String?)],
        });
      case 'agent_run_log.forPipelineStep':
        _replyData(id, op, {
          'logs': [
            _runLogJson(
              'rl1',
              'a1',
              pipelineRunId: args['pipeline_run_id'] as String?,
              pipelineStepRunId: args['pipeline_step_id'] as String?,
            ),
          ],
        });
      case 'agent_run_log.upsert':
        sentRunLogs.add(args);
        _replyData(id, op, {'ok': true});
      case 'isolated_repo.forUnitRepo':
        _replyData(id, op, {
          'repo': _isolatedRepoJson(
            'ir1',
            channelId: args['channel_id'] as String,
            repoId: args['repo_id'] as String,
          ),
        });
      case 'isolated_repo.forChannel':
        _replyData(id, op, {
          'repos': [
            _isolatedRepoJson('ir1', channelId: args['channel_id'] as String),
          ],
        });
      case 'isolated_repo.forTicket':
        _replyData(id, op, {
          'repos': [_isolatedRepoJson('ir1', ticketId: args['ticket_id'] as String)],
        });
      case 'isolated_repo.forChannelAcrossWorkspaces':
        _replyData(id, op, {
          'repos': [
            _isolatedRepoJson('ir1', channelId: args['channel_id'] as String),
          ],
        });
      case 'isolated_repo.forTicketAcrossWorkspaces':
        _replyData(id, op, {
          'repos': [_isolatedRepoJson('ir1', ticketId: args['ticket_id'] as String)],
        });
      case 'isolated_repo.upsert':
        sentIsolatedRepos.add(args);
        _replyData(id, op, {'ok': true});
      case 'isolated_repo.deleteById':
        sentIsolatedRepos.add(args);
        _replyData(id, op, {'ok': true});
      case 'voice_profile.getByWorkspace':
        _replyData(id, op, {
          'profiles': [_voiceProfileJson('vp1', 'Ada')],
        });
      case 'voice_profile.getByName':
        _replyData(id, op, {
          'profile': _voiceProfileJson('vp1', args['display_name'] as String),
        });
      case 'voice_profile.upsert':
      case 'voice_profile.enroll':
      case 'voice_profile.unenroll':
      case 'voice_profile.rename':
      case 'voice_profile.delete':
        sentVoiceProfiles.add(args);
        _replyData(id, op, {'ok': true});
      case 'project.getById':
        _replyData(id, op, {
          'project': _projectJson(args['id'] as String, 'First'),
        });
      case 'project.getForWorkspace':
        _replyData(id, op, {
          'projects': [_projectJson('p1', 'First'), _projectJson('p2', 'Second')],
        });
      case 'project.insert':
        sentProjects.add(args);
        _replyData(id, op, {'ok': true});
      case 'project.update':
        sentProjects.add(args);
        _replyData(id, op, {'count': 1});
      case 'project.delete':
        sentProjects.add(args);
        _replyData(id, op, {'count': 1});
      case 'ticket_link.insert':
        sentTicketLinks.add(args);
        _replyData(id, op, {'ok': true});
      case 'ticket_link.deleteById':
        sentTicketLinks.add(args);
        _replyData(id, op, {'deleted': 1});
      case 'ticket_link.deleteByEndpoints':
        sentTicketLinks.add(args);
        _replyData(id, op, {'deleted': 1});
      case 'ticket_link.getForTicket':
        _replyData(id, op, {
          'links': [
            _ticketLinkJson('tl1', args['ticket_id'] as String, 't2'),
          ],
        });
      case 'pipeline_run.insertRun':
      case 'pipeline_run.updateRun':
        sentPipelineRuns.add(args);
        _replyData(id, op, {'ok': true});
      case 'pipeline_run.getRun':
        _replyData(id, op, {
          'run': _pipelineRunJson(args['id'] as String, 'tmpl-1'),
        });
      case 'pipeline_run.updateRunState':
      case 'pipeline_run.incrementCost':
      case 'pipeline_run.deleteRun':
        sentPipelineRuns.add(args);
        _replyData(id, op, {'ok': true});
      case 'pipeline_run.nonTerminalRuns':
        _replyData(id, op, {
          'runs': [_pipelineRunJson('pr1', 'tmpl-1')],
        });
      case 'pipeline_run.activeForDedupKey':
        _replyData(id, op, {
          'run': _pipelineRunJson(
            'pr-dedup',
            args['template_id'] as String,
            dedupKey: args['dedup_key'] as String?,
          ),
        });
      case 'pipeline_run.insertStepRun':
      case 'pipeline_run.updateStepRun':
      case 'pipeline_run.deleteStepRun':
        sentPipelineStepRuns.add(args);
        _replyData(id, op, {'ok': true});
      case 'pipeline_run.stepRunsForPipeline':
        _replyData(id, op, {
          'step_runs': [
            _pipelineStepRunJson('sr1', args['pipeline_run_id'] as String),
          ],
        });
      case 'pipeline_run.getStepRunById':
        _replyData(id, op, {
          'step_run': _pipelineStepRunJson(
            args['step_run_id'] as String,
            'pr1',
          ),
        });
      case 'pipeline_template.forWorkspace':
        _replyData(id, op, {
          'templates': [_pipelineTemplateJson('pt1', 'PR review', isBuiltIn: true)],
        });
      case 'pipeline_template.getById':
        _replyData(id, op, {
          'template': _pipelineTemplateJson(
            args['template_id'] as String,
            'PR review',
          ),
        });
      case 'pipeline_template.upsert':
        sentTemplates.add(args);
        _replyData(id, op, {'ok': true});
      case 'pipeline_template.deleteById':
        sentTemplates.add(args);
        _replyData(id, op, {'deleted': 1});
      case 'pipeline_trigger.forWorkspace':
        _replyData(id, op, {
          'triggers': [_triggerJson('pt1', 'ExternalPrDetected')],
        });
      case 'pipeline_trigger.enabledForEvent':
        _replyData(id, op, {
          'triggers': [_triggerJson('pt1', args['event_type'] as String)],
        });
      case 'pipeline_trigger.getById':
        _replyData(id, op, {
          'trigger': _triggerJson(args['id'] as String, 'ExternalPrDetected'),
        });
      case 'pipeline_trigger.scheduled':
        _replyData(id, op, {
          'triggers': [
            _triggerJson('pt-sched', 'schedule', cronExpression: 'every:60'),
          ],
        });
      case 'pipeline_trigger.insert':
      case 'pipeline_trigger.update':
      case 'pipeline_trigger.deleteById':
      case 'pipeline_trigger.markFired':
        sentTriggers.add(args);
        _replyData(id, op, {'ok': true});
      case 'team.getTeam':
        _replyData(id, op, {
          'team': _teamJson(args['id'] as String, 'Platform'),
        });
      case 'team.teamsForWorkspace':
        _replyData(id, op, {
          'teams': [_teamJson('tm1', 'Platform')],
        });
      case 'team.membersOf':
        _replyData(id, op, {
          'members': [
            _teamMemberJson(args['team_id'] as String, 'a1', role: 'leader'),
          ],
        });
      case 'team.insertTeam':
      case 'team.updateTeam':
      case 'team.deleteTeam':
        sentTeams.add(args);
        _replyData(id, op, {'ok': true});
      case 'team.addMember':
      case 'team.removeMember':
        sentTeamMembers.add(args);
        _replyData(id, op, {'ok': true});
      case 'orchestration.insert':
      case 'orchestration.update':
        sentOrchestrations.add(args);
        _replyData(id, op, {'ok': true});
      case 'orchestration.getById':
        _replyData(id, op, {
          'orchestration': _orchestrationJson(args['id'] as String),
        });
      case 'orchestration.forParentTicket':
        _replyData(id, op, {
          'orchestration': _orchestrationJson(
            'orc1',
            parentTicketId: args['ticket_id'] as String?,
          ),
        });
      case 'orchestration.forPipelineRun':
      case 'orchestration.forPipelineRunAnyWorkspace':
        _replyData(id, op, {
          'orchestration': _orchestrationJson(
            'orc1',
            pipelineRunId: args['pipeline_run_id'] as String?,
          ),
        });
      case 'orchestration.approvedNeedingMaterialization':
        _replyData(id, op, {
          'orchestrations': [_orchestrationJson('orc1', status: 'approved')],
        });
      // ---- PR review ----
      case 'pr_review.getDraft':
        sentPrReviewOps.add({'op': op, ...args});
        _replyData(id, op, {'draft': 'WIP review notes'});
      case 'pr_review.listAssignableUsers':
        _replyData(id, op, {
          'users': [
            {'login': 'octocat', 'avatar_url': 'https://a/o.png'},
          ],
        });
      case 'pr_review.listRequestableReviewers':
        _replyData(id, op, {
          'candidates': [
            {
              'kind': 'user',
              'key': 'octocat',
              'label': 'octocat',
              'avatar_url': 'https://a/o.png',
            },
            {'kind': 'team', 'key': 'platform', 'label': 'Platform'},
          ],
        });
      case 'pr_review.prPreview':
        sentPrReviewOps.add({'op': op, ...args});
        _replyData(id, op, {
          'preview': {
            'title': 'Add feature',
            'state': 'open',
            'is_draft': false,
            'is_merged': false,
            'html_url': 'https://github.com/acme/cc/pull/7',
          },
        });
      case 'pr_review.commitPreview':
        sentPrReviewOps.add({'op': op, ...args});
        _replyData(id, op, {
          'preview': {'title': 'Fix bug', 'short_sha': 'abc1234'},
        });
      case 'pr_review.postReviewComment':
        sentPrReviewOps.add({'op': op, ...args});
        _replyData(id, op, {
          'result': {'id': 999},
        });
      case 'pr_review.uploadContent':
        sentPrReviewOps.add({'op': op, ...args});
        _replyData(id, op, {'url': 'https://github.com/acme/cc/raw/x.png'});
      case 'pr_review.mergePullRequest':
        sentPrReviewOps.add({'op': op, ...args});
        _replyData(id, op, {
          'result': {'merged': true, 'sha': 'deadbeef'},
        });
      case 'pr_review.upsertDraft':
      case 'pr_review.clearDraft':
      case 'pr_review.invalidatePullRequest':
      case 'pr_review.invalidateDiff':
      case 'pr_review.markFileAsViewed':
      case 'pr_review.replyToReviewComment':
      case 'pr_review.toggleReviewCommentReaction':
      case 'pr_review.toggleIssueCommentReaction':
      case 'pr_review.togglePullRequestReaction':
      case 'pr_review.submitReview':
      case 'pr_review.closePullRequest':
      case 'pr_review.updatePullRequest':
      case 'pr_review.addAssignees':
      case 'pr_review.removeAssignees':
      case 'pr_review.requestReviewers':
      case 'pr_review.removeRequestedReviewers':
        sentPrReviewOps.add({'op': op, ...args});
        _replyData(id, op, {'ok': true});
      default:
        _replyData(id, op, <String, dynamic>{});
    }
  }

  void _subscribe(dynamic id, Map<String, dynamic> params) {
    final query = params['query'] as String;
    const subId = 'sub-1';
    _reply(id, {'subscriptionId': subId});
    // Push one snapshot.
    final data = switch (query) {
      'tickets.watchForWorkspace' => {
        'tickets': [_ticketJson('t1', 'Live')],
      },
      'tickets.watchCollaborators' => {
        'collaborators': [
          _collaboratorJson(
            'tc1',
            params['args'] is Map
                ? (params['args'] as Map)['ticket_id'] as String? ?? 't1'
                : 't1',
            'a1',
          ),
        ],
      },
      'agents.watchForWorkspace' || 'agents.watchAll' => {
        'agents': [_agentJson('a1', 'Ada')],
      },
      'repos.watchAll' => {
        'repos': [_repoJson('r1', 'cc')],
      },
      'messaging.watchChannels' => {
        'channels': [_channelJson('c1', 'general')],
      },
      'messaging.watchMessages' || 'messaging.watchTopLevelMessages' => {
        'messages': [
          _messageJson(
            'm1',
            params['args'] is Map
                ? (params['args'] as Map)['channel_id'] as String? ?? 'c1'
                : 'c1',
          ),
        ],
      },
      'messaging.watchThread' => {
        'messages': [
          _messageJson(
            'm-reply',
            'c1',
            parentMessageId: params['args'] is Map
                ? (params['args'] as Map)['parent_message_id'] as String?
                : null,
          ),
        ],
      },
      'messaging.watchParticipants' => {
        'participants': [
          _participantJson(
            'p1',
            params['args'] is Map
                ? (params['args'] as Map)['channel_id'] as String? ?? 'c1'
                : 'c1',
            'user',
          ),
        ],
      },
      'workspace.watchAll' => {
        'workspaces': [_workspaceJson('ws1', 'Alpha')],
      },
      'workspace.watchReposForWorkspace' => {
        'repos': [_repoJson('r1', 'cc')],
      },
      'newsfeed.watchArticles' => {
        'articles': [_articleJson('a1', 'Live headline')],
      },
      'newsfeed.watchFeeds' => {
        'feeds': [_feedJson('f1', 'Live feed')],
      },
      'channel_read.watchUserLastReadAt' => _channelReadJson(
        params['args'] is Map
            ? (params['args'] as Map)['channel_id'] as String? ?? 'c1'
            : 'c1',
      ),
      'memory_domain.watchForWorkspace' => {
        'domains': [_memoryDomainJson('d1', 'architecture')],
      },
      'memory_access_grant.watchByWorkspace' => {
        'grants': [_memoryAccessGrantJson('coder', 'docs', 'write')],
      },
      'memory_fact.watchForWorkspace' => {
        'facts': [_factJson('mf1', 'preferences')],
      },
      'memory_policy.watchForWorkspace' => {
        'policies': [_policyJson('p1', 'coding')],
      },
      'agent_working_memory.watchByAgent' => {
        'memory': _workingMemoryJson('wm1', 'a1'),
      },
      'agent_working_memory.watchByWorkspace' => {
        'memories': [_workingMemoryJson('wm1', 'a1')],
      },
      'review_channel.watchByWorkspace' => {
        'associations': [_reviewChannelJson('rc1', 'c1')],
      },
      'review_channel.watchByPr' => {
        'association': _reviewChannelJson('rc1', 'c1', prNodeId: 'pr-node-1'),
      },
      'review_channel.watchByChannel' => {
        'association': _reviewChannelJson('rc1', 'c1'),
      },
      'agent_run_log.watchByAgent' ||
      'agent_run_log.watchActiveByConversation' ||
      'agent_run_log.watchAll' => {
        'logs': [_runLogJson('rl1', 'a1')],
      },
      'isolated_repo.watchForWorkspace' => {
        'repos': [_isolatedRepoJson('ir1', channelId: 'c1')],
      },
      'voice_profile.watchForWorkspace' => {
        'profiles': [_voiceProfileJson('vp1', 'Ada')],
      },
      'project.watchForWorkspace' => {
        'projects': [_projectJson('p1', 'Live')],
      },
      'ticket_link.watchForTicket' => {
        'links': [_ticketLinkJson('tl1', 't1', 't2')],
      },
      'pipeline_run.watchRun' => {
        'run': _pipelineRunJson('pr1', 'tmpl-1'),
      },
      'pipeline_run.watchAll' || 'pipeline_run.watchForWorkspace' => {
        'runs': [_pipelineRunJson('pr1', 'tmpl-1')],
      },
      'pipeline_run.watchStepRunsForPipeline' => {
        'step_runs': [_pipelineStepRunJson('sr1', 'pr1')],
      },
      'pipeline_template.watchForWorkspace' => {
        'templates': [_pipelineTemplateJson('pt1', 'PR review', isBuiltIn: true)],
      },
      'pipeline_trigger.watchForWorkspace' => {
        'triggers': [_triggerJson('pt1', 'ExternalPrDetected')],
      },
      'team.watchTeamsForWorkspace' => {
        'teams': [_teamJson('tm1', 'Platform')],
      },
      'team.watchMembersOf' => {
        'members': [
          _teamMemberJson(
            params['args'] is Map
                ? (params['args'] as Map)['team_id'] as String? ?? 'tm1'
                : 'tm1',
            'a1',
          ),
        ],
      },
      'orchestration.watchForWorkspace' => {
        'orchestrations': [_orchestrationJson('orc1')],
      },
      'orchestration.watchById' => {
        'orchestration': _orchestrationJson(
          params['args'] is Map
              ? (params['args'] as Map)['id'] as String? ?? 'orc1'
              : 'orc1',
        ),
      },
      // ---- PR review ----
      'pr_review.watchPullRequest' => {'pull_request': _pullRequestJson(7)},
      'pr_review.watchDiff' => {'diff': '@@ -1 +1 @@\n-old\n+new'},
      'pr_review.watchFiles' || 'pr_review.watchCommitFiles' => {
        'files': [_prFileJson('lib/main.dart')],
      },
      'pr_review.watchFileContent' => {'content': 'final x = 1;'},
      'pr_review.watchCommits' => {
        'commits': [_prCommitJson('abc1234567')],
      },
      'pr_review.watchReviews' => {
        'reviews': [
          {
            'state': 'approved',
            'author': {'login': 'octocat', 'avatar_url': 'https://a/o.png'},
            'body': 'LGTM',
          },
        ],
      },
      'pr_review.watchReviewComments' => {
        'comments': [_prReviewCommentJson(11)],
      },
      'pr_review.watchIssueComments' => {
        'comments': [_issueCommentJson(22)],
      },
      'pr_review.watchCheckRuns' => {
        'check_runs': [_checkRunJson('build')],
      },
      'pr_review.watchReviewers' => {
        'reviewers': [
          {
            'kind': 'user',
            'is_code_owner': true,
            'state': 'pending',
            'user': {'login': 'octocat', 'avatar_url': 'https://a/o.png'},
          },
          {
            'kind': 'team',
            'is_code_owner': false,
            'state': 'approved',
            'name': 'Platform',
            'slug': 'platform',
            'reviewed_by': {
              'login': 'reviewer',
              'avatar_url': 'https://a/r.png',
            },
          },
        ],
      },
      _ => <String, dynamic>{},
    };
    channel.send({
      'jsonrpc': '2.0',
      'method': RpcMethods.subSnapshot,
      'params': {'subscriptionId': subId, 'data': data},
    });
  }

  Map<String, dynamic> _ticketJson(
    String id,
    String title, {
    String? assignee,
  }) => {
    'ticket_id': id,
    'key': '',
    'title': title,
    'status': 'backlog',
    'priority': 'none',
    'provider': 'local',
    'assignee': ?assignee,
    'workspace_id': 'ws1',
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _agentJson(String id, String name) => {
    'id': id,
    'name': name,
    'title': 'Engineer',
    'agent_md_path': '/ws/agents/$id/AGENTS.md',
    'workspace_id': 'ws1',
    'skills': ['dart', 'flutter'],
    'strict_mode': false,
    'monthly_budget_cents': 0,
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _isolatedRepoJson(
    String id, {
    String channelId = 'c1',
    String repoId = 'r1',
    String? ticketId,
  }) => {
    'id': id,
    'workspace_id': 'ws1',
    'channel_id': channelId,
    'repo_id': repoId,
    'path': '/ws/ws1/conversations/$channelId/repos/$repoId',
    'branch': 'agent/$channelId',
    'backend': 'rift',
    'source_path': '/repos/$repoId',
    'ticket_id': ?ticketId,
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _voiceProfileJson(String id, String name) => {
    'id': id,
    'workspace_id': 'ws1',
    'display_name': name,
    'embedding': [0.1, 0.2, 0.3],
    'sample_count': 2,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _workingMemoryJson(String id, String agentId) => {
    'id': id,
    'workspace_id': 'ws1',
    'agent_id': agentId,
    'content': 'remember: ship it',
    'updated_at': '2026-01-03T00:00:00.000Z',
  };

  Map<String, dynamic> _repoJson(String id, String name) => {
    'id': id,
    'name': name,
    'path': '/repos/$id',
    'github_owner': 'acme',
    'github_repo_name': name,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _channelJson(String id, String name) => {
    'id': id,
    'name': name,
    'is_dm': false,
    'workspace_id': 'ws1',
    'mode': 'chat',
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _messageJson(
    String id,
    String channelId, {
    String? parentMessageId,
  }) => {
    'id': id,
    'content': 'Hello from $id',
    'sender_id': 'user',
    'sender_type': 'user',
    'message_type': 'text',
    'channel_id': channelId,
    'parent_message_id': ?parentMessageId,
    'compacted': false,
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _participantJson(
    String id,
    String channelId,
    String agentId,
  ) => {
    'id': id,
    'channel_id': channelId,
    'agent_id': agentId,
    'role': 'member',
    'joined_at': '2026-01-01T00:00:00.000Z',
    'last_read_at': '2026-01-03T00:00:00.000Z',
  };

  Map<String, dynamic> _workspaceJson(String id, String name) => {
    'id': id,
    'name': name,
    'logo_path': '/logos/$id.png',
    'review_concurrency': 5,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _channelReadJson(String channelId) => {
    'channel_id': channelId,
    'last_read_at': '2026-01-03T00:00:00.000Z',
  };

  Map<String, dynamic> _memoryDomainJson(String id, String name) => {
    'id': id,
    'workspace_id': 'ws1',
    'name': name,
    'label': 'Architecture',
    'description': 'Domain $id',
    'created_by_role': 'ceo',
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _memoryAccessGrantJson(
    String role,
    String domain,
    String permission,
  ) => {
    'workspace_id': 'ws1',
    'agent_role': role,
    'memory_domain': domain,
    'permission': permission,
  };

  Map<String, dynamic> _policyJson(String id, String domain) => {
    'id': id,
    'workspace_id': 'ws1',
    'domain': domain,
    'rule': 'always cite sources',
    'source_fact_ids': ['f1', 'f2'],
    'required_role': 'reviewer',
    'active': true,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _factJson(
    String id,
    String topic, {
    String? author,
  }) => {
    'id': id,
    'workspace_id': 'ws1',
    'domain': 'memory',
    'topic': topic,
    'content': 'The fact body for $topic',
    'source_observation_ids': ['obs1', 'obs2'],
    'confidence': 0.9,
    'authored_by_agent_id': ?author,
    'authored_by_role': 'coder',
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _reviewChannelJson(
    String id,
    String channelId, {
    String prNodeId = 'pr-node-1',
    int prNumber = 42,
    String repoFullName = 'acme/cc',
    String status = 'requested',
  }) => {
    'id': id,
    'channel_id': channelId,
    'workspace_id': 'ws1',
    'pr_node_id': prNodeId,
    'pr_number': prNumber,
    'repo_full_name': repoFullName,
    'status': status,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _runLogJson(
    String id,
    String agentId, {
    String? pipelineRunId,
    String? pipelineStepRunId,
  }) => {
    'id': id,
    'agent_id': agentId,
    'workspace_id': 'ws1',
    'started_at': '2026-01-01T00:00:00.000Z',
    'status': 'running',
    'input_tokens': 10,
    'output_tokens': 20,
    'estimated_cost_cents': 5,
    'output_contract_mode': 'strict',
    'output_rejections': 0,
    'retry_attempt': 0,
    'pipeline_run_id': ?pipelineRunId,
    'pipeline_step_run_id': ?pipelineStepRunId,
  };

  Map<String, dynamic> _pipelineTemplateJson(
    String templateId,
    String name, {
    bool isBuiltIn = false,
  }) => {
    'template_id': templateId,
    'workspace_id': 'ws1',
    'name': name,
    'is_built_in': isBuiltIn,
    'is_enabled': true,
    'version': 1,
    'steps': [
      {
        'id': 'trigger',
        'kind': 'trigger',
        'bodyKey': 'pipeline.trigger',
        'config': <String, dynamic>{},
      },
      {
        'id': 'work',
        'kind': 'listen',
        'bodyKey': 'pipeline.promptAgent',
        'triggers': [
          {'sourceStepIds': ['trigger']},
        ],
        'config': {'agentId': 'a1', 'outputKey': 'result'},
      },
    ],
    'inputs': [
      {'key': 'topic', 'label': 'Topic', 'type': 'text', 'required': true},
    ],
  };

  Map<String, dynamic> _pipelineRunJson(
    String id,
    String templateId, {
    String status = 'running',
    String? dedupKey,
  }) => {
    'id': id,
    'template_id': templateId,
    'workspace_id': 'ws1',
    'status': status,
    'state': {'k': 'v'},
    'dedup_key': ?dedupKey,
    'started_at': '2026-01-01T00:00:00.000Z',
    'template_version': 1,
    'total_cost_cents': 7,
    'total_tokens': 42,
    'dry_run': false,
  };

  Map<String, dynamic> _pipelineStepRunJson(
    String id,
    String pipelineRunId, {
    String stepId = 'setup',
    String status = 'running',
  }) => {
    'id': id,
    'pipeline_run_id': pipelineRunId,
    'step_id': stepId,
    'status': status,
    'attempt_count': 0,
    'started_at': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _projectJson(
    String id,
    String name, {
    String workspaceId = 'ws1',
    String color = 'blue',
    String status = 'active',
  }) => {
    'id': id,
    'workspace_id': workspaceId,
    'name': name,
    'color': color,
    'status': status,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _articleJson(String id, String title) => {
    'id': id,
    'feed_id': 'f1',
    'title': title,
    'url': 'https://example.com/$id',
    'is_read': false,
    'is_saved': false,
  };

  Map<String, dynamic> _feedJson(String id, String name) => {
    'id': id,
    'name': name,
    'url': 'https://example.com/feed',
    'description': 'A feed',
    'enabled': true,
  };

  Map<String, dynamic> _ticketLinkJson(
    String id,
    String sourceTicketId,
    String targetTicketId, {
    String type = 'blocks',
  }) => {
    'id': id,
    'workspace_id': 'ws1',
    'source_ticket_id': sourceTicketId,
    'target_ticket_id': targetTicketId,
    'type': type,
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _triggerJson(
    String id,
    String eventType, {
    String workspaceId = 'ws1',
    bool enabled = true,
    String? cronExpression,
    Map<String, dynamic> match = const {},
    String? lastFiredAt,
  }) => {
    'id': id,
    'event_type': eventType,
    'template_id': 'tmpl-1',
    'workspace_id': workspaceId,
    'enabled': enabled,
    'cron_expression': ?cronExpression,
    'match': match,
    'last_fired_at': ?lastFiredAt,
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _teamJson(String id, String name) => {
    'id': id,
    'workspace_id': 'ws1',
    'name': name,
    'description': 'A squad',
    'created_at': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _teamMemberJson(
    String teamId,
    String agentId, {
    String role = 'member',
  }) => {
    'team_id': teamId,
    'agent_id': agentId,
    'role': role,
  };

  Map<String, dynamic> _orchestrationJson(
    String id, {
    String? parentTicketId,
    String? pipelineRunId,
    String status = 'proposed',
  }) => {
    'id': id,
    'workspace_id': 'ws1',
    'proposal_json':
        '{"goal":"ship it","roles":[],"subTickets":[],'
        '"synthesis":{"roleKey":"lead","prompt":"sum","outputSchema":{}}}',
    'parent_ticket_id': ?parentTicketId,
    'pipeline_run_id': ?pipelineRunId,
    'status': status,
    'revision': 1,
    'hired_agent_ids': <String>[],
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-02T00:00:00.000Z',
  };

  Map<String, dynamic> _pullRequestJson(int number) => {
    'id': number * 1000,
    'number': number,
    'title': 'Add feature',
    'body': 'body',
    'state': 'open',
    'is_draft': false,
    'repo_full_name': 'acme/cc',
    'html_url': 'https://github.com/acme/cc/pull/$number',
    'author': {'login': 'octocat', 'avatar_url': 'https://a/o.png'},
    'node_id': 'PR_node',
    'head_sha': 'headsha',
    'base_ref': 'main',
    'base_sha': 'basesha',
    'head_ref': 'feature',
    'requested_reviewers': [
      {'login': 'octocat', 'avatar_url': 'https://a/o.png'},
    ],
    'assignees': <Map<String, dynamic>>[],
    'reviewed_by_me': false,
    'reactions': [
      {
        'content': '+1',
        'count': 2,
        'user_reacted': true,
        'usernames': ['octocat'],
      },
    ],
    'changed_files': 3,
    'commits_count': 2,
    'mergeable_state': 'clean',
    'checks_status': 'passing',
  };

  Map<String, dynamic> _prFileJson(String filename) => {
    'filename': filename,
    'status': 'modified',
    'additions': 5,
    'deletions': 2,
    'patch': '@@ -1 +1 @@',
    'viewer_viewed_state': 'VIEWED',
  };

  Map<String, dynamic> _prCommitJson(String sha) => {
    'sha': sha,
    'message': 'Fix bug\n\nmore',
    'author': {'login': 'octocat', 'avatar_url': 'https://a/o.png'},
    'date': '2026-01-01T00:00:00.000Z',
  };

  Map<String, dynamic> _prReviewCommentJson(int id) => {
    'id': id,
    'body': 'nit',
    'path': 'lib/main.dart',
    'user': {'login': 'octocat', 'avatar_url': 'https://a/o.png'},
    'side': 'RIGHT',
    'line': 10,
    'diff_hunk': '@@',
    'created_at': '2026-01-01T00:00:00.000Z',
    'reactions': <Map<String, dynamic>>[],
  };

  Map<String, dynamic> _issueCommentJson(int id) => {
    'id': id,
    'body': 'thanks',
    'user': {'login': 'octocat', 'avatar_url': 'https://a/o.png'},
    'created_at': '2026-01-01T00:00:00.000Z',
    'reactions': <Map<String, dynamic>>[],
  };

  Map<String, dynamic> _checkRunJson(String name) => {
    'name': name,
    'status': 'completed',
    'conclusion': 'success',
    'html_url': 'https://github.com/acme/cc/runs/1',
    'output': '',
    'workflow_name': 'CI',
    'check_suite_id': 42,
  };

  void _reply(dynamic id, Map<String, dynamic> result) {
    channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
  }

  void _replyData(dynamic id, String op, Map<String, dynamic> data) {
    channel.send({
      'jsonrpc': '2.0',
      'id': id,
      'result': {'op': op, 'data': data},
    });
  }

  void _replyError(dynamic id, int code, String message) {
    channel.send({
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message},
    });
  }

  Map<String, dynamic> _collaboratorJson(
    String id,
    String ticketId,
    String agentId,
  ) => {
    'id': id,
    'ticket_id': ticketId,
    'agent_id': agentId,
    'role': 'collaborator',
    'joined_at': '2026-01-01T00:00:00.000Z',
  };
}

void main() {
  late RemoteRpcClient client;
  late _FakeHost host;

  setUp(() async {
    final (server, clientChannel) = InProcessRpcChannel.pair();
    host = _FakeHost(server);
    client = RemoteRpcClient(clientChannel)..start();
    await client.initialize();
  });

  tearDown(() async {
    await client.close();
  });

  test('RemoteWorkspaceRepository lists + points the client', () async {
    final repo = RemoteWorkspaceRepository(client);
    final workspaces = await repo.list();
    expect(workspaces.map((w) => w.id), ['ws1', 'ws2']);
    // The server is stateless: setActive points the client (it injects the id
    // as `workspace_id` into subsequent requests), it does not bind a session.
    await repo.setActive('ws2');
    expect(client.activeWorkspaceId, 'ws2');
  });

  test('RemoteTicketRepository round-trips list/get/assign', () async {
    final repo = RemoteTicketRepository(client);
    final tickets = await repo.list();
    expect(tickets, hasLength(2));
    expect(tickets.first.title, 'First');

    final one = await repo.get('t1');
    expect(one.id, 't1');

    final assigned = await repo.assign('t1', agentId: 'agent-7');
    expect(assigned?.assignee, 'agent-7');
  });

  test('RemoteTicketRepository.watch emits a snapshot', () async {
    final repo = RemoteTicketRepository(client);
    final snapshot = await repo.watch().first;
    expect(snapshot.single.title, 'Live');
  });

  test('RemoteMessagingRepository lists channels + sends', () async {
    final repo = RemoteMessagingRepository(client);
    final channels = await repo.listChannels();
    expect(channels.single.name, 'general');

    final id = await repo.sendMessage(channelId: 'c1', content: 'hi');
    expect(id, 'm-new');
    expect(host.sentMessages.single['content'], 'hi');
  });

  test('RemoteNewsfeedRepository lists + toggles', () async {
    final repo = RemoteNewsfeedRepository(client);
    final articles = await repo.listArticles();
    expect(articles.single.title, 'Headline');
    await repo.setRead('a1', read: true);
    await repo.setSaved('a1', saved: true);
  });

  test('RemoteNewsfeedRepository.watch emits a snapshot', () async {
    final repo = RemoteNewsfeedRepository(client);
    final snapshot = await repo.watch().first;
    expect(snapshot.single.title, 'Live headline');
  });

  test('RpcNewsfeedRepository maps watch + getById to domain entities', () async {
    final repo = RpcNewsfeedRepository(client);
    final live = await repo.watchArticles().first;
    expect(live.single.id, 'a1');
    expect(live.single.title, 'Live headline');
    // The lossy DTO has no guid/createdAt — the adapter fills safe fallbacks.
    expect(live.single.guid, 'a1');
    expect(live.single.link, 'https://example.com/a1');

    final one = await repo.getArticleById('a1');
    expect(one, isNotNull);
    expect(one!.title, 'Headline');

    await repo.setArticleRead('a1', read: true);
    await repo.setArticleSaved('a1', saved: true);

    // Feed management + refresh now forward over RPC (host-side fetch), so they
    // succeed instead of throwing. watchFeeds streams the synced feed rows.
    final feeds = await repo.watchFeeds().first;
    expect(feeds.single.id, 'f1');
    expect(feeds.single.name, 'Live feed');

    final added = await repo.addFeed(name: 'My Feed', url: 'https://x/feed');
    expect(added.id, 'f1');

    await repo.refreshAll();
    await repo.refreshFeed('f1');
    await repo.setFeedEnabled('f1', enabled: false);
    await repo.deleteFeed('f1');
    await repo.markAllRead();
  });

  test('RpcTicketRepository maps watch + getById to domain entities', () async {
    final repo = RpcTicketRepository(client);
    final live = await repo.watchForWorkspace('ws1').first;
    expect(live.single.id, 't1');
    expect(live.single.title, 'Live');
    expect(live.single.workspaceId, isNotEmpty); // host binds it / defaulted

    final one = await repo.getById('t1');
    expect(one, isNotNull);
    expect(one!.title, 'First');
  });

  test('RpcTicketRepository insert/update/delete reach the host losslessly',
      () async {
    final repo = RpcTicketRepository(client);
    final ticket = Ticket(
      id: 't9',
      workspaceId: 'ws1',
      title: 'Wire me',
      description: 'body',
      status: TicketStatus.inProgress,
      priority: TicketPriority.high,
      labels: const ['bug', 'p1'],
      projectId: 'proj-1',
      parentTicketId: 'parent-1',
      assignedAgentId: 'a1',
      linkedPrIds: const ['pr-1'],
      version: 3,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 1, 2),
    );

    await repo.insert(ticket);
    final inserted = host.sentTickets.last;
    expect(inserted['op'], 'tickets.insert');
    final wire = (inserted['ticket'] as Map).cast<String, dynamic>();
    // The overlay + mirror fields the lossy DTO used to drop must survive.
    expect(wire['project_id'], 'proj-1');
    expect(wire['parent_ticket_id'], 'parent-1');
    expect(wire['labels'], ['bug', 'p1']);
    expect(wire['linked_pr_ids'], ['pr-1']);
    expect(wire['version'], 3);
    expect(wire['status'], 'inProgress');
    expect(wire['priority'], 'high');

    await repo.update(ticket, expectedVersion: 3);
    final updated = host.sentTickets.last;
    expect(updated['op'], 'tickets.update');
    expect(updated['expected_version'], 3);

    await repo.delete('t9', workspaceId: 'ws1');
    expect(host.sentTickets.last['op'], 'tickets.delete');
    expect(host.sentTickets.last['ticket_id'], 't9');
  });

  test('RpcTicketRepository.update maps a host conflict to '
      'ConcurrencyConflictException', () async {
    final repo = RpcTicketRepository(client);
    final ticket = Ticket(
      id: 't9',
      workspaceId: 'ws1',
      title: 'stale',
      status: TicketStatus.open,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    // 999 is the fake host's sentinel that triggers an RpcErrorCodes.conflict.
    await expectLater(
      () => repo.update(ticket, expectedVersion: 999),
      throwsA(isA<ConcurrencyConflictException>()),
    );
  });

  test('RpcTicketRepository round-trips collaborators over RPC', () async {
    final repo = RpcTicketRepository(client);

    await repo.addCollaborator(TicketCollaborator(
      id: 'tc9',
      ticketId: 't1',
      agentId: 'a1',
      joinedAt: DateTime.utc(2026),
    ));
    final added = host.sentTicketCollaborators.last;
    expect(added['op'], 'tickets.addCollaborator');
    expect(added['id'], 'tc9');
    expect(added['ticket_id'], 't1');
    expect(added['agent_id'], 'a1');

    final fetched = await repo.getCollaborators('t1');
    expect(fetched.single.id, 'tc1');
    expect(fetched.single.agentId, 'a1');

    final live = await repo.watchCollaborators('t1').first;
    expect(live.single.ticketId, 't1');

    await repo.removeCollaborator('t1', 'a1');
    expect(host.sentTicketCollaborators.last['op'], 'tickets.removeCollaborator');
  });

  test('RpcCalendarRepository link/unlink + RpcMeetingRepository.updateTitle '
      'reach the host', () async {
    final calendar = RpcCalendarRepository(client);
    await calendar.linkMeetingToEvent(
      workspaceId: 'ws1',
      meetingId: 'm1',
      calendarEventId: 'e1',
    );
    expect(host.sentCalendarMeetingOps.last, {
      'op': 'calendar.linkMeetingToEvent',
      'meeting_id': 'm1',
      'calendar_event_id': 'e1',
    });

    await calendar.unlinkMeeting('ws1', 'm1');
    expect(host.sentCalendarMeetingOps.last, {
      'op': 'calendar.unlinkMeeting',
      'meeting_id': 'm1',
    });

    final meeting = RpcMeetingRepository(client);
    await meeting.updateTitle(
      workspaceId: 'ws1',
      meetingId: 'm1',
      title: 'Standup',
    );
    expect(host.sentCalendarMeetingOps.last, {
      'op': 'meeting.updateTitle',
      'meeting_id': 'm1',
      'title': 'Standup',
    });
  });

  test(
      'RpcMeetingRecordingControl round-trips start/ingest/stop (op names + '
      'base64 PCM payload) and reads back the server-minted meeting id',
      () async {
    final control = RpcMeetingRecordingControl(client);

    // start → server mints + returns the meeting id.
    final meetingId = await control.startRecording(
      title: 'Standup',
      mode: 'remote',
    );
    expect(meetingId, 'm-fake');
    expect(host.sentRecordingOps.last, {
      'op': 'meeting.startRecording',
      'title': 'Standup',
      'mode': 'remote',
    });

    // ingest → PCM travels base64-encoded in the JSON envelope.
    final pcm = Uint8List.fromList([0, 1, 2, 3, 250, 251, 252, 253]);
    await control.ingestAudio(
      meetingId: meetingId,
      channel: 'me',
      seq: 0,
      pcm: pcm,
    );
    final ingest = host.sentRecordingOps.last;
    expect(ingest['op'], 'meeting.ingestAudio');
    expect(ingest['meeting_id'], 'm-fake');
    expect(ingest['channel'], 'me');
    expect(ingest['seq'], 0);
    expect(base64Decode(ingest['pcm'] as String), pcm);

    // stop → fires the host's summary path; instructions omitted when null.
    await control.stopRecording(meetingId: meetingId);
    expect(host.sentRecordingOps.last, {
      'op': 'meeting.stopRecording',
      'meeting_id': 'm-fake',
    });
  });

  test('RpcAgentRepository maps watch/getById/findByName to entities', () async {
    final repo = RpcAgentRepository(client);

    final live = await repo.watchByWorkspace('ws1').first;
    expect(live.single.id, 'a1');
    expect(live.single.name, 'Ada');
    expect(live.single.skills.toList(), ['dart', 'flutter']);
    expect(live.single.workspaceId, 'ws1');

    final all = await repo.watchAll().first;
    expect(all.single.id, 'a1');

    final one = await repo.getById('a1');
    expect(one, isNotNull);
    expect(one!.name, 'Ada');
    expect(one.title, 'Engineer');

    final byName = await repo.findByWorkspaceAndName('ws1', 'Bob');
    expect(byName, isNotNull);
    expect(byName!.name, 'Bob');
  });

  test('RpcAgentRepository upsert + delete reach the host', () async {
    final repo = RpcAgentRepository(client);
    final agent = Agent(
      id: 'a9',
      name: 'Zed',
      title: 'Engineer',
      agentMdPath: '/ws/agents/a9/AGENTS.md',
      workspaceId: 'ws1',
      skills: AgentSkills(const ['dart']),
      createdAt: DateTime.utc(2026),
    );
    await repo.upsert(agent);
    expect(host.sentAgents.last['agent'], isA<Map<dynamic, dynamic>>());
    expect(
      (host.sentAgents.last['agent'] as Map)['id'],
      'a9',
    );

    await repo.delete('a9');
    expect(host.sentAgents.last['agent_id'], 'a9');
  });

  test('RpcRepoRepository maps watch + getById; upsert returns id', () async {
    final repo = RpcRepoRepository(client);

    final live = await repo.watchAll().first;
    expect(live.single.id, 'r1');
    expect(live.single.githubOwner, 'acme');

    final one = await repo.getById('r1');
    expect(one, isNotNull);
    expect(one!.name, 'cc');

    final id = await repo.upsert(
      Repo(
        id: 'r2',
        name: 'tool',
        path: '/repos/r2',
        githubOwner: 'acme',
        githubRepoName: 'tool',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    expect(id, 'r-new');
    expect((host.sentRepos.last['repo'] as Map)['id'], 'r2');
  });

  test('RpcChannelReadRepository marks read + maps watch to DateTime', () async {
    final repo = RpcChannelReadRepository(client);

    await repo.markChannelRead('c1');
    expect(host.sentReadCursors.single['channel_id'], 'c1');

    final cursor = await repo.watchUserLastReadAt('c1').first;
    expect(cursor, DateTime.parse('2026-01-03T00:00:00.000Z'));
  });

  test('RpcMemoryDomainRepository maps watch/get/findByName; upsert reaches host', () async {
    final repo = RpcMemoryDomainRepository(client);

    final live = await repo.watchByWorkspace('ws1').first;
    expect(live.single.id, 'd1');
    expect(live.single.name, 'architecture');
    expect(live.single.workspaceId, 'ws1');
    expect(live.single.createdByRole, 'ceo');

    final all = await repo.getByWorkspace('ws1');
    expect(all.single.id, 'd1');
    expect(all.single.label, 'Architecture');

    final byName = await repo.findByName('ws1', 'security');
    expect(byName, isNotNull);
    expect(byName!.name, 'security');

    final domain = MemoryDomain(
      id: 'd9',
      workspaceId: 'ws1',
      name: 'testing',
      label: 'Testing',
      description: 'how we test',
      createdAt: DateTime.utc(2026),
      createdByRole: 'ceo',
    );
    await repo.upsert(domain);
    expect(host.sentMemoryDomains.last['domain'], isA<Map<dynamic, dynamic>>());
    expect(
      (host.sentMemoryDomains.last['domain'] as Map)['id'],
      'd9',
    );
  });

  test('RpcMemoryAccessGrantRepository maps watch/getByWorkspace + writes reach the host', () async {
    final repo = RpcMemoryAccessGrantRepository(client);

    final live = await repo.watchByWorkspace('ws1').first;
    expect(live.single.workspaceId, 'ws1');
    expect(live.single.agentRole, AgentRole.coder);
    expect(live.single.memoryDomain, 'docs');
    expect(live.single.permission, MemoryPermission.write);

    final all = await repo.getByWorkspace('ws1');
    expect(all.single.permission, MemoryPermission.read);

    final grant = MemoryAccessGrant(
      workspaceId: 'ws1',
      agentRole: AgentRole.reviewer,
      memoryDomain: 'design',
      permission: MemoryPermission.write,
    );
    await repo.upsert(grant);
    expect((host.sentGrants.last['grant'] as Map)['agent_role'], 'reviewer');
    expect((host.sentGrants.last['grant'] as Map)['permission'], 'write');

    await repo.upsertAll([grant]);
    expect(host.sentGrants.last['grants'], isA<List<dynamic>>());
    expect(
      ((host.sentGrants.last['grants'] as List).first as Map)['memory_domain'],
      'design',
    );
  });

  test(
    'RpcAgentWorkingMemoryRepository maps watch/getByAgent + upsert round-trip',
    () async {
      final repo = RpcAgentWorkingMemoryRepository(client);

      final live = await repo.watchByWorkspace('ws1').first;
      expect(live.single.id, 'wm1');
      expect(live.single.agentId, 'a1');
      expect(live.single.content, 'remember: ship it');
      expect(live.single.workspaceId, 'ws1');

      final forAgent = await repo.watchByAgent('ws1', 'a1').first;
      expect(forAgent, isNotNull);
      expect(forAgent!.id, 'wm1');

      final one = await repo.getByAgent('ws1', 'a1');
      expect(one, isNotNull);
      expect(one!.agentId, 'a1');
      expect(one.content, 'remember: ship it');

      await repo.upsert(
        AgentWorkingMemory(
          id: 'wm9',
          workspaceId: 'ws1',
          agentId: 'a9',
          content: 'fresh notes',
          updatedAt: DateTime.utc(2026),
        ),
      );
      expect(host.sentWorkingMemories.last['memory'], isA<Map<dynamic, dynamic>>());
      expect(
        (host.sentWorkingMemories.last['memory'] as Map)['id'],
        'wm9',
      );
    },
  );

  test('RpcReviewChannelRepository round-trips create/updateStatus/watch', () async {
    final repo = RpcReviewChannelRepository(client);

    final byWorkspace = await repo.watchByWorkspace('ws1').first;
    expect(byWorkspace.single.id, 'rc1');
    expect(byWorkspace.single.channelId, 'c1');
    expect(byWorkspace.single.workspaceId, 'ws1');
    expect(byWorkspace.single.status, ReviewChannelStatus.requested);

    final byPr = await repo.watchByPr('ws1', 'pr-node-1').first;
    expect(byPr, isNotNull);
    expect(byPr!.prNodeId, 'pr-node-1');

    final byChannel = await repo.watchByChannel('c1').first;
    expect(byChannel, isNotNull);
    expect(byChannel!.channelId, 'c1');

    final created = await repo.create(
      channelId: 'c1',
      workspaceId: 'ws1',
      prNodeId: 'pr-node-9',
      prNumber: 99,
      repoFullName: 'acme/cc',
    );
    expect(created.id, 'rc-new');
    expect(created.prNumber, 99);
    expect(host.sentReviewChannels.last['pr_node_id'], 'pr-node-9');

    await repo.updateStatus('rc-new', ReviewChannelStatus.completed);
    expect(host.sentReviewChannels.last['status'], 'completed');
  });

  test('RpcMemoryPolicyRepository round-trips watch/get/active + upsert/delete',
      () async {
    final repo = RpcMemoryPolicyRepository(client);

    final live = await repo.watchByWorkspace('ws1').first;
    expect(live.single.id, 'p1');
    expect(live.single.domain, 'coding');
    expect(live.single.rule, 'always cite sources');
    expect(live.single.sourceFactIds, ['f1', 'f2']);
    expect(live.single.requiredRole, AgentRole.reviewer);
    expect(live.single.workspaceId, 'ws1');

    final all = await repo.getByWorkspace('ws1');
    expect(all.single.id, 'p1');

    final one = await repo.getById('ws1', 'p1');
    expect(one, isNotNull);
    expect(one!.domain, 'coding');

    final active = await repo.getActiveByWorkspace('ws1', domain: 'review');
    expect(active.single.domain, 'review');

    final policy = MemoryPolicy(
      id: 'p9',
      workspaceId: 'ws1',
      domain: 'security',
      rule: 'never log secrets',
      sourceFactIds: const ['f3'],
      requiredRole: AgentRole.security,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await repo.upsert(policy);
    expect(host.sentPolicies.last['policy'], isA<Map<dynamic, dynamic>>());
    expect((host.sentPolicies.last['policy'] as Map)['id'], 'p9');
    expect(
      (host.sentPolicies.last['policy'] as Map)['required_role'],
      'security',
    );

    await repo.delete('ws1', 'p9');
    expect(host.sentPolicies.last['id'], 'p9');
  });

  test('RpcAgentRunLogRepository round-trips reads/watches/upsert', () async {
    final repo = RpcAgentRunLogRepository(client);

    final live = await repo.watchByAgent('ws1', 'a1').first;
    expect(live.single.id, 'rl1');
    expect(live.single.agentId, 'a1');
    expect(live.single.status, RunStatus.running);
    expect(live.single.cost.inputTokens, 10);
    expect(live.single.cost.outputTokens, 20);
    expect(live.single.workspaceId, 'ws1');

    final active = await repo.watchActiveByConversation('ws1', 'conv-1').first;
    expect(active.single.id, 'rl1');

    final all = await repo.watchAll().first;
    expect(all.single.id, 'rl1');

    final one = await repo.getById('rl1');
    expect(one, isNotNull);
    expect(one!.agentId, 'a1');

    final activeRun = await repo.activeRunForAgent('a1');
    expect(activeRun, isNotNull);
    expect(activeRun!.agentId, 'a1');

    final byRun = await repo.forPipelineRun('ws1', 'pr-1');
    expect(byRun.single.pipelineRunId, 'pr-1');

    final byStep = await repo.forPipelineStep('ws1', 'pr-1', 'step-1');
    expect(byStep.single.pipelineRunId, 'pr-1');
    expect(byStep.single.pipelineStepRunId, 'step-1');

    final log = AgentRunLog(
      id: 'rl9',
      agentId: 'a1',
      workspaceId: 'ws1',
      startedAt: DateTime.utc(2026),
      status: RunStatus.completed,
    );
    await repo.upsert(log);
    expect((host.sentRunLogs.last['log'] as Map)['id'], 'rl9');
    expect((host.sentRunLogs.last['log'] as Map)['status'], 'completed');
  });

  test(
    'RpcPipelineTemplateRepository round-trips reads/watch/upsert/delete',
    () async {
      final repo = RpcPipelineTemplateRepository(client);

      final live = await repo.watchForWorkspace('ws1').first;
      expect(live.single.templateId, 'pt1');
      expect(live.single.workspaceId, 'ws1');
      expect(live.single.name, 'PR review');
      expect(live.single.isBuiltIn, isTrue);
      // Graph + inputs round-trip losslessly.
      expect(live.single.steps.length, 2);
      expect(live.single.entryStep.kind, StepKind.trigger);
      expect(
        live.single.steps.last.triggers.single.sourceStepIds,
        ['trigger'],
      );
      expect(live.single.steps.last.config.agentId, 'a1');
      expect(live.single.steps.last.config.outputKey, 'result');
      expect(live.single.inputs.single.key, 'topic');
      expect(live.single.inputs.single.required, isTrue);

      final all = await repo.forWorkspace('ws1');
      expect(all.single.templateId, 'pt1');

      final one = await repo.getById('ws1', 'pt1');
      expect(one, isNotNull);
      expect(one!.name, 'PR review');

      final definition = PipelineDefinition(
        templateId: 'pt9',
        workspaceId: 'ws1',
        name: 'Hello',
        steps: [
          PipelineStepDefinition(
            id: 'trigger',
            kind: StepKind.trigger,
            bodyKey: 'pipeline.trigger',
          ),
          PipelineStepDefinition(
            id: 'work',
            kind: StepKind.terminal,
            bodyKey: 'pipeline.promptAgent',
            triggers: const [StepTrigger(sourceStepIds: ['trigger'])],
            config: const PipelineNodeConfig(agentId: 'a1', outputKey: 'out'),
          ),
        ],
      );
      await repo.upsert(definition);
      expect((host.sentTemplates.last['template'] as Map)['template_id'], 'pt9');
      expect(
        ((host.sentTemplates.last['template'] as Map)['steps'] as List).length,
        2,
      );

      final deleted = await repo.deleteById('ws1', 'pt9');
      expect(deleted, 1);
      expect(host.sentTemplates.last['template_id'], 'pt9');
    },
  );

  test(
    'RpcIsolatedRepoRepository maps reads/watch + upsert/delete to entities',
    () async {
      final repo = RpcIsolatedRepoRepository(client);

      final live = await repo.watchForWorkspace('ws1').first;
      expect(live.single.id, 'ir1');
      expect(live.single.workspaceId, 'ws1');
      expect(live.single.channelId, 'c1');
      expect(live.single.backend, RepoIsolationBackend.rift);

      final unit = await repo.forUnitRepo('ws1', 'c1', 'r1');
      expect(unit, isNotNull);
      expect(unit!.channelId, 'c1');
      expect(unit.repoId, 'r1');

      final byChannel = await repo.forChannel('ws1', 'c1');
      expect(byChannel.single.channelId, 'c1');

      final byTicket = await repo.forTicket('ws1', 'tk1');
      expect(byTicket.single.ticketId, 'tk1');

      // Cross-workspace teardown lookups (declared exemptions).
      final acrossCh = await repo.forChannelAcrossWorkspaces('c1');
      expect(acrossCh.single.id, 'ir1');
      final acrossTk = await repo.forTicketAcrossWorkspaces('tk1');
      expect(acrossTk.single.ticketId, 'tk1');

      final entity = IsolatedRepo(
        id: 'ir9',
        workspaceId: 'ws1',
        channelId: 'c1',
        repoId: 'r1',
        path: '/ws/ws1/conversations/c1/repos/r1',
        branch: 'agent/c1',
        backend: RepoIsolationBackend.gitWorktree,
        sourcePath: '/repos/r1',
        createdAt: DateTime.utc(2026),
      );
      await repo.upsert(entity);
      expect((host.sentIsolatedRepos.last['repo'] as Map)['id'], 'ir9');
      expect((host.sentIsolatedRepos.last['repo'] as Map)['backend'], 'gitWorktree');

      await repo.deleteById('ir9');
      expect(host.sentIsolatedRepos.last['id'], 'ir9');
    },
  );

  test('RpcMemoryFactRepository round-trips reads/watch/upsert/delete', () async {
    final repo = RpcMemoryFactRepository(client);

    final live = await repo.watchByWorkspace('ws1').first;
    expect(live.single.id, 'mf1');
    expect(live.single.topic, 'preferences');
    expect(live.single.workspaceId, 'ws1');
    expect(live.single.authoredByRole, AgentRole.coder);

    final all = await repo.getByWorkspace('ws1');
    expect(all, hasLength(2));
    expect(all.first.sourceObservationIds, ['obs1', 'obs2']);

    final one = await repo.getById('ws1', 'mf1');
    expect(one, isNotNull);
    expect(one!.confidence, 0.9);

    final byTopic = await repo.getActiveByTopic('ws1', 'preferences');
    expect(byTopic.single.topic, 'preferences');

    final byAuthor = await repo.getByAuthor('ws1', 'agent-7');
    expect(byAuthor.single.authoredByAgentId, 'agent-7');

    final hits = await repo.search('ws1', 'pref');
    expect(hits.single.id, 'mf1');

    // Hybrid (embedding) search is host-only over the thin client.
    expect(
      () => repo.search('ws1', 'pref', queryEmbedding: Float32List(4)),
      throwsUnsupportedError,
    );

    final fact = MemoryFact(
      id: 'mf9',
      workspaceId: 'ws1',
      domain: 'memory',
      topic: 'goals',
      content: 'Ship the thin client',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await repo.upsert(fact);
    expect((host.sentFacts.last['fact'] as Map)['id'], 'mf9');

    await repo.delete('ws1', 'mf9');
    expect(host.sentFacts.last['fact_id'], 'mf9');
  });

  test('RpcVoiceProfileRepository round-trips watch/get/mutations', () async {
    final repo = RpcVoiceProfileRepository(client);

    final live = await repo.watchByWorkspace('ws1').first;
    expect(live.single.id, 'vp1');
    expect(live.single.displayName, 'Ada');
    expect(live.single.embedding, [0.1, 0.2, 0.3]);
    expect(live.single.sampleCount, 2);
    expect(live.single.workspaceId, 'ws1');

    final all = await repo.getByWorkspace('ws1');
    expect(all.single.id, 'vp1');

    final byName = await repo.getByName('ws1', 'Bob');
    expect(byName, isNotNull);
    expect(byName!.displayName, 'Bob');

    await repo.upsert(
      VoiceProfile(
        id: 'vp9',
        workspaceId: 'ws1',
        displayName: 'Zed',
        embedding: const [0.4, 0.5],
        sampleCount: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    expect((host.sentVoiceProfiles.last['profile'] as Map)['id'], 'vp9');

    await repo.enroll(
      workspaceId: 'ws1',
      displayName: 'Ada',
      sampleEmbedding: const [0.1, 0.2],
    );
    expect(host.sentVoiceProfiles.last['display_name'], 'Ada');
    expect(host.sentVoiceProfiles.last['sample_embedding'], [0.1, 0.2]);

    await repo.unenroll(
      workspaceId: 'ws1',
      displayName: 'Ada',
      sampleEmbedding: const [0.1, 0.2],
    );
    expect(host.sentVoiceProfiles.last['display_name'], 'Ada');

    await repo.rename(workspaceId: 'ws1', id: 'vp1', displayName: 'Ada B');
    expect(host.sentVoiceProfiles.last['id'], 'vp1');
    expect(host.sentVoiceProfiles.last['display_name'], 'Ada B');

    await repo.delete('ws1', 'vp1');
    expect(host.sentVoiceProfiles.last['id'], 'vp1');
  });

  test('RpcProjectRepository round-trips reads/watch + insert/update/delete', () async {
    final repo = RpcProjectRepository(client);

    final live = await repo.watchForWorkspace('ws1').first;
    expect(live.single.id, 'p1');
    expect(live.single.name, 'Live');
    expect(live.single.workspaceId, 'ws1');
    expect(live.single.color, ProjectColor.blue);
    expect(live.single.status, ProjectStatus.active);

    final all = await repo.getForWorkspace('ws1');
    expect(all, hasLength(2));
    expect(all.first.name, 'First');

    final one = await repo.getById('p1');
    expect(one, isNotNull);
    expect(one!.id, 'p1');

    final project = Project(
      id: 'p9',
      workspaceId: 'ws1',
      name: 'New project',
      color: ProjectColor.green,
      status: ProjectStatus.active,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await repo.insert(project);
    expect((host.sentProjects.last['project'] as Map)['id'], 'p9');
    expect((host.sentProjects.last['project'] as Map)['color'], 'green');

    final updated = await repo.update(project);
    expect(updated, 1);

    final deleted = await repo.delete('p9', workspaceId: 'ws1');
    expect(deleted, 1);
    expect(host.sentProjects.last['project_id'], 'p9');
  });

  test('RpcTicketLinkRepository round-trips insert/delete/get/watch', () async {
    final repo = RpcTicketLinkRepository(client);

    final live = await repo.watchForTicket('ws1', 't1').first;
    expect(live.single.id, 'tl1');
    expect(live.single.workspaceId, 'ws1');
    expect(live.single.sourceTicketId, 't1');
    expect(live.single.targetTicketId, 't2');
    expect(live.single.type, TicketLinkType.blocks);

    final forTicket = await repo.getForTicket('ws1', 't1');
    expect(forTicket.single.id, 'tl1');
    expect(forTicket.single.sourceTicketId, 't1');

    final link = TicketLink(
      id: 'tl9',
      workspaceId: 'ws1',
      sourceTicketId: 't1',
      targetTicketId: 't3',
      type: TicketLinkType.relatesTo,
      createdAt: DateTime.utc(2026),
    );
    await repo.insert(link);
    expect((host.sentTicketLinks.last['link'] as Map)['id'], 'tl9');
    expect((host.sentTicketLinks.last['link'] as Map)['type'], 'relates_to');

    final deletedById = await repo.deleteById('tl9', workspaceId: 'ws1');
    expect(deletedById, 1);
    expect(host.sentTicketLinks.last['id'], 'tl9');

    final deletedByEndpoints = await repo.deleteByEndpoints(
      workspaceId: 'ws1',
      sourceTicketId: 't1',
      targetTicketId: 't3',
      type: TicketLinkType.relatesTo,
    );
    expect(deletedByEndpoints, 1);
    expect(host.sentTicketLinks.last['source_ticket_id'], 't1');
    expect(host.sentTicketLinks.last['type'], 'relates_to');
  });

  test('RpcPipelineRunRepository round-trips runs/step-runs/watches', () async {
    final repo = RpcPipelineRunRepository(client);

    final liveRun = await repo.watchRun('pr1').first;
    expect(liveRun, isNotNull);
    expect(liveRun!.id, 'pr1');
    expect(liveRun.status, PipelineRunStatus.running);
    expect(liveRun.workspaceId, 'ws1');
    expect(liveRun.state['k'], 'v');
    expect(liveRun.totalCostCents, 7);
    expect(liveRun.totalTokens, 42);

    final all = await repo.watchAll().first;
    expect(all.single.id, 'pr1');

    final forWs = await repo.watchForWorkspace('ws1').first;
    expect(forWs.single.id, 'pr1');

    final liveSteps = await repo.watchStepRunsForPipeline('pr1').first;
    expect(liveSteps.single.id, 'sr1');
    expect(liveSteps.single.pipelineRunId, 'pr1');
    expect(liveSteps.single.status, PipelineStepStatus.running);

    final run = await repo.getRun('pr1');
    expect(run, isNotNull);
    expect(run!.templateId, 'tmpl-1');

    final pending = await repo.nonTerminalRuns();
    expect(pending.single.id, 'pr1');

    final active = await repo.activeForDedupKey(
      templateId: 'tmpl-1',
      workspaceId: 'ws1',
      dedupKey: 'dk-1',
    );
    expect(active, isNotNull);
    expect(active!.dedupKey, 'dk-1');

    final steps = await repo.stepRunsForPipeline('pr1');
    expect(steps.single.id, 'sr1');

    final step = await repo.getStepRunById('sr1');
    expect(step, isNotNull);
    expect(step!.pipelineRunId, 'pr1');

    final newRun = PipelineRun(
      id: 'pr9',
      templateId: 'tmpl-1',
      workspaceId: 'ws1',
      status: PipelineRunStatus.completed,
      startedAt: DateTime.utc(2026),
    );
    await repo.insertRun(newRun);
    expect((host.sentPipelineRuns.last['run'] as Map)['id'], 'pr9');
    expect((host.sentPipelineRuns.last['run'] as Map)['status'], 'completed');

    await repo.updateRun(newRun);
    expect((host.sentPipelineRuns.last['run'] as Map)['id'], 'pr9');

    await repo.updateRunState('pr9', {'phase': 'done'});
    expect(host.sentPipelineRuns.last['run_id'], 'pr9');
    expect((host.sentPipelineRuns.last['state'] as Map)['phase'], 'done');

    await repo.incrementCost('pr9', 12, 100);
    expect(host.sentPipelineRuns.last['cents'], 12);
    expect(host.sentPipelineRuns.last['tokens'], 100);

    await repo.deleteRun('ws1', 'pr9');
    expect(host.sentPipelineRuns.last['run_id'], 'pr9');

    await repo.updateStepRun(
      'sr9',
      status: PipelineStepStatus.completed,
      outputJson: '{"ok":true}',
    );
    expect(host.sentPipelineStepRuns.last['step_run_id'], 'sr9');
    expect(host.sentPipelineStepRuns.last['status'], 'completed');
    expect(host.sentPipelineStepRuns.last['output_json'], '{"ok":true}');

    await repo.deleteStepRun('sr9');
    expect(host.sentPipelineStepRuns.last['step_run_id'], 'sr9');
  });

  test('RpcPipelineTriggerRepository round-trips reads/watch/mutations', () async {
    final repo = RpcPipelineTriggerRepository(client);

    final live = await repo.watchForWorkspace('ws1').first;
    expect(live.single.id, 'pt1');
    expect(live.single.eventType, 'ExternalPrDetected');
    expect(live.single.workspaceId, 'ws1');
    expect(live.single.enabled, isTrue);

    final forWs = await repo.forWorkspace('ws1');
    expect(forWs.single.id, 'pt1');

    final enabled = await repo.enabledForEvent('ExternalPrDetected');
    expect(enabled.single.eventType, 'ExternalPrDetected');

    final one = await repo.getById('pt1');
    expect(one, isNotNull);
    expect(one!.eventType, 'ExternalPrDetected');

    final scheduled = await repo.scheduled();
    expect(scheduled.single.eventType, 'schedule');
    expect(scheduled.single.intervalSeconds, 60);

    final trigger = PipelineTrigger(
      id: 'pt9',
      eventType: 'PrMerged',
      templateId: 'tmpl-1',
      workspaceId: 'ws1',
      enabled: true,
      match: const {'status': 'merged'},
    );
    await repo.insert(trigger);
    expect((host.sentTriggers.last['trigger'] as Map)['id'], 'pt9');
    expect((host.sentTriggers.last['trigger'] as Map)['event_type'], 'PrMerged');
    expect(
      ((host.sentTriggers.last['trigger'] as Map)['match'] as Map)['status'],
      'merged',
    );

    await repo.update(trigger.copyWith(enabled: false));
    expect((host.sentTriggers.last['trigger'] as Map)['enabled'], false);

    await repo.markFired('pt9', DateTime.utc(2026, 2));
    expect(host.sentTriggers.last['id'], 'pt9');
    expect(host.sentTriggers.last['when'], '2026-02-01T00:00:00.000Z');

    await repo.deleteById('pt9');
    expect(host.sentTriggers.last['id'], 'pt9');
  });

  test('RpcTeamRepository round-trips teams/members + watches', () async {
    final repo = RpcTeamRepository(client);

    final liveTeams = await repo.watchTeamsForWorkspace('ws1').first;
    expect(liveTeams.single.id, 'tm1');
    expect(liveTeams.single.name, 'Platform');
    expect(liveTeams.single.workspaceId, 'ws1');

    final teams = await repo.teamsForWorkspace('ws1');
    expect(teams.single.id, 'tm1');
    expect(teams.single.description, 'A squad');

    final one = await repo.getTeam('tm1');
    expect(one, isNotNull);
    expect(one!.name, 'Platform');

    final liveMembers = await repo.watchMembersOf('tm1').first;
    expect(liveMembers.single.teamId, 'tm1');
    expect(liveMembers.single.agentId, 'a1');
    expect(liveMembers.single.role, TeamMemberRole.member);

    final members = await repo.membersOf('tm1');
    expect(members.single.agentId, 'a1');
    expect(members.single.role, TeamMemberRole.leader);

    final team = Team(
      id: 'tm9',
      workspaceId: 'ws1',
      name: 'Infra',
      createdAt: DateTime.utc(2026),
    );
    await repo.insertTeam(team);
    expect((host.sentTeams.last['team'] as Map)['id'], 'tm9');
    expect((host.sentTeams.last['team'] as Map)['name'], 'Infra');

    await repo.updateTeam(team.copyWith(name: 'Infra & SRE'));
    expect((host.sentTeams.last['team'] as Map)['name'], 'Infra & SRE');

    await repo.deleteTeam('tm9');
    expect(host.sentTeams.last['id'], 'tm9');

    await repo.addMember(
      TeamMember(teamId: 'tm1', agentId: 'a2', role: TeamMemberRole.leader),
    );
    expect((host.sentTeamMembers.last['member'] as Map)['agent_id'], 'a2');
    expect((host.sentTeamMembers.last['member'] as Map)['role'], 'leader');

    await repo.removeMember('tm1', 'a2');
    expect(host.sentTeamMembers.last['team_id'], 'tm1');
    expect(host.sentTeamMembers.last['agent_id'], 'a2');
  });

  test('RpcOrchestrationRepository round-trips reads/watches/insert/update', () async {
    final repo = RpcOrchestrationRepository(client);

    final live = await repo.watchForWorkspace('ws1').first;
    expect(live.single.id, 'orc1');
    expect(live.single.workspaceId, 'ws1');
    expect(live.single.status, OrchestrationStatus.proposed);
    expect(live.single.proposal.goal, 'ship it');

    final one = await repo.watchById('ws1', 'orc1').first;
    expect(one, isNotNull);
    expect(one!.id, 'orc1');

    final byId = await repo.getById('ws1', 'orc1');
    expect(byId, isNotNull);
    expect(byId!.id, 'orc1');

    final byTicket = await repo.forParentTicket('ws1', 't1');
    expect(byTicket!.parentTicketId, 't1');

    final byRun = await repo.forPipelineRun('ws1', 'pr-1');
    expect(byRun!.pipelineRunId, 'pr-1');

    final byRunAny = await repo.forPipelineRunAnyWorkspace('pr-1');
    expect(byRunAny!.pipelineRunId, 'pr-1');

    final approved = await repo.approvedNeedingMaterialization();
    expect(approved.single.status, OrchestrationStatus.approved);

    final orc = Orchestration(
      id: 'orc9',
      workspaceId: 'ws1',
      proposal: const OrchestrationProposal(
        goal: 'new ask',
        roles: [],
        subTickets: [],
        synthesis: SynthesisSpec(
          roleKey: 'lead',
          prompt: 'sum',
          outputSchema: {},
        ),
      ),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await repo.insert(orc);
    expect((host.sentOrchestrations.last['orchestration'] as Map)['id'], 'orc9');

    await repo.update(orc.copyWith(status: OrchestrationStatus.approved));
    expect(
      (host.sentOrchestrations.last['orchestration'] as Map)['status'],
      'approved',
    );
  });

  test('RpcMessagingRepository maps channels/messages/participants', () async {
    final repo = RpcMessagingRepository(client);

    final channels = await repo.watchChannels().first;
    expect(channels.single.id, 'c1');
    expect(channels.single.name, 'general');
    expect(channels.single.workspaceId, 'ws1');
    expect(channels.single.mode, ConversationMode.chat);

    // watchChannelsByWorkspace resolves to the bound-workspace channel stream.
    final scoped = await repo.watchChannelsByWorkspace('ws1').first;
    expect(scoped.single.id, 'c1');

    final messages = await repo.watchMessages('c1').first;
    expect(messages.single.id, 'm1');
    expect(messages.single.channelId, 'c1');
    expect(messages.single.senderType, ChannelSenderType.user);

    final topLevel = await repo.watchTopLevelMessages('c1').first;
    expect(topLevel.single.channelId, 'c1');

    final window = await repo.watchTopLevelMessagesWindow('c1', limit: 50).first;
    expect(window.messages.single.id, 'm1');
    expect(window.hasMore, isFalse);

    final thread = await repo.watchThread('m1').first;
    expect(thread.single.id, 'm-reply');
    expect(thread.single.parentMessageId, 'm1');

    final participants = await repo.watchParticipants('c1').first;
    expect(participants.single.id, 'p1');
    expect(participants.single.agentId, 'user');
    expect(participants.single.isUser, isTrue);

    final byId = await repo.getMessageById('m9');
    expect(byId, isNotNull);
    expect(byId!.id, 'm9');

    expect(await repo.channelExists('c1'), isTrue);

    final got = await repo.getMessages('c1');
    expect(got.single.channelId, 'c1');

    final gotParticipants = await repo.getParticipants('c1');
    expect(gotParticipants.single.id, 'p1');
  });

  test('RpcMessagingRepository mutations reach the host', () async {
    final repo = RpcMessagingRepository(client);

    final messageId = await repo.sendMessage(
      channelId: 'c1',
      content: 'system notice',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
      metadata: const {'status': 'approved'},
    );
    expect(messageId, 'm-new');
    expect(host.sentMessages.last['sender_type'], 'agent');
    expect(host.sentMessages.last['sender_id'], 'system');
    expect(host.sentMessages.last['message_type'], 'system');

    await repo.updateMessage('m1', metadata: const {'status': 'dismissed'});
    expect(host.sentMessagingMutations.last['op'], 'messaging.updateMessage');
    expect(host.sentMessagingMutations.last['message_id'], 'm1');

    await repo.setChannelMode('c1', ConversationMode.review);
    expect(host.sentMessagingMutations.last['op'], 'messaging.setChannelMode');
    expect(host.sentMessagingMutations.last['mode'], 'review');

    await repo.addParticipant('c1', 'a7');
    expect(host.sentMessagingMutations.last['op'], 'messaging.addParticipant');
    expect(host.sentMessagingMutations.last['agent_id'], 'a7');
  });

  test('RpcMessagingRepository host-owned ops throw UnsupportedError', () async {
    final repo = RpcMessagingRepository(client);
    expect(() => repo.openDm('a1'), throwsUnsupportedError);
    expect(
      () => repo.createGroup('g', const ['a1']),
      throwsUnsupportedError,
    );
    expect(() => repo.deleteChannel('c1'), throwsUnsupportedError);
    expect(() => repo.clearChannelMessages('c1'), throwsUnsupportedError);
    expect(() => repo.removeParticipant('c1', 'a1'), throwsUnsupportedError);
    expect(() => repo.markCompacted(const ['m1']), throwsUnsupportedError);
    expect(
      () => repo.getMessagesWithEmbedding('c1'),
      throwsUnsupportedError,
    );
    expect(repo.getMessagesWithoutEmbedding, throwsUnsupportedError);
    expect(
      () => repo.updateChannelName('c1', 'x'),
      throwsUnsupportedError,
    );
  });

  test('RpcMessagingPort channel lifecycle reaches the host over messaging.* '
      'ops (works on a headless server)', () async {
    final port = RpcMessagingPort(client);

    final dm = await port.openDm('a1');
    expect(dm.id, 'dm-1');
    expect(host.sentMessagingMutations.last['op'], 'messaging.openDm');
    expect(host.sentMessagingMutations.last['agent_id'], 'a1');

    final group = await port.createGroup('Team', const ['a1', 'a2']);
    expect(group.id, 'grp-1');
    expect(group.name, 'Team');
    expect(host.sentMessagingMutations.last['op'], 'messaging.createGroup');

    await port.clearChannelMessages('c1');
    expect(
      host.sentMessagingMutations.last['op'],
      'messaging.clearChannelMessages',
    );

    await port.removeParticipant('c1', 'a1');
    expect(host.sentMessagingMutations.last, {
      'op': 'messaging.removeParticipant',
      'channel_id': 'c1',
      'agent_id': 'a1',
    });

    await port.deleteChannel('c1');
    expect(host.sentMessagingMutations.last['op'], 'messaging.deleteChannel');
    expect(host.sentMessagingMutations.last['channel_id'], 'c1');
  });

  test('RpcWorkspaceRepository maps watchAll + repo links', () async {
    final repo = RpcWorkspaceRepository(client);

    final live = await repo.watchAll().first;
    expect(live.single.id, 'ws1');
    expect(live.single.name, 'Alpha');
    expect(live.single.logoPath, '/logos/ws1.png');
    expect(live.single.reviewConcurrency, 5);

    final repos = await repo.watchReposForWorkspace('ws1').first;
    expect(repos.single.id, 'r1');
    expect(repos.single.githubOwner, 'acme');

    expect(await repo.isRepoLinkedToWorkspace('ws1', 'r1'), isTrue);
  });

  test('RpcWorkspaceRepository upsert/delete/link reach the host', () async {
    final repo = RpcWorkspaceRepository(client);

    final id = await repo.upsert(
      Workspace(
        id: 'ws9',
        name: 'Gamma',
        reviewConcurrency: 2,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    expect(id, 'ws-new');
    expect((host.sentWorkspaces.last['workspace'] as Map)['id'], 'ws9');
    expect((host.sentWorkspaces.last['workspace'] as Map)['name'], 'Gamma');

    await repo.delete('ws9');
    expect(host.sentWorkspaces.last['id'], 'ws9');

    // The server is stateless, so the target workspace rides in the args of
    // every repo-link op (no session binding to infer it from).
    await repo.linkRepoToWorkspace('ws1', 'r1');
    expect(
      host.sentWorkspaceRepoLinks.last['op'],
      'workspace.linkRepoToWorkspace',
    );
    expect(host.sentWorkspaceRepoLinks.last['workspace_id'], 'ws1');
    expect(host.sentWorkspaceRepoLinks.last['repo_id'], 'r1');

    await repo.unlinkRepoFromWorkspace('ws1', 'r1');
    expect(
      host.sentWorkspaceRepoLinks.last['op'],
      'workspace.unlinkRepoFromWorkspace',
    );
    expect(host.sentWorkspaceRepoLinks.last['workspace_id'], 'ws1');

    await repo.setReposForWorkspace('ws1', const ['r1', 'r2']);
    expect(
      host.sentWorkspaceRepoLinks.last['op'],
      'workspace.setReposForWorkspace',
    );
    expect(host.sentWorkspaceRepoLinks.last['workspace_id'], 'ws1');
    expect(host.sentWorkspaceRepoLinks.last['repo_ids'], ['r1', 'r2']);
  });

  test('RpcPrReviewRepository maps PR watches to entities', () async {
    final repo = RpcPrReviewRepository(
      client,
      workspaceId: 'ws1',
      owner: 'acme',
      repo: 'cc',
    );

    final pr = await repo.watchPullRequest(7).first;
    expect(pr, isNotNull);
    expect(pr!.number, 7);
    expect(pr.title, 'Add feature');
    expect(pr.state, PrState.open);
    expect(pr.author?.login, 'octocat');
    expect(pr.requestedReviewers.single.login, 'octocat');
    expect(pr.changedFiles, 3);
    expect(pr.mergeableState, PrMergeableState.clean);
    expect(pr.checksStatus, PrChecksStatus.passing);
    expect(pr.reactions.single.content, '+1');
    expect(pr.reactions.single.emoji, '👍');
    expect(pr.reactions.single.userReacted, isTrue);

    final diff = await repo.watchDiff(7).first;
    expect(diff, contains('+new'));

    final files = await repo.watchFiles(7).first;
    expect(files.single.filename, 'lib/main.dart');
    expect(files.single.status, PrFileStatus.modified);
    expect(files.single.viewerViewedState, PrFileViewedState.viewed);

    final commitFiles = await repo.watchCommitFiles('abc1234567').first;
    expect(commitFiles.single.filename, 'lib/main.dart');

    final content = await repo.watchFileContent('lib/main.dart', 'main').first;
    expect(content, 'final x = 1;');

    final commits = await repo.watchCommits(7).first;
    expect(commits.single.sha, 'abc1234567');
    expect(commits.single.title, 'Fix bug');

    final reviews = await repo.watchReviews(7).first;
    expect(reviews.single.state, PrReviewSubmissionState.approved);
    expect(reviews.single.author?.login, 'octocat');

    final reviewComments = await repo.watchReviewComments(7).first;
    expect(reviewComments.single.id, 11);
    expect(reviewComments.single.path, 'lib/main.dart');

    final issueComments = await repo.watchIssueComments(7).first;
    expect(issueComments.single.id, 22);

    final checks = await repo.watchCheckRuns(7).first;
    expect(checks.single.name, 'build');
    expect(checks.single.conclusion, CheckRunConclusion.success);
    expect(checks.single.workflowName, 'CI');

    final reviewers = await repo.watchReviewers(7).first;
    expect(reviewers.length, 2);
    final user = reviewers.whereType<PrUserReviewer>().single;
    expect(user.user.login, 'octocat');
    expect(user.isCodeOwner, isTrue);
    final team = reviewers.whereType<PrTeamReviewer>().single;
    expect(team.slug, 'platform');
    expect(team.state, PrReviewSubmissionState.approved);
    expect(team.reviewedBy?.login, 'reviewer');
  });

  test('RpcPrReviewRepository round-trips reads + previews', () async {
    final repo = RpcPrReviewRepository(
      client,
      workspaceId: 'ws1',
      owner: 'acme',
      repo: 'cc',
    );

    expect(await repo.getDraft(7), 'WIP review notes');
    expect(host.sentPrReviewOps.last['owner'], 'acme');
    expect(host.sentPrReviewOps.last['repo'], 'cc');
    expect(host.sentPrReviewOps.last['pr_number'], 7);

    final users = await repo.listAssignableUsers();
    expect(users.single.login, 'octocat');

    final candidates = await repo.listRequestableReviewers();
    expect(candidates.length, 2);
    expect(candidates.first.kind, ReviewerKind.user);
    expect(candidates.last.kind, ReviewerKind.team);
    expect(candidates.last.key, 'platform');

    final prPreview = await repo.prPreview(7);
    expect(prPreview, isNotNull);
    expect(prPreview!.title, 'Add feature');
    expect(prPreview.isMerged, isFalse);
    expect(host.sentPrReviewOps.last['op'], 'pr_review.prPreview');
    expect(host.sentPrReviewOps.last['number'], 7);

    final commitPreview = await repo.commitPreview('abc1234');
    expect(commitPreview, isNotNull);
    expect(commitPreview!.shortSha, 'abc1234');
    expect(host.sentPrReviewOps.last['op'], 'pr_review.commitPreview');
    expect(host.sentPrReviewOps.last['sha'], 'abc1234');
  });

  test('RpcPrReviewRepository mutations reach the host with coords', () async {
    final repo = RpcPrReviewRepository(
      client,
      workspaceId: 'ws1',
      owner: 'acme',
      repo: 'cc',
    );

    final posted = await repo.postReviewComment(
      prNumber: 7,
      commitSha: 'headsha',
      path: 'lib/main.dart',
      line: 10,
      side: 'RIGHT',
      body: 'nit',
    );
    expect(posted['id'], 999);
    expect(host.sentPrReviewOps.last['op'], 'pr_review.postReviewComment');
    expect(host.sentPrReviewOps.last['owner'], 'acme');
    expect(host.sentPrReviewOps.last['commit_sha'], 'headsha');

    await repo.upsertDraft(7, 'draft text');
    expect(host.sentPrReviewOps.last['op'], 'pr_review.upsertDraft');
    expect(host.sentPrReviewOps.last['text'], 'draft text');

    await repo.markFileAsViewed(
      prNumber: 7,
      nodeId: 'PR_node',
      path: 'lib/main.dart',
      viewed: true,
    );
    expect(host.sentPrReviewOps.last['op'], 'pr_review.markFileAsViewed');
    expect(host.sentPrReviewOps.last['viewed'], isTrue);

    final merged = await repo.mergePullRequest(
      prNumber: 7,
      mergeMethod: 'squash',
    );
    expect(merged['merged'], isTrue);
    expect(host.sentPrReviewOps.last['op'], 'pr_review.mergePullRequest');
    expect(host.sentPrReviewOps.last['merge_method'], 'squash');

    await repo.submitReview(prNumber: 7, event: 'APPROVE', body: 'great');
    expect(host.sentPrReviewOps.last['op'], 'pr_review.submitReview');
    expect(host.sentPrReviewOps.last['event'], 'APPROVE');

    await repo.requestReviewers(
      prNumber: 7,
      userLogins: const ['octocat'],
      teamSlugs: const ['platform'],
    );
    expect(host.sentPrReviewOps.last['op'], 'pr_review.requestReviewers');
    expect(host.sentPrReviewOps.last['user_logins'], ['octocat']);
    expect(host.sentPrReviewOps.last['team_slugs'], ['platform']);

    final url = await repo.uploadContent('x.png', 'YmFzZTY0', 'add image');
    expect(url, contains('x.png'));
    expect(host.sentPrReviewOps.last['op'], 'pr_review.uploadContent');
  });

  test('RpcVcsProviderFactory builds an RpcPrReviewRepository', () async {
    final factory = RpcVcsProviderFactory(client);
    expect(factory.host, VcsHost.github);
    final repo = factory.create(
      VcsProviderContext(
        repo: Repo(
          id: 'r1',
          name: 'cc',
          path: '/tmp/cc',
          githubOwner: 'acme',
          githubRepoName: 'cc',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
        workspaceId: 'ws1',
      ),
    );
    expect(repo, isA<RpcPrReviewRepository>());
    // The created repository resolves over the same client (owner/repo carried).
    final pr = await repo.watchPullRequest(7).first;
    expect(pr?.number, 7);
  });
}
