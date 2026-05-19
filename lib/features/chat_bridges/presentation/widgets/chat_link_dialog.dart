import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_markdown/cc_markdown.dart' show CcSelectionRegion;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the personal "link my account" dialog for [descriptor]'s provider: the
/// server mints a one-time code the member sends to the bot.
///
/// A code rather than an in-app OAuth dance because the *provider* side has to
/// prove who it is: whoever sends the code from a chat account is that chat
/// account. Codes are single-use and short-lived, so a leaked one is worthless
/// minutes later. The exact command comes from the descriptor, since a provider
/// may spell it differently.
Future<void> showChatLinkDialog(
  BuildContext context,
  ChatProviderDescriptor descriptor,
) => showCcDialog<void>(
  context: context,
  builder: (_) => _ChatLinkDialog(descriptor: descriptor),
);

class _ChatLinkDialog extends ConsumerStatefulWidget {
  const _ChatLinkDialog({required this.descriptor});

  final ChatProviderDescriptor descriptor;

  @override
  ConsumerState<_ChatLinkDialog> createState() => _ChatLinkDialogState();
}

class _ChatLinkDialogState extends ConsumerState<_ChatLinkDialog> {
  late final Future<ChatLinkCodeView?> _code;

  /// The link this member already had when the dialog opened, if any. Held so a
  /// member who is re-linking (say, to a second chat account) still gets the
  /// confirmation: "linked" means a link that was not there a moment ago, not
  /// merely a link existing.
  String? _linkedBefore;
  bool _knowsBefore = false;

  /// The link that landed while this dialog was open.
  ChatUserLinkView? _linkedNow;

  @override
  void initState() {
    super.initState();
    // Minted once per dialog: re-minting on every rebuild would invalidate the
    // code the user is in the middle of typing.
    _code = ref
        .read(chatConnectionControllerProvider.notifier)
        .beginMyLink(widget.descriptor.provider);
    // The roster is normally already loaded (the settings screen behind this
    // dialog renders from it), and taking the baseline from it now matters:
    // `ref.listen` only fires on *later* emissions, so without this the very
    // emission that carries the new link would be mistaken for the baseline.
    final loaded = ref.read(chatUserLinksProvider).value;
    if (loaded != null) {
      _knowsBefore = true;
      _linkedBefore = _mine(loaded)?.externalUserId;
    }
  }

  /// The caller's own link on this provider in [links], or null.
  ChatUserLinkView? _mine(List<ChatUserLinkView> links) {
    final me = ref.read(currentUserIdProvider);
    if (me == null) {
      return null;
    }
    for (final link in links) {
      if (link.userId == me && link.provider == widget.descriptor.provider) {
        return link;
      }
    }
    return null;
  }

  /// Reads one roster snapshot. The first one describes the world *before* the
  /// code could possibly have been typed, so it only establishes the baseline.
  void _onRoster(List<ChatUserLinkView> links) {
    final mine = _mine(links);
    if (!_knowsBefore) {
      _knowsBefore = true;
      _linkedBefore = mine?.externalUserId;
      return;
    }
    if (mine == null || mine.externalUserId == _linkedBefore) {
      return;
    }
    setState(() => _linkedNow = mine);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final descriptor = widget.descriptor;
    // The link is made in the chat app, so the only way this dialog can know is
    // the server pushing the row it just wrote.
    ref.listen<AsyncValue<List<ChatUserLinkView>>>(chatUserLinksProvider, (
      _,
      next,
    ) {
      final links = next.value;
      if (links != null) {
        _onRoster(links);
      }
    });
    return CcDialog(
      title: l10n.chatLinkCodeTitle(descriptor.displayName),
      content: _linkedNow != null
          ? _Linked(descriptor: descriptor, link: _linkedNow!)
          : FutureBuilder<ChatLinkCodeView?>(
              future: _code,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    l10n.failedWithError('${snapshot.error}'),
                    style: TextStyle(fontSize: 13, color: t.bgErrorSolid),
                  );
                }
                final code = snapshot.data;
                if (code == null) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [CcSpinner(size: 16, color: t.textTertiary)],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.chatLinkCodeInstruction(descriptor.displayName),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: t.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CodeBox(command: descriptor.linkCommand(code.code)),
                  ],
                );
              },
            ),
      actions: [
        CcButton(
          variant: _linkedNow != null
              ? CcButtonVariant.primary
              : CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// What the dialog turns into the moment the code is redeemed in the chat app.
class _Linked extends StatelessWidget {
  const _Linked({required this.descriptor, required this.link});

  final ChatProviderDescriptor descriptor;
  final ChatUserLinkView link;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.checkCircle, size: 18, color: t.fgSuccessPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chatLinkCodeLinked(descriptor.displayName),
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: t.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.chatLinkedAs(link.externalUserId),
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The command to paste into the chat app, prominent and copyable.
class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.command});

  final String command;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            // Selectable as well as copyable: the code is often retyped into the
            // chat app on a phone, from a screen the copy button cannot reach.
            child: CcSelectionRegion(
              child: Text(
                command,
                style: CcFonts.code(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          CcIconButton(
            size: CcButtonSize.sm,
            icon: AppIcons.copy,
            tooltip: l10n.copy,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: command));
              if (context.mounted) {
                CcToastScope.of(
                  context,
                ).show(l10n.copied, variant: CcToastVariant.success);
              }
            },
          ),
        ],
      ),
    );
  }
}
