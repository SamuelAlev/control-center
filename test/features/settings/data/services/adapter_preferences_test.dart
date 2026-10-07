import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/settings/data/services/adapter_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AdapterPreferences prefs;

  setUp(() async {
    prefs = AdapterPreferences(AppPreferences.inMemory());
  });

  group('AdapterPreferences', () {
    // -- Default Chat Adapter --

    test(
      'getDefaultChatAdapterId returns null initially',
      timeout: const Timeout.factor(2),
      () {
        expect(prefs.getDefaultChatAdapterId(), isNull);
      },
    );

    test(
      'setDefaultChatAdapterId persists value',
      timeout: const Timeout.factor(2),
      () async {
        await prefs.setDefaultChatAdapterId('claude-code');
        expect(prefs.getDefaultChatAdapterId(), 'claude-code');
      },
    );

    test(
      'setDefaultChatAdapterId with null removes',
      timeout: const Timeout.factor(2),
      () async {
        await prefs.setDefaultChatAdapterId('claude-code');
        await prefs.setDefaultChatAdapterId(null);
        expect(prefs.getDefaultChatAdapterId(), isNull);
      },
    );

    // -- Default Chat Model --

    test(
      'getDefaultChatModelId returns null initially',
      timeout: const Timeout.factor(2),
      () {
        expect(prefs.getDefaultChatModelId(), isNull);
      },
    );

    test(
      'setDefaultChatModelId persists value',
      timeout: const Timeout.factor(2),
      () async {
        await prefs.setDefaultChatModelId('anthropic/claude-opus-4-7');
        expect(prefs.getDefaultChatModelId(), 'anthropic/claude-opus-4-7');
      },
    );

    test(
      'setDefaultChatModelId with null removes',
      timeout: const Timeout.factor(2),
      () async {
        await prefs.setDefaultChatModelId('model-a');
        await prefs.setDefaultChatModelId(null);
        expect(prefs.getDefaultChatModelId(), isNull);
      },
    );

    // -- Independence --

    test(
      'chat adapter and model are independent',
      timeout: const Timeout.factor(2),
      () async {
        await prefs.setDefaultChatAdapterId('chat-adapter');
        await prefs.setDefaultChatModelId('chat-model');

        expect(prefs.getDefaultChatAdapterId(), 'chat-adapter');
        expect(prefs.getDefaultChatModelId(), 'chat-model');

        // Clearing one doesn't affect others
        await prefs.setDefaultChatAdapterId(null);
        expect(prefs.getDefaultChatAdapterId(), isNull);
        expect(prefs.getDefaultChatModelId(), 'chat-model');
      },
    );
  });
}
