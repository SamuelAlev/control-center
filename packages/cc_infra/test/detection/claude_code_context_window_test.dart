import 'package:cc_infra/src/detection/acp_models_service.dart';
import 'package:test/test.dart';

/// Claude Code has no window flag — the window is a property of the `--model`
/// id — so the meter reads the window off that id when the agent sets none.
void main() {
  group('claudeCodeContextWindow', () {
    test('reads the window off the catalog', () {
      expect(AcpModelsService.claudeCodeContextWindow('opus'), 200000);
      expect(AcpModelsService.claudeCodeContextWindow('opus[1m]'), 1000000);
    });

    test('an unlisted id is read by its suffix', () {
      expect(
        AcpModelsService.claudeCodeContextWindow('claude-opus-9[1m]'),
        1000000,
      );
      expect(AcpModelsService.claudeCodeContextWindow('claude-opus-9'), 200000);
    });

    test('no model is the default model at the standard window', () {
      expect(
        AcpModelsService.claudeCodeContextWindow(null),
        AcpModelsService.claudeCodeDefaultContextWindow,
      );
    });
  });
}
