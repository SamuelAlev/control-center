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

    test('getDefaultChatAdapterId returns null initially', timeout: const Timeout.factor(2), () {
      expect(prefs.getDefaultChatAdapterId(), isNull);
    });

    test('setDefaultChatAdapterId persists value', timeout: const Timeout.factor(2), () async {
      await prefs.setDefaultChatAdapterId('claude-code');
      expect(prefs.getDefaultChatAdapterId(), 'claude-code');
    });

    test('setDefaultChatAdapterId with null removes', timeout: const Timeout.factor(2), () async {
      await prefs.setDefaultChatAdapterId('claude-code');
      await prefs.setDefaultChatAdapterId(null);
      expect(prefs.getDefaultChatAdapterId(), isNull);
    });

    // -- Default Chat Model --

    test('getDefaultChatModelId returns null initially', timeout: const Timeout.factor(2), () {
      expect(prefs.getDefaultChatModelId(), isNull);
    });

    test('setDefaultChatModelId persists value', timeout: const Timeout.factor(2), () async {
      await prefs.setDefaultChatModelId('anthropic/claude-opus-4-7');
      expect(prefs.getDefaultChatModelId(), 'anthropic/claude-opus-4-7');
    });

    test('setDefaultChatModelId with null removes', timeout: const Timeout.factor(2), () async {
      await prefs.setDefaultChatModelId('model-a');
      await prefs.setDefaultChatModelId(null);
      expect(prefs.getDefaultChatModelId(), isNull);
    });

    // -- Short Task Adapter --

    test('getShortTaskAdapterId returns null initially', timeout: const Timeout.factor(2), () {
      expect(prefs.getShortTaskAdapterId(), isNull);
    });

    test('setShortTaskAdapterId persists value', timeout: const Timeout.factor(2), () async {
      await prefs.setShortTaskAdapterId('pi-dev');
      expect(prefs.getShortTaskAdapterId(), 'pi-dev');
    });

    test('setShortTaskAdapterId with null removes', timeout: const Timeout.factor(2), () async {
      await prefs.setShortTaskAdapterId('pi-dev');
      await prefs.setShortTaskAdapterId(null);
      expect(prefs.getShortTaskAdapterId(), isNull);
    });

    // -- Short Task Model --

    test('getShortTaskModelId returns null initially', timeout: const Timeout.factor(2), () {
      expect(prefs.getShortTaskModelId(), isNull);
    });

    test('setShortTaskModelId persists value', timeout: const Timeout.factor(2), () async {
      await prefs.setShortTaskModelId('openai/gpt-5');
      expect(prefs.getShortTaskModelId(), 'openai/gpt-5');
    });

    test('setShortTaskModelId with null removes', timeout: const Timeout.factor(2), () async {
      await prefs.setShortTaskModelId('model-x');
      await prefs.setShortTaskModelId(null);
      expect(prefs.getShortTaskModelId(), isNull);
    });

    // -- Independence --

    test('all four preferences are independent', timeout: const Timeout.factor(2), () async {
      await prefs.setDefaultChatAdapterId('chat-adapter');
      await prefs.setDefaultChatModelId('chat-model');
      await prefs.setShortTaskAdapterId('task-adapter');
      await prefs.setShortTaskModelId('task-model');

      expect(prefs.getDefaultChatAdapterId(), 'chat-adapter');
      expect(prefs.getDefaultChatModelId(), 'chat-model');
      expect(prefs.getShortTaskAdapterId(), 'task-adapter');
      expect(prefs.getShortTaskModelId(), 'task-model');

      // Clearing one doesn't affect others
      await prefs.setDefaultChatAdapterId(null);
      expect(prefs.getDefaultChatAdapterId(), isNull);
      expect(prefs.getDefaultChatModelId(), 'chat-model');
      expect(prefs.getShortTaskAdapterId(), 'task-adapter');
      expect(prefs.getShortTaskModelId(), 'task-model');
    });
  });
}
