import 'package:cc_ui/src/components/cc_diagram.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcSequenceDiagram', () {
    testWidgets('collapses to an empty box when there are no participants', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(const CcSequenceDiagram(participants: [], messages: [])),
      );

      // The widget is in the tree but its build returns a SizedBox.shrink, so no
      // canvas is painted for the empty case.
      expect(find.byType(CcSequenceDiagram), findsOneWidget);
      expect(find.byType(CustomPaint), findsNothing);
    });

    testWidgets('renders a custom-painted canvas for participants', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcSequenceDiagram(
            participants: ['Client', 'Server', 'DB'],
            messages: [
              CcSequenceMessage(
                from: 'Client',
                to: 'Server',
                label: 'POST /login',
              ),
              CcSequenceMessage(from: 'Server', to: 'DB', label: 'select user'),
              CcSequenceMessage(
                from: 'Server',
                to: 'Client',
                label: '200 OK',
                verified: false,
              ),
            ],
          ),
        ),
      );

      expect(find.byType(CcSequenceDiagram), findsOneWidget);
      // The diagram paints itself on a CustomPaint (at least one).
      expect(find.byType(CustomPaint), findsWidgets);
      // No exceptions thrown while painting (verifies paint() runs end-to-end).
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with a single participant and no messages', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcSequenceDiagram(participants: ['Solo'], messages: []),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'skips messages referencing unknown participants without crashing',
      (tester) async {
        await tester.pumpWidget(
          ccTestApp(
            const CcSequenceDiagram(
              participants: ['A', 'B'],
              messages: [
                CcSequenceMessage(from: 'A', to: 'B', label: 'known'),
                // from/to unknown — painter must continue, not throw.
                CcSequenceMessage(from: 'Ghost', to: 'X', label: 'unknown'),
              ],
            ),
          ),
        );

        expect(find.byType(CustomPaint), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('is horizontally scrollable', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcSequenceDiagram(
            participants: ['A', 'B', 'C', 'D', 'E', 'F'],
            messages: [],
          ),
        ),
      );

      // The body wraps the canvas in a horizontal SingleChildScrollView.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
        findsOneWidget,
      );
    });
  });

  group('CcStateMachineDiagram', () {
    testWidgets('renders every state pill', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcStateMachineDiagram(
            states: ['idle', 'loading', 'ready'],
            transitions: [],
          ),
        ),
      );

      expect(find.text('idle'), findsOneWidget);
      expect(find.text('loading'), findsOneWidget);
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('marks the initial state pill distinctly', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcStateMachineDiagram(
            states: ['idle', 'ready'],
            transitions: [],
            initialState: 'idle',
          ),
        ),
      );

      // Both labels render; the initial-state styling is exercised in build.
      expect(find.text('idle'), findsOneWidget);
      expect(find.text('ready'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders verified transition rows with their labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcStateMachineDiagram(
            states: ['idle', 'ready'],
            transitions: [
              CcStateTransition(from: 'idle', to: 'ready', label: 'load'),
              CcStateTransition(from: 'ready', to: 'idle', label: ''),
            ],
          ),
        ),
      );

      // Verified transition with a label appends " : <label>".
      expect(find.text('idle  →  ready : load'), findsOneWidget);
      // Empty label omits the suffix.
      expect(find.text('ready  →  idle'), findsOneWidget);
    });

    testWidgets('tags unverified transitions', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcStateMachineDiagram(
            states: ['a', 'b'],
            transitions: [
              CcStateTransition(
                from: 'a',
                to: 'b',
                label: 'guess',
                verified: false,
              ),
            ],
          ),
        ),
      );

      expect(find.text('a  →  b : guess  (unverified)'), findsOneWidget);
    });
  });

  group('CcEntityRelationDiagram', () {
    testWidgets('renders entity names and their fields', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcEntityRelationDiagram(
            entities: [
              CcErEntity(
                name: 'users',
                fields: [
                  CcErField(name: 'id', type: 'uuid', isKey: true),
                  CcErField(name: 'email', type: 'text'),
                ],
              ),
              CcErEntity(name: 'orphan'),
            ],
          ),
        ),
      );

      expect(find.text('users'), findsOneWidget);
      expect(find.text('🔑 id: uuid'), findsOneWidget);
      expect(find.text('email: text'), findsOneWidget);
      // Entity with no fields still renders its header.
      expect(find.text('orphan'), findsOneWidget);
    });

    testWidgets('renders relationship rows with optional labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcEntityRelationDiagram(
            entities: [
              CcErEntity(name: 'users'),
              CcErEntity(name: 'posts'),
            ],
            relations: [
              CcErRelation(from: 'users', to: 'posts', label: 'has many'),
              CcErRelation(from: 'posts', to: 'users', label: ''),
            ],
          ),
        ),
      );

      expect(find.text('users  ⟶  posts  (has many)'), findsOneWidget);
      expect(find.text('posts  ⟶  users'), findsOneWidget);
    });

    testWidgets('renders with no entities or relations', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcEntityRelationDiagram(entities: [])),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
