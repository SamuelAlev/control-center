import 'dart:async';

import 'package:cc_data/cc_data.dart' show SandboxExecGrantView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/providers/sandbox_exec_grant_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A list longer than this earns the search field (the settings kit's rule).
const int _kFilterThreshold = 8;

/// Settings → Server → Sandbox → Executable grants.
///
/// The audit surface for a decision the operator can only ever have made by
/// answering a prompt: which working copies agents may run programs from.
///
/// Blocked trees are listed alongside allowed ones on purpose — "you already
/// said no" is why a prompt stopped appearing, and with no row for it that is
/// indistinguishable from the feature being broken.
///
/// Every agent working copy the operator allowed leaves a row, so the list is
/// paged and searched on the server rather than loaded whole.
class SandboxExecGrantsSection extends ConsumerStatefulWidget {
  /// Creates a [SandboxExecGrantsSection].
  const SandboxExecGrantsSection({super.key});

  @override
  ConsumerState<SandboxExecGrantsSection> createState() =>
      _SandboxExecGrantsSectionState();
}

class _SandboxExecGrantsSectionState
    extends ConsumerState<SandboxExecGrantsSection> {
  /// What the field shows, updated on every keystroke.
  String _typed = '';

  /// What the server is asked for, settled after a pause in typing.
  String _query = '';

  Timer? _debounce;

  /// The last loaded list, kept on screen while a new query loads so typing
  /// does not flash a spinner over the rows.
  SandboxExecGrantList? _last;

  /// Latched once the list has been long enough to search, so the field does
  /// not vanish when a query narrows the rows below the threshold.
  bool _searchable = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _typed = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null || workspaceId.isEmpty) {
      return const SizedBox.shrink();
    }
    final key = (workspaceId: workspaceId, query: _query);
    final grants = ref.watch(sandboxExecGrantsProvider(key));
    final list = grants.value ?? (grants.isLoading ? _last : null);
    if (grants.value != null) {
      _last = grants.value;
      _searchable = _searchable || grants.value!.total > _kFilterThreshold;
    }

    return SectionCard(
      label: l10n.sandboxExecGrantsTitle,
      subtitle: Text(l10n.sandboxExecGrantsSubtitle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_searchable) ...[
            SettingsFilterBar<void>(
              query: _typed,
              onQueryChanged: _onQueryChanged,
              searchHint: l10n.sandboxExecGrantsSearchHint,
              resultLabel: list == null
                  ? null
                  : l10n.settingsCountOfTotal(list.grants.length, list.total),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (grants.hasError && list == null)
            CcAlert(
              title: failureMessage(l10n, grants.error!),
              variant: CcAlertVariant.danger,
            )
          else if (list == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CcSpinner()),
            )
          else if (list.grants.isEmpty)
            CcEmptyState(
              icon: _query.isEmpty ? AppIcons.shield : AppIcons.searchX,
              size: CcEmptyStateSize.sm,
              message: _query.isEmpty
                  ? l10n.sandboxExecGrantsEmpty
                  : l10n.sandboxExecGrantsNoMatch,
            )
          else ...[
            for (final g in list.grants) _GrantRow(grant: g, listKey: key),
            if (list.loadMoreError != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                child: CcAlert(
                  title: failureMessage(l10n, list.loadMoreError!),
                  variant: CcAlertVariant.danger,
                ),
              ),
            if (list.hasMore)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
                child: Center(
                  child: CcButton(
                    variant: CcButtonVariant.ghost,
                    size: CcButtonSize.sm,
                    loading: list.loadingMore,
                    onPressed: list.loadingMore
                        ? null
                        : () => ref
                              .read(sandboxExecGrantsProvider(key).notifier)
                              .loadMore(),
                    child: Text(l10n.showMore),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _GrantRow extends ConsumerWidget {
  const _GrantRow({required this.grant, required this.listKey});

  final SandboxExecGrantView grant;
  final SandboxExecGrantsKey listKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Status never rides on colour alone — the badge carries its word.
          CcBadge(
            label: grant.allowed
                ? l10n.sandboxExecGrantAllowed
                : l10n.sandboxExecGrantBlocked,
            variant: grant.allowed
                ? CcBadgeVariant.warning
                : CcBadgeVariant.neutral,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grant.path,
                  style: CcFonts.code(
                    textStyle: TextStyle(fontSize: 12, color: t.textPrimary),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                AppTimestamp.relative(
                  grant.createdAt,
                  style: TextStyle(fontSize: 11, color: t.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => _revoke(context, ref, l10n),
            child: Text(l10n.sandboxExecGrantRevoke),
          ),
        ],
      ),
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.sandboxExecGrantRevokeConfirmTitle,
        content: Text(l10n.sandboxExecGrantRevokeConfirmBody),
        actions: [
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.sandboxExecGrantRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(sandboxExecGrantsProvider(listKey).notifier)
        .revoke(grant.id);
  }
}
