import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/widgets.dart';

/// Center pane: the in-app UI visual diff (PRD 18 §4). Shows before/after
/// renders (when servable) with the changed-region percentage and an "approve
/// intended change" gate. When the host can't render (no Flutter SDK / no
/// Widgetbook), the axis reports "unavailable" honestly instead.
class VisualDiffPanel extends StatelessWidget {
  /// Creates a [VisualDiffPanel].
  const VisualDiffPanel({
    super.key,
    required this.snapshots,
    required this.visualAxis,
    required this.onApprove,
  });

  /// The visual snapshots.
  final List<VisualDiffSnapshot> snapshots;

  /// The visual axis result (drives the honest "unavailable" state).
  final ReviewAxisResult? visualAxis;

  /// Called when the operator approves an intended change.
  final void Function(String snapshotId, VisualDiffStatus status) onApprove;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    if (visualAxis?.verdict == ReviewAxisVerdict.unavailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.imageOff, size: 28, color: ds.textTertiary),
              const SizedBox(height: 10),
              Text(
                l10n.reviewStudioVisualUnavailable,
                style: TextStyle(color: ds.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                visualAxis?.note ?? '',
                style: TextStyle(color: ds.textTertiary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (snapshots.isEmpty) {
      return Center(
        child: Text(
          l10n.reviewStudioNoVisualChanges,
          style: TextStyle(color: ds.textTertiary, fontSize: 13),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final s in snapshots)
          _SnapshotCard(snapshot: s, onApprove: onApprove),
      ],
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({required this.snapshot, required this.onApprove});

  final VisualDiffSnapshot snapshot;
  final void Function(String, VisualDiffStatus) onApprove;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final variant = snapshot.variants.isEmpty ? null : snapshot.variants.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ds.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ds.borderPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  snapshot.componentTitle,
                  style: TextStyle(
                    color: ds.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _statusBadge(ds, l10n),
            ],
          ),
          if (snapshot.maxChangedPercent > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                l10n.reviewStudioChangedRegion(
                  snapshot.maxChangedPercent.toStringAsFixed(1),
                ),
                style: TextStyle(color: ds.textSecondary, fontSize: 12),
              ),
            ),
          const SizedBox(height: 10),
          _imagesRow(context, ds, l10n, variant),
          if (snapshot.blocksGate) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: CcButton(
                variant: CcButtonVariant.primary,
                onPressed: () =>
                    onApprove(snapshot.id, VisualDiffStatus.approved),
                child: Text(l10n.reviewStudioApproveChange),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imagesRow(
    BuildContext context,
    DesignSystemTokens ds,
    AppLocalizations l10n,
    VisualDiffVariant? variant,
  ) {
    if (variant == null) {
      return const SizedBox.shrink();
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _image(context, ds, l10n, variant.baseImageRef, 'base'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _image(
            context,
            ds,
            l10n,
            variant.diffImageRef ?? variant.headImageRef,
            'head',
          ),
        ),
      ],
    );
  }

  Widget _image(
    BuildContext context,
    DesignSystemTokens ds,
    AppLocalizations l10n,
    String? ref,
    String label,
  ) {
    final url = ref == null ? '' : MediaProxyScope.urlOf(context, ref);
    final servable = url.startsWith('http');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: ds.textTertiary, fontSize: 10)),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 4 / 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ds.bgSecondary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ds.borderPrimary),
            ),
            child: servable
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Image.network(
                        url,
                        fit: BoxFit.contain,
                        // Decode at the THUMBNAIL size. These are
                        // full-resolution screenshots painted into a 4:3 tile;
                        // `width`/`height` would bind the paint size only, so
                        // without this the full frame is decoded and held.
                        cacheWidth: constraints.maxWidth.isFinite
                            ? (constraints.maxWidth *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .round()
                            : null,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      l10n.reviewStudioRenderedOnHost,
                      style: TextStyle(color: ds.textTertiary, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(DesignSystemTokens ds, AppLocalizations l10n) {
    final (label, color) = switch (snapshot.status) {
      VisualDiffStatus.added => (l10n.reviewStudioVisualAdded, ds.accent),
      VisualDiffStatus.changed => (l10n.reviewStudioVisualChanged, ds.warn),
      VisualDiffStatus.removed => (l10n.reviewStudioVisualRemoved, ds.danger),
      VisualDiffStatus.approved => (
        l10n.reviewStudioVisualApproved,
        ds.success,
      ),
      VisualDiffStatus.unchanged => (
        l10n.reviewStudioVisualUnchanged,
        ds.textTertiary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
