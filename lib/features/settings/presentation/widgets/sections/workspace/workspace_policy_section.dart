import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_level.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → General: the workspace's own policy fields.
///
/// Both of these existed in the schema, on the wire and in the domain entity,
/// with **no UI anywhere** — so a security control shipped unreachable:
///
///  * `secretExcludeGlobs` — extra path globs hidden from viewers and guests on
///    code-bearing surfaces, layered on top of `SecretExclusionPolicy`'s
///    built-in defaults.
///  * `reviewConcurrency` — how many reviewers `dispatch_reviewers` fans out to
///    when no explicit concurrency is given.
///
/// It also owns the workspace's default **review level**, which belongs beside
/// the fan-out it interacts with rather than in a card of its own.
///
/// Two write lanes, deliberately: the two fields above go through
/// `workspace.upsert` behind the Save button, while the review level rides
/// `workspace_settings` and saves on selection. Admin-gated: these are
/// workspace policy, not preferences.
class WorkspacePolicySection extends ConsumerStatefulWidget {
  /// Creates a [WorkspacePolicySection].
  const WorkspacePolicySection({super.key, required this.workspaceId});

  /// The workspace being configured.
  final String workspaceId;

  @override
  ConsumerState<WorkspacePolicySection> createState() =>
      _WorkspacePolicySectionState();
}

class _WorkspacePolicySectionState
    extends ConsumerState<WorkspacePolicySection> {
  final TextEditingController _globs = TextEditingController();
  int? _concurrency;
  String? _seededFor;
  bool _saving = false;

  @override
  void dispose() {
    _globs.dispose();
    super.dispose();
  }

  /// Seeds the fields once per workspace, so a live update from another client
  /// does not stomp an edit in progress.
  void _seed(Workspace workspace) {
    if (_seededFor == workspace.id) {
      return;
    }
    _seededFor = workspace.id;
    _globs.text = workspace.secretExcludeGlobs.join('\n');
    _concurrency = workspace.reviewConcurrency;
  }

  List<String> get _parsedGlobs => _globs.text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  Future<void> _save(Workspace workspace) async {
    setState(() => _saving = true);
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .upsert(
            Workspace(
              id: workspace.id,
              name: workspace.name,
              logoPath: workspace.logoPath,
              ownerUserId: workspace.ownerUserId,
              secretExcludeGlobs: _parsedGlobs,
              reviewConcurrency: _concurrency ?? workspace.reviewConcurrency,
              createdAt: workspace.createdAt,
              updatedAt: DateTime.now(),
            ),
          );
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).saved,
          variant: CcToastVariant.success,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).failedWithError('$e'),
          variant: CcToastVariant.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _saveReviewLevel(ReviewLevel level) async {
    try {
      await setWorkspaceSetting(ref, kReviewLevelSettingKey, level.wireName);
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).failedWithError('$e'),
          variant: CcToastVariant.danger,
        );
      }
    }
  }

  String _reviewLevelLabel(AppLocalizations l10n, ReviewLevel level) =>
      switch (level) {
        ReviewLevel.light => l10n.reviewLevelLight,
        ReviewLevel.balanced => l10n.reviewLevelBalanced,
        ReviewLevel.thorough => l10n.reviewLevelThorough,
      };

  String _reviewLevelHint(AppLocalizations l10n, ReviewLevel level) =>
      switch (level) {
        ReviewLevel.light => l10n.reviewLevelLightHint,
        ReviewLevel.balanced => l10n.reviewLevelBalancedHint,
        ReviewLevel.thorough => l10n.reviewLevelThoroughHint,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspace = ref.watch(activeWorkspaceProvider);
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(widget.workspaceId))?.isAdmin ??
        false;
    final reviewLevel = ref.watch(workspaceReviewLevelProvider);

    if (workspace == null) {
      return const SizedBox.shrink();
    }
    _seed(workspace);

    return SectionCard(
      label: l10n.settingsWorkspacePolicyLabel,
      subtitle: Text(l10n.settingsWorkspacePolicyDescription),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsSecretGlobsLabel,
            style: CcTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsSecretGlobsHelp,
            style: CcTypography.caption.copyWith(
              color: t.textTertiary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          CcTextField(
            controller: _globs,
            enabled: isAdmin,
            maxLines: 5,
            hintText: '**/secrets/**\n**/*.internal.md',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.settingsReviewConcurrencyLabel,
            style: CcTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsReviewConcurrencyHelp,
            style: CcTypography.caption.copyWith(
              color: t.textTertiary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          CcSlider(
            value: (_concurrency ?? workspace.reviewConcurrency).toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            semanticLabel: l10n.settingsReviewConcurrencyLabel,
            semanticFormatter: (v) => '${v.round()}',
            onChanged: isAdmin
                ? (v) => setState(() => _concurrency = v.round())
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.settingsReviewLevelLabel,
            style: CcTypography.body.copyWith(
              fontWeight: FontWeight.w500,
              color: t.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.settingsReviewLevelHelp,
            style: CcTypography.caption.copyWith(
              color: t.textTertiary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            // Writes immediately rather than waiting for Save: this one rides
            // the `workspace_settings` lane, not the `workspace.upsert` the
            // fields above share, and a single Save button that persisted some
            // of the card's controls and not others would be worse than two
            // honest behaviours.
            child: CcSegmentedToggle<ReviewLevel>(
              value: reviewLevel,
              semanticLabel: l10n.settingsReviewLevelLabel,
              onChanged: isAdmin ? _saveReviewLevel : null,
              segments: [
                for (final level in ReviewLevel.values)
                  CcSegment(
                    value: level,
                    label: _reviewLevelLabel(l10n, level),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _reviewLevelHint(l10n, reviewLevel),
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: CcButton(
              loading: _saving,
              onPressed: isAdmin ? () => _save(workspace) : null,
              child: Text(l10n.saveChanges),
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.settingsWorkspaceAdminOnly,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}
