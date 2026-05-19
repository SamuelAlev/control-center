import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/conversation_title_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/model_select.dart';
import 'package:control_center/features/settings/presentation/widgets/scope_badge.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/settings/settings_nav.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → General: the runner that names new conversations.
///
/// An **adapter + model pair**, laid out like the default-runner rows in
/// Settings → Adapters, because that is what a runner is everywhere else in
/// the app — a model id alone does not say what executes it, and the same
/// string means different things per adapter (`cc-harness` folds its provider
/// into the model id; a CLI advertises bare names).
///
/// Workspace-scoped, admin-gated. The title lands on a conversation every
/// member reads, so it is one decision for the workspace rather than a
/// preference that made the same space titled or untitled depending on who
/// sent its first message.
///
/// Off until an adapter is picked — the caption says so, and clearing the
/// adapter is how you turn it back off.
class ConversationTitlesSection extends ConsumerWidget {
  /// Creates a [ConversationTitlesSection].
  const ConversationTitlesSection({super.key, required this.workspaceId});

  /// The workspace being configured.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final isAdmin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
    final adapterId = ref.watch(conversationTitleAdapterProvider);
    final modelId = ref.watch(conversationTitleModelProvider);
    final available = ref.watch(availableAdaptersProvider);

    return SectionCard(
      label: l10n.conversationTitlesSectionTitle,
      trailing: const ScopeBadge(SettingScope.workspace),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Text(
              l10n.conversationTitlesSectionCaption,
              style: CcTypography.caption.copyWith(
                color: tokens?.textTertiary,
                height: 1.45,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Labelled(
                  label: l10n.conversationTitlesAdapterLabel,
                  child: CcSelect<String>(
                    value: adapterId,
                    enabled: isAdmin,
                    hintText: l10n.conversationTitlesAdapterHint,
                    options: _adapterOptions(l10n, available),
                    // `_offValue` is the way back to off: CcSelect has no
                    // clear affordance, so "off" has to be a row you can pick.
                    onChanged: (id) => setConversationTitleAdapter(
                      ref,
                      id == _offValue ? null : id,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Labelled(
                  label: l10n.conversationTitlesModelLabel,
                  // Reused rather than reimplemented: it already resolves the
                  // right catalogue per transport (the harness's qualified
                  // provider/model ids, a CLI's advertised names) and keeps
                  // free-text entry for anything unadvertised.
                  child: ModelSelect(
                    adapterId: adapterId,
                    selectedModelId: modelId,
                    enabled: isAdmin,
                    onChange: (id) => setConversationTitleModel(ref, id),
                  ),
                ),
              ),
            ],
          ),
          if (!isAdmin) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.settingsWorkspaceAdminOnly,
              style: CcTypography.caption.copyWith(color: tokens?.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  /// Installed runners only. Titling runs on the server, so a runner the server
  /// does not have would name nothing — it would just leave the feature quietly
  /// broken with a plausible-looking setting behind it. "Off" always stays,
  /// because it is the way back out.
  List<CcSelectOption<String>> _adapterOptions(
    AppLocalizations l10n,
    List<Adapter> available,
  ) {
    return [
      CcSelectOption(
        value: _offValue,
        label: l10n.conversationTitlesAdapterOff,
      ),
      for (final adapter in available)
        CcSelectOption(value: adapter.id, label: adapter.name),
    ];
  }
}

/// Sentinel for the "off" row. Not an adapter id, and never stored: the
/// setting is DELETED when it is chosen, so off stays the absence of a row.
const String _offValue = '';

/// A caption above a control, matching the workspace policy card's fields.
class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: CcTypography.caption.copyWith(
            color: context.designSystem?.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
