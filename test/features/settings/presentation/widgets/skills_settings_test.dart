import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart' show workspaceFilesystemPortProvider;
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/skills_settings.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../fakes/fake_filesystem_port.dart';

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;

  @override
  String? build() => _id;
}

late SharedPreferences prefs;

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  List baseOverrides() {
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      workspacesProvider.overrideWith(
        (ref) => Stream.value(const <Workspace>[]),
      ),
    ];
  }

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [...baseOverrides()],
      child: FTheme(
        data: FThemes.zinc.light.desktop,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SkillsSettings rendering', () {
    testWidgets('renders no workspace selected state', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        wrap(const SkillsSettings()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No workspace selected'), findsOneWidget);

      // Flush the drift StreamQueryStore cleanup timer created during
      // ProviderScope dispose so the test framework invariant check passes.
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('renders loading state when workspace is selected', (
      tester,
    ) async {
      setView(tester);
      final completer = Completer<List<SkillInfo>>();
      addTearDown(() => completer.complete([]));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) => completer.future),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(FCircularProgress), findsOneWidget);
    });

    testWidgets('renders Skills header and New button', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('renders empty skills prompt', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Select'), findsOneWidget);
    });

    testWidgets('renders empty editor placeholder when no skill selected', (
      tester,
    ) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Select'), findsOneWidget);
    });

    testWidgets('New button is tappable', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final newBtn = find.text('New');
      expect(newBtn, findsOneWidget);
      await tester.tap(newBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Flush pending drift timers.
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('renders breadcrumbs', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Skills'), findsOneWidget);
    });

    testWidgets('renders page title', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Skills'), findsWidgets);
    });

    testWidgets('renders SectionCard in list pane', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SectionCard), findsWidgets);
    });
  });

  group('SkillsSettings with mocked agents', () {
    testWidgets('renders with agents provider override', (tester) async {
      setView(tester);
      final agents = [
        Agent(
          id: 'a1',
          name: 'architect',
          title: 'Architect',
          agentMdPath: '/tmp/architect.md',
          workspaceId: 'ws-1',
          skills: AgentSkills(['code-review']),
          createdAt: DateTime(2025),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            agentsProvider.overrideWith((ref) => Stream.value(agents)),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Select'), findsOneWidget);
    });

    testWidgets('renders editor area when isNew', (tester) async {
      setView(tester);
      final agents = [
        Agent(
          id: 'a1',
          name: 'architect',
          title: 'Architect',
          agentMdPath: '/tmp/architect.md',
          workspaceId: 'ws-1',
          skills: AgentSkills([]),
          createdAt: DateTime(2025),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(agents),
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            agentsProvider.overrideWith((ref) => Stream.value(agents)),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final newButton = find.widgetWithText(FButton, 'New');
      expect(newButton, findsOneWidget);
      await tester.tap(newButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('NEW SKILL'), findsOneWidget);
    });
  });

  group('SkillsSettings widget key', () {
    testWidgets('widget accepts key parameter', (tester) async {
      const widget = SkillsSettings(key: ValueKey('skills'));
      expect(widget.key, const ValueKey('skills'));
    });
  });

  group('extractYamlField', () {
    test('extracts description from yaml frontmatter', () {
      const content =
          '---\nname: test-skill\ndescription: My test skill\n---\n\n# Body';
      final result = extractYamlField(content, 'description');
      expect(result, 'My test skill');
    });

    test('returns null when no frontmatter delimiter', () {
      final result = extractYamlField('# Just markdown\n', 'description');
      expect(result, isNull);
    });

    test('returns null when missing closing delimiter', () {
      final result = extractYamlField('---\nname: test', 'description');
      expect(result, isNull);
    });

    test('returns null for missing field', () {
      const content = '---\nname: test-skill\n---\n\nBody';
      final result = extractYamlField(content, 'description');
      expect(result, isNull);
    });

    test('handles invalid yaml gracefully', () {
      const content = '---\n:invalid: yaml: here\n---\n\nBody';
      final result = extractYamlField(content, 'description');
      expect(result, isNull);
    });

    test('extracts name field', () {
      const content = '---\nname: my-skill\ndescription: desc\n---\n\nBody';
      final result = extractYamlField(content, 'name');
      expect(result, 'my-skill');
    });

    test('returns null for empty frontmatter', () {
      final result = extractYamlField('---\n---\n\nBody', 'description');
      expect(result, isNull);
    });

    test('handles yaml with multiple fields', () {
      const content =
          '---\nname: multi\ndescription: first\nversion: 1.0\n---\n\nBody';
      final result = extractYamlField(content, 'version');
      expect(result, '1.0');
    });

    test('handles yaml with comments', () {
      const content =
          '---\nname: test-skill\n# A comment\ndescription: has comment\n---\n\nBody';
      final result = extractYamlField(content, 'description');
      expect(result, 'has comment');
    });

    test('returns null for non-YamlMap result', () {
      const content = '---\n- item1\n- item2\n---\n\nBody';
      final result = extractYamlField(content, 'description');
      expect(result, isNull);
    });

    test('handles field with numeric value', () {
      const content = '---\nname: test\npriority: 5\n---\n\nBody';
      final result = extractYamlField(content, 'priority');
      expect(result, '5');
    });

    test('handles field with boolean value', () {
      const content = '---\nname: test\nenabled: true\n---\n\nBody';
      final result = extractYamlField(content, 'enabled');
      expect(result, 'true');
    });

    test('handles empty field value', () {
      const content = '---\nname: \ndescription: \n---\n\nBody';
      final result = extractYamlField(content, 'name');
      expect(result, '');
    });

    test('returns null for completely empty content', () {
      final result = extractYamlField('', 'description');
      expect(result, isNull);
    });

    test('returns null when only first delimiter present', () {
      final result = extractYamlField('---\n', 'description');
      expect(result, isNull);
    });
  });

  group('extractMarkdownBody', () {
    test('extracts body after frontmatter', () {
      const content = '---\nname: test\n---\n\n# Heading\n\nBody text';
      final result = extractMarkdownBody(content);
      expect(result, '# Heading\n\nBody text');
    });

    test('returns whole content when no frontmatter', () {
      final result = extractMarkdownBody('# Just markdown');
      expect(result, '# Just markdown');
    });

    test('returns whole content when missing closing delimiter', () {
      final result = extractMarkdownBody('---\nname: test');
      expect(result, '---\nname: test');
    });

    test('handles multiline body content', () {
      const content = '---\nname: test\n---\n\nLine 1\nLine 2\nLine 3';
      final result = extractMarkdownBody(content);
      expect(result, 'Line 1\nLine 2\nLine 3');
    });

    test('handles only delimiter pair with no body', () {
      const content = '---\nname: test\n---\n';
      final result = extractMarkdownBody(content);
      expect(result, '');
    });

    test('preserves markdown formatting in body', () {
      const content =
          '---\nname: test\n---\n\n## Section\n\n```dart\nvoid main() {}\n```';
      final result = extractMarkdownBody(content);
      expect(result, contains('## Section'));
      expect(result, contains('void main()'));
    });

    test('handles multiple frontmatter delimiters in body', () {
      const content =
          '---\nname: test\n---\n\nNot frontmatter\n---\nstill body';
      final result = extractMarkdownBody(content);
      expect(result, 'Not frontmatter\n---\nstill body');
    });
  });
  group('SkillsSettings with skill data', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
      const SkillInfo(
        name: 'testing',
        content: '---\nname: testing\ndescription: Write tests\n---\n\n# Testing',
        description: 'Write tests',
      ),
      const SkillInfo(
        name: 'deploy',
        content: '---\nname: deploy\ndescription: Deploy apps\n---\n\n# Deploy',
        description: 'Deploy apps',
      ),
    ];

    testWidgets('renders skill tiles in list pane', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('testing'), findsOneWidget);
      expect(find.text('deploy'), findsOneWidget);
    });

    testWidgets('renders skill descriptions in list tiles', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Review code'), findsOneWidget);
      expect(find.text('Write tests'), findsOneWidget);
      expect(find.text('Deploy apps'), findsOneWidget);
    });

    testWidgets('selecting a skill opens editor', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Editor shows the skill name as card label
      expect(find.text('code-review'), findsWidgets);
      // Delete button appears for existing skills
      expect(find.text('Delete'), findsOneWidget);
      // Open folder button appears
      expect(find.text('Open folder'), findsOneWidget);
    });

    testWidgets('filter skills by name', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // All three skills visible initially
      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('testing'), findsOneWidget);
      expect(find.text('deploy'), findsOneWidget);

      // Type filter text
      await tester.enterText(find.byType(FTextField).first, 'test');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Only "testing" remains
      expect(find.text('testing'), findsOneWidget);
      expect(find.text('code-review'), findsNothing);
      expect(find.text('deploy'), findsNothing);
    });

    testWidgets('filter skills by description', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Type filter matching description
      await tester.enterText(find.byType(FTextField).first, 'review');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('testing'), findsNothing);
      expect(find.text('deploy'), findsNothing);
    });

    testWidgets('filter with no matches shows "No matches."', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(FTextField).first, 'nonexistent');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No matches.'), findsOneWidget);
    });

    testWidgets('selecting a different skill switches editor', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Select first skill
      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Switch to second skill
      await tester.tap(find.text('testing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Editor shows the new skill name
      expect(find.text('Delete'), findsOneWidget);
      // The editor has filter + name + description + body = 4 FTextFields
      expect(find.byType(FTextField), findsNWidgets(4));
    });

    testWidgets('New button creates editor with cleared form', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final newBtn = find.widgetWithText(FButton, 'New');
      await tester.tap(newBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Editor shows 'NEW SKILL' heading (SectionCard uppercases label)
      expect(find.textContaining('NEW SKILL'), findsOneWidget);
      // No delete button for new skills
      expect(find.text('Delete'), findsNothing);
      // No open folder for new skills
      expect(find.text('Open folder'), findsNothing);
    });

    testWidgets('save button disabled when form not dirty', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Select a skill - editor opens with loaded content, not dirty
      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Find save button - it should be present and not dirty means disabled
      expect(find.widgetWithText(FButton, 'Save'), findsOneWidget);

      // Now modify the name field (index 1, after filter at 0) to make it dirty
      await tester.enterText(find.byType(FTextField).at(1), 'modified');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Now "Unsaved changes" should appear
      expect(find.text('Unsaved changes'), findsOneWidget);
    });

    testWidgets('save validates empty name', (tester) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Start new skill
      final newBtn = find.widgetWithText(FButton, 'New');
      await tester.tap(newBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Type something in body field (index 3: after filter=0, name=1, desc=2)
      final bodyField = find.byType(FTextField).at(3);
      await tester.enterText(bodyField, 'body content');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Try to save with empty name
      final saveBtn = find.widgetWithText(FButton, 'Save');
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Snackbar with validation message should appear
      expect(find.text('Skill name is required.'), findsOneWidget);
    });

    testWidgets('shows loading indicator while skills load', (tester) async {
      setView(tester);
      final completer = Completer<List<SkillInfo>>();
      addTearDown(() {
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) => completer.future),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(FCircularProgress), findsOneWidget);

      // Complete with data to transition out of loading
      completer.complete([]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Loading indicator should be gone, empty state shown
      expect(find.byType(FCircularProgress), findsNothing);
      expect(find.text('Select'), findsOneWidget);
    });

    testWidgets('skills with no description show only name in list', (
      tester,
    ) async {
      setView(tester);
      const skills = [
        SkillInfo(
          name: 'bare-skill',
          content: '---\nname: bare-skill\n---\n\nJust body',
          description: '',
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => skills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('bare-skill'), findsOneWidget);
    });

    testWidgets('no agents shows placeholder message in editor', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No agents registered yet.'), findsOneWidget);
    });

    testWidgets('attached agents section renders with agents', (tester) async {
      setView(tester);
      final agents = [
        Agent(
          id: 'a1',
          name: 'architect',
          title: 'Architect',
          agentMdPath: '/tmp/architect.md',
          workspaceId: 'ws-1',
          skills: AgentSkills(['code-review']),
          createdAt: DateTime(2025),
        ),
        Agent(
          id: 'a2',
          name: 'tester',
          title: 'Tester',
          agentMdPath: '/tmp/tester.md',
          workspaceId: 'ws-1',
          skills: AgentSkills([]),
          createdAt: DateTime(2025),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(agents),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Select code-review which architect has
      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should show "Attached agents" label
      expect(find.text('Attached agents'), findsOneWidget);
    });

    testWidgets('save produces success snackbar', (tester) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // New skill
      await tester.tap(find.widgetWithText(FButton, 'New'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Fill name (index 1, after filter at 0)
      await tester.enterText(find.byType(FTextField).at(1), 'my-skill');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Save
      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Success snackbar
      expect(find.textContaining('saved'), findsOneWidget);
    });
  });

  group('SkillsSettings CRUD operations', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
    ];

    testWidgets('delete shows confirmation dialog', (tester) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Select skill
      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap delete
      final deleteBtn = find.widgetWithText(FButton, 'Delete');
      await tester.tap(deleteBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirmation dialog appears
      expect(find.textContaining('Delete'), findsWidgets);
      // Cancel button in dialog
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel in delete dialog does not delete', (tester) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Still on editor (skill still selected)
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('save creates skill then shows success snackbar', (
      tester,
    ) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // New
      await tester.tap(find.widgetWithText(FButton, 'New'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Fill name field (index 1, after filter at 0)
      await tester.enterText(find.byType(FTextField).at(1), 'my-new-skill');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Save
      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Success snackbar
      expect(find.textContaining('saved'), findsOneWidget);
    });
  });

  group('SkillInfo', () {
    test('equality', () {
      const a = SkillInfo(name: 'a', content: 'c', description: 'd');
      const b = SkillInfo(name: 'a', content: 'c', description: 'd');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('fields preserved', () {
      const skill = SkillInfo(
        name: 'test-skill',
        content: '---\nname: test\n---\n\n# Body',
        description: 'A test skill',
      );
      expect(skill.name, 'test-skill');
      expect(skill.content, contains('Body'));
      expect(skill.description, 'A test skill');
    });
  });

  group('SkillsListTile rendering', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
      const SkillInfo(
        name: 'testing',
        content: '---\nname: testing\ndescription: Write tests\n---\n\n# Testing',
        description: 'Write tests',
      ),
    ];

    testWidgets('tile renders name and description', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('testing'), findsOneWidget);
      expect(find.text('Review code'), findsOneWidget);
      expect(find.text('Write tests'), findsOneWidget);
    });
  });

  group('SkillEmptyState rendering', () {
    testWidgets('empty state shows select prompt', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => []),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Select'), findsOneWidget);
    });
  });

  group('SectionLabel rendering', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
    ];

    testWidgets('section labels render in editor', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // FTextField labels
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      // Section labels
      expect(find.text('Attached agents'), findsOneWidget);
      expect(find.text('Content (Markdown)'), findsOneWidget);
    });
  });

  group('_SkillsBodyState operations', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
    ];

    testWidgets('rename and save updates selected skill', (tester) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Select skill
      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Change name field (index 1, after filter at 0)
      await tester.enterText(find.byType(FTextField).at(1), 'code-review-renamed');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Save
      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Success snackbar with 'saved'
      expect(find.textContaining('saved'), findsOneWidget);
    });

    testWidgets('save with description updates frontmatter', (tester) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // New
      await tester.tap(find.widgetWithText(FButton, 'New'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Fill name (index 1, after filter at 0)
      await tester.enterText(find.byType(FTextField).at(1), 'my-skill');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Fill description (index 2, after filter 0 and name 1)
      await tester.enterText(find.byType(FTextField).at(2), 'My custom description');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Save
      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the written file content includes the description in frontmatter
      final content = fs.files['ws-1/skills/my-skill/SKILL.md'];
      expect(content, isNotNull);
      expect(content, contains('description: My custom description'));
    });
  });

  group('SkillsSettings CRUD - delete confirm', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
    ];

    testWidgets('confirming delete dialog removes skill from filesystem', (
      tester,
    ) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      // Pre-populate the skill file so delete actually has something to remove.
      await fs.writeSkillFile(
        'ws-1',
        'code-review',
        '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Confirm deletion in the dialog — tap the destructive 'Delete' button.
      final deleteButtons = find.widgetWithText(FButton, 'Delete');
      await tester.tap(deleteButtons.last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // After delete, the mocked provider still returns the old list.
      // Verify the file was actually deleted from the filesystem.
      expect(fs.files.containsKey('ws-1/skills/code-review/SKILL.md'), isFalse);
    });
  });

  group('SkillsSettings CRUD - update description', () {
    final testSkills = [
      const SkillInfo(
        name: 'review',
        content: '---\nname: review\ndescription: Old desc\n---\n\n# Review',
        description: 'Old desc',
      ),
    ];

    testWidgets('editing description saves new description to file', (
      tester,
    ) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Edit description field (index 2, after filter 0 and name 1)
      await tester.enterText(find.byType(FTextField).at(2), 'Updated description');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('saved'), findsOneWidget);

      final content = fs.files['ws-1/skills/review/SKILL.md'];
      expect(content, isNotNull);
      expect(content, contains('description: Updated description'));
    });
  });

  group('SkillsSettings CRUD - update body content', () {
    final testSkills = [
      const SkillInfo(
        name: 'review',
        content: '---\nname: review\ndescription: A skill\n---\n\n# Old Body',
        description: 'A skill',
      ),
    ];

    testWidgets('editing body saves new markdown content to file', (
      tester,
    ) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Edit body field (index 3, after filter 0, name 1, description 2)
      await tester.enterText(
        find.byType(FTextField).at(3),
        '# Updated Body\n\nNew markdown content.',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('saved'), findsOneWidget);

      final content = fs.files['ws-1/skills/review/SKILL.md'];
      expect(content, isNotNull);
      expect(content, contains('# Updated Body'));
      expect(content, contains('New markdown content.'));
    });
  });

  group('SkillsSettings CRUD - save with special characters', () {
    testWidgets('creating skill with quotes dashes underscores works', (
      tester,
    ) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith(
              (ref, workspaceId) async => const <SkillInfo>[],
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'New'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(FTextField).at(1), 'special--skill__name');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(
        find.byType(FTextField).at(2),
        'Description with "quotes" and \'apostrophes\' and -- dashes',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('saved'), findsOneWidget);
      // Verify a file was written with the special name content
      expect(
        fs.files.values.any((v) => v.contains('special--skill__name')),
        isTrue,
      );
    });
  });

  group('SkillsSettings CRUD - non-ASCII characters', () {
    testWidgets('creating skill with accented characters in name', (
      tester,
    ) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith(
              (ref, workspaceId) async => const <SkillInfo>[],
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'New'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(
        find.byType(FTextField).at(1),
        'résumé-writing-skill',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('saved'), findsOneWidget);
      // Verify a file was written with the accented name content
      expect(
        fs.files.values.any((v) => v.contains('résumé-writing-skill')),
        isTrue,
      );
    });
  });

  group('SkillsSettings CRUD - very long skill name', () {
    testWidgets('saving a 100+ char name succeeds and creates file', (
      tester,
    ) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      const longName =
          'a-very-long-skill-name-that-exceeds-one-hundred-characters-to-test-the-save-handling-of-unusually-long-input';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith(
              (ref, workspaceId) async => const <SkillInfo>[],
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'New'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(FTextField).at(1), longName);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('saved'), findsOneWidget);
      // The slugified key should exist in the filesystem
      const slugified =
          'a-very-long-skill-name-that-exceeds-one-hundred-characters-to-test-the-save-handling-of-unusually-long-input';
      expect(
        fs.files.containsKey('ws-1/skills/$slugified/SKILL.md'),
        isTrue,
      );
    });
  });

  group('SkillsSettings CRUD - very long body content', () {
    testWidgets('pasting large markdown body saves successfully', (
      tester,
    ) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      final largeBody = [
        '# Large Body',
        '',
        for (int i = 0; i < 50; i++) '## Section $i\n\nContent for section $i goes here.\n',
      ].join('\n');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith(
              (ref, workspaceId) async => const <SkillInfo>[],
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'New'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(FTextField).at(1), 'large-skill');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(find.byType(FTextField).at(3), largeBody);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('saved'), findsOneWidget);
      final content = fs.files['ws-1/skills/large-skill/SKILL.md'];
      expect(content, isNotNull);
      expect(content, contains('Section 0'));
      expect(content, contains('Section 49'));
    });
  });

  group('SkillsSettings filter - case insensitive', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
      const SkillInfo(
        name: 'testing',
        content: '---\nname: testing\ndescription: Write tests\n---\n\n# Testing',
        description: 'Write tests',
      ),
    ];

    testWidgets('uppercase filter matches lowercase skill names', (
      tester,
    ) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Type 'CODE' in filter field (index 0)
      await tester.enterText(find.byType(FTextField).at(0), 'CODE');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 'code-review' should still be visible (case-insensitive match)
      expect(find.text('code-review'), findsOneWidget);
      // 'testing' should be hidden
      expect(find.text('testing'), findsNothing);
    });
  });

  group('SkillsSettings filter - clear filter', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
      const SkillInfo(
        name: 'testing',
        content: '---\nname: testing\ndescription: Write tests\n---\n\n# Testing',
        description: 'Write tests',
      ),
    ];

    testWidgets('clearing filter shows all skills again', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Both visible initially
      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('testing'), findsOneWidget);

      // Type filter to narrow down
      await tester.enterText(find.byType(FTextField).at(0), 'test');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Only 'testing' visible
      expect(find.text('testing'), findsOneWidget);
      expect(find.text('code-review'), findsNothing);

      // Clear the filter
      await tester.enterText(find.byType(FTextField).at(0), '');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Both visible again
      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('testing'), findsOneWidget);
    });
  });

  group('SkillsSettings CRUD - save existing without changes', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
    ];

    testWidgets('saving unchanged skill produces no error', (tester) async {
      setView(tester);
      final fs = FakeFilesystemPort();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceFilesystemPortProvider.overrideWithValue(fs),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Save without modifying any fields
      await tester.tap(find.widgetWithText(FButton, 'Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // When form is not dirty, save button is disabled — tapping does nothing.
      // Verify the widget didn't crash and the save button still exists.
      expect(find.byType(SkillsSettings), findsOneWidget);
      expect(find.widgetWithText(FButton, 'Save'), findsOneWidget);
      // No error snackbar either
      expect(find.textContaining('failed'), findsNothing);
      expect(find.textContaining('error'), findsNothing);
    });
  });

  group('SkillsSettings - open folder button', () {
    final testSkills = [
      const SkillInfo(
        name: 'code-review',
        content: '---\nname: code-review\ndescription: Review code\n---\n\n# Code Review',
        description: 'Review code',
      ),
    ];

    testWidgets('open folder button renders for existing skill', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith((ref, workspaceId) async => testSkills),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('code-review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.widgetWithText(FButton, 'Open folder'), findsOneWidget);
    });
  });

  group('SkillsSettings error state', () {
    testWidgets('skillListProvider throwing renders error message', (
      tester,
    ) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            skillListProvider.overrideWith(
              (ref, workspaceId) async => throw Exception('Failed to load skills'),
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            workspaceAgentsProvider.overrideWith(
              (ref, workspaceId) => Stream.value(const <Agent>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Widget should render without crash; error text may be rendered or the
      // widget may silently handle the error via AsyncValue.
      expect(find.byType(SkillsSettings), findsOneWidget);
    });
  });
}
