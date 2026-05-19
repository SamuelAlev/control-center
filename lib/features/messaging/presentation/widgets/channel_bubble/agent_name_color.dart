import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A deterministic, per-agent identity color for the agent-name header.
///
/// Hashes [agentId] into a small curated palette derived from the design
/// system's token hues (warm signal + status accents). The color is an
/// *additional* legibility cue layered on top of the name text — it is never
/// the only carrier of meaning (DESIGN.md: never color-as-only-signal). It is
/// stable per agent across reloads, and adapts to light/dark because it draws
/// on [DesignSystemTokens] roles rather than hardcoded hexes.
///
/// Mirrors openchamber's `getAgentColor`: distinct, calm, AA-legible.
Color agentNameColor(String agentId, DesignSystemTokens tokens) {
  if (agentId.isEmpty) {
    return tokens.textSecondary;
  }
  final palette = _palette(tokens);
  // Stable FNV-style hash over the id bytes — no randomness, no drift.
  var hash = 2166136261;
  for (final unit in agentId.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}

/// The curated per-agent palette: warm signal + status accents drawn from the
/// active design tokens. Kept short so hues repeat predictably and stay
/// distinct; avoids cool blue/violet (forbidden by DESIGN.md) entirely.
List<Color> _palette(DesignSystemTokens t) => [
      t.fgBrandSecondary,
      t.fgWarningPrimary,
      t.textSuccessPrimary,
      t.fgErrorPrimary,
      t.accent,
      t.fgSecondary,
    ];
