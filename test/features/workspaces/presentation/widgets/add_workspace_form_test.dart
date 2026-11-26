import 'dart:async';
import 'dart:typed_data';

import 'package:cc_data/cc_data.dart' show IdentityMe;
import 'package:cc_domain/cc_domain.dart' show ServerOwnerRequiredException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late AppPreferences prefs;

  setUp(() async {
    prefs = AppPreferences.inMemory();
  });

  testWidgets('renders workspace name field and submit button', (tester) async {
    const bool created = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Workspace name'), findsOneWidget);
    expect(find.text('Add workspace'), findsOneWidget);
    expect(created, false);
  });

  testWidgets('the logo picker is a named button', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(AddWorkspaceForm)),
    );

    final picker = find.bySemanticsLabel(l10n.uploadImage);
    expect(picker, findsOneWidget);
    expect(tester.getSemantics(picker).flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('renders cancel button when onCancel provided', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop, onCancel: () {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('submit button is enabled before any form interaction', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final buttons = find.byType(CcButton);
    expect(buttons, findsAtLeastNWidgets(1));
  });

  testWidgets('renders custom submit label', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(
                  onCreated: _noop,
                  submitLabel: 'Create',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('does not render cancel when onCancel is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('workspace name field always visible', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Workspace name'), findsOneWidget);
  });

  testWidgets('a refusal for not being the server owner says so in words', (
    tester,
  ) async {
    var identityReads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          createWorkspaceProvider.overrideWith(_RefusedCreate.new),
          currentIdentityProvider.overrideWith((ref) {
            identityReads++;
            return Completer<IdentityMe>().future;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    // Something showing the right keeps the identity read
                    // alive, as the title-bar chip does in the app.
                    Consumer(
                      builder: (context, ref, _) {
                        ref.watch(currentIdentityProvider);
                        return const SizedBox.shrink();
                      },
                    ),
                    const AddWorkspaceForm(onCreated: _noop),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'Platform');
    await tester.tap(find.text('Add workspace'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'Only the server owner can create workspaces. Ask them to create '
        'one, or ask a workspace admin to invite you.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('RemoteRpcException'), findsNothing);
    expect(find.textContaining('server_owner_required'), findsNothing);
    // The stale right is re-read, so the create affordances follow it.
    expect(identityReads, 2);
  });
}

void _noop(String _) {}

/// The server refused: only its owner may create workspaces.
class _RefusedCreate extends CreateWorkspaceNotifier {
  @override
  Future<String?> create({
    required String name,
    Uint8List? logoBytes,
    String logoExtension = '',
  }) async {
    state = const AsyncError<String?>(
      ServerOwnerRequiredException('server_owner_required'),
      StackTrace.empty,
    );
    return null;
  }
}
