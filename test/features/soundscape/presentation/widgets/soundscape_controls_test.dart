import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/soundscape/presentation/widgets/soundscape_controls.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('soundscape controls render under RTL', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
          rpcClientProvider.overrideWithValue(fakeRpcClient()),
          soundscapeSceneProvider.overrideWith(
            (ref) => Stream.value(const {'name': 'Focus rain'}),
          ),
          weatherProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: testWrap(
          const SingleChildScrollView(
            child: SizedBox(width: 480, child: SoundscapeControls()),
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.soundscapePlay), findsOneWidget);
    expect(find.text(l10n.soundscapeMoodFocus), findsOneWidget);
  });
}
