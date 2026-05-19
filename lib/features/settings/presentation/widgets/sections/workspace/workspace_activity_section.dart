import 'package:cc_domain/cc_domain.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/activity_formatting.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/member_avatar.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace audit trail: who did what, newest first (the server caps the
/// stream length). Each row carries the actor's avatar and name, the op as a
/// mono action chip, a prose description of what happened, the network origin
/// (IP / country) as clickable filter chips and a right-aligned timestamp —
/// hairline-separated so a long trail scans as a ledger, not a text block.
///
/// The body is searchable (name, action, description, target, IP, country)
/// and paginated ten rows per page; IP/country chip taps toggle list-wide
/// filters that compose (AND) with the query and surface as dismissible
/// chips above the list.
class WorkspaceActivitySection extends ConsumerStatefulWidget {
  /// Creates a [WorkspaceActivitySection] for [workspaceId].
  const WorkspaceActivitySection({super.key, required this.workspaceId});

  /// The workspace whose audit trail is shown.
  final String workspaceId;

  @override
  ConsumerState<WorkspaceActivitySection> createState() =>
      _WorkspaceActivitySectionState();
}

class _WorkspaceActivitySectionState
    extends ConsumerState<WorkspaceActivitySection> {
  static const _pageSize = 10;

  final _searchController = TextEditingController();
  String _query = '';
  String? _filterIp;
  String? _filterCountry;
  int _page = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WorkspaceActivitySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      setState(() {
        _page = 0;
        _filterIp = null;
        _filterCountry = null;
      });
    }
  }

  void _toggleIpFilter(String ip) => setState(() {
    _filterIp = _filterIp == ip ? null : ip;
    _page = 0;
  });

  void _toggleCountryFilter(String country) => setState(() {
    _filterCountry = _filterCountry == country ? null : country;
    _page = 0;
  });

  List<UserActivityDto> _filtered(
    AppLocalizations l10n,
    List<UserActivityDto> entries,
    Map<String, UserDto> users,
  ) {
    final query = _query.trim().toLowerCase();
    return entries.where((entry) {
      if (_filterIp != null && entry.ip != _filterIp) {
        return false;
      }
      if (_filterCountry != null &&
          activityCountryLabel(l10n, entry) != _filterCountry) {
        return false;
      }
      return query.isEmpty || _matchesQuery(l10n, entry, users, query);
    }).toList();
  }

  bool _matchesQuery(
    AppLocalizations l10n,
    UserActivityDto entry,
    Map<String, UserDto> users,
    String query,
  ) {
    final user = users[entry.userId];
    final name = user?.displayName.isNotEmpty ?? false
        ? user!.displayName
        : l10n.unknownUserLabel;
    final haystack = [
      name,
      entry.action,
      describeActivity(l10n, entry),
      entry.targetId,
      entry.ip,
      activityCountryLabel(l10n, entry),
    ];
    return haystack.any((s) => s?.toLowerCase().contains(query) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final activityAsync = ref.watch(
      workspaceActivityProvider(widget.workspaceId),
    );
    final users = ref.watch(usersByIdProvider).value ?? const {};
    final entries = activityAsync.asData?.value;

    return SectionCard(
      label: l10n.activityLabel,
      trailing: entries == null || entries.isEmpty
          ? null
          : _CountChip(count: entries.length),
      child: activityAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CcSpinner()),
        ),
        error: (_, _) => Text(
          l10n.couldNotLoadActivity,
          style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Text(
              l10n.noActivityYet,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            );
          }

          final filtered = _filtered(l10n, entries, users);
          final pageCount = filtered.isEmpty
              ? 1
              : (filtered.length + _pageSize - 1) ~/ _pageSize;
          // A shrinking list (filter, search, or a shorter stream) can leave
          // the page index past the end — clamp it back into range.
          if (_page >= pageCount) {
            _page = pageCount - 1;
          }
          final start = _page * _pageSize;
          final end = filtered.length < start + _pageSize
              ? filtered.length
              : start + _pageSize;
          final pageEntries = filtered.sublist(start, end);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CcTextField(
                controller: _searchController,
                size: CcTextFieldSize.sm,
                hintText: l10n.activitySearchHint,
                prefix: Icon(AppIcons.search, size: 16, color: t.textTertiary),
                onChanged: (value) => setState(() {
                  _query = value;
                  _page = 0;
                }),
              ),
              if (_filterIp != null || _filterCountry != null) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (_filterIp != null)
                      _ActiveFilterChip(
                        label: l10n.activityFilterIp(_filterIp!),
                        clearLabel: l10n.activityClearFilter,
                        onClear: () => setState(() => _filterIp = null),
                      ),
                    if (_filterCountry != null)
                      _ActiveFilterChip(
                        label: l10n.activityFilterCountry(_filterCountry!),
                        clearLabel: l10n.activityClearFilter,
                        onClear: () => setState(() => _filterCountry = null),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                Text(
                  l10n.activityNoMatches,
                  style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                )
              else ...[
                for (var i = 0; i < pageEntries.length; i++) ...[
                  if (i > 0) Container(height: 1, color: t.borderSecondary),
                  _ActivityRow(
                    entry: pageEntries[i],
                    user: users[pageEntries[i].userId],
                    description: describeActivity(l10n, pageEntries[i]),
                    country: activityCountryLabel(l10n, pageEntries[i]),
                    onIpTap: () => _toggleIpFilter(pageEntries[i].ip!),
                    onCountryTap: () => _toggleCountryFilter(
                      activityCountryLabel(l10n, pageEntries[i])!,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _PaginationFooter(
                  start: start + 1,
                  end: end,
                  total: filtered.length,
                  onPrevious: _page > 0 ? () => setState(() => _page--) : null,
                  onNext: _page < pageCount - 1
                      ? () => setState(() => _page++)
                      : null,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.entry,
    required this.user,
    required this.description,
    required this.country,
    required this.onIpTap,
    required this.onCountryTap,
  });

  final UserActivityDto entry;
  final UserDto? user;
  final String description;
  final String? country;
  final VoidCallback onIpTap;
  final VoidCallback onCountryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final name = user?.displayName.isNotEmpty ?? false
        ? user!.displayName
        : l10n.unknownUserLabel;
    final createdAt = entry.createdAt;
    final ip = entry.ip;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optical top alignment: the name's 14/20 line box parks its glyphs
          // ~7px below the box top, so drop the avatar to the cap line rather
          // than aligning it to the (higher) box/chip edge.
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: MemberAvatar(
              name: name,
              user: user,
              workspaceId: entry.workspaceId,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.body.copyWith(
                          color: t.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ActionChip(action: entry.action),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                        ),
                      ),
                    ),
                    if (ip != null && ip.isNotEmpty) ...[
                      if (country != null) ...[
                        const SizedBox(width: 8),
                        _MetaChip(label: country!, onPressed: onCountryTap),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '·',
                            style: CcTypography.caption.copyWith(
                              color: t.textTertiary,
                            ),
                          ),
                        ),
                      ] else
                        const SizedBox(width: 8),
                      _MetaChip(label: ip, onPressed: onIpTap),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (createdAt != null) ...[
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AppTimestamp.relative(
                createdAt,
                style: CcFonts.code(
                  textStyle: CcTypography.monoNum.copyWith(
                    fontSize: 12,
                    color: t.textTertiary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The op name (`agents.upsert`) as machine truth: monospace, lowercase, on a
/// quiet surface chip — scannable without pretending to be prose.
class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.action});

  final String action;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: t.bgTertiary,
      child: Text(
        action,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

/// A small mono network token (an IP or a country) in the row meta line.
/// Tertiary at rest, underlined on hover/press — it is a filter toggle, not
/// decoration.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: label,
      semanticButton: false,
      showFocusRing: false,
      builder: (context, states) {
        final highlighted =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused);
        return Text(
          label,
          style: CcFonts.code(
            textStyle: CcTypography.monoNum.copyWith(
              fontSize: 11,
              color: highlighted ? t.textSecondary : t.textTertiary,
              decoration: highlighted ? TextDecoration.underline : null,
              decorationColor: t.textTertiary,
            ),
          ),
        );
      },
    );
  }
}

/// An active list filter (IP or country) rendered above the rows: the value
/// plus an inline clear affordance. Tapping the x drops just this filter.
class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.clearLabel,
    required this.onClear,
  });

  final String label;
  final String clearLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      color: t.bgTertiary,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: CcFonts.code(
              textStyle: CcTypography.monoNum.copyWith(
                fontSize: 12,
                color: t.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          CcTappable(
            onPressed: onClear,
            semanticLabel: clearLabel,
            showFocusRing: false,
            builder: (context, states) {
              final highlighted =
                  states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.pressed);
              return Icon(
                AppIcons.x,
                size: 12,
                color: highlighted ? t.textPrimary : t.textTertiary,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The footer ledger line (`1–10 of 47`) plus previous/next ghost buttons,
/// hairline-separated from the rows above. Buttons disable at the bounds by
/// dropping their handler.
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
        border: Border(top: BorderSide(color: t.borderSecondary, width: 1)),
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

/// The header count: how many entries the (server-capped) trail currently
/// shows, in tabular mono on a quiet chip.
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
