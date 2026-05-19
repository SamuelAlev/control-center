import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for the review diagram widgets (PRD 18 §3) — native, token-driven
/// renderers for generated, graph-verified diagrams. No mermaid; unverified
/// edges render dashed.

const _path = '[Components]/Diagrams';

/// A sequence diagram of a call flow, with one unverified edge shown dashed.
@widgetbook.UseCase(name: 'Sequence', type: CcSequenceDiagram, path: _path)
Widget ccSequenceDiagramUseCase(BuildContext context) {
  return const Center(
    child: CcSequenceDiagram(
      participants: ['SpaceInput', 'DispatchSession', 'AgentRunner'],
      messages: [
        CcSequenceMessage(
          from: 'SpaceInput',
          to: 'DispatchSession',
          label: 'submit(prompt)',
        ),
        CcSequenceMessage(
          from: 'DispatchSession',
          to: 'AgentRunner',
          label: 'run()',
        ),
        CcSequenceMessage(
          from: 'AgentRunner',
          to: 'SpaceInput',
          label: 'stream(delta)',
          verified: false,
        ),
      ],
    ),
  );
}

/// A state machine for a status enum, one transition unverified.
@widgetbook.UseCase(
  name: 'State machine',
  type: CcStateMachineDiagram,
  path: _path,
)
Widget ccStateMachineDiagramUseCase(BuildContext context) {
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

/// An ER diagram for a schema change.
@widgetbook.UseCase(
  name: 'Entity relation',
  type: CcEntityRelationDiagram,
  path: _path,
)
Widget ccEntityRelationDiagramUseCase(BuildContext context) {
  return const Center(
    child: CcEntityRelationDiagram(
      entities: [
        CcErEntity(
          name: 'review_cohorts',
          fields: [
            CcErField(name: 'id', type: 'text', isKey: true),
            CcErField(name: 'pr_external_id', type: 'text'),
            CcErField(name: 'cohort_key', type: 'text'),
          ],
        ),
        CcErEntity(
          name: 'review_axis_results',
          fields: [
            CcErField(name: 'id', type: 'text', isKey: true),
            CcErField(name: 'axis', type: 'text'),
            CcErField(name: 'verdict', type: 'text'),
          ],
        ),
      ],
      relations: [
        CcErRelation(
          from: 'review_cohorts',
          to: 'review_axis_results',
          label: 'shares PR',
        ),
      ],
    ),
  );
}
