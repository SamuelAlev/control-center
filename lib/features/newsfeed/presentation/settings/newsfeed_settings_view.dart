import 'package:cc_ui/cc_ui.dart';

import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/newsfeed/presentation/settings/newsfeed_feeds_section.dart';
import 'package:control_center/features/newsfeed/presentation/settings/newsfeed_filter_list_section.dart';
import 'package:control_center/features/newsfeed/presentation/settings/newsfeed_reader_preferences_section.dart';
import 'package:control_center/features/newsfeed/presentation/settings/newsfeed_trusted_sites_section.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → You → Newsfeed: the signed-in user's feed registry and reader
/// preferences. The newsfeed is PER-USER, so this lives under the `You` scope
/// (it followed the user, not the server), not on the newsfeed page.
class NewsfeedSettingsView extends ConsumerWidget {
  /// Creates a new [NewsfeedSettingsView].
  const NewsfeedSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockContent = ref.watch(contentBlockingProvider);
    final l10n = AppLocalizations.of(context);
    final isDemo = ref.watch(isDemoServerProvider);

    return SettingsPage(
      title: l10n.newsfeedSettingsTitle,
      subtitle: l10n.newsfeedSettingsDescription,
      actions: [
        CcTooltip(
          // demo: real feeds, fixed list — `newsfeed.addFeed` is not exposed.
          message: isDemo ? l10n.demoUnavailableFeeds : '',
          child: CcButton(
            onPressed: isDemo ? null : () => showAddFeedDialog(context, ref),
            icon: AppIcons.plus,
            size: CcButtonSize.sm,
            child: Text(l10n.addFeed),
          ),
        ),
      ],
      sections: [
        const NewsfeedReaderPreferencesSection(),
        // Content blocking (and its filter lists / trusted sites) drives the
        // DESKTOP in-app ad-blocking webview. On web the browser is the
        // reader, so there is nothing to configure — hide rather than show
        // inert switches over an all-zero filter list.
        if (blockContent && !kIsWeb) ...[
          const NewsfeedFilterListSection(),
          const NewsfeedTrustedSitesSection(),
        ],
        const NewsfeedFeedsSection(),
      ],
    );
  }
}
