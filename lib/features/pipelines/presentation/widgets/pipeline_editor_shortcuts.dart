import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// Keyboard map for the pipeline editor canvas. Mirrors PlanCanvas: arrows
/// move selection geometrically, `e` starts a connect, Enter completes it,
/// Escape cancels, Delete/Backspace removes a body step or a selected
/// trigger node. Arrow cycling stays steps-only.
KeyEventResult handlePipelineEditorKey({
  required KeyEvent event,
  required PipelineDefinition definition,
  required String? selectedStepId,
  required String? selectedTriggerId,
  required String? connectFrom,
  required Map<String, Offset> dragPositions,
  required void Function(String id) onSelect,
  required void Function(String id) onBeginConnect,
  required void Function(String from, String to) onCompleteConnect,
  required VoidCallback onCancelConnect,
  required void Function(String id) onDeleteStep,
  required void Function(String id) onDeleteTrigger,
}) {
  if (event is! KeyDownEvent) {
    return KeyEventResult.ignored;
  }
  final key = event.logicalKey;
  final renderable = [
    for (final s in definition.steps)
      if (s.kind != StepKind.terminal && s.kind != StepKind.trigger) s,
  ];
  final positions = {
    for (final s in renderable)
      s.id: pipelineEditorNodeOffset(s, dragPositions),
  };
  if (key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.arrowDown) {
    final next = nearestPipelineEditorNode(
      fromId: selectedStepId,
      dir: key,
      positions: positions,
    );
    if (next != null) {
      onSelect(next);
    }
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.delete ||
      key == LogicalKeyboardKey.backspace) {
    if (selectedTriggerId != null) {
      onDeleteTrigger(selectedTriggerId);
      return KeyEventResult.handled;
    }
    final selected = selectedStepId;
    if (selected == null) {
      return KeyEventResult.ignored;
    }
    final step = definition.step(selected);
    if (step != null && step.kind != StepKind.trigger) {
      onDeleteStep(selected);
    }
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.escape && connectFrom != null) {
    onCancelConnect();
    return KeyEventResult.handled;
  }
  if (key == LogicalKeyboardKey.keyE) {
    final from = selectedTriggerId ?? selectedStepId;
    if (from != null) {
      onBeginConnect(from);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
  final selected = selectedStepId;
  if (selected == null) {
    return KeyEventResult.ignored;
  }
  if (key == LogicalKeyboardKey.enter && connectFrom != null) {
    onCompleteConnect(connectFrom, selected);
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
}
