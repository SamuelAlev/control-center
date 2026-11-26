import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_menu.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _emptyPopulation = Provider.autoDispose<List<PullRequest>>(
  (_) => const [],
);

final _scope = PrFilterScope(
  filters: prListFiltersProvider,
  population: _emptyPopulation,
);

void main() {
  testWidgets('clicking the trigger focuses the menu search field, even '
      'though the click focused the trigger first', (tester) async {
    final container = ProviderContainer(
      overrides: [currentUserLoginProvider.overrideWith((ref) => 'me')],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: [
            ...appLocalizationsDelegates,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(
              body: Align(
                alignment: AlignmentDirectional.topEnd,
                child: PrFilterButton(scope: _scope),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(PrFilterButton));
    await tester.pumpAndSettle();

    final focused = FocusManager.instance.primaryFocus?.context;
    expect(focused, isNotNull);
    expect(
      focused!.widget is EditableText ||
          focused.findAncestorWidgetOfExactType<EditableText>() != null,
      isTrue,
      reason: 'typing right after opening the menu filters it',
    );
  });
}
