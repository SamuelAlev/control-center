import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/member_avatar.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/member_repo_access_dialog.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/membership_formatting.dart';
import 'package:control_center/features/settings/providers/governance_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The workspace member roster: display name + handle per member with a role
/// chip. Admins additionally get a role dropdown (never `owner`), a remove
/// action on every non-owner row and the minted-but-unredeemed invites
/// rendered below the members (role chip + status + timing, revoke on open
/// ones) — one card is the whole picture of who is and who is about to be, in
/// the workspace. Other roles see a read-only roster.
class MembersRosterSection extends ConsumerWidget {
  /// Creates a [MembersRosterSection] for [workspaceId].
  const MembersRosterSection({super.key, required this.workspaceId});

  /// The workspace whose members are listed.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final membersAsync = ref.watch(workspaceMembersProvider(workspaceId));
    final users = ref.watch(usersByIdProvider).value ?? const {};
    final myRole = ref.watch(myWorkspaceRoleProvider(workspaceId));
    final isAdmin = myRole?.isAdmin ?? false;
    final isOwner = myRole == WorkspaceRole.owner;
    // Invites are an admin surface, and the server now enforces that: the
    // watch carries `minRole: admin`, so a non-admin subscription is refused
    // rather than streaming the invite roster to anyone with membership.
    final invitesAsync = isAdmin
        ? ref.watch(workspaceInvitesProvider(workspaceId))
        : null;

    return SectionCard(
      label: l10n.memberRosterLabel,
      child: membersAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: CcSpinner()),
        ),
        error: (_, _) => Text(
          l10n.couldNotLoadMembers,
          style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
        ),
        data: (members) {
          final sorted = [...members]..sort(_byRankThenName(users));
          return Column(
            children: [
              for (final member in sorted)
                _MemberRow(
                  workspaceId: workspaceId,
                  member: member,
                  user: users[member.userId],
                  canAdminister: isAdmin,
                  isOwner: isOwner,
                ),
              ...?_inviteRows(context, invitesAsync),
            ],
          );
        },
      ),
    );
  }

  /// The invite rows appended under the members (admins only): null for
  /// non-admins, an empty list while loading or when there are no invites, a
  /// divider + rows (or the load error) otherwise.
  List<Widget>? _inviteRows(
    BuildContext context,
    AsyncValue<List<WorkspaceInviteDto>>? invitesAsync,
  ) {
    if (invitesAsync == null) {
      return null;
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return invitesAsync.when(
      loading: () => const [],
      error: (_, _) => [
        const CcDivider(),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            l10n.couldNotLoadInvites,
            style: CcTypography.bodySm.copyWith(color: t.textErrorPrimary),
          ),
        ),
      ],
      data: (invites) {
        if (invites.isEmpty) {
          return const [];
        }
        final sorted = [...invites]
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          );
        return [
          const CcDivider(),
          for (final invite in sorted)
            _InviteRow(workspaceId: workspaceId, invite: invite),
        ];
      },
    );
  }

  static int Function(WorkspaceMemberDto, WorkspaceMemberDto) _byRankThenName(
    Map<String, UserDto> users,
  ) => (a, b) {
    final rankA = WorkspaceRole.fromWire(a.role)?.rank ?? -1;
    final rankB = WorkspaceRole.fromWire(b.role)?.rank ?? -1;
    if (rankA != rankB) {
      return rankB.compareTo(rankA);
    }
    final nameA = users[a.userId]?.displayName ?? '';
    final nameB = users[b.userId]?.displayName ?? '';
    return nameA.toLowerCase().compareTo(nameB.toLowerCase());
  };
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.workspaceId,
    required this.member,
    required this.user,
    required this.canAdminister,
    required this.isOwner,
  });

  final String workspaceId;
  final WorkspaceMemberDto member;
  final UserDto? user;
  final bool canAdminister;

  /// Whether the SIGNED-IN user owns this workspace (not whether [member]
  /// does — that is [_isOwner]). Gates the ownership handover.
  final bool isOwner;

  bool get _isOwner => member.role == WorkspaceRole.owner.wireName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final name = user?.displayName.isNotEmpty ?? false
        ? user!.displayName
        : l10n.unknownUserLabel;
    final handle = user?.handle ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          MemberAvatar(name: name, user: user, workspaceId: workspaceId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: CcTypography.body.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (handle.isNotEmpty)
                  Text(
                    '@$handle',
                    style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (canAdminister && !_isOwner)
            ..._adminControls(context, ref, l10n, name)
          else
            CcChip(label: workspaceRoleLabel(l10n, member.role)),
        ],
      ),
    );
  }

  List<Widget> _adminControls(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String name,
  ) => [
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 180),
      child: Consumer(
        builder: (context, ref, _) {
          // Custom roles appear alongside the presets. They are subtractive
          // restrictions of a preset, so picking one can only ever narrow
          // what the member may do.
          final custom =
              ref.watch(workspaceCustomRolesProvider).value ?? const [];
          return CcSelect<String>(
            semanticLabel: l10n.roleLabel,
            value: member.effectiveRoleWire,
            options: [
              for (final role in const ['admin', 'member', 'viewer', 'guest'])
                CcSelectOption(
                  value: role,
                  label: workspaceRoleLabel(l10n, role),
                ),
              for (final role in custom)
                CcSelectOption(value: role.wire, label: role.name),
            ],
            onChanged: (role) => _setRole(context, ref, role),
          );
        },
      ),
    ),
    const SizedBox(width: 8),
    CcButton(
      variant: CcButtonVariant.ghost,
      onPressed: () => showMemberRepoAccessDialog(
        context,
        workspaceId: workspaceId,
        userId: member.userId,
        memberName: name,
      ),
      child: Text(l10n.memberRepoAccessAction),
    ),
    // Handing the workspace over is the OWNER's call and only to an existing
    // admin — the two-step (promote, then transfer) is deliberate. Without
    // this action an owner who leaves the company cannot be removed at all:
    // SCIM deprovisioning refuses to delete the last owner and points here.
    if (isOwner && member.role == WorkspaceRole.admin.wireName) ...[
      const SizedBox(width: 8),
      CcButton(
        variant: CcButtonVariant.ghost,
        onPressed: () => _confirmTransferOwnership(context, ref, l10n, name),
        child: Text(l10n.transferOwnershipAction),
      ),
    ],
    const SizedBox(width: 8),
    CcButton(
      variant: CcButtonVariant.destructive,
      onPressed: () => _confirmRemove(context, ref, l10n, name),
      child: Text(l10n.remove),
    ),
  ];

  Future<void> _confirmTransferOwnership(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String name,
  ) async {
    final confirmed = await showCcDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CcDialog(
        title: l10n.transferOwnershipTitle,
        content: Text(l10n.transferOwnershipConfirm(name)),
        actions: [
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.transferOwnershipCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(identityRepositoryProvider)
          .transferOwnership(workspaceId, member.userId);
      // The caller is no longer the owner: re-resolve identity so the
      // owner-only affordances (this button included) disappear immediately
      // rather than after the next connection.
      ref.invalidate(currentIdentityProvider);
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  Future<void> _setRole(
    BuildContext context,
    WidgetRef ref,
    String role,
  ) async {
    if (role == member.effectiveRoleWire) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    try {
      // A custom role has no `WorkspaceRole` to send — it resolves to its
      // base preset only after the server reads the custom row — so it goes
      // through its own op.
      if (role.startsWith('custom:')) {
        await assignCustomRole(
          ref.read(rpcClientProvider),
          workspaceId: workspaceId,
          userId: member.userId,
          roleWire: role,
        );
      } else {
        await ref
            .read(identityRepositoryProvider)
            .setMemberRole(workspaceId, member.userId, role);
      }
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String name,
  ) async {
    final confirmed = await showCcDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => CcDialog(
        title: l10n.removeMemberTitle,
        content: Text(l10n.removeMemberConfirm(name)),
        actions: [
          CcButton(
            variant: CcButtonVariant.ghost,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref
          .read(identityRepositoryProvider)
          .removeMember(workspaceId, member.userId);
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }
}

/// The lifecycle state of an invite, derived from its timestamps.
enum _InviteState { open, used, revoked, expired }

/// A minted invite rendered in the roster below the members: role chip +
/// status tag + timing, with a revoke action while still open. Invites are
/// admin-only; this row only ever appears under an admin's roster.
class _InviteRow extends ConsumerWidget {
  const _InviteRow({required this.workspaceId, required this.invite});

  final String workspaceId;
  final WorkspaceInviteDto invite;

  _InviteState get _state {
    if (invite.revokedAt != null) {
      return _InviteState.revoked;
    }
    if (invite.usedAt != null) {
      return _InviteState.used;
    }
    final expires = invite.expiresAt;
    if (expires != null && expires.isBefore(DateTime.now())) {
      return _InviteState.expired;
    }
    return _InviteState.open;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final state = _state;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(AppIcons.send, size: 18, color: t.fgTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CcChip(label: workspaceRoleLabel(l10n, invite.role)),
                    const SizedBox(width: 8),
                    CcStatusTag(
                      label: _stateLabel(l10n, state),
                      tone: _stateTone(state),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _timing(
                  l10n,
                  CcTypography.bodySm.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
          if (state == _InviteState.open) ...[
            const SizedBox(width: 12),
            CcButton(
              variant: CcButtonVariant.destructive,
              onPressed: () => _revoke(context, ref, l10n),
              child: Text(l10n.revoke),
            ),
          ],
        ],
      ),
    );
  }

  Widget _timing(AppLocalizations l10n, TextStyle style) {
    final created = invite.createdAt;
    final expires = invite.expiresAt;
    // Each concrete instant (created, absolute expiry date) carries the shared
    // accessibility hover card; the ' · ' separator sits between them.
    final segments = <Widget>[
      if (created != null)
        AppTimestamp(
          dateTime: created,
          child: Text(
            l10n.inviteCreatedTime(relativeTimeLabel(l10n, created)),
            style: style,
          ),
        ),
      if (expires != null)
        AppTimestamp(
          dateTime: expires,
          child: Text(
            l10n.inviteExpiresOn(shortDateLabel(expires)),
            style: style,
          ),
        ),
    ];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0) Text(' · ', style: style),
          segments[i],
        ],
      ],
    );
  }

  Future<void> _revoke(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    try {
      await ref
          .read(identityRepositoryProvider)
          .revokeInvite(workspaceId, invite.id);
    } on Object catch (e) {
      if (context.mounted) {
        CcToastScope.of(
          context,
        ).show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
      }
    }
  }

  static String _stateLabel(AppLocalizations l10n, _InviteState state) =>
      switch (state) {
        _InviteState.open => l10n.inviteStatusOpen,
        _InviteState.used => l10n.inviteStatusUsed,
        _InviteState.revoked => l10n.inviteStatusRevoked,
        _InviteState.expired => l10n.inviteStatusExpired,
      };

  static CcStatusTone _stateTone(_InviteState state) => switch (state) {
    _InviteState.open => CcStatusTone.positive,
    _InviteState.used => CcStatusTone.neutral,
    _InviteState.revoked => CcStatusTone.negative,
    _InviteState.expired => CcStatusTone.caution,
  };
}
