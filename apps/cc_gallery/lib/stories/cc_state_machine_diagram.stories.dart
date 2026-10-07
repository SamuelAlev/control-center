import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_state_machine_diagram.stories.g.dart';

/// Stories for the review diagram widgets (PRD 18 §3) — native, token-driven
/// renderers for generated, graph-verified diagrams. No mermaid; unverified
/// edges render dashed.

const _path = '[Components]/Diagrams';

const component = ComponentMeta(name: 'CcStateMachineDiagram', path: _path);

const meta = Meta(Showcase.new);

final $StateMachine = _Story(
  name: 'State machine',
  args: _Args.fixed(preview: ccStateMachineDiagramStory),
);

/// A state machine for a status enum, one transition unverified.
Widget ccStateMachineDiagramStory(BuildContext context) {
  return const Center(
    child: CcStateMachineDiagram(
      states: ['requested', 'inProgress', 'awaitingApproval', 'completed'],
      initialState: 'requested',
      transitions: [
        CcStateTransition(
          from: 'requested',
          to: 'inProgress',
          label: 'dispatch',
        ),
        CcStateTransition(
          from: 'inProgress',
          to: 'awaitingApproval',
          label: 'finalize',
        ),
        CcStateTransition(
          from: 'awaitingApproval',
          to: 'completed',
          label: 'approve',
          verified: false,
        ),
      ],
    ),
  );
}
