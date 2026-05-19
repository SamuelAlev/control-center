import 'dart:async';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_egress_settings.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_image_settings.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-workspace image overrides for the enclosed Terminal and Browser.
///
/// A workspace can extend the default images with its own tooling (or point
/// at any compatible one on a registry); the machines still boot inside the
/// same enclosure with the same egress gate. The write is the admin-gated
/// workspace settings op, so a member's attempt is denied server-side even if
/// this UI forgot to hide itself.
class CustomImagesSection extends ConsumerWidget {
  /// Creates a [CustomImagesSection].
  const CustomImagesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SectionCard(
      label: l10n.rigsCustomImagesTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rigsCustomImagesHint,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          ImageOverrideField(
            label: l10n.rigsCustomTerminalImageLabel,
            settingKey: kRigExecImageSettingKey,
          ),
          const SizedBox(height: AppSpacing.md),
          ImageOverrideField(
            label: l10n.rigsCustomBrowserImageLabel,
            settingKey: kRigBrowserImageSettingKey,
          ),
        ],
      ),
    );
  }
}

/// One workspace image override: a label, a field and a save button.
class ImageOverrideField extends ConsumerStatefulWidget {
  /// Creates an [ImageOverrideField].
  const ImageOverrideField({
    super.key,
    required this.label,
    required this.settingKey,
  });

  /// The field's label.
  final String label;

  /// The workspace-settings key this field reads and writes.
  final String settingKey;

  @override
  ConsumerState<ImageOverrideField> createState() =>
      _ImageOverrideFieldState();
}

/// Per-workspace egress hosts for the enclosed browser.
///
/// The browser's egress gate is deny-by-default with only the product site
/// admitted; this is where a workspace admits its own (an internal staging
/// site, a package mirror). Same rails as the image overrides above: the
/// write is the admin-gated workspace settings op, and the server
/// re-validates the stored list at read before any host reaches a machine
/// definition.
class BrowserEgressSection extends ConsumerStatefulWidget {
  /// Creates a [BrowserEgressSection].
  const BrowserEgressSection({super.key});

  @override
  ConsumerState<BrowserEgressSection> createState() =>
      _BrowserEgressSectionState();
}

class _BrowserEgressSectionState extends ConsumerState<BrowserEgressSection> {
  final TextEditingController _controller = TextEditingController();
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final hosts = _controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final invalid = hosts.firstWhere(
      (host) => !isValidRigEgressHost(host),
      orElse: () => '',
    );
    if (invalid.isNotEmpty) {
      setState(() => _error = l10n.rigsEgressInvalid(invalid));
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await setWorkspaceSetting(
        ref,
        kRigBrowserEgressHostsSettingKey,
        hosts.isEmpty ? null : encodeRigEgressHostsSetting(hosts),
      );
      if (mounted) {
        CcToastScope.of(context).show(l10n.rigsEgressSaved);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Seed once from the live setting; afterwards the field is the user's.
    final stored = ref.watch(
      workspaceSettingProvider(kRigBrowserEgressHostsSettingKey),
    );
    if (!_seeded && stored != null) {
      _seeded = true;
      _controller.text = parseRigEgressHostsSetting(stored).join('\n');
    }
    return SectionCard(
      label: l10n.rigsEgressTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.rigsEgressHint,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          CcTextField(
            controller: _controller,
            maxLines: 4,
            hintText: 'api.example.com\n*.internal.example.com',
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _error!,
              style: CcTypography.caption.copyWith(color: t.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              loading: _saving,
              onPressed: () => unawaited(_save()),
              child: Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageOverrideFieldState extends ConsumerState<ImageOverrideField> {
  final TextEditingController _controller = TextEditingController();
  bool _seeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final value = normalizeCustomRigImageRef(_controller.text);
    if (value != null && !isValidCustomRigImageRef(value)) {
      setState(() => _error = l10n.rigsCustomImageInvalid);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await setWorkspaceSetting(ref, widget.settingKey, value);
      if (mounted) {
        CcToastScope.of(context).show(l10n.rigsCustomImageSaved);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    // Seed once from the live setting; afterwards the field is the user's.
    final stored = ref.watch(workspaceSettingProvider(widget.settingKey));
    if (!_seeded && stored != null) {
      _seeded = true;
      _controller.text = stored;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: CcTypography.bodySm.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: CcTextField(
                controller: _controller,
                hintText: l10n.rigsCustomImagePlaceholder,
                onSubmitted: (_) => unawaited(_save()),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              loading: _saving,
              onPressed: () => unawaited(_save()),
              child: Text(l10n.save),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _error!,
            style: CcTypography.caption.copyWith(color: t.danger),
          ),
        ],
      ],
    );
  }
}
