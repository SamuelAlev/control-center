import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_actions.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_fact_details.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_record_links.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_record_page.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/styled_markdown_body.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One fact: what it says rendered, its details, and the facts around it.
class MemoryFactPage extends ConsumerStatefulWidget {
  /// Creates a [MemoryFactPage].
  const MemoryFactPage({
    super.key,
    required this.workspaceId,
    required this.factId,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The fact.
  final String factId;

  @override
  ConsumerState<MemoryFactPage> createState() => _MemoryFactPageState();
}

class _MemoryFactPageState extends ConsumerState<MemoryFactPage> {
  final _topic = TextEditingController();
  final _domain = TextEditingController();
  final _content = TextEditingController();
  final _contentFocus = FocusNode();
  double _confidence = 1;
  bool _editing = false;
  bool _saving = false;
  bool _left = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final field in [_topic, _domain, _content]) {
      field.addListener(_onEdited);
    }
  }

  @override
  void dispose() {
    _topic.dispose();
    _domain.dispose();
    _content.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _onEdited() => setState(() {});

  bool _dirty(MemoryFact fact) =>
      _editing &&
      (_topic.text != fact.topic ||
          _domain.text != fact.domain ||
          _content.text != fact.content ||
          _confidence != fact.confidence);

  bool get _complete =>
      _topic.text.trim().isNotEmpty &&
      _domain.text.trim().isNotEmpty &&
      _content.text.trim().isNotEmpty;

  void _startEditing(MemoryFact fact) => setState(() {
    _topic.text = fact.topic;
    _domain.text = fact.domain;
    _content.text = fact.content;
    _confidence = fact.confidence;
    _error = null;
    _editing = true;
  });

  void _stopEditing() => setState(() {
    _editing = false;
    _error = null;
  });

  /// Once only. A delete both returns here and takes the record out from under
  /// the page, and each would step back: the second a page too far.
  void _leave() {
    if (_left) {
      return;
    }
    _left = true;
    leaveMemoryRecord(ref, widget.workspaceId);
  }

  Future<void> _back(MemoryFact fact) async {
    if (await mayDiscardMemoryEdits(context, dirty: _dirty(fact)) && mounted) {
      _leave();
    }
  }

  Future<void> _cancel(MemoryFact fact) async {
    if (await mayDiscardMemoryEdits(context, dirty: _dirty(fact)) && mounted) {
      _stopEditing();
    }
  }

  Future<void> _delete(MemoryFact fact) async {
    if (await deleteMemoryFact(context, ref, fact) && mounted) {
      _leave();
    }
  }

  Future<void> _save(MemoryFact fact, AppLocalizations l10n) async {
    final toasts = CcToastScope.maybeOf(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final saved = await runMemorySave(
      () => ref
          .read(memoryFactRepositoryProvider)
          .upsert(
            fact.copyWith(
              topic: _topic.text.trim(),
              domain: _domain.text.trim(),
              content: _content.text.trim(),
              confidence: _confidence,
              updatedAt: DateTime.now(),
            ),
          ),
      onError: (message) => _error = message,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _editing = _editing && !saved;
    });
    if (saved) {
      toasts?.show(l10n.saved, variant: CcToastVariant.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final factsAsync = ref.watch(memoryFactsProvider(widget.workspaceId));
    final facts = factsAsync.value ?? const <MemoryFact>[];
    final fact = facts.firstWhereOrNull((fact) => fact.id == widget.factId);
    if (fact == null) {
      // Gone: an agent replaced it, or someone else deleted it.
      if (factsAsync.hasValue) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _leave();
          }
        });
      }
      return const Center(child: CcSpinner());
    }

    final replacement = facts.firstWhereOrNull(
      (other) => other.id == fact.supersededBy,
    );
    final earlier = facts.where((other) => other.supersededBy == fact.id);
    return MemoryRecordPage(
      title: _editing && _topic.text.isNotEmpty ? _topic.text : fact.topic,
      editing: _editing,
      onBack: memoryAction(() => _back(fact)),
      onEdit: () => _startEditing(fact),
      onCancelEdit: memoryAction(() => _cancel(fact)),
      onDelete: memoryAction(() => _delete(fact)),
      body: _editing
          ? _form(l10n, facts)
          : SectionCard(
              label: l10n.contentLabel,
              child: StyledMarkdownBody(data: fact.content),
            ),
      details: MemoryFactDetails(fact: fact),
      links: [
        if (fact.isSuperseded) MemoryReplacedNotice(replacement: replacement),
        if (earlier.isNotEmpty)
          MemoryFactLinks(label: l10n.superseded, facts: earlier.toList()),
      ],
      saveBar: _editing
          ? SettingsSaveBar(
              dirty: _dirty(fact),
              busy: _saving,
              saveEnabled: _complete,
              error: _error,
              onSave: memoryAction(() => _save(fact, l10n)),
              onDiscard: _stopEditing,
            )
          : null,
    );
  }

  Widget _form(AppLocalizations l10n, List<MemoryFact> facts) {
    return SectionCard(
      label: l10n.editFact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsField(
            label: l10n.topic,
            child: CcTextField(controller: _topic, hintText: l10n.topicHint),
          ),
          const SizedBox(height: AppSpacing.lg),
          MemoryDomainField(
            controller: _domain,
            domains: facts.map((fact) => fact.domain),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsField(
            label: l10n.confidenceLabel((_confidence * 100).round()),
            child: CcSlider(
              value: _confidence,
              divisions: 20,
              showValue: false,
              semanticLabel: l10n.confidenceLabel((_confidence * 100).round()),
              onChanged: (value) => setState(() => _confidence = value),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SettingsField(
            label: l10n.contentLabel,
            layout: SettingsFieldLayout.stacked,
            child: MemoryMarkdownField(
              controller: _content,
              focusNode: _contentFocus,
              hint: l10n.contentHint,
            ),
          ),
        ],
      ),
    );
  }
}
