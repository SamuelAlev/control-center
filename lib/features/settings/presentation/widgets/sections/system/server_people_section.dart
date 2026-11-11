import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show ServerOwnerRequiredException, UserDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/workspace/member_avatar.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/inline_load_error.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everyone with an account on this server, for its owner.
///
/// An address a person typed in themselves is theirs alone until someone
/// vouches for it: single sign-on matches only a confirmed address to an
/// account, so a typed one cannot claim someone else's sign-in. The owner
/// sees which addresses are unconfirmed and can confirm one from its row.
/// Server owner only: anyone else sees that the list is the owner's.
class ServerPeopleSection extends ConsumerWidget {
  /// Creates the section.
  const ServerPeopleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ownerOnly = CcAlert(
      title: l10n.serverOwnerOnly,
      description: Text(l10n.serverPeopleOwnerOnly),
    );
    if (!ref.watch(isServerOwnerProvider)) {
      return SectionCard(label: l10n.serverPeopleLabel, child: ownerOnly);
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SectionCard(
      label: l10n.serverPeopleLabel,
      child: ref
          .watch(usersByIdProvider)
          .when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CcSpinner()),
            ),
            error: (e, _) => InlineLoadError(e, center: false),
            data: (byId) {
              final people = [...byId.values]
                ..sort(
                  (a, b) => a.displayName.toLowerCase().compareTo(
                    b.displayName.toLowerCase(),
                  ),
                );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < people.length; i++) ...[
                    if (i > 0) Container(height: 1, color: t.borderSecondary),
                    ServerPersonRow(user: people[i]),
                  ],
                ],
              );
            },
          ),
    );
  }
}

/// One account: avatar, name, username and email, whether the address is
/// confirmed, and (while it is not) a hover-revealed "Confirm email".
class ServerPersonRow extends ConsumerStatefulWidget {
  /// Creates the row for [user].
  const ServerPersonRow({super.key, required this.user});

  /// The account.
  final UserDto user;

  @override
  ConsumerState<ServerPersonRow> createState() => _ServerPersonRowState();
}

class _ServerPersonRowState extends ConsumerState<ServerPersonRow> {
  bool _hovered = false;
  bool _busy = false;

  /// The row as `users.vouchEmail` returned it, until the live list catches
  /// up, so the state changes the moment the server confirms.
  UserDto? _vouched;

  UserDto get _user {
    final vouched = _vouched;
    return vouched != null && vouched.id == widget.user.id
        ? vouched
        : widget.user;
  }

  Future<void> _vouch(String email, String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.serverPeopleConfirmEmail,
      message: l10n.serverPeopleConfirmEmailBody(email, name),
      confirmLabel: l10n.serverPeopleConfirmEmail,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final user = await ref
          .read(identityRepositoryProvider)
          .vouchEmail(widget.user.id);
      if (!mounted) {
        return;
      }
      setState(() => _vouched = user);
      CcToastScope.maybeOf(context)?.show(
        l10n.serverPeopleEmailConfirmed(email),
        variant: CcToastVariant.success,
      );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(context)?.show(
        e is ServerOwnerRequiredException
            ? l10n.serverPeopleOwnerOnly
            : l10n.failedWithError('$e'),
        variant: CcToastVariant.danger,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final user = _user;
    final name = user.displayName.isNotEmpty
        ? user.displayName
        : l10n.unknownUserLabel;
    final email = user.email?.trim() ?? '';
    final unconfirmed = email.isNotEmpty && !user.emailVerified;
    final meta = CcTypography.bodySm.copyWith(color: t.textTertiary);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            MemberAvatar(name: name, user: user),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: CcTypography.body.copyWith(
                            color: t.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (unconfirmed) ...[
                        const SizedBox(width: AppSpacing.sm),
                        CcStatusTag(
                          label: l10n.serverPeopleEmailNotConfirmed,
                          tone: CcStatusTone.caution,
                        ),
                      ],
                    ],
                  ),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      if (user.handle.isNotEmpty)
                        Text(
                          '@${user.handle}',
                          // RTL carve-out: a username reads left to right.
                          textDirection: TextDirection.ltr,
                          style: meta,
                        ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          // RTL carve-out: an address reads left to right.
                          textDirection: TextDirection.ltr,
                          style: meta,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (unconfirmed) ...[
              const SizedBox(width: 12),
              SettingsHoverReveal(
                active: _hovered,
                child: CcIconButton(
                  icon: AppIcons.userCheck,
                  color: t.fgTertiary,
                  size: CcButtonSize.sm,
                  tooltip: l10n.serverPeopleConfirmEmail,
                  semanticLabel: l10n.serverPeopleConfirmEmail,
                  onPressed: _busy
                      ? null
                      : () => unawaited(_vouch(email, name)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
