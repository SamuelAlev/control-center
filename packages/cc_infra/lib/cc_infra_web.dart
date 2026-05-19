/// Web-safe subset of the cc_infra surface.
///
/// The full `package:cc_infra/cc_infra.dart` barrel re-exports files that
/// transitively reach `dart:ffi` (code-graph tree-sitter, embeddings/onnx,
/// rift worktrees, terminal sessions, dispatch/embedding chains). Importing
/// that barrel from web-reachable app code (`lib/`) breaks `flutter build web`
/// — the CFE aborts with "library 'dart:ffi' is not available on this
/// platform". The `architecture_constraints_test.dart` web-reachability guard
/// enforces this and documents the workaround.
///
/// This barrel exports ONLY the ffi-free subset, computed by the same
/// transitive reachability the guard uses (BFS through cc_infra + cc_natives
/// src files, flagging any file that reaches `dart:ffi`/`onnxruntime`/
/// `sherpa_onnx`). Web-reachable presentation and provider code imports this
/// public entry point instead of reaching into `package:cc_infra/src/<file>`.
/// Anything that transitively touches FFI is deliberately OMITTED — import
/// those VM-only adapters from `cc_infra.dart` (server / desktop only) or via
/// their specific `src/` path.
library;

export 'src/agents/agent_discovery_service.dart';
export 'src/calendar/calendar_sync_service.dart';
export 'src/calendar/google_device_auth_client.dart';
export 'src/detection/acp_models_repository_impl.dart';
export 'src/detection/acp_models_service.dart';
export 'src/dictation/dictation_service.dart';
export 'src/dispatch/acp/acp_client.dart';
export 'src/dispatch/agent_registry_impl.dart';
export 'src/dispatch/backend_registry.dart';
export 'src/dispatch/backends/acp_backend.dart';
export 'src/dispatch/backends/cli_backends.dart';
export 'src/dispatch/backends/harness_backend.dart';
export 'src/dispatch/persona_loader.dart';
export 'src/dispatch/worktree_isolation_runner.dart';
export 'src/edit/file_edit_service.dart';
export 'src/embedding/embedding_model_manager.dart';
export 'src/fleet/fleet_scheduler_service.dart';
export 'src/fleet/local_job_executor.dart';
export 'src/git/git_diff_z_parser.dart';
export 'src/git/git_repo_inspector.dart';
export 'src/git/github_api_pr_diff_source.dart';
export 'src/git/github_cli_service.dart';
export 'src/git/github_pr_search_adapter.dart';
export 'src/git/pr_polling_service.dart';
export 'src/git/process_git_command_adapter.dart';
export 'src/git/process_git_snapshot_adapter.dart';
export 'src/git/process_session_diff_adapter.dart';
export 'src/git/review_publisher_service.dart';
export 'src/git/service_status_service.dart';
export 'src/harness/harness_command_runner.dart';
export 'src/harness/mcp_tool_bridge.dart';
export 'src/harness/tools/apply_patch_tool.dart';
export 'src/ide/code_server_service.dart';
export 'src/log/cc_infra_log.dart';
export 'src/log/rotating_file_log_sink.dart';
export 'src/meetings/calendar_meeting_signal_collector.dart';
export 'src/meetings/meeting_audio_loader.dart';
export 'src/meetings/meeting_echo_filter.dart';
export 'src/meetings/meeting_recording_session.dart';
export 'src/meetings/meeting_summary_reconciler.dart';
export 'src/meetings/meeting_transcription_service.dart';
export 'src/meetings/process_meeting_signal_collector.dart';
export 'src/messaging/active_stream_registry.dart';
export 'src/messaging/agent_question_service.dart';
export 'src/messaging/agent_responder_resolver.dart';
export 'src/messaging/agent_working_directory.dart';
export 'src/messaging/channel_turn_relay.dart';
export 'src/messaging/conversation_checkpoint_coordinator.dart';
export 'src/messaging/conversation_checkpoint_service.dart';
export 'src/messaging/conversation_compaction_service.dart';
export 'src/messaging/conversation_fork_service.dart';
export 'src/messaging/json_content_extractor.dart';
export 'src/messaging/run_transcript_relay.dart';
export 'src/messaging/transcript_folder.dart';
export 'src/messaging/vision/bitmap_font.dart';
export 'src/messaging/vision/png_encoder.dart';
export 'src/messaging/vision/vision_compactor.dart';
export 'src/messaging/vision/vision_normalize.dart';
export 'src/messaging/vision/vision_plan.dart';
export 'src/messaging/vision/vision_serialize.dart';
export 'src/messaging/vision/vision_shapes.dart';
export 'src/model_routing/file_models_dev_source.dart';
export 'src/model_routing/in_memory_models_dev_source.dart';
export 'src/model_routing/model_catalog_service.dart';
export 'src/model_routing/models_dev_snapshot.dart';
export 'src/network/app_network.dart';
export 'src/network/dedup_interceptor.dart';
export 'src/network/dns_wire.dart';
export 'src/network/error_mapper.dart';
export 'src/network/github_api_client.dart';
export 'src/network/github_content_client.dart';
export 'src/network/github_graphql_client.dart';
export 'src/network/github_pr_client.dart';
export 'src/network/google_calendar_api_client.dart';
export 'src/network/klipy_api_client.dart';
export 'src/network/mdns_responder.dart';
export 'src/network/models/date_parser.dart';
export 'src/network/models/github_check_run.dart';
export 'src/network/models/github_commit.dart';
export 'src/network/models/github_issue_comment.dart';
export 'src/network/models/github_pr_review_state.dart';
export 'src/network/models/github_pull_request.dart';
export 'src/network/models/github_pull_request_file.dart';
export 'src/network/models/github_reaction.dart';
export 'src/network/models/github_review.dart';
export 'src/network/models/github_review_comment.dart';
export 'src/network/models/github_team.dart';
export 'src/network/models/github_user_profile.dart';
export 'src/network/models/github_workflow_run.dart';
export 'src/network/models/google_calendar_event.dart';
export 'src/network/models/google_calendar_list_entry.dart';
export 'src/network/network_constants.dart';
export 'src/network/pr_review_mapper.dart';
export 'src/network/retry_interceptor.dart';
export 'src/network/tunnel_manager.dart';
export 'src/newsfeed/abp_parser.dart';
export 'src/newsfeed/filter_list_service.dart';
export 'src/newsfeed/rss_fetcher_service.dart';
export 'src/newsfeed/scriptlet_library.dart';
export 'src/newsfeed/site_icon_resolver.dart';
export 'src/pipelines/bash_script_template.dart';
export 'src/pipelines/condition_template.dart';
export 'src/pipelines/register_meeting_bodies.dart';
export 'src/ports/workspace_filesystem_port.dart';
export 'src/pr_review/api_contract_diff_service.dart';
export 'src/pr_review/dispatch_reviewers_service.dart';
export 'src/pr_review/image_differ.dart';
export 'src/pr_review/pr_worktree_service.dart';
export 'src/pr_review/visual_diff_service.dart';
export 'src/process/binary_resolver.dart';
export 'src/process/process_control_service.dart';
export 'src/process/process_detection_service.dart';
export 'src/repos/filesystem_directory_browser.dart';
export 'src/repos/repo_workspace_provisioner.dart';
export 'src/sandboxing/claude_stream_json.dart';
export 'src/sandboxing/domain_matcher.dart';
export 'src/sandboxing/env_credential_broker.dart';
export 'src/sandboxing/env_credentials_repository.dart';
export 'src/sandboxing/env_sanitizer.dart';
export 'src/sandboxing/github_app_token_minter.dart';
export 'src/sandboxing/github_fine_grained_broker.dart';
export 'src/sandboxing/http_proxy.dart';
export 'src/sandboxing/linux_sandbox.dart';
export 'src/sandboxing/macos_sandbox.dart';
export 'src/sandboxing/native_sandbox_adapter.dart';
export 'src/sandboxing/no_sandbox_adapter.dart';
export 'src/sandboxing/run_log_writer.dart';
export 'src/sandboxing/sandbox_backend_detector.dart';
export 'src/sandboxing/sandbox_config.dart';
export 'src/sandboxing/sandbox_config_builder.dart';
export 'src/sandboxing/sandbox_manager.dart';
export 'src/sandboxing/socks_proxy.dart';
export 'src/sandboxing/violation_monitor.dart';
export 'src/skills/skill_bundle_service.dart';
export 'src/skills/skill_llm_review_runner.dart';
export 'src/skills/skill_scanner_adapter.dart';
export 'src/skills/skills_sh_registry_adapter.dart';
export 'src/speech/diarization_model_manager.dart';
export 'src/speech/voice_model_manager.dart';
export 'src/teams/messaging_team_leader_dispatch.dart';
export 'src/tickets/cancellation_watcher.dart';
export 'src/tickets/idle_watchdog.dart';
export 'src/tickets/linear/linear_graphql_client.dart';
export 'src/tickets/linear/linear_issue_dto.dart';
export 'src/tickets/linear/linear_ticket_adapter.dart';
export 'src/tickets/sync/clickup_ticket_sync_adapter.dart';
export 'src/tickets/sync/github_issues_ticket_sync_adapter.dart';
export 'src/tickets/sync/jira_ticket_sync_adapter.dart';
export 'src/tickets/sync/linear_ticket_sync_adapter.dart';
export 'src/tickets/task_retry_service.dart';
export 'src/tickets/ticket_sync_service.dart';
export 'src/usage/subscription_usage_service.dart';
export 'src/usecases/approve_orchestration_use_case.dart';
export 'src/usecases/hire_agent_use_case.dart';
export 'src/util/agents_md_parser.dart';
export 'src/util/cc_paths.dart';
export 'src/util/command_redaction.dart';
export 'src/util/isolate_json.dart';
export 'src/util/json_schema_validator.dart';
export 'src/util/wav_io.dart';
export 'src/workspaces/create_ceo_agent.dart';
export 'src/workspaces/create_specialist_agents.dart';
export 'src/workspaces/workspace_filesystem_service.dart';
export 'src/workspaces/workspace_seeder.dart';
