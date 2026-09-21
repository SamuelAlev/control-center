/// Shared settings layout vocabulary on `cc_ui` tokens only.
///
/// Layers (add only what the surface needs): `SettingsPage` → `SectionCard` →
/// optional `SettingsGroup` (never nested cards) → one of `SettingsField`,
/// `SettingsToggle`, or `SettingsEntityRow` (collapsed by default).
///
/// Rules: open with `SettingsSummary`; put expert/rare controls behind
/// `SettingsDisclosure` (badge non-defaults); long lists use `SettingsFilterBar`;
/// unit-save forms use `SettingsSaveBar`.
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
