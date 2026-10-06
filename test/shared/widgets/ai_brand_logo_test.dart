import 'package:control_center/shared/widgets/ai_brand_logo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiBrand.forProvider', () {
    test('maps every built-in provider, runner and plan id', () {
      expect(AiBrand.forProvider('cc-harness'), AiBrand.controlCenter);
      expect(AiBrand.forProvider('claude-code'), AiBrand.claude);
      expect(AiBrand.forProvider('claude'), AiBrand.claude);
      expect(AiBrand.forProvider('anthropic'), AiBrand.anthropic);
      expect(AiBrand.forProvider('google'), AiBrand.gemini);
      expect(AiBrand.forProvider('moonshotai'), AiBrand.moonshot);
      expect(AiBrand.forProvider('kimi-code'), AiBrand.kimi);
      expect(AiBrand.forProvider('zai-coding'), AiBrand.zai);
    });

    test('a custom provider has no brand', () {
      expect(AiBrand.forProvider('my-local-llm'), isNull);
    });
  });

  group('AiBrand.forModel', () {
    test('reads the vendor, not the serving provider', () {
      // Cursor serves every vendor; the `cursor/` prefix must not win.
      expect(AiBrand.forModel('cursor/claude-opus-5-thinking'), AiBrand.claude);
      expect(AiBrand.forModel('cursor/gpt-5.6-sol-high'), AiBrand.openai);
      expect(AiBrand.forModel('cursor/grok-4'), AiBrand.grok);
      expect(AiBrand.forModel('cursor/composer-2.5'), AiBrand.cursor);
      expect(
        AiBrand.forModel('openrouter/anthropic/claude-sonnet-5'),
        AiBrand.claude,
      );
      expect(AiBrand.forModel('codex/gpt-6-astra'), AiBrand.openai);
    });

    test('falls back to the display name, then to nothing', () {
      expect(
        AiBrand.forModel('cursor/xyz', name: 'Codex 5.3 High'),
        AiBrand.openai,
      );
      expect(AiBrand.forModel('opus[1m]'), AiBrand.claude);
      expect(AiBrand.forModel('zai/glm-4.6'), AiBrand.zai);
      // An alias that names no family leaves the caller to use the provider.
      expect(AiBrand.forModel('cursor/default', name: 'Auto'), isNull);
      expect(AiBrand.forModel('best', name: 'Best available'), isNull);
    });
  });

  test('every brand ships its asset', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final brand in AiBrand.values) {
      final svg = await rootBundle.loadString(brand.asset);
      expect(svg, contains('<svg'), reason: brand.asset);
    }
  });
}
