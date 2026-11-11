import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_page_heading.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/account_profile_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/identity_provider_section.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Profile: everything that is the person's own on this
/// server, on one page.
///
/// First who they are everywhere (username, name, email, picture) and, when
/// there is one, the identity provider their account signs in through. Then
/// their connected accounts: code hosting sign-ins and tokens, their
/// ticketing sign-in, calendar accounts and chat link. Every one is stored
/// against the person, never the workspace, so changing one affects only
/// them; what a workspace decides about the same providers is on Workspace →
/// Integrations. Each account card says whether it applies in every
/// workspace on this server or only in the one settings were opened from.
///
/// Settings owns the page and the profile, not the accounts: every card
/// under the heading is contributed to [SettingsSlot.userAccounts] by the
/// feature behind it. Workspace → Profile & identity is the per-workspace
/// overlay on top of the profile; it never changes the username.
class AccountProfileSettingsScreen extends ConsumerWidget {
  /// Creates an [AccountProfileSettingsScreen].
  const AccountProfileSettingsScreen({super.key, this.openAtAccounts = false});

  /// Whether the page opens at the connected accounts instead of the
  /// profile, for a link that is about one of them.
  final bool openAtAccounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // The card renders nothing for an account with no identity provider, and
    // an empty card would still cost the page a gap.
    final hasIdentityProvider =
        (ref.watch(currentIdentityProvider).value?.ssoIssuer ?? '').isNotEmpty;
    return SettingsPage(
      title: l10n.accountProfileTitle,
      subtitle: l10n.accountProfileDescription,
      sections: [
        const AccountProfileSection(),
        if (hasIdentityProvider) const IdentityProviderSection(),
      ],
      slot: SettingsSlot.userAccounts,
      slotHeading: SettingsPageHeading(
        title: l10n.linkedAccountsTitle,
        description: l10n.settingsAccountsDescription,
      ),
      openAtSlot: openAtAccounts,
    );
  }
}
