import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Dialog for creating or editing a memory fact.
class FactEditDialog extends StatefulWidget {
  /// Creates a [FactEditDialog] for creating a new fact or editing [fact].
  const FactEditDialog({super.key, this.fact, this.existingDomains = const []});

  /// The fact to edit, or `null` when creating a new fact.
  final MemoryFact? fact;

  /// Existing domain names to suggest in the autocomplete field.
  final List<String> existingDomains;
  @override
  State<FactEditDialog> createState() => _FactEditDialogState();
}

class _FactEditDialogState extends State<FactEditDialog> {
  late final TextEditingController _topicController;
  late final TextEditingController _contentController;
  // Owned by the [Autocomplete] widget — assigned in its fieldViewBuilder and
  // disposed by it, so we neither create nor dispose it here.
  late TextEditingController _domainController;
  late double _confidence;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.fact?.topic ?? '');
    _contentController = TextEditingController(
      text: widget.fact?.content ?? '',
    );
    _confidence = widget.fact?.confidence ?? 1.0;
  }

  @override
  void dispose() {
    _topicController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.fact != null;
    final l10n = AppLocalizations.of(context);

    return CcDialog(
      maxWidth: 560,
      title: isEditing ? l10n.editFact : l10n.newFact,
      content: SizedBox(
        width: 480,
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Autocomplete<String>(
                  initialValue: TextEditingValue(
                    text: widget.fact?.domain ?? '',
                  ),
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return widget.existingDomains;
                    }
                    return widget.existingDomains.where(
                      (d) => d.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        _domainController = controller;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: l10n.domainLabel,
                            hintText: l10n.domainHint,
                          ),
                          onSubmitted: (_) => onFieldSubmitted(),
                        );
                      },
                  onSelected: (selection) {
                    _domainController.text = selection;
                  },
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.topic),
                    const SizedBox(height: 6),
                    CcTextField(
                      controller: _topicController,
                      hintText: l10n.topicHint,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.contentLabel),
                    const SizedBox(height: 6),
                    CcTextArea(
                      controller: _contentController,
                      hintText: l10n.contentHint,
                      maxLines: 6,
                      minLines: 3,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.confidenceLabel((_confidence * 100).round()),
                  style: theme.textTheme.labelMedium,
                ),
                Slider(
                  value: _confidence,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  label: '${(_confidence * 100).round()}%',
                  onChanged: (v) => setState(() => _confidence = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () {
            final topic = _topicController.text.trim();
            final content = _contentController.text.trim();
            final domain = _domainController.text.trim();
            if (topic.isEmpty || content.isEmpty || domain.isEmpty) {
              return;
            }

            final now = DateTime.now();
            final result =
                widget.fact?.copyWith(
                  domain: domain,
                  topic: topic,
                  content: content,
                  confidence: _confidence,
                  updatedAt: now,
                ) ??
                MemoryFact(
                  id: '',
                  workspaceId: '',
                  domain: domain,
                  topic: topic,
                  content: content,
                  confidence: _confidence,
                  createdAt: now,
                  updatedAt: now,
                );
            Navigator.of(context).pop(result);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
