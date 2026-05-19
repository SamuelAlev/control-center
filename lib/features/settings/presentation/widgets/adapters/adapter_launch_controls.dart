import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Per-adapter launch customization: a button to edit environment variables
/// (stored in the keychain) and a text field for extra argv (YOLO / skip-perms
/// flags, stored in SharedPreferences). Both feed the dispatch session.
class AdapterLaunchControls extends ConsumerWidget {
  /// Creates an [AdapterLaunchControls].
  const AdapterLaunchControls({super.key, required this.adapterId});

  /// The adapter whose launch configuration is edited.
  final String adapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final args = ref.watch(adapterArgsProvider(adapterId)).value ?? '';
    final env = ref.watch(adapterEnvOverridesProvider(adapterId)).value ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsField(
          label: l10n.environmentVariables,
          description: l10n.environmentVariablesDescription,
          controlWidth: 200,
          child: CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: AppIcons.slidersHorizontal,
            onPressed: () => _openEnvEditor(context, ref),
            child: Text(
              env.isEmpty
                  ? l10n.adaptersEnvNone
                  : l10n.adaptersEnvCount(env.length),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SettingsField(
          label: l10n.adapterArguments,
          description: l10n.adapterArgumentsDescription,
          layout: SettingsFieldLayout.stacked,
          child: _AdapterArgsField(adapterId: adapterId, initial: args),
        ),
      ],
    );
  }

  void _openEnvEditor(BuildContext context, WidgetRef ref) {
    showCcDialog<void>(
      context: context,
      builder: (_) => _AdapterEnvDialog(adapterId: adapterId),
    ).then((_) => ref.invalidate(adapterEnvOverridesProvider(adapterId)));
  }
}

/// Stateful argv field: owns its [TextEditingController] so focus/state
/// survives rebuilds, syncing from the provider when the initial value changes
/// and persisting on edit.
class _AdapterArgsField extends ConsumerStatefulWidget {
  const _AdapterArgsField({required this.adapterId, required this.initial});

  final String adapterId;
  final String initial;

  @override
  ConsumerState<_AdapterArgsField> createState() => _AdapterArgsFieldState();
}

class _AdapterArgsFieldState extends ConsumerState<_AdapterArgsField> {
  late final TextEditingController _ctl = TextEditingController(
    text: widget.initial,
  );

  @override
  void didUpdateWidget(covariant _AdapterArgsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initial != oldWidget.initial && widget.initial != _ctl.text) {
      _ctl.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcTextField(
      controller: _ctl,
      hintText: l10n.adapterArgumentsHint,
      onChanged: (value) => ref
          .read(adapterPreferencesProvider)
          .setAdapterArgs(widget.adapterId, value.isEmpty ? null : value)
          .then((_) => ref.invalidate(adapterArgsProvider(widget.adapterId))),
    );
  }
}

/// Dialog for editing one adapter's environment variables as KEY=VALUE rows.
class _AdapterEnvDialog extends ConsumerStatefulWidget {
  const _AdapterEnvDialog({required this.adapterId});

  final String adapterId;

  @override
  ConsumerState<_AdapterEnvDialog> createState() => _AdapterEnvDialogState();
}

class _AdapterEnvDialogState extends ConsumerState<_AdapterEnvDialog> {
  List<SettingsKeyValuePair> _entries = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final env = await ref
        .read(adapterEnvOverridesRepositoryProvider)
        .getFor(widget.adapterId);
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = [
        for (final e in env.entries) SettingsKeyValuePair(e.key, e.value),
      ];
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await ref.read(adapterEnvOverridesRepositoryProvider).setFor(
      widget.adapterId,
      {for (final e in _entries) e.key: e.value},
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcDialog(
      title: l10n.environmentVariables,
      maxWidth: 520,
      content: _loaded
          ? SizedBox(
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.environmentVariablesDescription,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SettingsKeyValueEditor(
                    entries: _entries,
                    keyHint: l10n.variableKey,
                    valueHint: l10n.variableValue,
                    addLabel: l10n.addVariable,
                    emptyLabel: l10n.adaptersEnvNone,
                    obscureValues: true,
                    onChanged: (next) => _entries = next,
                  ),
                ],
              ),
            )
          : const SizedBox(height: 80, child: Center(child: CcSpinner())),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(onPressed: _save, child: Text(l10n.saveChanges)),
      ],
    );
  }
}
