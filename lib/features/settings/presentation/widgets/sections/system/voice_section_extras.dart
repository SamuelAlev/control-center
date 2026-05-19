// The ASR model picker (over RPC).
//
// Both the desktop and web are thin clients: speech transcription runs on the
// connected `cc_server` (`meeting.startRecording`/`ingestAudio`), so the ASR
// model SELECTION is a server-side choice driven over the
// `models.voiceCatalog` / `models.selectVoice` ops.
library;

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/general/settings_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The title shown on the voice model's status row: the selected ASR model's
/// display name (sourced from the server's catalog), falling back to a generic
/// label while the catalog loads or when none is reported.
final voiceModelRowTitleProvider = Provider<String>((ref) {
  return ref
      .watch(voiceModelCatalogProvider)
      .maybeWhen(
        data: (catalog) {
          if (catalog == null) {
            return 'Voice model';
          }
          for (final m in catalog.models) {
            if (m.id == catalog.selectedId) {
              return m.displayName;
            }
          }
          return 'Voice model';
        },
        orElse: () => 'Voice model',
      );
});

/// Whether the platform offers an ASR model picker above the status row. Drives
/// the connected server's model selection (collapses to nothing when the server
/// exposes no selectable voice control).
const bool voiceModelPickerEnabled = true;

/// The ASR model picker shown above the voice model's status row. Lists the
/// connected server's installable models and switches the active one over
/// `models.selectVoice`. Disabled while a download is in flight or a switch is
/// pending; hidden entirely when the server reports no selectable catalog.
class VoiceModelPicker extends ConsumerStatefulWidget {
  /// Creates a [VoiceModelPicker].
  const VoiceModelPicker({required this.enabled, super.key});

  /// Whether the picker accepts a new selection (false while downloading).
  final bool enabled;

  @override
  ConsumerState<VoiceModelPicker> createState() => _VoiceModelPickerState();
}

class _VoiceModelPickerState extends ConsumerState<VoiceModelPicker> {
  /// The optimistically-selected id while the server switches models (so the
  /// dropdown reflects the pick immediately, before the catalog refetches).
  String? _pending;

  Future<void> _select(String id) async {
    final control = ref.read(voiceModelControlProvider);
    if (control is! SelectableModelControl) {
      return;
    }
    setState(() => _pending = id);
    try {
      await control.select(id);
      // Re-read the catalog (its `selectedId` is the source of truth); the
      // status row updates on its own via the `models.watchVoice` stream.
      ref.invalidate(voiceModelCatalogProvider);
    } catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _pending = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Always render the picker row (the section only mounts it when the server
    // hosts a voice model). While the catalog loads — or if a server somehow
    // reports none — the select is empty + disabled rather than silently hidden,
    // so a missing list is visible instead of masking the section.
    final catalog = ref.watch(voiceModelCatalogProvider).asData?.value;
    final options = [
      for (final m in catalog?.models ?? const <ModelChoice>[])
        CcSelectOption(value: m.id, label: m.displayName),
    ];
    return SettingsRow(
      icon: AppIcons.languages,
      title: l10n.speechModel,
      subtitle: l10n.speechModelHint,
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: CcSelect<String>(
          options: options,
          value: _pending ?? catalog?.selectedId,
          enabled: widget.enabled && _pending == null && options.isNotEmpty,
          hintText: l10n.checkingEllipsis,
          onChanged: _select,
        ),
      ),
    );
  }
}
