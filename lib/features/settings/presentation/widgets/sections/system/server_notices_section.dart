import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/providers/backup_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the Backups page shows [ServerNoticesSection]: the server owner
/// has open notices, or they could not be read.
bool showServerNotices(WidgetRef ref) {
  final notices = ref.watch(serverNoticesProvider);
  return notices.hasError || (notices.value?.isNotEmpty ?? false);
}

/// Settings → Server → Backup & restore: what only the server owner can fix,
/// first on the page because the fix (a restore) is right below it.
///
/// Today that is a workspace whose database failed its integrity check: it
/// serves reads and refuses writes until restored. Each notice names the
/// workspace, since when, and what to do; the database's own finding is
/// there for diagnosis, behind Details, in its own words.
class ServerNoticesSection extends ConsumerWidget {
  /// Creates the section.
  const ServerNoticesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final names = {
      for (final w
          in ref.watch(workspacesProvider).value ?? const <Workspace>[])
        w.id: w.name,
    };

    return switch (ref.watch(serverNoticesProvider)) {
      AsyncData(:final value) when value.isNotEmpty => SectionCard(
        label: l10n.serverNoticesLabel,
        count: value.length,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final notice in value)
              _ReadOnlyNoticeRow(
                key: ValueKey('${notice.kind.wire}:${notice.subject}'),
                notice: notice,
                workspaceName: names[notice.subject],
              ),
          ],
        ),
      ),
      AsyncError(:final error) => SectionCard(
        label: l10n.serverNoticesLabel,
        child: Text(
          failureMessage(l10n, error),
          style: CcTypography.bodySm.copyWith(color: tokens.textErrorPrimary),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// A workspace that is read-only until restored. Always open: the row is
/// there to be acted on, and its instruction is the point of it.
class _ReadOnlyNoticeRow extends StatelessWidget {
  const _ReadOnlyNoticeRow({
    super.key,
    required this.notice,
    required this.workspaceName,
  });

  final ServerNotice notice;
  final String? workspaceName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final since = notice.createdAt;
    final detail = notice.detail;

    return SettingsEntityRow(
      // The id when this client does not know the workspace by name: a
      // notice about a workspace nobody can name is still one to act on.
      title: workspaceName ?? notice.subject,
      icon: AppIcons.lock,
      tone: CcStatusTone.negative,
      statusLabel: l10n.serverNoticeReadOnlyStatus,
      subtitleWidget: AppTimestamp(
        dateTime: since,
        child: Text(
          l10n.serverNoticeSince(formatRelativeTime(context, since)),
          style: CcTypography.caption.copyWith(color: tokens.textTertiary),
        ),
      ),
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.serverNoticeReadOnlyBody,
            style: CcTypography.bodySm.copyWith(color: tokens.textSecondary),
          ),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SettingsDisclosure(
              title: l10n.serverNoticeDetails,
              dense: true,
              // Copyable rather than selectable (the kit has no Material
              // selection): the whole finding is what goes into a report.
              child: SettingsCopyField(value: detail, maxLines: 8),
            ),
          ],
        ],
      ),
    );
  }
}
