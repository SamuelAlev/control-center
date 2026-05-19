import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/chat_bridges/presentation/chat_provider_l10n.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_bot_form.dart';
import 'package:control_center/features/chat_bridges/presentation/widgets/chat_connect_dialog.dart';
import 'package:control_center/features/chat_bridges/providers/chat_bridge_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the guided create flow for [descriptor]'s provider: Control Center
/// composes the provider-side app (transport, permissions, events, the slash
/// command) and creates it from a pasted app-management credential.
///
/// The flow can end in the provider's own UI, and says so instead of pretending:
/// the server returns the steps it has no API for, each with its own link, and
/// this dialog walks them before handing off to the connect dialog.
Future<void> showChatCreateAppDialog(
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
    builder: (_) => _ChatCreateAppDialog(descriptor: descriptor),
  );
}

class _ChatCreateAppDialog extends ConsumerStatefulWidget {
  const _ChatCreateAppDialog({required this.descriptor});

  final ChatProviderDescriptor descriptor;

  @override
  ConsumerState<_ChatCreateAppDialog> createState() =>
      _ChatCreateAppDialogState();
}

class _ChatCreateAppDialogState extends ConsumerState<_ChatCreateAppDialog> {
  final _credential = TextEditingController();
  ChatBotProfile? _edited;
  ChatAppCreation? _created;
  String? _setupUrl;

  @override
  void dispose() {
    _credential.dispose();
    super.dispose();
  }

  Future<void> _create(ChatBotProfile profile) async {
    final created = await ref
        .read(chatConnectionControllerProvider.notifier)
        .createApp(
          provider: widget.descriptor.provider,
          managementCredential: _credential.text.trim(),
          profile: profile,
        );
    if (mounted && created != null) {
      setState(() => _created = created);
    }
  }

  /// Hands the provider's own console the configuration and lets the user
  /// confirm it there — the path that needs no credential at all.
  Future<void> _openSetupLink(ChatBotProfile profile) async {
    final url = await ref
        .read(chatConnectionControllerProvider.notifier)
        .setupLink(provider: widget.descriptor.provider, profile: profile);
    if (!mounted || url == null || url.isEmpty) {
      return;
    }
    openExternalUrl(url);
    setState(() => _setupUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final descriptor = widget.descriptor;
    final state = ref.watch(chatConnectionControllerProvider);
    final busy = state.isLoading;
    final created = _created;
    final setupUrl = _setupUrl;
    // The one box this dialog collects, named by the descriptor: creating an app
    // is an app-management call, not a connection.
    final field = descriptor.managementField;
    final defaults = ChatBotProfile.initial(
      workspaceName: ref.watch(activeWorkspaceProvider)?.name,
    );
    // Either hand-off ends the same way: the provider's UI has the app and the
    // user comes back with tokens.
    final handedOff = created != null || setupUrl != null;

    return CcDialog(
      title: l10n.chatCreateAppTitle(descriptor.displayName),
      content: created != null
          ? _RemainingSteps(creation: created, descriptor: descriptor)
          : setupUrl != null
          ? _SetupLinkSteps(descriptor: descriptor, setupUrl: setupUrl)
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.chatCreateAppHint(descriptor.displayName),
                  style: CcTypography.caption.copyWith(
                    color: t.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                if (field != null)
                  CcTextField(
                    controller: _credential,
                    label: field.localizedLabel(l10n),
                    helperText: field.hint,
                    obscureText: field.secret,
                    enabled: !busy,
                    // Rebuilds so the create button un-disables as soon as
                    // there is a credential to send.
                    onChanged: (_) => setState(() {}),
                  ),
                const SizedBox(height: 16),
                ChatBotForm(
                  initial: defaults,
                  providerName: descriptor.displayName,
                  enabled: !busy,
                  onChanged: (edited) => _edited = edited,
                ),
                if (descriptor.supportsSetupLink) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.chatCreateAppLinkHint(descriptor.displayName),
                    style: CcTypography.caption.copyWith(
                      color: t.textTertiary,
                      height: 1.45,
                    ),
                  ),
                ],
                if (state.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.failedWithError('${state.error}'),
                    style: CcTypography.caption.copyWith(color: t.bgErrorSolid),
                  ),
                ],
              ],
            ),
      actions: handedOff
          ? [
              CcButton(
                variant: CcButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
              ),
              CcButton(
                icon: AppIcons.plug,
                onPressed: () {
                  Navigator.of(context).pop();
                  showChatConnectDialog(context, ref, descriptor);
                },
                child: Text(l10n.chatContinueToCredentials),
              ),
            ]
          : [
              CcButton(
                variant: CcButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.cancel),
              ),
              // Always enabled: this path is exactly the one that needs no
              // credential, so gating it on the box above would defeat it.
              if (descriptor.supportsSetupLink)
                CcButton(
                  variant: CcButtonVariant.secondary,
                  icon: AppIcons.externalLink,
                  onPressed: busy ? null : () => _openSetupLink(_edited ?? defaults),
                  child: Text(
                    l10n.chatCreateAppWithLink(descriptor.displayName),
                  ),
                ),
              CcButton(
                icon: AppIcons.sparkles,
                onPressed: busy || _credential.text.trim().isEmpty
                    ? null
                    : () => _create(_edited ?? defaults),
                child: Text(l10n.chatCreateApp),
              ),
            ],
    );
  }
}

/// What is left after the provider's console was opened with our configuration
/// pre-filled.
///
/// The steps are built here rather than by the server because there is nothing to
/// report: the provider creates the app in its own UI and tells us nothing, so
/// Control Center does not learn the app id and cannot deep-link to that app's
/// pages. The links go to the console instead, and the last line says plainly what
/// that costs.
class _SetupLinkSteps extends StatelessWidget {
  const _SetupLinkSteps({required this.descriptor, required this.setupUrl});

  final ChatProviderDescriptor descriptor;

  /// The pre-filled creation link, kept so the user can reopen it if the tab was
  /// closed before confirming.
  final String setupUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final name = descriptor.displayName;
    final console = descriptor.consoleUrl ?? setupUrl;
    // Client-authored, so the text is already localized: the step ids the client
    // knows are translated by `localizedTitle`, and the hints are passed through
    // verbatim.
    final steps = [
      ChatSetupStep(
        id: 'createApp',
        title: l10n.chatStepCreateApp,
        url: setupUrl,
        hint: l10n.chatStepCreateAppHint(name),
      ),
      ChatSetupStep(
        id: 'appToken',
        title: l10n.chatStepAppToken,
        url: console,
        hint: l10n.chatStepAppTokenHint,
      ),
      ChatSetupStep(
        id: 'install',
        title: l10n.chatStepInstall,
        url: console,
        hint: l10n.chatStepInstallHint,
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.chatSetupLinkBody(name),
          style: CcTypography.bodySm.copyWith(
            color: t.textPrimary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        for (final (index, step) in steps.indexed) ...[
          if (index > 0) const SizedBox(height: 12),
          ChatStepRow(index: index + 1, step: step),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.chatSetupLinkNotManageable(name),
          style: CcTypography.caption.copyWith(
            color: t.textTertiary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

/// The steps the provider keeps to itself, each a link to the exact page.
class _RemainingSteps extends StatelessWidget {
  const _RemainingSteps({required this.creation, required this.descriptor});

  final ChatAppCreation creation;
  final ChatProviderDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final steps = creation.remainingSteps;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.chatAppCreated(descriptor.displayName, creation.appId),
          style: CcTypography.bodySm.copyWith(color: t.textPrimary),
        ),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.chatRemainingSteps(descriptor.displayName),
            style: CcTypography.caption.copyWith(
              color: t.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          for (final (index, step) in steps.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            ChatStepRow(index: index + 1, step: step),
          ],
        ],
        const SizedBox(height: 16),
        CcButton(
          variant: CcButtonVariant.ghost,
          icon: AppIcons.externalLink,
          onPressed: () => openExternalUrl(creation.settingsUrl),
          child: Text(l10n.chatOpenAppSettings),
        ),
      ],
    );
  }
}

/// One numbered hand-off step: what to do, where, and a button that opens it.
class ChatStepRow extends StatelessWidget {
  /// Creates a [ChatStepRow] for [step], numbered [index].
  const ChatStepRow({required this.index, required this.step, super.key});

  /// The step's 1-based position.
  final int index;

  /// The step itself, as the server described it.
  final ChatSetupStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.bgSecondary,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$index',
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.localizedTitle(l10n),
                style: CcTypography.bodySm.copyWith(color: t.textPrimary),
              ),
              if (step.hint case final hint?) ...[
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: CcTypography.caption.copyWith(
                    color: t.textTertiary,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        CcIconButton(
          size: CcButtonSize.sm,
          icon: AppIcons.externalLink,
          onPressed: () => openExternalUrl(step.url),
        ),
      ],
    );
  }
}
