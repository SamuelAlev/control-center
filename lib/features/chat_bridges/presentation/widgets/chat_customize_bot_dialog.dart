import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_bot_form.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the customize-bot dialog for [descriptor]'s provider: rename the bot,
/// reword what it says about itself, or rename the slash command.
///
/// Edits the provider's *live* app (read on open, merged on save), so a change
/// somebody made in the provider's own UI is what this dialog starts from — and
/// anything Control Center does not model survives the write untouched.
Future<void> showChatCustomizeBotDialog(
  BuildContext context,
  WidgetRef ref,
  ChatProviderDescriptor descriptor,
) {
  // Clearing the shared controller here rather than in the dialog's initState:
  // Riverpod forbids writing to a provider while the tree is building, and this
  // runs from the press that opens the dialog, before its first frame.
  ref.read(chatConnectionControllerProvider.notifier).reset();
  return showCcDialog<void>(
    context: context,
    builder: (_) => _ChatCustomizeBotDialog(descriptor: descriptor),
  );
}

class _ChatCustomizeBotDialog extends ConsumerStatefulWidget {
  const _ChatCustomizeBotDialog({required this.descriptor});

  final ChatProviderDescriptor descriptor;

  @override
  ConsumerState<_ChatCustomizeBotDialog> createState() =>
      _ChatCustomizeBotDialogState();
}

class _ChatCustomizeBotDialogState
    extends ConsumerState<_ChatCustomizeBotDialog> {
  ChatBotProfile? _edited;

  /// Set when the provider reports the edit needs a step finished before it does
  /// anything — the dialog then stays open holding that step's link.
  ChatSetupStep? _remainingStep;

  Future<void> _save(ChatBotProfile profile) async {
    final update = await ref
        .read(chatConnectionControllerProvider.notifier)
        .updateBotProfile(
          provider: widget.descriptor.provider,
          profile: profile,
        );
    if (!mounted || !update.didSave) {
      return;
    }
    if (update.remainingStep case final step?) {
      setState(() => _remainingStep = step);
      return;
    }
    CcToastScope.of(context).show(
      AppLocalizations.of(
        context,
      ).chatBotUpdated(widget.descriptor.displayName),
      variant: CcToastVariant.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final descriptor = widget.descriptor;
    final profile = ref.watch(chatBotProfileProvider(descriptor.provider));
    final action = ref.watch(chatConnectionControllerProvider);
    final busy = action.isLoading;
    final remaining = _remainingStep;

    return CcDialog(
      title: l10n.chatCustomizeBot,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (profile) {
            AsyncData(:final value) => ChatBotForm(
              initial: value,
              providerName: descriptor.displayName,
              enabled: !busy,
              onChanged: (edited) => _edited = edited,
            ),
            AsyncError(:final error) => Text(
              l10n.failedWithError('$error'),
              style: CcTypography.caption.copyWith(color: t.bgErrorSolid),
            ),
            _ => Center(child: CcSpinner(size: 16, color: t.textTertiary)),
          },
          if (remaining != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.chatScopesChangedReinstall(descriptor.displayName),
              style: CcTypography.caption.copyWith(
                color: t.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 8),
            CcButton(
              variant: CcButtonVariant.secondary,
              icon: AppIcons.externalLink,
              // The link comes from the server with the step, so this button
              // never has to know which provider it opens.
              onPressed: () => openExternalUrl(remaining.url),
              child: Text(l10n.chatReinstallApp),
            ),
          ],
          if (action.hasError) ...[
            const SizedBox(height: 12),
            Text(
              l10n.failedWithError('${action.error}'),
              style: CcTypography.caption.copyWith(color: t.bgErrorSolid),
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(remaining != null ? l10n.close : l10n.cancel),
        ),
        CcButton(
          icon: AppIcons.check,
          onPressed: busy || !profile.hasValue
              ? null
              : () => _save(_edited ?? profile.requireValue),
          child: Text(l10n.saveChanges),
        ),
      ],
    );
  }
}
