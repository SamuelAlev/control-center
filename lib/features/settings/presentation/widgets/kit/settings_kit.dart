/// The settings layout kit — the shared vocabulary every settings surface is
/// built from.
///
/// ## Why this exists
///
/// Settings pages were each inventing their own layout on top of a bare
/// `SectionCard`: a `Column` of ad-hoc rows, a hand-rolled label above a text
/// field, a switch row copied between four files, and every control in a
/// feature rendered at once no matter how many there were. Three surfaces made
/// the cost obvious — Single sign-on presented twelve undifferentiated fields
/// before saying whether SSO was even on, Model providers rendered an API-key
/// field and a sampling panel for all eighteen providers at once, and Detected
/// runners drew a capability matrix plus an env editor under every runner
/// including the ones that are not installed. All three read as a wall.
///
/// ## The architecture
///
/// Four layers, and a surface only ever adds the ones it needs:
///
/// 1. **Page** — `SettingsPage` (title, subtitle, page actions, scroll).
/// 2. **Card** — `SectionCard` (one subject: "Connection", "Providers"). Its
///    label is the uppercase eyebrow; nothing else in the card outranks it.
/// 3. **Group** — `SettingsGroup`: a titled block INSIDE a card, for a card
///    that genuinely holds more than one question. Never a nested card; a rule
///    and a heading, so there is no box-in-a-box.
/// 4. **Row** — exactly one of:
///    - `SettingsField` — a labelled control (a text field, a select, a
///      button). Owns the label / description / hint / error anatomy so every
///      control on every page has the same one.
///    - `SettingsToggle` — a switch with a title and a description.
///    - `SettingsEntityRow` — a repeating thing with a state (a provider, a
///      runner, an MCP server): status-led, collapsed by default, its detail
///      behind its own disclosure.
///
/// ## The four rules that make a dense page readable
///
/// - **State before configuration.** A surface opens with `SettingsSummary`:
///   what is on, what is connected, what is missing. The operator learns where
///   they stand before they meet a single input. This is "situational command
///   in one glance" applied to settings.
/// - **Progressive disclosure by default.** Anything expert, per-item or rarely
///   touched goes behind `SettingsDisclosure`, which states in its header what
///   is inside and badges itself when the values within are non-default — so
///   collapsing never hides that something was changed.
/// - **A long list gets a filter, not a scroll.** More than a handful of
///   repeating rows earns a `SettingsFilterBar` (search + facets + a live
///   count) and a grouping that puts what matters first.
/// - **Edits are committed, not ambient.** A form that saves as a unit uses
///   `SettingsSaveBar`: nothing to hunt for at the bottom of a scroll, and the
///   page says out loud when there is unsaved work.
///
/// Everything here is built on `cc_ui` primitives and design tokens only, so a
/// token change propagates and no surface carries its own colours.
library;

export 'package:control_center/features/settings/presentation/widgets/kit/settings_copy_field.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_disclosure.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_entity_row.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_field.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_filter_bar.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_group.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_key_value_editor.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_key_value_pair.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_meta_fact.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_rail.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_save_bar.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_summary.dart';
export 'package:control_center/features/settings/presentation/widgets/kit/settings_toggle.dart';
