import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The words cc_ui's own controls speak and show, in the app's language.
///
/// One [CcStrings] per [AppLocalizations] instance: `CcThemeData` compares
/// its strings by identity, so handing it a fresh object on every build would
/// rebuild everything that reads the theme.
final Expando<CcStrings> _byLocalizations = Expando<CcStrings>();

/// The [CcStrings] for [l10n].
CcStrings ccStringsFor(AppLocalizations l10n) =>
    _byLocalizations[l10n] ??= CcStrings(
      close: l10n.close,
      dismiss: l10n.dismiss,
      loading: l10n.ccLoading,
      progress: l10n.ccProgress,
      breadcrumb: l10n.ccBreadcrumb,
      dialog: l10n.ccDialog,
      clear: l10n.clear,
      clearAll: l10n.clearAll,
      resize: l10n.ccResize,
      notifications: l10n.notifications,
      noMatches: l10n.ideMenuNoMatches,
      selectedCount: l10n.selectedCount,
      remove: l10n.removeLabel,
      unverified: l10n.ccUnverifiedLabel,
    );

/// Gives the [CcTheme] above it the app's translated [CcStrings].
///
/// For hosts whose [CcTheme] sits above their `Localizations` (the startup
/// and connect surfaces build the theme first, then a `WidgetsApp`): placed
/// under the app, it re-publishes the same theme with localized strings.
class LocalizedCcStrings extends StatelessWidget {
  /// Localizes cc_ui's own strings for [child].
  const LocalizedCcStrings({super.key, required this.child});

  /// The subtree that reads the theme.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = CcTheme.of(context);
    return CcTheme(
      data: theme.copyWith(strings: ccStringsFor(AppLocalizations.of(context))),
      child: child,
    );
  }
}
