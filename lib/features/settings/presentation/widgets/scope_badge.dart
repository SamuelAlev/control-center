import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Says who a setting affects, in the header of the section that owns it.
///
/// Before this existed, every settings section rendered in an identical
/// `SectionCard` whether its value lived in NSUserDefaults on one laptop or in
/// a workspace policy table every member reads. "Sandboxing" (per-device) sat
/// directly beside "Agent permissions" (workspace server policy) with nothing
/// to tell them apart.
///
/// Reuses `CcSourceBadge` rather than adding a component: it already renders a
/// mono uppercase provenance chip and accepts a label override. Its
/// `CcConfigSource` vocabulary is about POLICY LAYERING (default → global →
/// project → local override), not scope, so this maps scope onto the nearest
/// source purely for the visual treatment — the label carries the meaning.
class ScopeBadge extends StatelessWidget {
  /// Creates a [ScopeBadge] for [scope].
  const ScopeBadge(this.scope, {super.key});

  /// Who a change here affects.
  final SettingScope scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcSourceBadge(
      source: switch (scope) {
        // Quiet neutral: these are the expected, inherited scopes.
        SettingScope.user => CcConfigSource.global,
        SettingScope.server => CcConfigSource.system,
        // Tinted + accent stripe: a change here reaches past the person making
        // it, so it earns the eye.
        SettingScope.workspace => CcConfigSource.project,
        SettingScope.device => CcConfigSource.localOverride,
      },
      label: switch (scope) {
        SettingScope.user => l10n.settingsScopeBadgeYou,
        SettingScope.device => l10n.settingsScopeBadgeDevice,
        SettingScope.workspace => l10n.settingsScopeBadgeWorkspace,
        SettingScope.server => l10n.settingsScopeBadgeServer,
      },
    );
  }
}
