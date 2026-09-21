import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/soundscape/device_location_reader.dart';
import 'package:control_center/features/soundscape/presentation/widgets/soundscape_controls.dart';
import 'package:control_center/features/soundscape/presentation/widgets/soundscape_tune_pad.dart';
import 'package:control_center/features/soundscape/providers/soundscape_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_rpc_client.dart';
import '../../../../helpers/test_wrap.dart';

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

void main() {
  testWidgets('soundscape controls render a two-row picker under RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(
            AppPreferences.inMemory({'soundscape_mood': 'rise'}),
          ),
          rpcClientProvider.overrideWithValue(fakeRpcClient()),
          soundscapeSceneProvider.overrideWith(
            (ref) => Stream.value(const {'name': 'Focus rain'}),
          ),
          weatherProvider.overrideWith((ref) => Stream.value(null)),
          deviceLocationReaderProvider.overrideWithValue(
            const UnavailableDeviceLocationReader(),
          ),
          activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new),
        ],
        child: testWrap(
          const SingleChildScrollView(
            child: SizedBox(width: 420, child: SoundscapeControls()),
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.soundscapePlay), findsOneWidget);
    expect(find.text(l10n.soundscapeMoodFocus), findsOneWidget);
    expect(find.text(l10n.soundscapeMoodRise), findsOneWidget);
    expect(find.text(l10n.soundscapeMoodRelax), findsOneWidget);
    expect(find.text(l10n.soundscapeMoodSleep), findsOneWidget);

    final focus = tester.getTopLeft(find.text(l10n.soundscapeMoodFocus));
    final rise = tester.getTopLeft(find.text(l10n.soundscapeMoodRise));
    final relax = tester.getTopLeft(find.text(l10n.soundscapeMoodRelax));
    final sleep = tester.getTopLeft(find.text(l10n.soundscapeMoodSleep));
    expect(focus.dy, closeTo(rise.dy, 1));
    expect(relax.dy, closeTo(sleep.dy, 1));
    expect(relax.dy, greaterThan(focus.dy + 8));
    // RTL: first in the row sits on the right.
    expect(focus.dx, greaterThan(rise.dx));
    expect(find.byType(SoundscapeTunePad), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
