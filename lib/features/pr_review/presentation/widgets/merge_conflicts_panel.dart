import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_merge_conflicts_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The merge flyout's body while a pull request conflicts with its base: the
/// conflicting files, and a button that hands them to an agent.
///
/// Replaces the merge form rather than sitting above it, because GitHub
/// refuses that merge outright (`405`) — offering a merge button that can only
/// fail is the state this exists to end.
class MergeConflictsPanel extends ConsumerStatefulWidget {
  /// Creates a [MergeConflictsPanel].
  const MergeConflictsPanel({
    super.key,
    required this.pr,
    required this.prRef,
    required this.onFixStarted,
  });

  /// The conflicting pull request.
  final PullRequest pr;

  /// The PR's identity key (repo coords + number).
  final PrRef prRef;

  /// Called once an agent is resolving the conflicts, so the host can close.
  final VoidCallback onFixStarted;

  @override
  ConsumerState<MergeConflictsPanel> createState() =>
      _MergeConflictsPanelState();
}

class _MergeConflictsPanelState extends ConsumerState<MergeConflictsPanel> {
  bool _starting = false;

  // Tall enough for a typical conflict; a long list scrolls in place so the
  // fix button never leaves the flyout.
  static const _listMaxHeight = 240.0;

  Future<void> _fix() async {
    if (_starting) {
      return;
    }
    // Captured up front and not gated on `mounted`: the host closes the
    // flyout on success, and the toast scope lives at the app shell.
    final l10n = AppLocalizations.of(context);
    final toaster = CcToastScope.maybeOf(context);
    final slash = widget.prRef.repoFullName.indexOf('/');
    setState(() => _starting = true);
    try {
      await ref
          .read(reviewStudioRepositoryProvider)
          .fixMergeConflicts(
            workspaceId: widget.prRef.workspaceId,
            owner: widget.prRef.repoFullName.substring(0, slash),
            repo: widget.prRef.repoFullName.substring(slash + 1),
            prNumber: widget.prRef.number,
          );
      // The fix may have minted the PR's space; the chat tab keys off it.
      ref.invalidate(reviewSpaceForPrProvider(widget.pr.externalId));
      toaster?.show(l10n.fixConflictsStarted, variant: CcToastVariant.success);
      widget.onFixStarted();
    } on RemoteRpcException catch (e) {
      toaster?.show(
        l10n.failedToStartConflictFix(e.message),
        variant: CcToastVariant.danger,
      );
    } on Exception catch (e) {
      toaster?.show(
        l10n.failedToStartConflictFix('$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final isDemo = ref.watch(isDemoServerProvider);
    final conflicts = isDemo
        ? null
        : ref.watch(prMergeConflictsProvider(widget.prRef));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              AppIcons.alertTriangle,
              size: 16,
              color: tokens.fgWarningPrimary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.mergeConflictsWithBase,
                style: CcTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (conflicts != null) ...[
          const SizedBox(height: 10),
          conflicts.when(
            loading: () => _Status(
              leading: const CcSpinner(size: 14),
              text: l10n.mergeConflictsLoading,
            ),
            error: (_, _) => _Status(
              text: l10n.mergeConflictsLoadFailed,
              trailing: CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                onPressed: () =>
                    ref.invalidate(prMergeConflictsProvider(widget.prRef)),
                child: Text(l10n.retry),
              ),
            ),
            data: (list) => list.files.isEmpty
                ? _Status(text: l10n.mergeConflictsNoneFound)
                : _FileList(
                    files: list.files,
                    summary: l10n.mergeConflictsFileCount(
                      list.files.length,
                      list.baseRef.isEmpty ? widget.pr.baseRef : list.baseRef,
                    ),
                    maxHeight: _listMaxHeight,
                  ),
          ),
          const SizedBox(height: 12),
          CcButton(
            onPressed: _starting ? null : _fix,
            fullWidth: true,
            loading: _starting,
            icon: AppIcons.sparkles,
            child: Text(l10n.askAiToFixConflicts),
          ),
        ],
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.text, this.leading, this.trailing});

  final String text;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        Expanded(
          child: Text(
            text,
            style: CcTypography.caption.copyWith(color: tokens.textSecondary),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({
    required this.files,
    required this.summary,
    required this.maxHeight,
  });

  final List<String> files;
  final String summary;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final pathStyle = CcFonts.code(
      textStyle: CcTypography.caption,
    ).copyWith(color: tokens.textPrimary);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          summary,
          style: CcTypography.caption.copyWith(color: tokens.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: tokens.bgSecondary,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: files.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                children: [
                  Icon(AppIcons.fileText, size: 14, color: tokens.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    // RTL carve-out: a file path reads left to right in every
                    // locale.
                    child: Text(
                      files[i],
                      style: pathStyle,
                      textDirection: TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
