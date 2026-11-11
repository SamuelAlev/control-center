import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/coauthor_credit_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/commit_signing_key_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Settings → You → Commits: whose name commits carry, the co-author credit
/// preference (a workspace may override it), and the commit signing key that
/// makes them verified.
class CommitsSettingsScreen extends StatelessWidget {
  /// Creates a [CommitsSettingsScreen].
  const CommitsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsPage(
      title: l10n.commits,
      subtitle: l10n.settingsCommitsDescription,
      sections: const [CoauthorCreditSection(), CommitSigningKeySection()],
    );
  }
}
