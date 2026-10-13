import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/merged_space_archive_prompt.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// Light desktop notice, with interactive archive and keep actions.
@Preview(name: 'Merged space — light', group: 'Spaces', size: Size(800, 240))
Widget mergedSpaceLightPreview() => const _MergedSpacePreview();

/// Dark desktop notice.
@Preview(name: 'Merged space — dark', group: 'Spaces', size: Size(800, 240))
Widget mergedSpaceDarkPreview() => const _MergedSpacePreview(dark: true);

/// Narrow Arabic notice with naturally mirrored actions.
@Preview(
  name: 'Merged space — narrow RTL',
  group: 'Spaces',
  size: Size(390, 320),
)
Widget mergedSpaceRtlPreview() => const _MergedSpacePreview(rtl: true);

class _MergedSpacePreview extends StatefulWidget {
  const _MergedSpacePreview({this.dark = false, this.rtl = false});

  final bool dark;
  final bool rtl;

  @override
  State<_MergedSpacePreview> createState() => _MergedSpacePreviewState();
}

class _MergedSpacePreviewState extends State<_MergedSpacePreview> {
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.dark ? CcThemeData.dark() : CcThemeData.light();
    return WidgetsApp(
      color: theme.tokens.bgPrimary,
      debugShowCheckedModeBanner: false,
      locale: Locale(widget.rtl ? 'ar' : 'en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => CcTheme(
        data: theme,
        child: Builder(
          builder: (context) => DefaultTextStyle(
            style: CcFonts.ui(textStyle: CcTypography.body).copyWith(
              color: theme.tokens.textPrimary,
              decoration: TextDecoration.none,
            ),
            child: child!,
          ),
        ),
      ),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: ColoredBox(
        color: theme.tokens.bgPrimary,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: _answered
                ? const SizedBox.shrink()
                : MergedSpaceArchiveNotice(
                    onArchive: () => setState(() => _answered = true),
                    onKeep: () => setState(() => _answered = true),
                  ),
          ),
        ),
      ),
    );
  }
}
