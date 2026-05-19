import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/model_select.dart';
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

    return SettingsField(
      label: label,
      description: description,
      layout: SettingsFieldLayout.stacked,
      child: Row(
        children: [
          Expanded(
            child: CcSelect<String>(
              options: adapterItems.entries
                  .map((e) => CcSelectOption(value: e.value, label: e.key))
                  .toList(),
              value: currentAdapterId,
              hintText: l10n.adapterLabel,
              onChanged: (id) {
                // ignore: avoid_dynamic_calls
                ref.read(adapterIdProvider.notifier).set(id);
                // ignore: avoid_dynamic_calls
                ref.read(modelIdProvider.notifier).set(null);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ModelSelect(
              adapterId: currentAdapterId,
              selectedModelId: currentModelId,
              onChange: (id) {
                // ignore: avoid_dynamic_calls
                ref.read(modelIdProvider.notifier).set(id);
              },
            ),
          ),
        ],
      ),
    );
  }
}
