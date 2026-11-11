import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Profile → Single sign-on: the identity provider the
/// person's account is pinned to, when it is pinned to one.
///
/// It is part of who the person is, so it sits with the profile card, above
/// the accounts they connect for themself. Read-only: whoever runs the
/// server manages the identity provider, so there is nothing to send the
/// person to.
///
/// Renders nothing for an account with no identity provider (most of them,
/// and every account on a demo server) and while identity is on its way.
class IdentityProviderSection extends ConsumerWidget {
  /// Creates an [IdentityProviderSection].
  const IdentityProviderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuer = ref.watch(currentIdentityProvider).value?.ssoIssuer ?? '';
    if (issuer.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SectionCard(
      label: l10n.settingsServerSso,
      subtitle: Text(l10n.ssoIdentityDescription),
      child: SettingsEntityRow(
        title: l10n.linkedAccountsIdentityProvider,
        tone: CcStatusTone.positive,
        statusLabel: l10n.connectedLabel,
        subtitleWidget: Text(
          issuer,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // RTL carve-out: issuer URLs read left to right.
          textDirection: TextDirection.ltr,
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
      ),
    );
  }
}
