import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Newsfeed: how the user reads articles — in-app webview
/// vs system browser, and (desktop-only) content blocking.
class NewsfeedReaderPreferencesSection extends ConsumerWidget {
  /// Creates a [NewsfeedReaderPreferencesSection].
  const NewsfeedReaderPreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openMode = ref.watch(articleOpenModeProvider);
    final blockContent = ref.watch(contentBlockingProvider);
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.readerPreferences,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        children: [
          _PreferenceTile(
            icon: AppIcons.appWindow,
            title: l10n.openArticlesInApp,
            subtitle: l10n.openArticlesInAppDescription,
            trailing: CcSwitch(
              value: openMode == ArticleOpenMode.inApp,
              onChanged: (v) => ref
                  .read(articleOpenModeProvider.notifier)
                  .set(
                    v ? ArticleOpenMode.inApp : ArticleOpenMode.externalBrowser,
                  ),
            ),
          ),
          // Content blocking (and its filter lists / trusted sites) drives
          // the DESKTOP in-app ad-blocking webview. On web the browser is
          // the reader, so the toggle has nothing to act on — hide it
          // rather than show an inert switch over an all-zero filter list.
          if (!kIsWeb) ...[
            const CcDivider(),
            _PreferenceTile(
              icon: AppIcons.shield,
              title: l10n.blockAdsTrackers,
              subtitle: l10n.blockAdsTrackersDescription,
              trailing: CcSwitch(
                value: blockContent,
                onChanged: (v) =>
                    ref.read(contentBlockingProvider.notifier).set(enabled: v),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: tokens?.fgTertiary ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CcTypography.body.copyWith(
                    color: tokens?.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: CcTypography.caption.copyWith(
                      color:
                          tokens?.textTertiary ??
                          theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
