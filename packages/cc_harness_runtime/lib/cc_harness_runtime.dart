/// Batteries for the `cc_harness` kernel — VM-only, Control-Center-free.
///
/// Everything here depends only on the kernel + `dart:io` (+ `crypto`/`path`):
/// streaming LLM providers, OAuth/PKCE brokering, credential stores, the
/// generic tool set, context loaders, run config, the watchdog advisor and
/// shell loop hooks. Control-Center-coupled adapters (the sandboxed command
/// runner, the MCP tool bridge, `apply_patch`) live in `cc_infra`.
library;

export 'src/advisor/advisor_panel.dart';
export 'src/advisor/watchdog_advisor.dart';
export 'src/advisor/watchdog_discovery.dart';
export 'src/advisor/watchdog_roster.dart';
export 'src/composite_provider_credential_store.dart';
export 'src/context/agents_md_context_loader.dart';
export 'src/context/harness_agent_scanner.dart';
export 'src/context/harness_command_scanner.dart';
export 'src/context/harness_run_config.dart';
export 'src/context/harness_skill_scanner.dart';
export 'src/context/llm_harness_summarizer.dart';
export 'src/env_provider_credential_store.dart';
export 'src/file_provider_credential_store.dart';
export 'src/harness_provider_factory.dart';
export 'src/oauth/harness_oauth_broker.dart';
export 'src/oauth/jwt_claims.dart';
export 'src/oauth/kimi_oauth.dart';
export 'src/oauth/oauth_provider.dart';
export 'src/oauth/openai_oauth.dart';
export 'src/oauth/pkce.dart';
export 'src/providers/anthropic_provider.dart';
export 'src/providers/fallback_provider.dart';
export 'src/providers/openai_provider.dart';
export 'src/providers/provider_http.dart';
export 'src/providers/sse.dart';
export 'src/shell_agent_loop_hooks.dart';
export 'src/tools/bash_tool.dart';
export 'src/tools/context_control_tools.dart';
export 'src/tools/edit_tool.dart';
export 'src/tools/file_search_tool.dart';
export 'src/tools/find_tool.dart';
export 'src/tools/read_tool.dart';
export 'src/tools/resolve_tool.dart';
export 'src/tools/search_backends.dart';
export 'src/tools/search_tool.dart';
export 'src/tools/site_extractors.dart';
export 'src/tools/task_tool.dart';
export 'src/tools/vibe_tools.dart';
export 'src/tools/web_fetch_tool.dart';
export 'src/tools/web_search_tool.dart';
export 'src/tools/workspace_file_search.dart';
export 'src/tools/workspace_paths.dart';
export 'src/tools/write_tool.dart';
