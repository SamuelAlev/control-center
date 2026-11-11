import 'package:cc_data/cc_data.dart' show ConnectModeSetting, ConnectStatus;
import 'package:control_center/features/connect/providers/connect_providers.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/settings_contribution.dart';
import '../../../../../../helpers/test_wrap.dart';

/// The server's own apps apply only under "Use my own apps"; the card offers
/// them only then.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pump(
    WidgetTester tester,
    Future<ConnectStatus?> Function() status,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          providerAppsProvider.overrideWith(
            (ref) async => const [ProviderAppStatusView(provider: 'github')],
          ),
          connectStatusProvider.overrideWith((ref) => status()),
        ],
        child: testWrap(const ContributedSection('settings.provider-apps')),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final mode in [ConnectModeSetting.off, ConnectModeSetting.unset]) {
    testWidgets('shown under ${mode.name}', (tester) async {
      await pump(tester, () async => ConnectStatus(mode: mode));
      expect(find.text(l10n.providerAppsDescription), findsOneWidget);
    });
  }

  for (final mode in [ConnectModeSetting.hosted, ConnectModeSetting.custom]) {
    testWidgets('hidden under ${mode.name}', (tester) async {
      await pump(tester, () async => ConnectStatus(mode: mode));
      expect(find.text(l10n.providerAppsDescription), findsNothing);
    });
  }

  testWidgets('kept when the Connect choice cannot be read', (tester) async {
    await pump(tester, () async => throw StateError('unreachable'));
    expect(find.text(l10n.providerAppsDescription), findsOneWidget);
  });
}
