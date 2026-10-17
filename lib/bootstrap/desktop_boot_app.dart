import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/foreground_ticker_gate.dart';
import 'package:control_center/shared/widgets/server_activity_overlay.dart'
    show ServerStartupIndicator;
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// The product name, shown as the startup wordmark. A brand name is the same in
/// every locale, so it is not routed through `AppLocalizations`.
const String _productName = 'Control Center';

/// The first-run desktop frame, before native media and server boot.
///
/// Contains no session or cached workspace data. Configured launches skip it;
/// first-run setup reuses its window until the authenticated app can mount.
class DesktopBootApp extends StatelessWidget {
  /// Creates the localized, OS-themed startup surface.
  @Preview(name: 'Desktop startup', group: 'Bootstrap', size: Size(640, 420))
  const DesktopBootApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    final theme = dark ? CcThemeData.dark() : CcThemeData.light();
    return CcTheme(
      data: theme,
      child: ForegroundTickerGate(
        child: WidgetsApp(
          color: theme.tokens.bgPrimary,
          title: _productName,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          textStyle: CcFonts.ui(textStyle: CcTypography.body).copyWith(
            color: theme.tokens.textPrimary,
            decoration: TextDecoration.none,
          ),
          builder: (context, _) {
            final loading = AppLocalizations.of(context).loadingEllipsis;
            return ServerStartupIndicator(
              child: ColoredBox(
                color: theme.tokens.bgPrimary,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(_productName),
                        const SizedBox(height: 16),
                        CcSpinner(semanticLabel: loading),
                        const SizedBox(height: 12),
                        ExcludeSemantics(
                          child: Text(
                            loading,
                            style: TextStyle(color: theme.tokens.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
