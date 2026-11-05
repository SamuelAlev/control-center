import 'package:cc_domain/cc_domain.dart' show BuildInfo;
import 'package:cc_domain/features/changelog/domain/entities/changelog_release.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/changelog/providers/changelog_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart' show rootNavigatorKey;
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const String _changelogPageUrl = 'https://usectrl.dev/changelog';

/// Opens the What's new dialog over the root navigator.
Future<void> showChangelogDialog(BuildContext context) => showCcDialog<void>(
  context: rootNavigatorKey.currentContext ?? context,
  builder: (_) => const ChangelogDialog(),
);

/// The website's changelog, newest release first, with the running build
/// marked. The entries are published in English only.
class ChangelogDialog extends ConsumerWidget {
  /// Creates a [ChangelogDialog].
  const ChangelogDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final releases = ref.watch(changelogProvider);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 640, maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.panel,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: t.borderPrimary),
          boxShadow: CcElevation.floating,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 12, 12),
              child: Row(
                children: [
                  Icon(AppIcons.rocket, size: 18, color: t.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.helpWhatsNew,
                      style: CcTypography.title.copyWith(color: t.textPrimary),
                    ),
                  ),
                  CcIconButton(
                    icon: AppIcons.externalLink,
                    tooltip: l10n.changelogOpenWebsite,
                    onPressed: () => openExternalUrl(_changelogPageUrl),
                  ),
                  CcIconButton(
                    icon: AppIcons.x,
                    tooltip: l10n.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const CcDivider(),
            Flexible(
              child: switch (releases) {
                AsyncData(:final value) => ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: value.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.xxl),
                  itemBuilder: (_, index) =>
                      _ReleaseSection(release: value[index]),
                ),
                AsyncError() => _LoadFailed(
                  onRetry: () => ref.invalidate(changelogProvider),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Center(child: CcSpinner(size: 18)),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.changelogLoadFailed,
            textAlign: TextAlign.center,
            style: CcTypography.body.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          CcButton(
            onPressed: onRetry,
            variant: CcButtonVariant.line,
            size: CcButtonSize.sm,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _ReleaseSection extends StatelessWidget {
  const _ReleaseSection({required this.release});

  final ChangelogRelease release;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final releasedOn = release.releasedOn;
    final body = CcTypography.body.copyWith(color: t.textPrimary);
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              release.version,
              style: CcTypography.title.copyWith(color: t.textPrimary),
            ),
            if (release.version == BuildInfo.buildVersion) ...[
              const SizedBox(width: AppSpacing.sm),
              CcBadge(
                label: l10n.changelogInstalled,
                variant: CcBadgeVariant.success,
              ),
            ],
            const Spacer(),
            if (releasedOn == null)
              Text(release.dateLabel, style: caption)
            else
              AppTimestamp(
                dateTime: releasedOn,
                child: Text(
                  DateFormat.yMMMd(
                    Localizations.localeOf(context).toString(),
                  ).format(releasedOn),
                  style: caption,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const CcDivider(),
        const SizedBox(height: AppSpacing.md),
        if (release.title.isNotEmpty) ...[
          Text(
            release.title,
            style: body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        if (release.lead.isNotEmpty) Text(release.lead, style: body),
        for (final group in release.groups) _ChangeGroup(group: group),
        if (release.note case final note?) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(note, style: caption),
        ],
      ],
    );
  }
}

class _ChangeGroup extends StatelessWidget {
  const _ChangeGroup({required this.group});

  final ChangelogChangeGroup group;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final heading = switch (group.type) {
      ChangelogChangeType.added => l10n.changelogGroupNew,
      ChangelogChangeType.improved => l10n.changelogGroupImproved,
      ChangelogChangeType.fixed => l10n.changelogGroupFixed,
      ChangelogChangeType.other => null,
    };
    final style = CcTypography.body.copyWith(color: t.textPrimary);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heading != null) ...[
            Text(
              heading,
              style: CcTypography.label.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          for (final item in group.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 10, 0),
                    child: SizedBox.square(
                      dimension: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: t.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: Text(item, style: style)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
