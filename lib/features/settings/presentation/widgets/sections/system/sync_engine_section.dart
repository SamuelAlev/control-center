import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/providers/sync_engine_provider.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-store kill-switch preference (PRD 16 §6). `store` is one of 'tickets' /
/// 'messaging' / 'notes' (see [syncEngineStoreKeys]). Default TRUE — OFF is an
/// emergency escape hatch back to full-snapshot mode, not a staged opt-in.
final _syncEngineToggleProvider =
    NotifierProvider.family<_SyncEngineToggleNotifier, bool, String>(
      _SyncEngineToggleNotifier.new,
    );

class _SyncEngineToggleNotifier extends Notifier<bool> {
  _SyncEngineToggleNotifier(this.store);

  /// The adopted store this toggle controls ('tickets' / 'messaging' / 'notes').
  final String store;

  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getBool(syncEngineStoreKeys[store]!) ??
      true;

  /// Persists the preference and updates the live value. Only NEW `sync.watch`
  /// subscriptions read it — a running one keeps whatever mode it started in —
  /// so a change takes full effect after a reload (the section's caption says
  /// so).
  Future<void> setEnabled({required bool value}) async {
    await ref
        .read(appPreferencesProvider)
        .setBool(syncEngineStoreKeys[store]!, value: value);
    state = value;
  }
}

/// Settings → Advanced → "Sync engine": per-store kill-switches for the
/// deterministic sync engine (PRD 16 §6).
///
/// OFF falls that store back to today's full-snapshot subscriptions; the
/// engine ships ON, so these toggles exist for emergencies, not as an opt-in.
class SyncEngineSection extends StatelessWidget {
  /// Creates a [SyncEngineSection].
  const SyncEngineSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SectionCard(
      label: l10n.syncEngineSectionTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              l10n.syncEngineDescription,
              style: CcTypography.bodySm.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
          ),
          _SyncEngineToggleRow(
            store: 'tickets',
            title: l10n.syncEngineTicketsTitle,
          ),
          _SyncEngineToggleRow(
            store: 'messaging',
            title: l10n.syncEngineMessagingTitle,
          ),
          _SyncEngineToggleRow(
            store: 'notes',
            title: l10n.syncEngineNotesTitle,
          ),
        ],
      ),
    );
  }
}

class _SyncEngineToggleRow extends ConsumerWidget {
  const _SyncEngineToggleRow({required this.store, required this.title});

  /// The adopted store this row controls ('tickets' / 'messaging' / 'notes').
  final String store;

  /// The row's display title.
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final enabled = ref.watch(_syncEngineToggleProvider(store));
    return SettingsRow(
      icon: AppIcons.refreshCw,
      title: title,
      subtitle: enabled
          ? l10n.syncEngineOnSubtitle
          : l10n.syncEngineOffSubtitle,
      trailing: CcSwitch(
        value: enabled,
        onChanged: (v) => ref
            .read(_syncEngineToggleProvider(store).notifier)
            .setEnabled(value: v),
      ),
    );
  }
}
