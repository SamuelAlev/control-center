import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/server_activity_panel.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// Preview of concurrent background model work in the light theme.
@Preview(name: 'Server activity · light', group: 'Server', size: Size(640, 480))
Widget serverActivityLightPreview() => _preview(false);

/// Preview of persistent download failure in the dark theme.
@Preview(name: 'Server activity · dark', group: 'Server', size: Size(390, 600))
Widget serverActivityDarkPreview() => _preview(true);

Widget _preview(bool dark) {
  final theme = dark ? CcThemeData.dark() : CcThemeData.light();
  return CcTheme(
    data: theme,
    child: WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: theme.tokens.bgPrimary,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        return ColoredBox(
          color: theme.tokens.bgPrimary,
          child: ServerActivityPanel(
            entries: [
              ServerActivityEntry(
                id: 'voice',
                title: 'Parakeet TDT v3',
                message: l10n.downloadingLabel,
                busy: true,
                progress: 0.42,
              ),
              ServerActivityEntry(
                id: 'embedding',
                title: l10n.embeddingModel,
                message: l10n.serverActivityDownloadFailed,
                error: 'Connection closed before the download completed.',
              ),
            ],
          ),
        );
      },
    ),
  );
}
