import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audit/audit_log_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Server → Audit log: the server trail (server owner) and the
/// trail of every workspace the person administers, in one table.
class AuditLogSettingsScreen extends StatelessWidget {
  /// Creates an [AuditLogSettingsScreen].
  const AuditLogSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.settingsAuditLog,
      subtitle: l10n.settingsAuditLogDescription,
      sections: const [AuditLogSection()],
    );
  }
}
