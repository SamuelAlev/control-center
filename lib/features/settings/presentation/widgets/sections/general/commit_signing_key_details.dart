import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

/// Where a person adds a signing key on GitHub.
const String kGitHubNewSigningKeyUrl = 'https://github.com/settings/ssh/new';

/// Where a person adds a signing key on GitLab.
const String kGitLabSigningKeysUrl =
    'https://gitlab.com/-/user_settings/ssh_keys';

/// An existing commit signing key: the public half to copy, its fingerprint
/// and age, and where each forge takes it.
class CommitSigningKeyDetails extends StatelessWidget {
  /// Creates a [CommitSigningKeyDetails].
  const CommitSigningKeyDetails({super.key, required this.signingKey});

  /// The caller's key.
  final CommitSigningKey signingKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final created = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(signingKey.createdAt.toLocal());
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsField(
          label: l10n.settingsCommitSigningPublicKeyLabel,
          layout: SettingsFieldLayout.stacked,
          child: SettingsCopyField(
            value: signingKey.publicKey,
            maxLines: 2,
            copiedMessage: l10n.settingsCommitSigningKeyCopied,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xs,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.settingsCommitSigningFingerprintLabel,
                  style: caption,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  // RTL carve-out: a key fingerprint is a machine string.
                  child: Text(
                    signingKey.fingerprint,
                    textDirection: TextDirection.ltr,
                    overflow: TextOverflow.ellipsis,
                    style: CcFonts.code(
                      textStyle: CcTypography.caption.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.settingsCommitSigningCreatedLabel, style: caption),
                const SizedBox(width: AppSpacing.xs),
                AppTimestamp(
                  dateTime: signingKey.createdAt,
                  child: Text(
                    created,
                    style: CcTypography.caption.copyWith(
                      color: t.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsGroup(
          showRule: true,
          title: l10n.settingsCommitSigningAddTitle,
          description: l10n.settingsCommitSigningAddDescription,
          separator: SettingsGroupSeparator.rule,
          gap: 0,
          children: [
            _ForgeStep(
              forge: ForgeHost.github,
              steps: l10n.settingsCommitSigningGitHubSteps,
              url: kGitHubNewSigningKeyUrl,
            ),
            _ForgeStep(
              forge: ForgeHost.gitlab,
              steps: l10n.settingsCommitSigningGitLabSteps,
              url: kGitLabSigningKeysUrl,
            ),
            _ForgeStep(
              forge: ForgeHost.bitbucket,
              steps: l10n.settingsCommitSigningBitbucketSteps,
            ),
          ],
        ),
      ],
    );
  }
}

/// One forge: what to do there, and a link to the page that takes the key.
/// A forge with no [url] does not take the key, and says so.
class _ForgeStep extends StatelessWidget {
  const _ForgeStep({required this.forge, required this.steps, this.url});

  final ForgeHost forge;
  final String steps;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final url = this.url;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      forge.displayName,
                      style: CcTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                    if (url == null)
                      CcStatusTag(
                        label: l10n.settingsCommitSigningUnsupported,
                        tone: CcStatusTone.caution,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  steps,
                  style: CcTypography.caption.copyWith(
                    color: url == null ? t.textWarningPrimary : t.textTertiary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (url != null) ...[
            const SizedBox(width: AppSpacing.md),
            CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              icon: AppIcons.externalLink,
              onPressed: () => openExternalUrl(url),
              child: Text(l10n.openOnForge(forge.displayName)),
            ),
          ],
        ],
      ),
    );
  }
}

/// What a person trusts by creating a key, in plain words: shown whether or
/// not they have one, because it is the reason signing is off by default.
class CommitSigningTrust extends StatelessWidget {
  /// Creates a [CommitSigningTrust].
  const CommitSigningTrust({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    Widget line(IconData icon, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: 2),
          child: Icon(icon, size: 14, color: t.fgTertiary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: CcTypography.caption.copyWith(
              color: t.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
    return SettingsGroup(
      showRule: true,
      title: l10n.settingsCommitSigningTrustTitle,
      gap: AppSpacing.sm,
      children: [
        line(AppIcons.lock, l10n.settingsCommitSigningTrustPrivate),
        line(AppIcons.bot, l10n.settingsCommitSigningTrustAgents),
        line(AppIcons.keyRound, l10n.settingsCommitSigningTrustControl),
        line(AppIcons.shieldCheck, l10n.settingsCommitSigningTrustVerified),
        line(AppIcons.gitCommit, l10n.settingsCommitsNoHooks),
      ],
    );
  }
}
