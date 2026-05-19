/// SharedPreferences storage keys.
library;

/// Storage key for the GitHub token.
const String githubTokenKey = 'github_token';

/// Secure-storage key for the remote ticketing provider API key.
const String ticketingApiKeyKey = 'ticketing_api_key';

/// Storage key for the theme mode preference.
const String themeModeKey = 'theme_mode';

/// Storage key for the embedded-editor (code-server) auto-save preference.
/// One of the `EditorAutoSaveMode` wire values ('off'/'afterDelay'/
/// 'onFocusChange'); seeded into code-server's `files.autoSave` on every open.
const String editorAutoSaveKey = 'editor_auto_save';

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

/// Storage key for whether programming ligatures are enabled in code text.
const String codeFontLigaturesKey = 'code_font_ligatures';

/// Storage key for the imported VS Code editor theme (raw `*-color-theme.json`).
/// Non-sensitive; applied to the embedded diff/editor surfaces.
const String vscodeEditorThemeKey = 'vscode_editor_theme_json';

/// Storage key for the preferred audio input device id (mic).
const String audioInputDeviceIdKey = 'audio_input_device_id';

/// Storage key for the preferred audio output device (libmpv device name),
/// applied to EVERY sound the app makes. Device-scoped: the id names this
/// machine's hardware.
const String audioOutputDeviceKey = 'audio_output_device';

/// The key [audioOutputDeviceKey] replaced, back when the output choice only
/// routed the soundscape. Read once and migrated forward so an existing
/// selection survives the widening; never written.
const String legacySoundscapeOutputDeviceKey = 'soundscape_output_device';

/// SharedPreferences key for the composer dictation push-to-talk mode. `true`
/// = hold-to-talk (dictate while held, stop on release); `false`/absent =
/// toggle (press once to start, again to stop).
const String dictationHoldToTalkKey = 'dictation_hold_to_talk';

/// SharedPreferences key for the JSON list of custom meeting-note templates.
const String meetingTemplatesKey = 'meeting_templates';

/// SharedPreferences key for the selected meeting-note template id.
const String selectedMeetingTemplateKey = 'selected_meeting_template';

/// SharedPreferences key for whether automatic meeting detection is enabled.
const String meetingAutoDetectKey = 'meeting_auto_detect';

/// Default conversation status when created.
const String defaultConversationStatus = 'active';

/// Default MCP server host.
const String defaultMcpHost = '127.0.0.1';

/// Storage key for the PR file-tree panel width preference.
const String prTreeWidthKey = 'pr_tree_width';

/// Storage key for the PR file-tree panel visibility preference.
const String prTreeVisibleKey = 'pr_tree_visible';

/// Storage key for the PR diff split (side-by-side) view preference.
const String prDiffSplitViewKey = 'pr_diff_split_view';

/// Storage key for the PR queue grouping preference (a `PrListGrouping` name).
const String prListGroupingKey = 'pr_list_grouping';

/// Storage key for the PR queue draft-visibility preference.
const String prListShowDraftsKey = 'pr_list_show_drafts';

/// Storage key for the PR queue row-properties preference (a JSON array of
/// `PrRowProperty` names).
const String prListRowPropertiesKey = 'pr_list_row_properties';

/// Storage key for the recently-merged window preference (a `PrMergedWindow`
/// name), shared by the PR queue and the inbox display options.
const String prListMergedWindowKey = 'pr_list_merged_window';

/// Storage key for the messaging IDE sidebar's pinned views (a JSON array of
/// `IdeSidebarView` names). Views absent from the list are reachable only from
/// the strip's overflow menu.
const String ideSidebarPinnedViewsKey = 'ide_sidebar_pinned_views';

/// SharedPreferences key for whether crash/error diagnostics are sent to the
/// error-reporting service (Sentry). Defaults to `true` (enabled).
///
/// Read at startup by `runAppWithSentry` (core/observability/sentry_bootstrap)
/// to gate initialization and read/written by `PrivacyPreferences`
/// (features/settings/data) for the in-app and onboarding opt-out. Kept here in
/// core so both the bootstrap and the feature can share the one key without a
/// core→feature import.
const String errorReportingEnabledKey = 'privacy_error_reporting_enabled';

/// Storage key for the locale preference.
const String localeKey = 'app_locale';

// There is deliberately no `onboardingFinishedKey` here any more. "Has this
// person finished first-run setup" is a fact about the ACCOUNT and lives on
// `users.onboarding_finished_at`, read back through `identity.me`. As a synced
// preference it was seeded onto whichever account first signed in on a machine
// that already held the local value, which marked people as onboarded who never
// were. Do not reintroduce it as a key.

/// Storage key for the diff viewer overflow mode (wrap vs horizontal scroll).
const String diffOverflowModeKey = 'diff_overflow_mode';

/// Storage key for the tickets screen view mode (list vs board).
const String ticketsViewModeKey = 'tickets_view_mode';

/// Storage key for the user's preferred editor/IDE used by the PR "open in
/// editor" split button (an editor id such as `vscode` or `cursor`).
const String selectedIdeKey = 'selected_ide_id';

/// Storage key for the calendar screen view mode (month vs week vs agenda).
const String calendarViewModeKey = 'calendar_view_mode';

/// Cache `kind` for the messaging IDE editor split layout, persisted per
/// conversation (the cache `key` is the space id) so each conversation
/// restores its own panes/tabs/sizes on restart. See `editor_layout_snapshot`.
const String editorLayoutCacheKind = 'editor_layout_v1';

/// Cache `kind` for the PR workbench editor split layout, persisted per PR (the
/// cache `key` is `owner/repo#number`) so each PR restores its own workbench
/// panes/tabs/sizes on restart. Kept distinct from [editorLayoutCacheKind] so
/// PR layouts never collide with messaging's space-keyed entries.
const String prEditorLayoutCacheKind = 'pr_editor_layout_v1';

// ── Google Calendar OAuth ──
//
// Nothing here: OAuth lives entirely on the HOST (device-code grant). The
// client drives the connect dialog over RPC and never holds a Google token, so
// there are no client-side endpoint/scope/credential-key constants. See
// `lib/features/calendar/README.md`.
