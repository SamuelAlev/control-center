import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/agent_name_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final light = DesignSystemTokens.light();
  final dark = DesignSystemTokens.dark();

  group('agentNameColor', () {
    test('is deterministic — same id yields the same color across calls', () {
      expect(agentNameColor('agent-1', light), agentNameColor('agent-1', light));
      expect(agentNameColor('agent-42', dark), agentNameColor('agent-42', dark));
    });

    test('empty id falls back to a neutral text color', () {
      expect(agentNameColor('', light), light.textSecondary);
    });

    test('never returns a fully transparent color', () {
      for (final id in ['a', 'b', 'c', 'agent-1', 'architect', 'builder']) {
        expect(agentNameColor(id, light), isNot(Colors.transparent));
        expect(agentNameColor(id, dark), isNot(Colors.transparent));
      }
    });

    test('draws only from the curated token palette (warm/status hues)', () {
      final palette = <Color>{
        light.fgBrandSecondary,
        light.fgWarningPrimary,
        light.textSuccessPrimary,
        light.fgErrorPrimary,
        light.accent,
        light.fgSecondary,
      };
      for (final id in ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']) {
        expect(palette, contains(agentNameColor(id, light)));
      }
    });
  });
}
