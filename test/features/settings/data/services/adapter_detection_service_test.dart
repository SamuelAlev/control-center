import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdapterDetectionService', () {
    test('detectOne refuses an adapter the registry does not name', () async {
      const service = AdapterDetectionService();
      await expectLater(
        service.detectOne(
          const Adapter(
            id: 'nonexistent',
            name: 'Nonexistent',
            description: 'Does not exist',
            cliName: 'nonexistent-cli-tool-xyz',
            transport: AdapterTransport.claudeCli,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('detectOne returns notFound when CLI not available', () async {
      const missing = Adapter(
        id: 'nonexistent',
        name: 'Nonexistent',
        description: 'Does not exist',
        cliName: 'nonexistent-cli-tool-xyz',
        transport: AdapterTransport.claudeCli,
      );
      const service = AdapterDetectionService(registry: [missing]);
      final result = await service.detectOne(missing);
      expect(result.status, DetectionStatus.notFound);
      expect(result.path, isNull);
      expect(result.isFound, isFalse);
    });

    test('detectOne returns notFound when CLI path empty', () async {
      const empty = Adapter(
        id: 'empty-path',
        name: 'Empty',
        description: 'Empty path test',
        cliName: '',
        transport: AdapterTransport.claudeCli,
      );
      const service = AdapterDetectionService(registry: [empty]);
      final result = await service.detectOne(empty);
      expect(result.status, DetectionStatus.notFound);
    });

    test('detectOne catches exceptions gracefully', () async {
      const invalid = Adapter(
        id: 'invalid',
        name: 'Invalid',
        description: 'Invalid CLI',
        cliName: '/dev/null/invalid/path/tool',
        transport: AdapterTransport.claudeCli,
      );
      const service = AdapterDetectionService(registry: [invalid]);
      final result = await service.detectOne(invalid);
      expect(result.status, DetectionStatus.notFound);
    });
  });
}
