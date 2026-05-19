import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/embedding_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/logging_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/privacy_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/sandboxing_sections.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/sync_engine_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/system_behavior_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Diagnostics & privacy.
///
/// What the install does about isolation, indexing, syncing, logging and crash
/// reporting. This is where most of the old "Advanced" page landed, together
/// with the sandboxing and privacy halves of the old "Security & privacy".
///
/// The old `CommandRulesSection` is deliberately NOT carried over: it was a
/// static explainer with no `ref.watch` anywhere, describing a command-gating
/// model the workspace guardrail matrix (Workspace → Agent permissions) now
/// owns for real. Keeping a read-only description of superseded rules beside
/// the live ones is how two sources of truth start.
class DiagnosticsSettingsScreen extends StatelessWidget {
  /// Creates a [DiagnosticsSettingsScreen].
  const DiagnosticsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsDiagnostics,
      subtitle: l10n.settingsDiagnosticsDescription,
      sections: const [
        SandboxingSections(),
        EmbeddingSection(),
        SystemBehaviorSection(),
        SyncEngineSection(),
        LoggingSection(),
        PrivacySection(),
      ],
    );
  }
}
