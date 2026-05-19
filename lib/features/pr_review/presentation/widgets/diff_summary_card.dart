import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/file_change.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Summary card showing PR diff statistics.
class DiffSummaryCard extends ConsumerWidget {
  /// Creates a diff summary card.
  const DiffSummaryCard({
    super.key,
    this.filesChanged = 0,
    this.additions = 0,
    this.deletions = 0,
    this.files = const [],
  });

  /// Number of files changed.
  final int filesChanged;

  /// Number of lines added.
  final int additions;

  /// Number of lines removed.
  final int deletions;

  /// Per-file change details.
  final List<FileChange> files;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codeFont = ref.watch(codeFontFamilyProvider);

    return SectionCard(
      title: Text(AppLocalizations.of(context).changesSummary),
      subtitle: Text(
        '$filesChanged file${filesChanged == 1 ? "" : "s"} changed',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatBadge(label: '+$additions', color: Colors.green),
              const SizedBox(width: 8),
              _StatBadge(label: '-$deletions', color: Colors.red),
            ],
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...files.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      f.isNew
                          ? LucideIcons.filePlus
                          : f.isDeleted
                          ? LucideIcons.trash2
                          : LucideIcons.fileEdit,
                      size: 14,
                      color: f.isNew
                          ? Colors.green
                          : f.isDeleted
                          ? Colors.red
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.path,
                        style: AppFonts.codeDynamic(
                          codeFont,
                          textStyle: theme.textTheme.bodySmall,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '+${f.additions}  -${f.deletions}',
                      style: AppFonts.codeDynamic(
                        codeFont,
                        textStyle: theme.textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CcBadge(
      label: label,
      variant: color == Colors.green
          ? CcBadgeVariant.success
          : CcBadgeVariant.danger,
    );
  }
}
