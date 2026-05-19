import 'package:control_center/features/settings/data/privacy_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PrivacyPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PrivacyPreferences(await SharedPreferences.getInstance());
  });

  group('PrivacyPreferences', () {
    test('llmDiffSharingEnabled defaults to true', timeout: const Timeout.factor(2), () {
      expect(prefs.llmDiffSharingEnabled, isTrue);
    });

    test('setLlmDiffSharingEnabled(false) persists', timeout: const Timeout.factor(2), () async {
      await prefs.setLlmDiffSharingEnabled(value: false);
      expect(prefs.llmDiffSharingEnabled, isFalse);
    });

    test('setLlmDiffSharingEnabled(true) persists', timeout: const Timeout.factor(2), () async {
      await prefs.setLlmDiffSharingEnabled(value: false);
      await prefs.setLlmDiffSharingEnabled(value: true);
      expect(prefs.llmDiffSharingEnabled, isTrue);
    });
  });
}
