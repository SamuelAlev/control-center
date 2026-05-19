/// SharedPreferences storage keys.
library;

/// Storage key for the GitHub token.
const String githubTokenKey = 'github_token';

/// Secure-storage key for the remote ticketing provider API key.
const String ticketingApiKeyKey = 'ticketing_api_key';

/// SharedPreferences key for the chosen ticketing provider id.
const String ticketingProviderKey = 'ticketing_provider';

/// Storage key for the theme mode preference.
const String themeModeKey = 'theme_mode';

// ── Font family preferences ──

/// Storage key for the app font family.
const String appFontFamilyKey = 'app_font_family';

/// Storage key for the app font source (google/system).
const String appFontSourceKey = 'app_font_source';

/// Storage key for the app font file path (system fonts only).
const String appFontPathKey = 'app_font_path';

/// Storage key for the code font family.
const String codeFontFamilyKey = 'code_font_family';

/// Storage key for the code font source (google/system).
const String codeFontSourceKey = 'code_font_source';

/// Storage key for the code font file path (system fonts only).
const String codeFontPathKey = 'code_font_path';

/// Storage key for the preferred audio input device id (mic).
const String audioInputDeviceIdKey = 'audio_input_device_id';

/// Default conversation status when created.
const String defaultConversationStatus = 'active';

/// Base URL for the GitHub REST API.
const String githubApiBaseUrl = 'https://api.github.com';

/// Default MCP server host.
const String defaultMcpHost = '127.0.0.1';

/// Storage key for the PR file-tree panel width preference.
const String prTreeWidthKey = 'pr_tree_width';

/// MCP JSON-RPC protocol version.
const String mcpProtocolVersion = '2024-11-05';

/// Storage key for the app-wide log level preference.
const String appLogLevelKey = 'app_log_level';

/// Storage key for the locale preference.
const String localeKey = 'app_locale';

/// Storage key for the diff viewer overflow mode (wrap vs horizontal scroll).
const String diffOverflowModeKey = 'diff_overflow_mode';

/// Storage key for the tickets screen view mode (list vs board).
const String ticketsViewModeKey = 'tickets_view_mode';

/// Storage key for the branch-name template used when provisioning isolated
/// worktrees for tickets (e.g. `{type}/{ticket-key}-{slug}`).
const String branchTemplateKey = 'branch_template';

/// Storage key for the user's preferred editor/IDE used by the PR "open in
/// editor" split button (an editor id such as `vscode` or `cursor`).
const String selectedIdeKey = 'selected_ide_id';
