import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_entity_relation_diagram.stories.g.dart';

/// Stories for the review diagram widgets (PRD 18 §3) — native, token-driven
/// renderers for generated, graph-verified diagrams. No mermaid; unverified
/// edges render dashed.

const _path = '[Components]/Diagrams';

const component = ComponentMeta(name: 'CcEntityRelationDiagram', path: _path);

const meta = Meta(Showcase.new);

final $EntityRelation = _Story(
  name: 'Entity relation',
  args: _Args.fixed(preview: ccEntityRelationDiagramStory),
);

/// An ER diagram for a schema change.
Widget ccEntityRelationDiagramStory(BuildContext context) {
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
