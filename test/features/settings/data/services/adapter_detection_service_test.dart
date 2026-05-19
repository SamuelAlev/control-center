import 'package:control_center/features/settings/data/services/adapter_detection_service.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdapterDetectionService', () {
    test('detectOne returns notFound when CLI not available', () async {
      const service = AdapterDetectionService();
      final result = await service.detectOne(const Adapter(
        id: 'nonexistent',
        name: 'Nonexistent',
        description: 'Does not exist',
        cliName: 'nonexistent-cli-tool-xyz',
      ));
      expect(result.status, DetectionStatus.notFound);
      expect(result.path, isNull);
      expect(result.isFound, isFalse);
    });

    test('detectOne returns notFound when CLI path empty', () async {
      const service = AdapterDetectionService();
      final result = await service.detectOne(const Adapter(
        id: 'empty-path',
        name: 'Empty',
        description: 'Empty path test',
        cliName: '',
      ));
      expect(result.status, DetectionStatus.notFound);
    });

    test('detectOne catches exceptions gracefully', () async {
      const service = AdapterDetectionService();
      final result = await service.detectOne(const Adapter(
        id: 'invalid',
        name: 'Invalid',
        description: 'Invalid CLI',
        cliName: '/dev/null/invalid/path/tool',
      ));
      expect(result.status, DetectionStatus.notFound);
    });
  });
}
