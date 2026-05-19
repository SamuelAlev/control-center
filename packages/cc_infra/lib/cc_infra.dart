/// Server-side VM-only infrastructure adapters for Control Center.
///
/// Pure `dart:io` implementations of `cc_domain` ports (git / process / GitHub
/// CLI), JSON-schema validation, and agent-adapter / ACP-model detection — the
/// concrete work a server performs. Kept SEPARATE from the `cc_host` RPC kernel
/// and free of Flutter / `cc_natives`, so both packages link into the
/// Flutter-free `dart build cli` server binary (the north star). The desktop
/// imports the same adapters during the thin-client migration.
library;

export 'src/calendar/calendar_sync_service.dart';
export 'src/code_graph/code_extractor.dart';
export 'src/code_graph/code_indexer.dart';
export 'src/code_graph/extraction_isolate.dart';
export 'src/detection/acp_models_repository_impl.dart';
export 'src/detection/acp_models_service.dart';
export 'src/detection/adapter_detection_repository.dart';
export 'src/detection/adapter_detection_service.dart';
export 'src/detection/doctor_service.dart';
export 'src/dispatch/agent_dispatch_service.dart';
export 'src/dispatch/agent_process_data_source.dart';
export 'src/dispatch/agent_registry_impl.dart';
export 'src/dispatch/dispatch_session.dart';
export 'src/dispatch/irc_bus_impl.dart';
export 'src/dispatch/persona_loader.dart';
export 'src/dispatch/sandboxed_agent_dispatch_adapter.dart';
export 'src/dispatch/worktree_isolation_runner.dart';
export 'src/edit/file_edit_service.dart';
export 'src/edit/tree_sitter_block_resolver.dart';
export 'src/embedding/embedding_model_manager.dart';
export 'src/git/git_repo_inspector.dart';
export 'src/git/github_api_pr_diff_source.dart';
export 'src/git/github_cli_service.dart';
export 'src/git/github_pr_search_adapter.dart';
export 'src/git/github_status_service.dart';
export 'src/git/pr_polling_service.dart';
export 'src/git/process_git_command_adapter.dart';
export 'src/git/process_git_snapshot_adapter.dart';
export 'src/git/review_publisher_service.dart';
export 'src/log/cc_infra_log.dart';
export 'src/messaging/active_stream_registry.dart';
export 'src/messaging/agent_question_service.dart';
export 'src/messaging/agent_stream_processor.dart';
export 'src/messaging/conversation_checkpoint_service.dart';
export 'src/messaging/conversation_compaction_service.dart';
export 'src/messaging/conversation_fork_service.dart';
export 'src/messaging/messaging_service.dart';
export 'src/network/app_network.dart';
export 'src/network/error_mapper.dart';
export 'src/network/github_api_client.dart';
export 'src/network/github_content_client.dart';
export 'src/network/github_graphql_client.dart';
export 'src/network/github_pr_client.dart';
export 'src/network/google_calendar_api_client.dart';
export 'src/network/network_constants.dart';
export 'src/network/pr_review_mapper.dart';
export 'src/newsfeed/filter_list_service.dart';
export 'src/newsfeed/rss_fetcher_service.dart';
export 'src/ports/workspace_filesystem_port.dart';
export 'src/pr_review/dispatch_reviewers_service.dart';
export 'src/pr_review/local_git_pr_diff_source.dart';
export 'src/pr_review/pr_clone_manager.dart';
export 'src/process/binary_resolver.dart';
export 'src/process/process_control_service.dart';
export 'src/process/process_detection_service.dart';
export 'src/repos/filesystem_directory_browser.dart';
export 'src/repos/rift_repo_isolation_adapter.dart';
export 'src/sandboxing/claude_relay.dart';
export 'src/sandboxing/env_credentials_repository.dart';
export 'src/sandboxing/terminal_session_service.dart';
export 'src/speech/diarization_model_manager.dart';
export 'src/speech/voice_model_manager.dart';
export 'src/tickets/linear/linear_graphql_client.dart';
export 'src/tickets/linear/linear_issue_dto.dart';
export 'src/tickets/linear/linear_ticket_adapter.dart';
export 'src/usecases/hire_agent_use_case.dart';
// NOTE: agent_detection_service is intentionally NOT exported here — it defines
// its own `DetectionStatus`, which would collide with cc_domain's
// `DetectionStatus` for any barrel consumer. Import it by its src/ path.
export 'src/util/agents_md_parser.dart';
export 'src/util/cc_paths.dart';
export 'src/util/isolate_json.dart';
export 'src/util/json_schema_validator.dart';
export 'src/workspaces/create_ceo_agent.dart';
export 'src/workspaces/create_specialist_agents.dart';
export 'src/workspaces/workspace_filesystem_service.dart';
export 'src/workspaces/workspace_seeder.dart';
