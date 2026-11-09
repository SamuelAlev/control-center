import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_link_claim_panel.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_link_code_step.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/chat_bridges/providers/chat_link_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the personal "link my account" dialog for [descriptor]'s provider.
///
/// Linking takes both sides. The server mints a one-time code the member
/// sends to the bot in a direct message, which proves the chat account; the
/// member then confirms that exact profile here, which proves the two are the
/// same person. Codes are single-use and short-lived, so a leaked one is
/// worthless minutes later, and one sent from somebody else's account is
/// declined instead of linked.
Future<void> showChatLinkDialog(
  BuildContext context,
  WidgetRef ref,
  ChatProviderDescriptor descriptor,
) {
  // Cleared from the press that opens the dialog: Riverpod forbids writing to
  // a provider while the tree builds, and a fresh code starts undecided.
  ref
      .read(chatLinkClaimControllerProvider(descriptor.provider).notifier)
      .reset();
  return showCcDialog<void>(
    context: context,
    builder: (_) => _ChatLinkDialog(descriptor: descriptor),
  );
}

class _ChatLinkDialog extends ConsumerStatefulWidget {
  const _ChatLinkDialog({required this.descriptor});

  final ChatProviderDescriptor descriptor;

  @override
  ConsumerState<_ChatLinkDialog> createState() => _ChatLinkDialogState();
}

class _ChatLinkDialogState extends ConsumerState<_ChatLinkDialog> {
  /// Minted once per dialog (and again on "get a new code"): re-minting on a
  /// rebuild would invalidate the code the member is in the middle of sending.
  late Future<ChatLinkCodeView?> _code;

  @override
  void initState() {
    super.initState();
    _code = _mint();
  }

  Future<ChatLinkCodeView?> _mint() => ref
      .read(chatConnectionControllerProvider.notifier)
      .beginMyLink(widget.descriptor.provider);

  void _newCode() {
    ref
        .read(
          chatLinkClaimControllerProvider(widget.descriptor.provider).notifier,
        )
        .reset();
    setState(() {
      _code = _mint();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final descriptor = widget.descriptor;
    final name = descriptor.displayName;
    final answer = ref
        .watch(chatLinkClaimControllerProvider(descriptor.provider))
        .value;
    // The claim arrives from the chat app, so the server has to push it.
    final pending = ref.watch(chatPendingLinkProvider(descriptor.provider));

    final Widget content;
    final bool done;
    if (answer?.link case final link?) {
      content = _Linked(providerName: name, link: link);
      done = true;
    } else if (answer?.declined ?? false) {
      content = _Note(text: l10n.chatLinkDeclined(name));
      done = false;
    } else {
      done = false;
      content = FutureBuilder<ChatLinkCodeView?>(
        future: _code,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Note(
              text: l10n.failedWithError('${snapshot.error}'),
              error: true,
            );
          }
          final code = snapshot.data;
          if (code == null) {
            return const _Waiting();
          }
          // Only a claim on THIS code: a snapshot from before the mint can
          // still carry the previous one.
          final mine = pending.value;
          final claim = mine?.code == code.code ? mine?.claim : null;
          if (claim != null) {
            return ChatLinkClaimPanel(
              provider: descriptor.provider,
              providerName: name,
              claim: claim,
            );
          }
          return ChatLinkCodeStep(providerName: name, code: code.code);
        },
      );
    }
    return CcDialog(
      title: l10n.chatLinkCodeTitle(name),
      content: content,
      actions: [
        CcButton(
          variant: done ? CcButtonVariant.primary : CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
        if (answer?.declined ?? false)
          CcButton(onPressed: _newCode, child: Text(l10n.chatLinkNewCode)),
      ],
    );
  }
}

/// The dialog's final view once the member confirmed the profile.
class _Linked extends StatelessWidget {
  const _Linked({required this.providerName, required this.link});

  final String providerName;
  final ChatUserLinkView link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.checkCircle, size: 18, color: t.fgSuccessPrimary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chatLinkCodeLinked(providerName),
                style: CcTypography.bodySm.copyWith(
                  height: 1.4,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.chatLinkedAs(link.externalUserId),
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One line of explanation (a decline, a failure).
class _Note extends StatelessWidget {
  const _Note({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      text,
      style: CcTypography.bodySm.copyWith(
        height: 1.4,
        color: error ? t.bgErrorSolid : t.textSecondary,
      ),
    );
  }
}

/// While the code is being minted.
class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [CcSpinner(size: 16, color: t.textTertiary)],
    );
  }
}
