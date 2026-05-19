/// The `workspace_settings` keys naming the runner that titles conversations.
///
/// The runner is an **adapter + model pair**, the same shape every other
/// runner choice in the app uses (`Agent.adapterId` / `Agent.modelId`, the
/// default-runner rows in Settings → Adapters). There is no third "provider"
/// axis: for the built-in `cc-harness` adapter the provider is folded into the
/// model id (`anthropic/claude-haiku-4-5`), and an external CLI adapter
/// (`claude-code`, `codex`, an ACP agent) owns its own auth and advertises
/// plain model names.
///
/// Both unset/empty means automatic conversation titling is OFF: there is
/// deliberately no fallback runner, so no generation happens until an admin
/// explicitly picks one in Settings.
///
/// **Workspace-scoped, not per-user.** A conversation title is a property of
/// the conversation every member of the workspace reads, not of whoever
/// happened to send its first message — a per-user preference meant the same
/// space got titled or not depending on who typed first, and named the model
/// (and therefore the credential) a teammate never chose. Both keys ride the
/// same admin-gated `workspace_settings` lane as `kReviewLevelSettingKey`.
///
/// Shared kernel on purpose: the client's settings card writes them through
/// `workspace_settings.set` and the server's `ConversationTitleService` reads
/// those same rows, so the strings must be defined exactly once.
library;

/// The adapter that runs the titling prompt (an `Adapter.id`, e.g.
/// `cc-harness`, `claude-code`). Unset means titling is off.
const String kConversationTitleAdapterSettingKey = 'conversation_title_adapter';

/// The model the [kConversationTitleAdapterSettingKey] adapter runs it on.
///
/// A qualified `provider/model` id for `cc-harness`; whatever the CLI
/// advertises for an external adapter. Unset lets the adapter pick its own
/// default, which is meaningful for a CLI and means "the provider default" for
/// the harness.
const String kConversationTitleModelSettingKey = 'conversation_title_model';
