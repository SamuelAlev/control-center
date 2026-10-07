import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/model_picker_field.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single row for configuring a default runner (adapter + model dropdowns).
class DefaultRunnerRow extends ConsumerWidget {
  /// Creates a [DefaultRunnerRow].
  const DefaultRunnerRow({
    super.key,
    required this.label,
    required this.description,
    required this.adapterIdProvider,
    required this.modelIdProvider,
    required this.available,
    this.enabled = true,
    this.offLabel,
    this.footnote,
  });

  /// What this default is for.
  final String label;

  /// What picking it changes.
  final String description;

  /// Holds the selected adapter id.
  final NotifierProvider<dynamic, String?> adapterIdProvider;

  /// Holds the selected model id.
  final NotifierProvider<dynamic, String?> modelIdProvider;

  /// The runners installed on the server host — the only offerable set.
  final List<Adapter> available;

  /// False renders both pickers read-only (a member viewing workspace state
  /// only an admin may change).
  final bool enabled;

  /// When set, the adapter picker leads with a row of this label that clears
  /// the adapter — for a runner whose absence means "off". CcSelect has no
  /// clear affordance, so off has to be a row you can pick.
  final String? offLabel;

  /// A caption under the pickers.
  final String? footnote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentAdapterId = ref.watch(adapterIdProvider);
    final currentModelId = ref.watch(modelIdProvider);

    // Installed runners only. A default that names a runner the server does not
    // have is not a default — it is a dispatch failure deferred to whenever
    // this default is next used. The list of what is missing (and how to
    // install it) is the rail above this row, not a disabled-looking option in
    // the picker.
    final adapterItems = <String, String>{
      for (final adapter in available) adapter.name: adapter.id,
    };
    final off = offLabel;

    return SettingsField(
      label: label,
      description: description,
      layout: SettingsFieldLayout.stacked,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CcSelect<String>(
                  options: [
                    if (off != null)
                      CcSelectOption(value: _offValue, label: off),
                    ...adapterItems.entries.map(
                      (e) => CcSelectOption(value: e.value, label: e.key),
                    ),
                  ],
                  value: currentAdapterId ?? (off != null ? _offValue : null),
                  enabled: enabled,
                  hintText: l10n.adapterLabel,
                  onChanged: (picked) {
                    final id = picked == _offValue ? null : picked;
                    // Re-picking the selected adapter is not a change;
                    // treating it as one would wipe a model nobody touched.
                    if (id == currentAdapterId) {
                      return;
                    }
                    // ignore: avoid_dynamic_calls
                    ref.read(adapterIdProvider.notifier).set(id);
                    // Model ids are per-adapter, so switching adapters
                    // clears the model too.
                    // ignore: avoid_dynamic_calls
                    ref.read(modelIdProvider.notifier).set(null);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ModelPickerField(
                  adapterId: currentAdapterId,
                  selectedModelId: currentModelId,
                  enabled: enabled,
                  onChange: (id) {
                    // ignore: avoid_dynamic_calls
                    ref.read(modelIdProvider.notifier).set(id);
                  },
                ),
              ),
            ],
          ),
          if (footnote case final note?) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              note,
              style: CcTypography.caption.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Sentinel for the "off" row. Not an adapter id, and never stored: picking
/// it clears the adapter.
const String _offValue = '';
