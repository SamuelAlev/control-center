import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/providers/storage_providers.dart';
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

  Widget wrap(Widget child) => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: FTheme(
      data: FThemes.zinc.light.desktop,
      child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
    ),
  );

  void setView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 700);
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
    });

    testWidgets('renders loading state when workspace is selected', (
      tester,
    ) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('No skills yet'), findsOneWidget);
    });

    testWidgets('renders empty editor placeholder when no skill selected', (
      tester,
    ) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Select a skill'), findsOneWidget);
    });

    testWidgets('New button is tappable', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
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
    });

    testWidgets('renders breadcrumbs', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Skills'), findsOneWidget);
    });

    testWidgets('renders page title', (tester) async {
      setView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            agentsProvider.overrideWith((ref) => Stream.value(agents)),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('No skills yet'), findsOneWidget);
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier('ws-1'),
            ),
            agentsProvider.overrideWith((ref) => Stream.value(agents)),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
              home: Scaffold(body: SkillsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('New'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('New skill'), findsOneWidget);
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
}
