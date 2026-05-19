import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/app_log_level.dart';
import 'package:control_center/core/providers/app_log_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// General Settings → Logging level selector.
///
/// Reuses the card-based option pattern from the old sandbox log-level UI.
class LoggingSection extends ConsumerWidget {
  /// Creates a [LoggingSection].
  const LoggingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(appLogLevelProvider);
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.logLevel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in AppLogLevel.values)
            _LogLevelOption(
              option: option,
              selected: option == level,
              onSelect: () async {
                await ref
                    .read(appLogPreferencesProvider)
                    .setLogLevel(option);
                ref.invalidate(appLogPreferencesProvider);
              },
            ),
        ],
      ),
    );
  }
}

class _LogLevelOption extends StatelessWidget {
  const _LogLevelOption({
    required this.option,
    required this.selected,
    required this.onSelect,
  });

  final AppLogLevel option;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final borderColor = selected
        ? (tokens?.borderBrand ?? tokens?.textPrimary ?? Colors.grey)
        : (tokens?.borderSecondary ?? Colors.grey);
    final bg = selected
        ? (tokens?.bgBrandPrimary ?? Colors.transparent)
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onSelect,
        borderRadius: AppRadii.brSm,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: borderColor),
            borderRadius: AppRadii.brSm,
          ),
          child: Row(
            children: [
              Icon(
                _iconFor(option),
                size: 18,
                color: tokens?.fgSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.resolvedLabel(AppLocalizations.of(context)),
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: tokens?.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.resolvedDescription(AppLocalizations.of(context)),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: tokens?.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (selected)
                Icon(
                  LucideIcons.circleCheck,
                  size: 18,
                  color: tokens?.fgBrandPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _iconFor(AppLogLevel level) {
    switch (level) {
      case AppLogLevel.none:
        return LucideIcons.volumeOff;
      case AppLogLevel.error:
        return LucideIcons.alertCircle;
      case AppLogLevel.warning:
        return LucideIcons.alertTriangle;
      case AppLogLevel.info:
        return LucideIcons.info;
      case AppLogLevel.debug:
        return LucideIcons.bug;
      case AppLogLevel.verbose:
        return LucideIcons.terminal;
    }
  }
}
