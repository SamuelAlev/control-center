import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_node.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/org_chart_view.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Agent _agent(String id, String name, String title) => Agent(
  id: id,
  name: name,
  title: title,
  agentMdPath: '/a/$id.md',
  workspaceId: 'ws-1',
  skills: AgentSkills(const []),
  createdAt: DateTime(2025),
);

OrgNode _node(String id, {List<OrgNode> reports = const []}) =>
    OrgNode(agent: _agent(id, id, '$id title'), reports: reports);

Widget _wrap(List<OrgNode> roots) => ProviderScope(
  overrides: [
    orgChartProvider.overrideWith((ref, _) => roots),
    workspacePresenceProvider.overrideWith(
      (ref, _) async => const <String, AgentPresence>{},
    ),
  ],
  child: CcTheme(
    data: CcThemeData.light(),
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: OrgChartView(workspaceId: 'ws-1')),
    ),
  ),
);

/// cc_ui buttons carry a [CcTooltip], not a Material one, so `find.byTooltip`
/// never sees them.
Finder _control(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);

void main() {
  group('OrgChartView.subtreeWidth', () {
    test('a leaf is exactly one card wide', () {
      expect(OrgChartView.subtreeWidth(_node('solo')), 208);
    });

    test('a manager is as wide as its row of reports', () {
      final tree = _node('ceo', reports: [_node('a'), _node('b')]);
      // Two cards plus the sibling gap.
      expect(OrgChartView.subtreeWidth(tree), 208 * 2 + 20);
    });

    test('a manager with one report is still one card wide', () {
      // The report cannot be narrower than a card, so a single-child chain
      // stays a straight column rather than drifting sideways.
      final tree = _node('ceo', reports: [_node('only')]);
      expect(OrgChartView.subtreeWidth(tree), 208);
    });

    test('width comes from the widest generation, not the deepest', () {
      // ceo → lead → {x, y, z}: the grandchildren decide the width.
      final tree = _node(
        'ceo',
        reports: [
          _node('lead', reports: [_node('x'), _node('y'), _node('z')]),
        ],
      );
      expect(OrgChartView.subtreeWidth(tree), 208 * 3 + 20 * 2);
    });
  });

  group('OrgChartView', () {
    testWidgets('renders a card per agent and connects reports to a manager', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap([
          _node('ceo', reports: [_node('architect'), _node('engineer')]),
        ]),
      );
      await tester.pump();

      expect(find.text('ceo title'), findsOneWidget);
      expect(find.text('architect title'), findsOneWidget);
      expect(find.text('engineer title'), findsOneWidget);

      // One connector band per manager — the thing that makes it a chart
      // rather than an indented list.
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('2 reports'), findsOneWidget);
    });

    testWidgets('a manager sits ABOVE its reports, not beside them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap([
          _node('ceo', reports: [_node('architect'), _node('engineer')]),
        ]),
      );
      await tester.pump();

      // Measured on the avatars rather than the titles: a title is
      // left-aligned inside its card, so its centre moves with the length of
      // the words. Every card is the same width and every avatar sits at the
      // same inset, so avatar centres track card centres exactly.
      //
      // Tree order, which is also paint order: manager, then its reports.
      final avatars = find.byType(AgentAvatar);
      expect(avatars, findsNWidgets(3));
      final ceo = tester.getCenter(avatars.at(0));
      final architect = tester.getCenter(avatars.at(1));
      final engineer = tester.getCenter(avatars.at(2));

      // Top-down: the manager is higher up the screen than both reports...
      expect(ceo.dy, lessThan(architect.dy));
      expect(ceo.dy, lessThan(engineer.dy));
      // ...the reports share a generation line...
      expect(architect.dy, closeTo(engineer.dy, 0.5));
      // ...and the manager is centred over them, which is what the old
      // left-indented list could not say.
      expect(ceo.dx, closeTo((architect.dx + engineer.dx) / 2, 1));
    });

    testWidgets('reports a workspace with no agents', (tester) async {
      await tester.pumpWidget(_wrap(const []));
      await tester.pump();

      expect(find.textContaining('No agents'), findsOneWidget);
    });

    testWidgets('is a canvas whose zoom control actually zooms', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap([
          _node('ceo', reports: [_node('architect'), _node('engineer')]),
        ]),
      );
      await tester.pumpAndSettle();

      // A viewer, not a pair of scroll views: the scroll views could reach
      // every corner but only one at a time, and they swallowed the trackpad
      // pan-zoom that a viewer gets for free.
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(CanvasZoomControls), findsOneWidget);

      double siblingGap() =>
          (tester.getCenter(find.byType(AgentAvatar).at(2)) -
                  tester.getCenter(find.byType(AgentAvatar).at(1)))
              .dx;

      final before = siblingGap();
      await tester.tap(_control('Zoom in'));
      await tester.pumpAndSettle();

      // The whole chart grew, so two siblings moved apart.
      expect(siblingGap(), greaterThan(before));
    });

    testWidgets('reset puts a zoomed chart back where it opened', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap([
          _node('ceo', reports: [_node('architect'), _node('engineer')]),
        ]),
      );
      await tester.pumpAndSettle();

      final fitted = tester.getCenter(find.byType(AgentAvatar).first);

      await tester.tap(_control('Zoom in'));
      await tester.pumpAndSettle();
      expect(tester.getCenter(find.byType(AgentAvatar).first), isNot(fitted));

      await tester.tap(_control('Fit to view'));
      await tester.pumpAndSettle();

      final reset = tester.getCenter(find.byType(AgentAvatar).first);
      expect(reset.dx, closeTo(fitted.dx, 0.5));
      expect(reset.dy, closeTo(fitted.dy, 0.5));
    });
  });
}
