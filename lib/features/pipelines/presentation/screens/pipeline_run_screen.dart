import 'package:collection/collection.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Manual run launcher: lists every manually-runnable pipeline, renders a
/// dynamic form from the selected pipeline's declared [PipelineInput]s, and
/// starts a run with the submitted values as the trigger payload.
class PipelineRunScreen extends ConsumerStatefulWidget {
  /// Creates a [PipelineRunScreen]. [initialTemplateId] pre-selects a pipeline.
  const PipelineRunScreen({super.key, this.initialTemplateId});

  /// Template to pre-select when the screen first builds. Optional.
  final String? initialTemplateId;

  @override
  ConsumerState<PipelineRunScreen> createState() => _PipelineRunScreenState();
}

class _PipelineRunScreenState extends ConsumerState<PipelineRunScreen> {
  String? _selectedTemplateId;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplateId = widget.initialTemplateId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.pipelineRunLauncherTitle,
        subtitle: l10n.pipelineRunSubtitle,
        child: Center(child: Text(l10n.pipelinesNoActiveWorkspace)),
      );
    }

    final runnableAsync = ref.watch(
      manuallyRunnablePipelinesProvider(workspaceId),
    );
    final repos =
        ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];

    return PageWrapper(
      title: l10n.pipelineRunLauncherTitle,
      subtitle: l10n.pipelineRunSubtitle,
      actions: [
        FButton(
          onPress: () => context.go(pipelinesRoute),
          size: FButtonSizeVariant.sm,
          variant: FButtonVariant.secondary,
          child: Text(l10n.back),
        ),
      ],
      child: runnableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.pipelinesLoadError(e.toString()))),
        data: (pipelines) {
          if (pipelines.isEmpty) {
            return _EmptyState(l10n: l10n);
          }
          final selected = pipelines.firstWhereOrNull(
                (p) => p.templateId == _selectedTemplateId,
              ) ??
              pipelines.first;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 320,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 16, 24),
                  itemCount: pipelines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final p = pipelines[index];
                    return _PipelineTile(
                      name: p.name,
                      description: p.description ?? p.templateId,
                      inputCount: p.inputs.length,
                      selected: p.templateId == selected.templateId,
                      onTap: () => setState(
                        () => _selectedTemplateId = p.templateId,
                      ),
                    );
                  },
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  // Keyed by template so controllers reset when the selection
                  // changes.
                  child: _RunForm(
                    key: ValueKey(selected.templateId),
                    name: selected.name,
                    description: selected.description,
                    inputs: selected.inputs,
                    repos: repos,
                    running: _running,
                    onRun: (values) => _run(
                      workspaceId: workspaceId,
                      templateId: selected.templateId,
                      name: selected.name,
                      values: values,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _run({
    required String workspaceId,
    required String templateId,
    required String name,
    required Map<String, Object?> values,
  }) async {
    setState(() => _running = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      final engine = ref.read(pipelineEngineProvider);
      // For templates whose event triggers dedupe by a resource id (currently
      // index_code → repoId), derive the same dedup key on a manual run so a
      // manual launch can't race the event-triggered run for the same resource.
      final dedupKey =
          templateId == 'index_code' ? values['repoId'] as String? : null;
      final run = await engine.start(
        templateId,
        workspaceId: workspaceId,
        triggerEventType: 'manual',
        triggerPayload: {...values, 'workspaceId': workspaceId},
        dedupKey: dedupKey,
      );
      if (!mounted) {
        return;
      }
      if (run == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.pipelineRunCouldNotStart)),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pipelineRunStarted(name))),
      );
      context.go(pipelineRunRoute(run.id));
    } on Object catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.pipelinesRunFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }
}

/// One selectable pipeline in the left rail.
class _PipelineTile extends StatelessWidget {
  const _PipelineTile({
    required this.name,
    required this.description,
    required this.inputCount,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String description;
  final int inputCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? colors.secondary : colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.workflow, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.mutedForeground, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              inputCount == 0
                  ? l10n.pipelineRunNoInputsBadge
                  : l10n.pipelineRunInputsCount(inputCount),
              style: TextStyle(color: colors.mutedForeground, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dynamic form for one pipeline's inputs plus the Run button.
class _RunForm extends StatefulWidget {
  const _RunForm({
    super.key,
    required this.name,
    required this.description,
    required this.inputs,
    required this.repos,
    required this.running,
    required this.onRun,
  });

  final String name;
  final String? description;
  final List<PipelineInput> inputs;
  final List<Repo> repos;
  final bool running;
  final void Function(Map<String, Object?> values) onRun;

  @override
  State<_RunForm> createState() => _RunFormState();
}

class _RunFormState extends State<_RunForm> {
  final Map<String, TextEditingController> _text = {};
  final Map<String, bool> _bools = {};
  final Map<String, String?> _selects = {};
  // input.key -> selected repo id.
  final Map<String, String?> _repos = {};

  @override
  void initState() {
    super.initState();
    for (final input in widget.inputs) {
      switch (input.type) {
        case PipelineInputType.boolean:
          _bools[input.key] = input.defaultValue == true;
        case PipelineInputType.select:
          final def = input.defaultValue?.toString();
          _selects[input.key] =
              (def != null && input.options.contains(def)) ? def : null;
        case PipelineInputType.repo:
          // Pre-select when the workspace has exactly one repo.
          _repos[input.key] =
              widget.repos.length == 1 ? widget.repos.single.id : null;
        case PipelineInputType.text:
        case PipelineInputType.multiline:
        case PipelineInputType.number:
          _text[input.key] = TextEditingController(
            text: input.defaultValue?.toString() ?? '',
          )..addListener(_onChanged);
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _text.values) {
      ctrl
        ..removeListener(_onChanged)
        ..dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _isValid {
    for (final input in widget.inputs) {
      if (!input.required) {
        continue;
      }
      switch (input.type) {
        case PipelineInputType.boolean:
          break; // a required toggle is always satisfied
        case PipelineInputType.select:
          final v = _selects[input.key];
          if (v == null || v.isEmpty) {
            return false;
          }
        case PipelineInputType.repo:
          if (_repos[input.key] == null) {
            return false;
          }
        case PipelineInputType.number:
          final t = _text[input.key]?.text.trim() ?? '';
          if (t.isEmpty || num.tryParse(t) == null) {
            return false;
          }
        case PipelineInputType.text:
        case PipelineInputType.multiline:
          if ((_text[input.key]?.text.trim() ?? '').isEmpty) {
            return false;
          }
      }
    }
    return true;
  }

  Map<String, Object?> _collect() {
    final values = <String, Object?>{};
    for (final input in widget.inputs) {
      switch (input.type) {
        case PipelineInputType.boolean:
          values[input.key] = _bools[input.key] ?? false;
        case PipelineInputType.select:
          final v = _selects[input.key];
          if (v != null && v.isNotEmpty) {
            values[input.key] = v;
          }
        case PipelineInputType.repo:
          final repo =
              widget.repos.firstWhereOrNull((r) => r.id == _repos[input.key]);
          if (repo != null) {
            // Populate every repo-derived key so any downstream step can read
            // what it needs (repoId/repoLocalPath for index_code,
            // repoFullName/owner/name for the PR pipelines).
            values['repoId'] = repo.id;
            values['repoLocalPath'] = repo.path;
            values['repoFullName'] = repo.fullName;
            if (repo.hasGitHubRemote) {
              values['repoOwner'] = repo.githubOwner;
              values['repoName'] = repo.githubRepoName;
            }
          }
        case PipelineInputType.number:
          final t = _text[input.key]?.text.trim() ?? '';
          final n = num.tryParse(t);
          if (n != null) {
            values[input.key] = n;
          }
        case PipelineInputType.text:
        case PipelineInputType.multiline:
          final t = _text[input.key]?.text.trim() ?? '';
          if (t.isNotEmpty) {
            values[input.key] = t;
          }
      }
    }
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    return ListView(
      children: [
        Text(
          widget.name,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.description != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.description!,
            style: TextStyle(color: colors.mutedForeground, fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        if (widget.inputs.isEmpty)
          Text(
            l10n.pipelineRunNoInputs,
            style: TextStyle(color: colors.mutedForeground, fontSize: 13),
          )
        else
          for (final input in widget.inputs) ...[
            _field(context, input),
            const SizedBox(height: 16),
          ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FButton(
            onPress: widget.running || !_isValid
                ? null
                : () => widget.onRun(_collect()),
            prefix: widget.running
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.play, size: 14),
            child: Text(l10n.pipelineRunSubmit),
          ),
        ),
      ],
    );
  }

  Widget _field(BuildContext context, PipelineInput input) {
    final colors = context.theme.colors;
    final labelText = input.required ? '${input.label} *' : input.label;
    final label = Text(labelText);
    final description =
        input.helpText == null ? null : Text(input.helpText!);

    switch (input.type) {
      case PipelineInputType.multiline:
        return FTextField.multiline(
          control: FTextFieldControl.managed(controller: _text[input.key]!),
          label: label,
          hint: input.placeholder,
          description: description,
          minLines: 3,
          maxLines: 10,
        );
      case PipelineInputType.number:
        return FTextField(
          control: FTextFieldControl.managed(controller: _text[input.key]!),
          label: label,
          hint: input.placeholder,
          description: description,
          keyboardType: TextInputType.number,
          size: FTextFieldSizeVariant.sm,
        );
      case PipelineInputType.boolean:
        return Row(
          children: [
            FSwitch(
              value: _bools[input.key] ?? false,
              onChange: (v) => setState(() => _bools[input.key] = v),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText,
                    style: TextStyle(color: colors.foreground, fontSize: 14),
                  ),
                  if (input.helpText != null)
                    Text(
                      input.helpText!,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      case PipelineInputType.select:
        return FSelect<String>(
          items: {for (final o in input.options) o: o},
          label: label,
          description: description,
          control: FSelectControl<String>.lifted(
            value: _selects[input.key],
            onChange: (v) => setState(() => _selects[input.key] = v),
          ),
        );
      case PipelineInputType.repo:
        if (widget.repos.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labelText,
                  style: TextStyle(color: colors.foreground, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).pipelineRunNoRepos,
                style: TextStyle(color: colors.mutedForeground, fontSize: 12),
              ),
            ],
          );
        }
        return FSelect<String>(
          items: {for (final r in widget.repos) r.name: r.id},
          label: label,
          description: description,
          control: FSelectControl<String>.lifted(
            value: _repos[input.key],
            onChange: (v) => setState(() => _repos[input.key] = v),
          ),
        );
      case PipelineInputType.text:
        return FTextField(
          control: FTextFieldControl.managed(controller: _text[input.key]!),
          label: label,
          hint: input.placeholder,
          description: description,
          size: FTextFieldSizeVariant.sm,
        );
    }
  }
}

/// Shown when no pipeline has manual run turned on.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.workflow, size: 48, color: colors.mutedForeground),
          const SizedBox(height: 16),
          Text(
            l10n.pipelineRunEmptyTitle,
            style: TextStyle(
              color: colors.foreground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 420,
            child: Text(
              l10n.pipelineRunEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.mutedForeground, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          FButton(
            onPress: () => context.go(settingsPipelinesRoute),
            size: FButtonSizeVariant.sm,
            variant: FButtonVariant.secondary,
            prefix: const Icon(LucideIcons.settings, size: 14),
            child: Text(l10n.pipelineRunManageTemplates),
          ),
        ],
      ),
    );
  }
}
