import 'package:cc_domain/cc_domain.dart' show CodeModeStatusDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/code_mode/presentation/code_mode_copy.dart';
import 'package:control_center/features/code_mode/presentation/settings/code_mode_limit_specs.dart';
import 'package:control_center/features/code_mode/providers/code_mode_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long and how far one script may go, folded away by default.
///
/// The limits save together (one stored object), so they commit through a
/// save bar rather than per field. Each field is checked against its bounds
/// as it is typed, and Save stays disabled while one is out of range, so the
/// server's own refusal is the exception rather than the feedback loop. "Use
/// defaults" stages every default; it still needs Save, like any edit.
class CodeModeLimitsSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const CodeModeLimitsSection({
    super.key,
    required this.workspaceId,
    required this.status,
    required this.canEdit,
  });

  /// The workspace being configured.
  final String workspaceId;

  /// What the server reported.
  final CodeModeStatusDto status;

  /// Whether the reader administers the workspace.
  final bool canEdit;

  @override
  ConsumerState<CodeModeLimitsSection> createState() =>
      _CodeModeLimitsSectionState();
}

class _CodeModeLimitsSectionState extends ConsumerState<CodeModeLimitsSection> {
  late final Map<String, TextEditingController> _fields = {
    for (final spec in _specs) spec.key: TextEditingController(),
  };

  /// The limits, with the memory limit held to the server's heap ceiling.
  List<CodeModeLimitSpec> get _specs =>
      codeModeLimitSpecs(maxHeapBytes: widget.status.maxHeapBytes);
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFromStatus();
    for (final c in _fields.values) {
      c.addListener(_onChanged);
    }
  }

  @override
  void didUpdateWidget(covariant CodeModeLimitsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh status after a save (or from another client) reseeds the form,
    // unless the reader is in the middle of an edit.
    if (oldWidget.status.limits != widget.status.limits && !_dirty) {
      _loadFromStatus();
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() => _error = null);

  void _loadFromStatus() {
    for (final spec in _specs) {
      _fields[spec.key]!.text =
          '${spec.display(codeModeLimitValue(widget.status.limits, spec))}';
    }
  }

  void _stageDefaults() {
    for (final spec in _specs) {
      _fields[spec.key]!.text = '${spec.defaultValue}';
    }
  }

  int? _staged(CodeModeLimitSpec spec) => spec.parse(_fields[spec.key]!.text);

  bool get _dirty => _specs.any(
    (spec) =>
        _staged(spec) !=
        spec.display(codeModeLimitValue(widget.status.limits, spec)),
  );

  bool get _valid => _specs.every(
    (spec) =>
        spec.validate(AppLocalizations.of(context), _fields[spec.key]!.text) ==
        null,
  );

  bool get _atDefaults =>
      _specs.every((spec) => _staged(spec) == spec.defaultValue);

  Future<void> _save() async {
    final overrides = <String, int>{
      for (final spec in _specs)
        if (_staged(spec) case final v? when v != spec.defaultValue)
          spec.key: v * spec.unit.factor,
    };
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(codeModeSettingsControllerProvider(widget.workspaceId))
          .setLimits(overrides);
      if (mounted) {
        CcToastScope.of(context).show(
          AppLocalizations.of(context).saved,
          variant: CcToastVariant.success,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _error = codeModeWriteFailure(AppLocalizations.of(context), e),
        );
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
    final changed = widget.status.limitOverrides.length;
    final caption = CcTypography.caption.copyWith(
      color: t.textSecondary,
      height: 1.45,
    );
    return SectionCard(
      label: l10n.codeModeLimitsLabel,
      subtitle: Text(l10n.codeModeLimitsSubtitle),
      child: SettingsDisclosure(
        title: l10n.codeModeLimitsDisclosure,
        icon: AppIcons.slidersHorizontal,
        summary: changed == 0
            ? l10n.codeModeLimitsAtDefaults
            : l10n.codeModeLimitsChangedCount(changed),
        badge: changed == 0
            ? null
            : SettingsModifiedBadge(label: l10n.settingsChangedBadge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final spec in _specs) ...[
              SettingsField(
                label: spec.label(l10n),
                description: spec.description(l10n),
                hint: spec.range(l10n),
                error: spec.validate(l10n, _fields[spec.key]!.text),
                controlWidth: 200,
                child: CcTextField(
                  controller: _fields[spec.key],
                  enabled: widget.canEdit && !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  suffix: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: Text(spec.unit.suffix(l10n), style: caption),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              [
                l10n.codeModeServerCap(widget.status.maxProcesses),
                l10n.codeModeServerWorkspaceShare(
                  widget.status.maxWorkspaceProcesses,
                ),
              ].join(' '),
              style: caption,
            ),
            if (!widget.canEdit) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.settingsWorkspaceAdminOnly, style: caption),
            ] else ...[
              const SizedBox(height: AppSpacing.md),
              SettingsSaveBar(
                dirty: _dirty,
                busy: _saving,
                saveEnabled: _valid,
                error: _error,
                onSave: _save,
                onDiscard: () => setState(_loadFromStatus),
                secondaryActions: [
                  CcButton(
                    variant: CcButtonVariant.ghost,
                    size: CcButtonSize.sm,
                    icon: AppIcons.rotateCcw,
                    onPressed: _saving || _atDefaults
                        ? null
                        : () => setState(_stageDefaults),
                    child: Text(l10n.codeModeLimitsUseDefaults),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
