import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Opens the editor for a single input field, returning the built
/// [PipelineInput] or null if cancelled.
Future<PipelineInput?> showInputFieldDialog({
  required BuildContext context,
  PipelineInput? initial,
}) {
  return showCcDialog<PipelineInput>(
    context: context,
    builder: (ctx) => _InputFieldDialog(initial: initial),
  );
}

String _typeLabel(PipelineInputType type, AppLocalizations l10n) =>
    switch (type) {
      PipelineInputType.text => l10n.pipelineInputTypeText,
      PipelineInputType.multiline => l10n.pipelineInputTypeMultiline,
      PipelineInputType.number => l10n.pipelineInputTypeNumber,
      PipelineInputType.boolean => l10n.pipelineInputTypeBoolean,
      PipelineInputType.select => l10n.pipelineInputTypeSelect,
      PipelineInputType.repo => l10n.pipelineInputTypeRepo,
    };

class _InputFieldDialog extends StatefulWidget {
  const _InputFieldDialog({this.initial});

  final PipelineInput? initial;

  @override
  State<_InputFieldDialog> createState() => _InputFieldDialogState();
}

class _InputFieldDialogState extends State<_InputFieldDialog> {
  late final TextEditingController _keyCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _defaultCtrl;
  late final TextEditingController _helpCtrl;
  late final TextEditingController _placeholderCtrl;
  late final TextEditingController _optionsCtrl;
  late PipelineInputType _type;
  late bool _required;
  late bool _defaultBool;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _keyCtrl = TextEditingController(text: i?.key ?? '');
    _labelCtrl = TextEditingController(
      text: (i != null && i.label != i.key) ? i.label : '',
    );
    _defaultCtrl = TextEditingController(
      text: (i?.type == PipelineInputType.boolean)
          ? ''
          : (i?.defaultValue?.toString() ?? ''),
    );
    _helpCtrl = TextEditingController(text: i?.helpText ?? '');
    _placeholderCtrl = TextEditingController(text: i?.placeholder ?? '');
    _optionsCtrl = TextEditingController(text: i?.options.join(', ') ?? '');
    _type = i?.type ?? PipelineInputType.text;
    _required = i?.required ?? false;
    _defaultBool = i?.defaultValue == true;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _labelCtrl.dispose();
    _defaultCtrl.dispose();
    _helpCtrl.dispose();
    _placeholderCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  PipelineInput? _build() {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) {
      return null;
    }
    final options = _type == PipelineInputType.select
        ? _optionsCtrl.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList()
        : const <String>[];
    Object? defaultValue;
    switch (_type) {
      case PipelineInputType.boolean:
        defaultValue = _defaultBool;
      case PipelineInputType.number:
        defaultValue = num.tryParse(_defaultCtrl.text.trim());
      case PipelineInputType.repo:
        // The repo is chosen at run time from the workspace's repos; no
        // authored default.
        defaultValue = null;
      case PipelineInputType.text:
      case PipelineInputType.multiline:
      case PipelineInputType.select:
        final t = _defaultCtrl.text.trim();
        defaultValue = t.isEmpty ? null : t;
    }
    final label = _labelCtrl.text.trim();
    final help = _helpCtrl.text.trim();
    final placeholder = _placeholderCtrl.text.trim();
    return PipelineInput(
      key: key,
      label: label.isEmpty ? null : label,
      type: _type,
      required: _required,
      defaultValue: defaultValue,
      helpText: help.isEmpty ? null : help,
      placeholder: placeholder.isEmpty ? null : placeholder,
      options: options,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // Driven off the enum so a new input type cannot ship with no picker entry.
    final typeOptions = [
      for (final type in PipelineInputType.values)
        CcSelectOption(value: type, label: _typeLabel(type, l10n)),
    ];

    return CcDialog(
      title: l10n.pipelineInputEditTitle,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LabeledField(
                label: l10n.pipelineInputKeyLabel,
                tokens: tokens,
                description: l10n.pipelineInputKeyHelp,
                child: CcTextField(
                  controller: _keyCtrl,
                  hintText: 'repo_full_name',
                ),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: l10n.pipelineInputLabelLabel,
                tokens: tokens,
                child: CcTextField(controller: _labelCtrl),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: l10n.pipelineInputTypeLabel,
                tokens: tokens,
                child: CcSelect<PipelineInputType>(
                  options: typeOptions,
                  value: _type,
                  onChanged: (t) => setState(() => _type = t),
                ),
              ),
              if (_type == PipelineInputType.select) ...[
                const SizedBox(height: 12),
                _LabeledField(
                  label: l10n.pipelineInputOptionsLabel,
                  tokens: tokens,
                  child: CcTextField(
                    controller: _optionsCtrl,
                    hintText: 'docs, security, standard',
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (_type == PipelineInputType.boolean)
                Row(
                  children: [
                    CcSwitch(
                      value: _defaultBool,
                      onChanged: (v) => setState(() => _defaultBool = v),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.pipelineInputDefaultLabel,
                      style: TextStyle(color: tokens.textPrimary),
                    ),
                  ],
                )
              else if (_type != PipelineInputType.repo)
                _LabeledField(
                  label: l10n.pipelineInputDefaultLabel,
                  tokens: tokens,
                  child: CcTextField(
                    controller: _defaultCtrl,
                    keyboardType: _type == PipelineInputType.number
                        ? TextInputType.number
                        : null,
                  ),
                ),
              const SizedBox(height: 12),
              _LabeledField(
                label: l10n.pipelineInputPlaceholderLabel,
                tokens: tokens,
                child: CcTextField(controller: _placeholderCtrl),
              ),
              const SizedBox(height: 12),
              _LabeledField(
                label: l10n.pipelineInputHelpLabel,
                tokens: tokens,
                child: CcTextField(controller: _helpCtrl),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CcCheckbox(
                    value: _required,
                    onChanged: (v) => setState(() => _required = v),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.pipelineInputRequiredLabel,
                    style: TextStyle(color: tokens.textPrimary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(context),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () {
            final built = _build();
            if (built != null) {
              Navigator.pop(context, built);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// A form field with a label above it (and an optional help line below),
/// providing a consistent label/description layout for fields that don't
/// render their own.
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.tokens,
    required this.child,
    this.description,
  });

  final String label;
  final DesignSystemTokens tokens;
  final Widget child;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        child,
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(color: tokens.textTertiary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
