import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/account_pool_row.dart';
import 'package:control_center/features/settings/providers/account_pool_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One selectable credential in an [AccountPoolEditor].
class AccountPoolCandidate {
  /// Creates an [AccountPoolCandidate].
  const AccountPoolCandidate({
    required this.id,
    required this.label,
    this.detail,
    this.unavailable = false,
    this.unavailableReason,
  });

  /// Stable id — a Claude Code account id, or a harness credential id.
  final String id;

  /// What to call it in the list.
  final String label;

  /// A quieter second line: the plan, the org, remaining headroom.
  final String? detail;

  /// Whether it cannot serve a run right now (signed out, or cooling off).
  ///
  /// It stays selectable on purpose. Being unavailable is a passing state, and
  /// removing a row from the pool because its window happens to be closed
  /// would quietly rewrite the operator's configuration.
  final bool unavailable;

  /// Why, in one already-localized phrase.
  final String? unavailableReason;
}

/// Edits which credentials a scope may spend, in what order, and how to choose
/// between them.
///
/// ## One editor, two lanes
///
/// The Claude Code adapter's account directories and a harness provider's
/// stored keys are configured identically — an ordered list plus a strategy —
/// so they share this widget rather than each growing a bespoke surface that
/// drifts. What differs is underneath: the harness swaps credential mid-stream,
/// the CLI re-runs the turn. Neither difference is visible here, and neither
/// should be: the operator is expressing intent, not a mechanism.
///
/// ## Ordering is the interface
///
/// The list is explicitly ordered because both non-trivial strategies read it:
/// `serial` drains top-down, `roundRobin` cycles top-down. So the editor moves
/// rows rather than sorting them for you — a list that reordered itself would
/// make "drain this one first" unsayable.
class AccountPoolEditor extends ConsumerWidget {
  /// Creates an [AccountPoolEditor].
  const AccountPoolEditor({
    required this.scope,
    required this.candidates,
    this.emptyHint,
    super.key,
  });

  /// Which pool is being edited.
  final AccountPoolScope scope;

  /// Everything that could be attached, in their natural order.
  final List<AccountPoolCandidate> candidates;

  /// Shown instead of the controls when there is nothing to attach.
  final String? emptyHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    // Fewer than two credentials means there is nothing to choose between, so
    // the whole control is absent rather than disabled.
    if (candidates.length < 2) {
      final hint = emptyHint;
      return hint == null
          ? const SizedBox.shrink()
          : Text(hint, style: TextStyle(fontSize: 12, color: t.fgSecondary));
    }

    final view = ref.watch(accountPoolProvider(scope));
    final resolved = view.value;
    if (resolved == null) {
      // A failed read is a failed read, never a spinner. Riverpod retries a
      // failing provider by itself and each retry re-enters the loading state,
      // so treating "no value yet" as "still loading" spun forever and never
      // once said why — the operator sees an editor that is permanently about
      // to appear.
      if (view.hasError) {
        return Text(
          l10n.accountPoolLoadFailed('${view.error}'),
          style: TextStyle(fontSize: 12, color: t.textErrorPrimary),
        );
      }
      // Centered for the same reason as the accounts card: a stretched
      // spinner renders as a full-width arc rather than a spinner.
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CcSpinner()),
      );
    }

    final configured = resolved.pool;
    final inheriting = configured.isEmpty;
    // With nothing configured the editor shows what WOULD run — the inherited
    // pool, or every credential in its natural order — so the operator edits
    // from the real starting point instead of an empty list that implies
    // nothing is attached.
    final effective = inheriting
        ? (resolved.inherited?.isEmpty ?? true
              ? AccountPool(accountIds: [for (final c in candidates) c.id])
              : resolved.inherited!)
        : configured;

    final attached = [
      for (final id in effective.accountIds)
        if (candidates.any((c) => c.id == id)) id,
    ];
    final detached = [
      for (final c in candidates)
        if (!attached.contains(c.id)) c.id,
    ];

    Future<void> save(AccountPool pool) =>
        saveAccountPool(ref, scope, pool.isEmpty ? null : pool);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.accountPoolStrategy,
              style: TextStyle(fontSize: 12, color: t.fgSecondary),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: CcSegmentedToggle<AccountRotationStrategy>(
                semanticLabel: l10n.accountPoolStrategy,
                value: effective.strategy,
                segments: [
                  CcSegment(
                    value: AccountRotationStrategy.pinned,
                    label: l10n.accountPoolPinned,
                  ),
                  CcSegment(
                    value: AccountRotationStrategy.roundRobin,
                    label: l10n.accountPoolRoundRobin,
                  ),
                  CcSegment(
                    value: AccountRotationStrategy.serial,
                    label: l10n.accountPoolSerial,
                  ),
                ],
                onChanged: (s) =>
                    save(AccountPool(accountIds: attached, strategy: s)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(switch (effective.strategy) {
          AccountRotationStrategy.pinned => l10n.accountPoolPinnedHint,
          AccountRotationStrategy.roundRobin => l10n.accountPoolRoundRobinHint,
          AccountRotationStrategy.serial => l10n.accountPoolSerialHint,
        }, style: TextStyle(fontSize: 11, color: t.fgSecondary)),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < attached.length; i++)
          AccountPoolRow(
            candidate: candidates.firstWhere((c) => c.id == attached[i]),
            attached: true,
            // Order only means something once more than one is attached.
            canMoveUp: i > 0 && attached.length > 1,
            canMoveDown: i < attached.length - 1,
            position: i + 1,
            onToggle: () => save(
              AccountPool(
                accountIds: [
                  for (final id in attached)
                    if (id != attached[i]) id,
                ],
                strategy: effective.strategy,
              ),
            ),
            onMove: (delta) {
              final next = [...attached];
              final item = next.removeAt(i);
              next.insert(i + delta, item);
              return save(
                AccountPool(accountIds: next, strategy: effective.strategy),
              );
            },
          ),
        for (final id in detached)
          AccountPoolRow(
            candidate: candidates.firstWhere((c) => c.id == id),
            attached: false,
            canMoveUp: false,
            canMoveDown: false,
            position: null,
            onToggle: () => save(
              AccountPool(
                accountIds: [...attached, id],
                strategy: effective.strategy,
              ),
            ),
            onMove: (_) async {},
          ),
        if (inheriting) ...[
          const SizedBox(height: 6),
          Text(
            scope.agentId == null
                ? l10n.accountPoolUsingAll
                : l10n.accountPoolInheriting,
            style: TextStyle(fontSize: 11, color: t.fgSecondary),
          ),
        ] else if (scope.agentId != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: () => saveAccountPool(ref, scope, null),
              child: Text(l10n.accountPoolResetToWorkspace),
            ),
          ),
        ],
      ],
    );
  }
}
