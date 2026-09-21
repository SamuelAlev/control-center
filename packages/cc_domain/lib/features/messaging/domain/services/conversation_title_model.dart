/// `workspace_settings` keys for the conversation-title runner (adapter+model).
///
/// Same shape as other runners; no separate provider axis. Both unset → titling
/// off (no fallback). Workspace-scoped (not per-user) on the admin-gated
/// `workspace_settings` lane. Defined once for client write + server read.
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
