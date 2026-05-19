import 'package:control_center/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig constants', () {
    test('appName is set', () {
      expect(appName, isA<String>());
      expect(appName, isNotEmpty);
      expect(appName, 'Control Center');
    });

    test('appVersion is set', () {
      expect(appVersion, isA<String>());
      expect(appVersion, isNotEmpty);
      expect(appVersion, '0.0.1');
    });

    test('defaultWorkspaceBasePath is set', () {
      expect(defaultWorkspaceBasePath, isA<String>());
      expect(defaultWorkspaceBasePath, isNotEmpty);
      expect(defaultWorkspaceBasePath, contains('control-center-workspaces'));
    });

    test('claudeBinary is set', () {
      expect(claudeBinary, isA<String>());
      expect(claudeBinary, isNotEmpty);
      expect(claudeBinary, 'claude');
    });

    test('piBinary is set', () {
      expect(piBinary, isA<String>());
      expect(piBinary, isNotEmpty);
      expect(piBinary, 'pi');
    });
  });
}
