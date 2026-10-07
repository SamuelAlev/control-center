/// `workspace_settings` keys for the workspace's short-task runner
/// (adapter+model): the one-shot model behind conversation titles, side
/// questions (`/btw`, `/handoff`) and the `/goal` interview.
///
/// Workspace-scoped (not per-user) on the admin-gated `workspace_settings`
/// lane; both unset → those features are off (no fallback). Defined once for
/// client write + server read.
///
/// The stored key names predate the rename from "conversation title model" and
/// are kept so existing workspaces keep their choice.
library;

/// The adapter that runs short tasks (an `Adapter.id`, e.g. `cc-harness`,
/// `claude-code`). Unset means short tasks are off.
const String kShortTaskAdapterSettingKey = 'conversation_title_adapter';

/// The model the [kShortTaskAdapterSettingKey] adapter runs them on.
///
/// A qualified `provider/model` id for `cc-harness`; whatever the CLI
/// advertises for an external adapter. Unset lets the adapter pick its own
/// default, which is meaningful for a CLI and means "the provider default" for
/// the harness.
const String kShortTaskModelSettingKey = 'conversation_title_model';
