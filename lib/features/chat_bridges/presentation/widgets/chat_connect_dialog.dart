import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/chat_provider_l10n.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the connect dialog for [descriptor]'s provider: paste the credentials it
/// declares and the server dials the provider from here.
///
/// The dialog has no per-provider code. It grows one box per declared credential
/// field, labels it through the localization seam and posts the values back as a
/// map keyed by field id — so Discord's dialog is this dialog.
Future<void> showChatConnectDialog(
  BuildContext context,
  WidgetRef ref,
  ChatProviderDescriptor descriptor,
) {
  // Clearing the shared controller here rather than in the dialog's initState:
  // Riverpod forbids writing to a provider while the tree is building and this
  // runs from the press that opens the dialog, before its first frame.
  ref.read(chatConnectionControllerProvider.notifier).reset();
  return showCcDialog<void>(
    context: context,
    builder: (_) => _ChatConnectDialog(descriptor: descriptor),
  );
}

class _ChatConnectDialog extends ConsumerStatefulWidget {
  const _ChatConnectDialog({required this.descriptor});

  final ChatProviderDescriptor descriptor;

  @override
  ConsumerState<_ChatConnectDialog> createState() => _ChatConnectDialogState();
}

class _ChatConnectDialogState extends ConsumerState<_ChatConnectDialog> {
  /// One controller per declared field, keyed by field id.
  late final Map<String, TextEditingController> _fields = {
    for (final field in widget.descriptor.credentialFields)
      field.id: TextEditingController(),
  };

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Only the boxes the user actually filled: an empty optional field must not be
  /// stored as an empty credential, which would look like a rotation to nothing.
  Map<String, String> get _credentials => {
    for (final entry in _fields.entries)
      if (entry.value.text.trim().isNotEmpty)
        entry.key: entry.value.text.trim(),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final descriptor = widget.descriptor;
    final state = ref.watch(chatConnectionControllerProvider);
    final controller = ref.read(chatConnectionControllerProvider.notifier);
    final busy = state.isLoading;

    // Close once the server reports the connection stored; the settings card
    // then shows the live transport state.
    ref.listen(chatConnectionControllerProvider, (previous, next) {
      if (previous is AsyncLoading &&
          next is AsyncData &&
          Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });

    return CcDialog(
      title: l10n.chatConnectProvider(descriptor.displayName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.chatConnectHint(descriptor.displayName),
            style: TextStyle(fontSize: 13, height: 1.4, color: t.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (descriptor.consoleUrl case final url?)
                CcButton(
                  variant: CcButtonVariant.secondary,
                  icon: AppIcons.externalLink,
                  onPressed: () => openExternalUrl(url),
                  child: Text(l10n.chatOpenConsole(descriptor.displayName)),
                ),
              if (descriptor.docsUrl case final url?) ...[
                const SizedBox(width: 8),
                CcButton(
                  variant: CcButtonVariant.ghost,
                  icon: AppIcons.bookMarked,
                  onPressed: () => openExternalUrl(url),
                  child: Text(l10n.chatOpenSetupGuide),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          for (final field in descriptor.credentialFields) ...[
            CcTextField(
              controller: _fields[field.id]!,
              label: field.localizedLabel(l10n),
              // The provider's own navigation ("OAuth & Permissions → …") is
              // server-authored English on purpose: it names a screen in the
              // provider's UI, which is not translated either.
              helperText: field.hint,
              obscureText: field.secret,
              enabled: !busy,
              autofocus: field == descriptor.credentialFields.first,
            ),
            const SizedBox(height: 12),
          ],
          if (state.hasError)
            Text(
              l10n.failedWithError('${state.error}'),
              style: TextStyle(fontSize: 12, color: t.bgErrorSolid),
            ),
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          icon: AppIcons.plug,
          onPressed: busy
              ? null
              : () => controller.connect(
                  provider: descriptor.provider,
                  credentials: _credentials,
                ),
          child: Text(
            busy
                ? l10n.chatStateConnecting
                : l10n.chatConnectProvider(descriptor.displayName),
          ),
        ),
      ],
    );
  }
}
