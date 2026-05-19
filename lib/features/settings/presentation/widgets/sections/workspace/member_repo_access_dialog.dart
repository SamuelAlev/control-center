import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presents the per-member repo-access editor for [workspaceId].
Future<void> showMemberRepoAccessDialog(
  BuildContext context, {
  required String workspaceId,
  required String userId,
  required String memberName,
}) => showCcDialog<void>(
  context: context,
  builder: (_) => MemberRepoAccessDialog(
    workspaceId: workspaceId,
    userId: userId,
    memberName: memberName,
  ),
);

/// Edits one member's per-repo grants after they joined: the same
/// checkbox-plus-level picker the invite dialog offers, backed by the member's
/// current grants and applied immediately per change (like the roster's role
/// dropdown). Unchecking a repo sends `none`, which removes the grant row
/// server-side. A failed write is toasted and the picker reloaded from the
/// server so the UI never shows a grant the server rejected.
class MemberRepoAccessDialog extends ConsumerStatefulWidget {
  /// Creates a [MemberRepoAccessDialog] for [userId] in [workspaceId].
  const MemberRepoAccessDialog({
    super.key,
    required this.workspaceId,
    required this.userId,
    required this.memberName,
  });

  /// The workspace the membership belongs to.
  final String workspaceId;

  /// The member whose grants are edited.
  final String userId;

  /// Display name used in the dialog title.
  final String memberName;

  @override
  ConsumerState<MemberRepoAccessDialog> createState() =>
      _MemberRepoAccessDialogState();
}

class _MemberRepoAccessDialogState
    extends ConsumerState<MemberRepoAccessDialog> {
  /// repo id → level wire name; null while the first load is in flight.
  Map<String, String>? _grants;

  /// Set when the initial grant load failed.
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final grants = await ref
          .read(identityRepositoryProvider)
          .getRepoGrants(widget.workspaceId, widget.userId);
      if (mounted) {
        setState(() {
          _grants = grants;
          _loadError = null;
        });
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _loadError = e);
      }
    }
  }

  Future<void> _apply(String repoId, String? level) async {
    final l10n = AppLocalizations.of(context);
    final current = _grants;
    if (current == null) {
      return;
    }
    setState(() {
      if (level == null) {
        current.remove(repoId);
      } else {
        current[repoId] = level;
      }
    });
    try {
      await ref
          .read(identityRepositoryProvider)
          .setRepoGrant(
            widget.workspaceId,
            widget.userId,
            repoId,
            level ?? 'none',
          );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.of(
        context,
      ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final grants = _grants;
    final repos =
        ref.watch(reposForWorkspaceProvider(widget.workspaceId)).value ??
        const <Repo>[];

    final Widget content;
    if (_loadError != null) {
      content = Text(
        l10n.failedWithError('$_loadError'),
        style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
      );
    } else if (grants == null) {
      content = const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CcSpinner()),
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.inviteRepoAccessExplainer,
            style: CcTypography.bodySm.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final repo in repos)
                    _RepoGrantRow(
                      repo: repo,
                      level: grants[repo.id],
                      onChanged: (level) => _apply(repo.id, level),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CcDialog(
      title: l10n.memberRepoAccessTitle(widget.memberName),
      content: content,
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// One linked repo in the grant editor: a checkbox (share / keep hidden) and,
/// when shared, the access-level dropdown. Mirrors the invite dialog's picker.
class _RepoGrantRow extends StatelessWidget {
  const _RepoGrantRow({
    required this.repo,
    required this.level,
    required this.onChanged,
  });

  final Repo repo;

  /// The granted level wire name (`read` / `review` / `write`), or null when
  /// the repo is not shared.
  final String? level;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final checked = level != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: CcCheckbox(
              value: checked,
              label: Text(repo.name, overflow: TextOverflow.ellipsis),
              semanticLabel: repo.name,
              onChanged: (v) => onChanged(v ? 'read' : null),
            ),
          ),
          if (checked) ...[
            const SizedBox(width: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: CcSelect<String>(
                semanticLabel: l10n.inviteRepoAccessHeader,
                value: level,
                options: [
                  CcSelectOption(value: 'read', label: l10n.grantLevelRead),
                  CcSelectOption(value: 'review', label: l10n.grantLevelReview),
                  CcSelectOption(value: 'write', label: l10n.grantLevelWrite),
                ],
                onChanged: onChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
