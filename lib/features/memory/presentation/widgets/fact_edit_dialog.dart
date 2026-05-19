import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class FactEditDialog extends StatefulWidget {
  const FactEditDialog({super.key, this.fact, this.existingDomains = const []});

  final MemoryFact? fact;
  final List<String> existingDomains;

  @override
  State<FactEditDialog> createState() => _FactEditDialogState();
}

class _FactEditDialogState extends State<FactEditDialog> {
  late final TextEditingController _topicController;
  late final TextEditingController _contentController;
  late final TextEditingController _domainController;
  late double _confidence;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.fact?.topic ?? '');
    _contentController = TextEditingController(text: widget.fact?.content ?? '');
    _domainController = TextEditingController(text: widget.fact?.domain ?? '');
    _confidence = widget.fact?.confidence ?? 1.0;
  }

  @override
  void dispose() {
    _topicController.dispose();
    _contentController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.fact != null;
    final l10n = AppLocalizations.of(context);

    return FDialog(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
      title: Text(isEditing ? l10n.editFact : l10n.newFact),
      body: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: widget.fact?.domain ?? ''),
                optionsBuilder: (textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return widget.existingDomains;
                  }
                  return widget.existingDomains.where(
                    (d) => d.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                  );
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
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
              FTextField(
                control: FTextFieldControl.managed(controller: _topicController),
                label: Text(l10n.topic),
                hint: l10n.topicHint,
              ),
              const SizedBox(height: 16),
              FTextField(
                control: FTextFieldControl.managed(controller: _contentController),
                label: Text(l10n.contentLabel),
                hint: l10n.contentHint,
                maxLines: 6,
                minLines: 3,
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
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                onPress: () => Navigator.of(context).pop(),
                variant: FButtonVariant.outline,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: () {
                  final topic = _topicController.text.trim();
                  final content = _contentController.text.trim();
                  final domain = _domainController.text.trim();
                  if (topic.isEmpty || content.isEmpty || domain.isEmpty) {
                    return;
                  }

                  final now = DateTime.now();
                  final result = widget.fact?.copyWith(
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
          ),
        ),
      ],
    );
  }
}
