import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/invite_result_view.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/membership_formatting.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Presents the invite-a-member dialog for [workspaceId].
Future<void> showInviteMemberDialog(BuildContext context, String workspaceId) =>
    showCcDialog<void>(
      context: context,
      builder: (_) => InviteMemberDialog(workspaceId: workspaceId),
    );

/// Mints a workspace invite: role, per-repo grants (nothing is shared unless
/// explicitly checked), and expiry. After creation the dialog shows the
/// one-time code, the invite link, and a QR — the only time the code exists
/// client-side.
class InviteMemberDialog extends ConsumerStatefulWidget {
  /// Creates an [InviteMemberDialog] for [workspaceId].
  const InviteMemberDialog({super.key, required this.workspaceId});

  /// The workspace the invite grants membership of.
  final String workspaceId;

  @override
  ConsumerState<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends ConsumerState<InviteMemberDialog> {
  String _role = 'member';
  int _ttlHours = 7 * 24;
  final Map<String, String> _grants = {};
  bool _busy = false;
  ({String code, String redeemUrl, Map<String, dynamic>? descriptor})? _result;

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final minted = await ref
          .read(identityRepositoryProvider)
          .createInvite(
            widget.workspaceId,
            role: _role,
            repoGrants: Map.of(_grants),
            ttlHours: _ttlHours,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _result = (
          code: minted.code,
          redeemUrl: minted.redeemUrl,
          descriptor: minted.descriptor?.toJson(),
        );
      });
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      CcToastScope.of(
        context,
      ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = _result;
    if (result != null) {
      return CcDialog(
        title: l10n.inviteMember,
        content: InviteResultView(
          code: result.code,
          redeemUrl: result.redeemUrl,
          descriptor: result.descriptor,
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      );
    }
    return CcDialog(
      title: l10n.inviteMember,
      content: _buildForm(context, l10n),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.accent,
          loading: _busy,
          onPressed: _busy ? null : _create,
          child: Text(l10n.createInviteAction),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final repos =
        ref.watch(reposForWorkspaceProvider(widget.workspaceId)).value ??
        const <Repo>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcSelect<String>(
          label: l10n.roleLabel,
          value: _role,
          options: [
            for (final role in const ['member', 'admin', 'viewer', 'guest'])
              CcSelectOption(
                value: role,
                label: workspaceRoleLabel(l10n, role),
              ),
          ],
          enabled: !_busy,
          onChanged: (role) => setState(() => _role = role),
        ),
        const SizedBox(height: AppSpacing.md),
        CcSelect<int>(
          label: l10n.inviteExpiryLabel,
          value: _ttlHours,
          options: [
            CcSelectOption(value: 24, label: l10n.expiryOneDay),
            CcSelectOption(value: 7 * 24, label: l10n.expirySevenDays),
            CcSelectOption(value: 30 * 24, label: l10n.expiryThirtyDays),
          ],
          enabled: !_busy,
          onChanged: (h) => setState(() => _ttlHours = h),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.inviteRepoAccessHeader,
          style: CcTypography.bodySm.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
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
                    level: _grants[repo.id],
                    enabled: !_busy,
                    onChanged: (level) => setState(() {
                      if (level == null) {
                        _grants.remove(repo.id);
                      } else {
                        _grants[repo.id] = level;
                      }
                    }),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// One linked repo in the grant picker: a checkbox (share / keep hidden) and,
/// when shared, the access-level dropdown.
class _RepoGrantRow extends StatelessWidget {
  const _RepoGrantRow({
    required this.repo,
    required this.level,
    required this.enabled,
    required this.onChanged,
  });

  final Repo repo;

  /// The granted level wire name (`read` / `review` / `write`), or null when
  /// the repo is not shared.
  final String? level;
  final bool enabled;
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
              onChanged: enabled ? (v) => onChanged(v ? 'read' : null) : null,
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
                enabled: enabled,
                onChanged: onChanged,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
