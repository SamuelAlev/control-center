import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show SignInNeed;
import 'package:control_center/features/repos/presentation/widgets/repo_access_warnings_dialog.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One linked repository whose path now names a different repository on its
/// forge (deleted and re-created, or moved and replaced). The server sends it
/// no token, push, comment or request until a workspace admin relinks it.
///
/// Admins get "Relink", which re-saves the link with `relink: true`: the
/// server re-verifies it with the admin's own forge sign-in and re-pins it.
/// A refusal there is the ordinary link refusal (sign in, or the repository
/// cannot be seen). Members are told who to ask.
class RepoReplacedNotice extends ConsumerStatefulWidget {
  /// Creates the notice for [issue].
  const RepoReplacedNotice({
    super.key,
    required this.issue,
    required this.workspaceId,
    required this.isAdmin,
    required this.askAdmin,
  });

  /// The replaced repository.
  final RepoAccessIssue issue;

  /// The workspace it is linked to.
  final String workspaceId;

  /// Whether the reader may relink it.
  final bool isAdmin;

  /// Who a member should ask, already worded.
  final String askAdmin;

  @override
  ConsumerState<RepoReplacedNotice> createState() => _RepoReplacedNoticeState();
}

class _RepoReplacedNoticeState extends ConsumerState<RepoReplacedNotice> {
  bool _relinking = false;

  /// The linked repository this notice is about, by id, else by its forge
  /// coordinates.
  Repo? _repo() {
    final issue = widget.issue;
    final repos =
        ref.watch(reposForWorkspaceProvider(widget.workspaceId)).value ??
        const <Repo>[];
    for (final r in repos) {
      if (issue.repoId != null
          ? r.id == issue.repoId
          : r.forge == issue.forge &&
                r.remoteOwner.toLowerCase() == issue.owner.toLowerCase() &&
                r.remoteName.toLowerCase() == issue.name.toLowerCase()) {
        return r;
      }
    }
    return null;
  }

  Future<void> _relink(Repo repo) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _relinking = true);
    try {
      final linked = await ref.read(linkRepoProvider)(
        widget.workspaceId,
        repo,
        relink: true,
      );
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(context)?.show(
        l10n.repoRelinked(widget.issue.repoFullName),
        variant: CcToastVariant.success,
      );
      await showRepoAccessWarnings(context, linked.issues);
    } on Object catch (e) {
      if (!mounted ||
          offerSignInForRefusal(
            context,
            e,
            fallback: SignInNeed.forForge(repo.forge),
            workspaceId: widget.workspaceId,
          )) {
        return;
      }
      CcToastScope.maybeOf(context)?.show(
        l10n.failedWithError(describeRepoLinkError(l10n, e)),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _relinking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final issue = widget.issue;
    final repo = widget.isAdmin ? _repo() : null;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: CcAlert(
        variant: CcAlertVariant.warning,
        icon: AppIcons.alertTriangle,
        title: l10n.repoAccessReplacedTitle(issue.repoFullName),
        description: Text(
          [
            l10n.repoAccessReplacedBody(issue.forge.displayName),
            if (!widget.isAdmin) widget.askAdmin,
          ].join(' '),
        ),
        trailing: repo == null
            ? null
            : CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.secondary,
                icon: AppIcons.link,
                loading: _relinking,
                onPressed: _relinking ? null : () => unawaited(_relink(repo)),
                child: Text(l10n.repoRelink),
              ),
      ),
    );
  }
}
