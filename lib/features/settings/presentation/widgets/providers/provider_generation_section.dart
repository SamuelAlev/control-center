import 'package:cc_harness/provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One provider's sampling recipe and output ceiling, collapsed by default.
///
/// Collapsed because it is expert configuration: the defaults are correct for
/// hosted APIs and it only earns attention when running a local model that
/// publishes its own recipe. The header badges itself when a value is set, so
/// an override cannot hide inside a closed section.
class ProviderGenerationSection extends ConsumerStatefulWidget {
  /// Creates a [ProviderGenerationSection].
  const ProviderGenerationSection({super.key, required this.info});

  /// The provider whose defaults are being edited.
  final HarnessProviderInfo info;

  @override
  ConsumerState<ProviderGenerationSection> createState() =>
      _ProviderGenerationSectionState();
}

class _ProviderGenerationSectionState
    extends ConsumerState<ProviderGenerationSection> {
  final _maxTokens = TextEditingController();
  final _temperature = TextEditingController();
  final _topP = TextEditingController();
  final _topK = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final gen = widget.info.generation;
    // Empty means "unset" throughout, so a blank field round-trips to null
    // rather than to a zero the endpoint would reject.
    _maxTokens.text = gen.maxTokens?.toString() ?? '';
    _temperature.text = gen.temperature?.toString() ?? '';
    _topP.text = gen.topP?.toString() ?? '';
    _topK.text = gen.topK?.toString() ?? '';
  }

  @override
  void dispose() {
    _maxTokens.dispose();
    _temperature.dispose();
    _topP.dispose();
    _topK.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final configured = widget.info.generation.isNotEmpty;

    return SettingsDisclosure(
      title: l10n.providerGenerationLabel,
      icon: AppIcons.slidersHorizontal,
      summary: configured ? null : l10n.providerGenerationDefaults,
      badge: configured
          ? SettingsModifiedBadge(label: l10n.providerGenerationOverridden)
          : null,
      childPadding: const EdgeInsets.only(
        left: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.providerGenerationHint,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _field(l10n.providerMaxTokensLabel, _maxTokens),
              _field(l10n.providerTemperatureLabel, _temperature),
              _field(l10n.providerTopPLabel, _topP),
              _field(l10n.providerTopKLabel, _topK),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: CcTypography.caption.copyWith(
                color: tokens.textErrorPrimary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: _busy ? null : _save,
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) => SizedBox(
    width: 150,
    child: SettingsField(
      label: label,
      layout: SettingsFieldLayout.stacked,
      child: CcTextField(
        controller: controller,
        hintText: '—',
        size: CcTextFieldSize.sm,
      ),
    ),
  );

  Future<void> _save() async {
    final maxTokens = _parseInt(_maxTokens.text);
    final temperature = _parseDouble(_temperature.text);
    final topP = _parseDouble(_topP.text);
    final topK = _parseInt(_topK.text);
    final l10n = AppLocalizations.of(context);
    // Validate client-side so a typo does not need a server round trip to be
    // reported. The op validates again — the client is not the boundary.
    final invalid =
        (maxTokens != null && maxTokens <= 0) ||
        (topK != null && topK <= 0) ||
        (temperature != null && (temperature < 0 || temperature > 2)) ||
        (topP != null && (topP <= 0 || topP > 1)) ||
        _isMalformed(_maxTokens.text, maxTokens) ||
        _isMalformed(_temperature.text, temperature) ||
        _isMalformed(_topP.text, topP) ||
        _isMalformed(_topK.text, topK);
    if (invalid) {
      setState(() => _error = l10n.providerGenerationInvalid);
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      await saveHarnessGenerationDefaults(
        ref,
        providerId: widget.info.id,
        maxTokens: maxTokens,
        temperature: temperature,
        topP: topP,
        topK: topK,
      );
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.providerGenerationSaved, variant: CcToastVariant.success);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// True when the user typed something that is not a number — otherwise a typo
  /// would silently clear the field instead of reporting the mistake.
  static bool _isMalformed(String raw, num? parsed) =>
      raw.trim().isNotEmpty && parsed == null;

  static int? _parseInt(String raw) =>
      raw.trim().isEmpty ? null : int.tryParse(raw.trim());

  static double? _parseDouble(String raw) =>
      raw.trim().isEmpty ? null : double.tryParse(raw.trim());
}
