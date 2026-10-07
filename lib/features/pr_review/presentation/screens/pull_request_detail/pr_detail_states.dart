import 'package:cc_markdown/cc_markdown.dart' show CcSelectionRegion;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The pull request detail screen's empty state: the PR loaded as `null`
/// (deleted, transferred or never existed), with a way back to the list.
class PrDetailNotFound extends StatelessWidget {
  /// Creates the not-found state for pull request [prNumber].
  const PrDetailNotFound({required this.prNumber, super.key});

  /// The number of the pull request that could not be found.
  final int prNumber;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.fileQuestion, size: 48, color: t.textTertiary),
          const SizedBox(height: 16),
          Text(
            l10n.pullRequestNotFound,
            style: CcTypography.title.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.pullRequestNotFoundBody,
            textAlign: TextAlign.center,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: 20),
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () =>
                context.go(pullRequestsRoute(context.currentWorkspaceId!)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.arrowLeft, size: 16),
                const SizedBox(width: 8),
                Text(l10n.backToPullRequests),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The pull request detail screen's error state: a retry that re-subscribes
/// [prDetailProvider] and a collapsible, selectable dump of [error].
class PrDetailErrorState extends ConsumerStatefulWidget {
  /// Creates the error state for [prRef] failing with [error].
  const PrDetailErrorState({
    required this.prRef,
    required this.error,
    super.key,
  });

  /// The pull request whose detail stream failed; retry invalidates it.
  final PrRef prRef;

  /// The failure, shown verbatim under "Show details".
  final Object error;

  @override
  ConsumerState<PrDetailErrorState> createState() => _PrDetailErrorStateState();
}

class _PrDetailErrorStateState extends ConsumerState<PrDetailErrorState> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.triangleAlert, size: 48, color: t.textErrorPrimary),
              const SizedBox(height: 16),
              Text(
                l10n.couldntLoadPullRequest,
                textAlign: TextAlign.center,
                style: CcTypography.title.copyWith(color: t.textPrimary),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  CcButton(
                    onPressed: () =>
                        ref.invalidate(prDetailProvider(widget.prRef)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(AppIcons.refreshCw, size: 16),
                        const SizedBox(width: 8),
                        Text(l10n.retry),
                      ],
                    ),
                  ),
                  CcButton(
                    variant: CcButtonVariant.secondary,
                    onPressed: () =>
                        setState(() => _showDetails = !_showDetails),
                    child: Text(l10n.showDetails),
                  ),
                ],
              ),
              CcCollapsible(
                expanded: _showDetails,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    CcSelectionRegion(
                      child: Text(
                        widget.error.toString(),
                        textAlign: TextAlign.center,
                        style: CcTypography.caption.copyWith(
                          color: t.textTertiary,
                          fontFamily: CcFonts.codeFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
