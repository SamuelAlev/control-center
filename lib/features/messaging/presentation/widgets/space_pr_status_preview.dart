import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter/widgets.dart';

/// Toggle distinct PR states and inspect normal and selected leading glyphs.
@Preview(name: 'Space PR states — light', group: 'Spaces', size: Size(560, 300))
Widget spacePrStatusLightPreview() => const _SpacePrStatusPreview();

/// Dark-theme status colors, including the selected-row contrast backing.
@Preview(name: 'Space PR states — dark', group: 'Spaces', size: Size(560, 300))
Widget spacePrStatusDarkPreview() => const _SpacePrStatusPreview(dark: true);

/// The physical sector order remains stable in mirrored sidebar chrome.
@Preview(name: 'Space PR states — RTL', group: 'Spaces', size: Size(390, 340))
Widget spacePrStatusRtlPreview() => const _SpacePrStatusPreview(rtl: true);

class _SpacePrStatusPreview extends StatefulWidget {
  const _SpacePrStatusPreview({this.dark = false, this.rtl = false});

  final bool dark;
  final bool rtl;

  @override
  State<_SpacePrStatusPreview> createState() => _SpacePrStatusPreviewState();
}

class _SpacePrStatusPreviewState extends State<_SpacePrStatusPreview> {
  int _mask = PrSidebarStatus.closed.mask | PrSidebarStatus.merged.mask;

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
        child: DefaultTextStyle(
          style: CcFonts.ui(textStyle: CcTypography.body).copyWith(
            color: theme.tokens.textPrimary,
            decoration: TextDecoration.none,
          ),
          child: child!,
        ),
      ),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return ColoredBox(
            color: theme.tokens.bgPrimary,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final status in PrSidebarStatus.values)
                        CcCheckbox(
                          value: _mask & status.mask != 0,
                          label: Text(status.label(l10n)),
                          onChanged: (value) => setState(() {
                            _mask = value
                                ? _mask | status.mask
                                : _mask & ~status.mask;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final selected in [false, true])
                    ColoredBox(
                      color: selected
                          ? theme.tokens.bgBrandSolid
                          : theme.tokens.bgPrimary,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            for (final size in [18.0, 54.0]) ...[
                              if (_mask != 0)
                                PrStatusBadge(
                                  statusMask: _mask,
                                  size: size,
                                  selected: selected,
                                )
                              else
                                Icon(
                                  AppIcons.pencil,
                                  size: size,
                                  color: selected
                                      ? theme.tokens.accentOn
                                      : theme.tokens.textTertiary,
                                ),
                              const SizedBox(width: AppSpacing.lg),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
