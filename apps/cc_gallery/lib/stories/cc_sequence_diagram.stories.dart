import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_sequence_diagram.stories.g.dart';

/// Stories for the review diagram widgets (PRD 18 §3) — native, token-driven
/// renderers for generated, graph-verified diagrams. No mermaid; unverified
/// edges render dashed.

const _path = '[Components]/Diagrams';

const component = ComponentMeta(name: 'CcSequenceDiagram', path: _path);

const meta = Meta(Showcase.new);

final $Sequence = _Story(args: _Args.fixed(preview: ccSequenceDiagramStory));

/// A sequence diagram of a call flow, with one unverified edge shown dashed.
Widget ccSequenceDiagramStory(BuildContext context) {
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
