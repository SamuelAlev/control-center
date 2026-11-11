import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/value_objects/audit_log_page.dart'
    show AuditLogPageDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audit/audit_log_row.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audit/audit_log_toolbar.dart';
import 'package:control_center/features/settings/providers/audit_log_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The audit log: one ledger of who did what, newest first, over the server
/// trail (server owner only) and the trail of every workspace the person
/// administers. Searchable, filterable by actor, workspace, outcome, time,
/// address and country, and paginated against the server (keyset cursor,
/// real total). The page is `?cursor=` on the URL; any filter change returns
/// to the newest page.
class AuditLogSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const AuditLogSection({super.key});

  @override
  ConsumerState<AuditLogSection> createState() => _AuditLogSectionState();
}

class _AuditLogSectionState extends ConsumerState<AuditLogSection> {
  String? _localCursor;

  String? _routeCursor() {
    if (GoRouter.maybeOf(context) == null) {
      return _localCursor;
    }
    final cursor = GoRouterState.of(context).uri.queryParameters['cursor'];
    return cursor == null || cursor.isEmpty ? null : cursor;
  }

  void _setCursor(String? cursor) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      final next = uriWithCursor(router.state.uri, cursor);
      if (next != router.state.uri.toString()) {
        router.go(next);
      }
      return;
    }
    if (_localCursor != cursor) {
      setState(() => _localCursor = cursor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final quiet = CcTypography.bodySm.copyWith(color: t.textTertiary);
    if (!ref.watch(canSeeAuditLogProvider)) {
      return SectionCard(
        label: l10n.activityLabel,
        child: CcAlert(
          title: l10n.auditLogNoAccessTitle,
          description: Text(l10n.auditLogNoAccess),
        ),
      );
    }
    final users = ref.watch(usersByIdProvider).value ?? const {};
    final filters = ref.watch(auditLogFiltersProvider);
    final query = filters.query(
      cursor: _routeCursor(),
      users: users,
      localLabel: l10n.activityNetworkLocal,
    );
    final async = ref.watch(auditLogPageProvider(query));
    final page = async.asData?.value;

    return SectionCard(
      label: l10n.activityLabel,
      trailing: page == null || page.total == 0
          ? null
          : _CountChip(count: page.total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuditLogToolbar(
            page: page,
            users: users,
            onFiltersChanged: () => _setCursor(null),
          ),
          const SizedBox(height: AppSpacing.md),
          async.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CcSpinner()),
            ),
            error: (_, _) => Text(
              l10n.couldNotLoadActivity,
              style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
            ),
            data: (page) {
              if (page.scopes.isEmpty) {
                return CcAlert(
                  title: l10n.auditLogNoAccessTitle,
                  description: Text(l10n.auditLogNoAccess),
                );
              }
              if (page.entries.isEmpty &&
                  page.total > 0 &&
                  query.cursor != null) {
                // The cursor's page is gone (pruned rows): back to newest.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _setCursor(null);
                  }
                });
              }
              if (page.entries.isEmpty) {
                return Text(
                  filters.isFiltering
                      ? l10n.activityNoMatches
                      : l10n.noActivityYet,
                  style: quiet,
                );
              }
              return _Rows(
                page: page,
                users: users,
                hasCursor: query.cursor != null,
                onCursor: _setCursor,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Rows extends ConsumerWidget {
  const _Rows({
    required this.page,
    required this.users,
    required this.hasCursor,
    required this.onCursor,
  });

  final AuditLogPageDto page;
  final Map<String, UserDto> users;
  final bool hasCursor;
  final ValueChanged<String?> onCursor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final scopeNames = {
      for (final s in page.scopes) s.key: auditScopeLabel(l10n, s),
    };
    final multiple = page.scopes.length > 1;
    final filters = ref.read(auditLogFiltersProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, entry) in page.entries.indexed) ...[
          if (i > 0) Container(height: 1, color: t.borderSecondary),
          AuditLogEntryRow(
            entry: entry,
            user: users[entry.userId],
            sourceLabel: multiple
                ? scopeNames[entry.source] ?? l10n.auditLogSourceWorkspace
                : null,
            onIpTap: (ip) {
              filters.toggleIp(ip);
              onCursor(null);
            },
            onCountryTap: (country) {
              filters.toggleCountry(country);
              onCursor(null);
            },
          ),
        ],
        const SizedBox(height: 10),
        _PaginationFooter(
          start: page.start,
          end: page.end,
          total: page.total,
          onPrevious: page.prevCursor != null || hasCursor
              ? () => onCursor(page.prevCursor)
              : null,
          onNext: page.nextCursor != null
              ? () => onCursor(page.nextCursor)
              : null,
        ),
      ],
    );
  }
}

/// The footer ledger line (`1–25 of 47`) plus previous/next ghost buttons,
/// hairline-separated from the rows above. Buttons disable at the bounds.
class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.start,
    required this.end,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int start;
  final int end;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.borderSecondary)),
      ),
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Text(
            l10n.activityPageRange(start, end, total),
            style: CcFonts.code(
              textStyle: CcTypography.monoNum.copyWith(
                fontSize: 12,
                color: t.textTertiary,
              ),
            ),
          ),
          const Spacer(),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            semanticLabel: l10n.activityPreviousPage,
            onPressed: onPrevious,
            child: const Icon(AppIcons.chevronLeft, size: 16),
          ),
          const SizedBox(width: 4),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            semanticLabel: l10n.activityNextPage,
            onPressed: onNext,
            child: const Icon(AppIcons.chevronRight, size: 16),
          ),
        ],
      ),
    );
  }
}

/// The header count: how many records match, in tabular mono on a chip.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: t.bgTertiary,
      child: Text(
        '$count',
        style: CcFonts.code(
          textStyle: CcTypography.monoNum.copyWith(
            fontSize: 12,
            color: t.textSecondary,
          ),
        ),
      ),
    );
  }
}
