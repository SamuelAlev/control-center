import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NoMatchesRow extends StatelessWidget {
  const NoMatchesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.filterX, size: 14, color: colors.mutedForeground),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).noPrsMatchFilters,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadMoreRow extends StatelessWidget {
  const LoadMoreRow({super.key, required this.loading, required this.onLoad});

  final bool loading;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: FTappable.static(
          onPress: loading ? null : onLoad,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: FCircularProgress(),
                  )
                else
                  Icon(
                    LucideIcons.chevronsDown,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                const SizedBox(width: 8),
                Text(
                  loading
                      ? AppLocalizations.of(context).loadingMorePrs
                      : AppLocalizations.of(context).loadMorePrs,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
