import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/data/services/adapter_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AdapterPreferences prefs;

  setUp(() async {
    prefs = AdapterPreferences(AppPreferences.inMemory());
  });

  group('AdapterPreferences', () {
    test(
      'adapter args fall back to the built-in default',
      timeout: const Timeout.factor(2),
      () {
        expect(
          prefs.getAdapterArgs('claude-code'),
          defaultAdapterArgs['claude-code'],
        );
        expect(prefs.getAdapterArgs('pi'), isNull);
      },
    );

    test(
      'setAdapterArgs persists per adapter',
      timeout: const Timeout.factor(2),
      () async {
        await prefs.setAdapterArgs('pi', '--fast');
        expect(prefs.getAdapterArgs('pi'), '--fast');
        expect(
          prefs.getAdapterArgs('claude-code'),
          defaultAdapterArgs['claude-code'],
        );
      },
    );

    test(
      'clearing adapter args restores the default',
      timeout: const Timeout.factor(2),
      () async {
        await prefs.setAdapterArgs('claude-code', '--verbose');
        await prefs.setAdapterArgs('claude-code', null);
        expect(
          prefs.getAdapterArgs('claude-code'),
          defaultAdapterArgs['claude-code'],
        );
      },
    );
  });
}
