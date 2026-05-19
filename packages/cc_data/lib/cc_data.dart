/// Remote data layer for Control Center.
///
/// Repository adapters that satisfy reads/writes over the `cc_rpc` client
/// (`repo/call` + `sub/subscribe`) instead of a local database — the data
/// source for the full web build and the desktop in REMOTE mode. They return
/// the `cc_domain` wire DTOs and carry no `workspace_id`: the host binds the
/// authoritative workspace per session, so isolation is enforced server-side.
///
/// Web-safe — depends only on `cc_domain` + `cc_rpc` (no `dart:io`/`dart:ffi`,
/// no Flutter). The desktop in LOCAL mode keeps its Drift-backed repositories;
/// a composition root picks local vs. remote.
library;

export 'src/repositories/pr_dto_mapping.dart'
    show pullRequestFromWireDto, prFileFromWireDto, prCommitFromWireDto;
export 'src/repositories/remote_achievement_repository.dart';
export 'src/repositories/remote_activity_log.dart';
export 'src/repositories/remote_agent_repository.dart';
export 'src/repositories/remote_agent_run_log_repository.dart';
export 'src/repositories/remote_agent_working_memory_repository.dart';
export 'src/repositories/remote_analytics_repository.dart';
export 'src/repositories/remote_calendar_connect.dart';
export 'src/repositories/remote_calendar_repository.dart';
export 'src/repositories/remote_channel_read_repository.dart';
export 'src/repositories/remote_confirmation_repository.dart';
export 'src/repositories/remote_ide_repository.dart';
export 'src/repositories/remote_isolated_repo_repository.dart';
export 'src/repositories/remote_meeting_repository.dart';
export 'src/repositories/remote_memory_access_grant_repository.dart';
export 'src/repositories/remote_memory_domain_repository.dart';
export 'src/repositories/remote_memory_fact_repository.dart';
export 'src/repositories/remote_memory_policy_repository.dart';
export 'src/repositories/remote_messaging_dispatch.dart';
export 'src/repositories/remote_messaging_repository.dart';
export 'src/repositories/remote_newsfeed_repository.dart';
export 'src/repositories/remote_orchestration_actions.dart';
export 'src/repositories/remote_orchestration_repository.dart';
export 'src/repositories/remote_pairing_repository.dart';
export 'src/repositories/remote_pipeline_engine.dart';
export 'src/repositories/remote_pipeline_run_repository.dart';
export 'src/repositories/remote_pipeline_template_repository.dart';
export 'src/repositories/remote_pipeline_trigger_repository.dart';
export 'src/repositories/remote_pr_lifecycle_repository.dart';
export 'src/repositories/remote_project_repository.dart';
export 'src/repositories/remote_repo_repository.dart';
export 'src/repositories/remote_review_channel_repository.dart';
export 'src/repositories/remote_review_dispatch.dart';
export 'src/repositories/remote_sandbox_detector.dart';
export 'src/repositories/remote_streak_repository.dart';
export 'src/repositories/remote_team_repository.dart';
export 'src/repositories/remote_terminal_repository.dart';
export 'src/repositories/remote_ticket_link_repository.dart';
export 'src/repositories/remote_ticket_repository.dart';
export 'src/repositories/remote_voice_profile_repository.dart';
export 'src/repositories/remote_workspace_repository.dart';
export 'src/repositories/rpc_achievement_repository.dart';
export 'src/repositories/rpc_acp_model_repository.dart';
export 'src/repositories/rpc_adapter_repository.dart';
export 'src/repositories/rpc_agent_repository.dart';
export 'src/repositories/rpc_agent_run_log_repository.dart';
export 'src/repositories/rpc_agent_working_memory_repository.dart';
export 'src/repositories/rpc_analytics_repository.dart';
export 'src/repositories/rpc_calendar_repository.dart';
export 'src/repositories/rpc_channel_read_repository.dart';
export 'src/repositories/rpc_directory_browser_port.dart';
export 'src/repositories/rpc_github_cli_port.dart';
export 'src/repositories/rpc_isolated_repo_repository.dart';
export 'src/repositories/rpc_meeting_recording_control.dart';
export 'src/repositories/rpc_meeting_repository.dart';
export 'src/repositories/rpc_memory_access_grant_repository.dart';
export 'src/repositories/rpc_memory_domain_repository.dart';
export 'src/repositories/rpc_memory_fact_repository.dart';
export 'src/repositories/rpc_memory_policy_repository.dart';
export 'src/repositories/rpc_messaging_port.dart';
export 'src/repositories/rpc_messaging_repository.dart';
export 'src/repositories/rpc_newsfeed_repository.dart';
export 'src/repositories/rpc_open_pr_list_repository.dart';
export 'src/repositories/rpc_orchestration_repository.dart';
export 'src/repositories/rpc_pipeline_engine_port.dart';
export 'src/repositories/rpc_pipeline_run_repository.dart';
export 'src/repositories/rpc_pipeline_template_repository.dart';
export 'src/repositories/rpc_pipeline_trigger_repository.dart';
export 'src/repositories/rpc_pr_lifecycle_repository.dart';
export 'src/repositories/rpc_pr_review_repository.dart';
export 'src/repositories/rpc_pr_search_port.dart';
export 'src/repositories/rpc_process_detection_port.dart';
export 'src/repositories/rpc_project_repository.dart';
export 'src/repositories/rpc_repo_repository.dart';
export 'src/repositories/rpc_review_channel_repository.dart';
export 'src/repositories/rpc_streak_repository.dart';
export 'src/repositories/rpc_team_repository.dart';
export 'src/repositories/rpc_ticket_link_repository.dart';
export 'src/repositories/rpc_ticket_repository.dart';
export 'src/repositories/rpc_voice_profile_repository.dart';
export 'src/repositories/rpc_workspace_filesystem_port.dart';
export 'src/repositories/rpc_workspace_repository.dart';
