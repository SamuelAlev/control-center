import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/notifications_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → Notifications: per-event notification toggles.
class NotificationsSettingsScreen extends StatelessWidget {
  /// Creates a [NotificationsSettingsScreen].
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.notifications,
      subtitle: l10n.notificationsSettingsDescription,
      sections: const [NotificationsSection()],
    );
  }
}
