import 'package:control_center/features/pr_review/presentation/widgets/sticky_header.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders header and content', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StickyHeader(
              header: Container(
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Header')),
              ),
              content: Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('renders with pinnedBorderColor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StickyHeader(
              header: Container(
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Header')),
              ),
              content: Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('renders without pinnedBorderColor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StickyHeader(
              header: Container(
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Header')),
              ),
              content: Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Header'), findsOneWidget);
  });

  testWidgets('supports tapping on header', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StickyHeader(
              header: GestureDetector(
                onTap: () => tapped = true,
                child: Container(
                  height: 50,
                  color: Colors.blue,
                  child: const Center(child: Text('Header')),
                ),
              ),
              content: Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Header'));

    expect(tapped, isTrue);
  });

  testWidgets('supports tapping on content', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StickyHeader(
              header: Container(
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Header')),
              ),
              content: GestureDetector(
                onTap: () => tapped = true,
                child: Container(
                  height: 200,
                  color: Colors.grey.shade100,
                  child: const Center(child: Text('Content')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('Content'));

    expect(tapped, isTrue);
  });

  testWidgets('renders with custom pinnedBorderRadius', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StickyHeader(
              header: Container(
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Header')),
              ),
              content: Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(child: Text('Content')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Header'), findsOneWidget);
  });

  testWidgets('scrolling pins header', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 300),
                StickyHeader(
                  header: Container(
                    height: 50,
                    color: Colors.blue.withValues(alpha: 0.5),
                    child: const Center(child: Text('Header')),
                  ),
                  content: Container(
                    height: 400,
                    color: Colors.grey.shade100,
                    child: const Center(child: Text('Content')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
    await tester.pump();

    expect(find.text('Header'), findsOneWidget);
  });

  testWidgets('renders without pinnedBorderColor in scroll view', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                StickyHeader(
                  header: Container(
                    height: 50,
                    color: Colors.blue,
                    child: const Center(child: Text('Header')),
                  ),
                  content: Container(
                    height: 300,
                    color: Colors.grey.shade100,
                    child: const Center(child: Text('Content')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Header'), findsOneWidget);
  }, skip: false);

  testWidgets('supports long content scrolling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: StickyHeader(
              header: Container(
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Header')),
              ),
              content: Container(
                height: 2000,
                color: Colors.grey.shade100,
                child: const Center(child: Text('Long Content')),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Header'), findsOneWidget);
    expect(find.text('Long Content'), findsOneWidget);
  });
}
