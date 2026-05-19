import 'package:control_center/core/theme/system_font_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SystemFontService', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('com.controlcenter/fonts');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getInstalledFonts parses font list correctly', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getSystemFonts') {
              return <Map<String, String>>[
                {'family': 'Arial', 'path': '/System/Library/Fonts/Arial.ttf'},
                {
                  'family': 'Helvetica',
                  'path': '/System/Library/Fonts/Helvetica.ttf',
                },
              ];
            }
            return null;
          });

      final service = SystemFontService();
      final fonts = await service.getInstalledFonts();

      expect(fonts, hasLength(2));
      expect(fonts[0]['family'], 'Arial');
      expect(fonts[0]['path'], '/System/Library/Fonts/Arial.ttf');
      expect(fonts[1]['family'], 'Helvetica');
      expect(fonts[1]['path'], '/System/Library/Fonts/Helvetica.ttf');
    });

    test('getInstalledFonts returns empty list when channel returns null',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getSystemFonts') {
              return null;
            }
            return null;
          });

      final service = SystemFontService();
      final fonts = await service.getInstalledFonts();

      expect(fonts, isEmpty);
    });

    test('getInstalledFonts returns empty list when channel returns empty',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getSystemFonts') {
              return <Map<String, String>>[];
            }
            return null;
          });

      final service = SystemFontService();
      final fonts = await service.getInstalledFonts();

      expect(fonts, isEmpty);
    });

    test('getInstalledFonts handles MissingPluginException gracefully',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            throw MissingPluginException();
          });

      final service = SystemFontService();
      final fonts = await service.getInstalledFonts();

      expect(fonts, isEmpty);
    });

    test('getInstalledFonts handles generic exception gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            throw Exception('Channel error');
          });

      final service = SystemFontService();
      final fonts = await service.getInstalledFonts();

      expect(fonts, isEmpty);
    });

    test('getInstalledFonts handles entries with missing family/path', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            if (call.method == 'getSystemFonts') {
              return <Map<String, String>>[
                <String, String>{},
              ];
            }
            return null;
          });

      final service = SystemFontService();
      final fonts = await service.getInstalledFonts();

      expect(fonts, hasLength(1));
      expect(fonts[0]['family'], '');
      expect(fonts[0]['path'], '');
    });
  });
}
