import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/identity/providers/account_profile_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/user/account_profile_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Profile → Account: the username, name, email and
/// picture that follow the person into every workspace.
class AccountProfileSection extends ConsumerWidget {
  /// Creates an [AccountProfileSection].
  const AccountProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    if (ref.watch(isDemoServerProvider)) {
      return SectionCard(
        label: l10n.accountSectionTitle,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: DemoUnavailable(
            capability: DemoCapability.account,
            compact: true,
          ),
        ),
      );
    }
    final state = ref.watch(accountProfileProvider);
    return SectionCard(
      label: l10n.accountSectionTitle,
      subtitle: Text(l10n.accountSectionDescription),
      child: switch (state) {
        // Keyed by user so a different sign-in reseeds the form, while a
        // refresh of the same account keeps what is being typed.
        AsyncValue(:final value?) => AccountProfileForm(
          key: ValueKey(value.id),
          user: value,
        ),
        AsyncError(:final error) => Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(AppIcons.triangleAlert, size: 14, color: t.fgErrorPrimary),
            Text(
              storageRefusalMessage(l10n, error) ??
                  l10n.accountLoadFailed(
                    error is RemoteRpcException ? error.message : '$error',
                  ),
              style: CcTypography.caption.copyWith(color: t.textErrorPrimary),
            ),
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: () => ref.invalidate(accountProfileProvider),
              child: Text(l10n.retry),
            ),
          ],
        ),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(child: CcSpinner(size: 16)),
        ),
      },
    );
  }
}
