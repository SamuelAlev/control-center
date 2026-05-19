import 'package:flutter/widgets.dart';

/// design system base color palette.
///
/// Scales mirror design system's Tailwind config so the CSS variable names
/// in the design source (e.g. `--color-neutral-700`, `--color-brand-500`)
/// map 1:1 to fields on this class. Use `DesignSystemTokens` (in
/// `design_system_tokens.dart`) for the semantic tokens that compose these.
abstract final class DesignSystemPalette {
  const DesignSystemPalette._();

  // Brand — signal-orange accent scale. The single high-signal color of the
  // design system; #fa520f is the canonical accent (600). Flame (#fb6424) is
  // the hover warm-up (500); burnt orange (#dc480d) is the pressed state (700);
  // block-edge (#c0400f) terminates the brand mosaic (800).
  /// Brand 50 — faint orange tint (active-chip / brand-primary background).
  static const Color brand50 = Color(0xFFFEF1EA);
  /// Brand 100 — soft orange tint.
  static const Color brand100 = Color(0xFFFDDFD2);
  /// Brand 200 — light orange.
  static const Color brand200 = Color(0xFFFBC4AC);
  /// Brand 300 — orange.
  static const Color brand300 = Color(0xFFF89E78);
  /// Brand 400 — light flame.
  static const Color brand400 = Color(0xFFFD8A5C);
  /// Brand 500 — Flame (hover warm-up).
  static const Color brand500 = Color(0xFFFB6424);
  /// Brand 600 — Signal orange (the canonical accent).
  static const Color brand600 = Color(0xFFFA520F);
  /// Brand 700 — burnt orange (pressed / accent-active).
  static const Color brand700 = Color(0xFFDC480D);
  /// Brand 800 — block-edge (brand-mosaic terminus).
  static const Color brand800 = Color(0xFFC0400F);
  /// Brand 900 — deep burnt orange.
  static const Color brand900 = Color(0xFFA6380C);
  /// Brand 950 — darkest orange.
  static const Color brand950 = Color(0xFF7A2A09);

  // Gray — warm-neutral ladder. Replaces the old cool blue-tinted graphite.
  // 50 is the near-white page canvas (#fcfbf9); 100 the warm-neutral secondary
  // surface (#f2f0e9); 200 the default hairline border (#e8e5dc); 600 is muted
  // metadata (#3d3d3d); 900 is Ink black (#1f1f1f), never pure #000.
  /// Gray 25 — just above the canvas.
  static const Color gray25 = Color(0xFFFDFCFA);
  /// Gray 50 — near-white page canvas.
  static const Color gray50 = Color(0xFFFCFBF9);
  /// Gray 100 — warm-neutral secondary surface (chips, secondary buttons).
  static const Color gray100 = Color(0xFFF2F0E9);
  /// Gray 200 — default warm hairline border.
  static const Color gray200 = Color(0xFFE8E5DC);
  /// Gray 300 — stronger hairline.
  static const Color gray300 = Color(0xFFD8D3C6);
  /// Gray 400 — disabled foreground / muted line.
  static const Color gray400 = Color(0xFFB8B2A4);
  /// Gray 500 — placeholder / quaternary text (≈ idle).
  static const Color gray500 = Color(0xFF8C8578);
  /// Gray 600 — muted secondary text & resting icons (#3d3d3d).
  static const Color gray600 = Color(0xFF3D3D3D);
  /// Gray 700 — secondary text.
  static const Color gray700 = Color(0xFF2C2C2A);
  /// Gray 800 — dark surface / warm border (dark theme).
  static const Color gray800 = Color(0xFF262522);
  /// Gray 900 — Ink black, primary text (#1f1f1f).
  static const Color gray900 = Color(0xFF1F1F1F);
  /// Gray 950 — warm near-black (overlays, dark canvas, dark solids).
  static const Color gray950 = Color(0xFF171614);

  // Error (red).
  /// Red 25 from the design system palette.
  static const Color red25 = Color(0xFFFFFBFA);
  /// Red 50 from the design system palette.
  static const Color red50 = Color(0xFFFEF3F2);
  /// Red 100 from the design system palette.
  static const Color red100 = Color(0xFFFEE4E2);
  /// Red 200 from the design system palette.
  static const Color red200 = Color(0xFFFECDCA);
  /// Red 300 from the design system palette.
  static const Color red300 = Color(0xFFFDA29B);
  /// Red 400 from the design system palette.
  static const Color red400 = Color(0xFFF97066);
  /// Red 500 from the design system palette.
  static const Color red500 = Color(0xFFF04438);
  /// Red 600 — design-system danger (#dc2626).
  static const Color red600 = Color(0xFFDC2626);
  /// Red 700 from the design system palette.
  static const Color red700 = Color(0xFFB42318);
  /// Red 800 from the design system palette.
  static const Color red800 = Color(0xFF912018);
  /// Red 900 from the design system palette.
  static const Color red900 = Color(0xFF7A271A);
  /// Red 950 from the design system palette.
  static const Color red950 = Color(0xFF55160C);

  // Success (green).
  /// Green 25 from the design system palette.
  static const Color green25 = Color(0xFFF6FEF9);
  /// Green 50 from the design system palette.
  static const Color green50 = Color(0xFFECFDF3);
  /// Green 100 from the design system palette.
  static const Color green100 = Color(0xFFDCFAE6);
  /// Green 200 from the design system palette.
  static const Color green200 = Color(0xFFABEFC6);
  /// Green 300 from the design system palette.
  static const Color green300 = Color(0xFF75E0A7);
  /// Green 400 from the design system palette.
  static const Color green400 = Color(0xFF47CD89);
  /// Green 500 from the design system palette.
  static const Color green500 = Color(0xFF17B26A);
  /// Green 600 — design-system success (#17a34a).
  static const Color green600 = Color(0xFF17A34A);
  /// Green 700 from the design system palette.
  static const Color green700 = Color(0xFF067647);
  /// Green 800 from the design system palette.
  static const Color green800 = Color(0xFF085D3A);
  /// Green 900 from the design system palette.
  static const Color green900 = Color(0xFF074D31);
  /// Green 950 from the design system palette.
  static const Color green950 = Color(0xFF053321);

  // Warning (yellow).
  /// Yellow 25 from the design system palette.
  static const Color yellow25 = Color(0xFFFEFDF0);
  /// Yellow 50 from the design system palette.
  static const Color yellow50 = Color(0xFFFEFBE8);
  /// Yellow 100 from the design system palette.
  static const Color yellow100 = Color(0xFFFEF7C3);
  /// Yellow 200 from the design system palette.
  static const Color yellow200 = Color(0xFFFEEE95);
  /// Yellow 300 from the design system palette.
  static const Color yellow300 = Color(0xFFFDE272);
  /// Yellow 400 from the design system palette.
  static const Color yellow400 = Color(0xFFFAC515);
  /// Yellow 500 — design-system warn (#eab308).
  static const Color yellow500 = Color(0xFFEAB308);
  /// Yellow 600 from the design system palette.
  static const Color yellow600 = Color(0xFFCA8504);
  /// Yellow 700 from the design system palette.
  static const Color yellow700 = Color(0xFFA15C07);
  /// Yellow 800 from the design system palette.
  static const Color yellow800 = Color(0xFF854A0E);
  /// Yellow 900 from the design system palette.
  static const Color yellow900 = Color(0xFF713B12);
  /// Yellow 950 from the design system palette.
  static const Color yellow950 = Color(0xFF542C0D);

  // Utility — orange.
  /// Orange 50 from the design system palette.
  static const Color orange50 = Color(0xFFFEFAF5);
  /// Orange 100 from the design system palette.
  static const Color orange100 = Color(0xFFFEF6EE);
  /// Orange 200 from the design system palette.
  static const Color orange200 = Color(0xFFF9DBAF);
  /// Orange 300 from the design system palette.
  static const Color orange300 = Color(0xFFF7B27A);
  /// Orange 400 from the design system palette.
  static const Color orange400 = Color(0xFFF38744);
  /// Orange 500 from the design system palette.
  static const Color orange500 = Color(0xFFEF6820);
  /// Orange 600 from the design system palette.
  static const Color orange600 = Color(0xFFE04F16);
  /// Orange 700 from the design system palette.
  static const Color orange700 = Color(0xFFB93815);
  /// Orange 800 from the design system palette.
  static const Color orange800 = Color(0xFF932F19);
  /// Orange 900 from the design system palette.
  static const Color orange900 = Color(0xFF772917);
  /// Orange 950 from the design system palette.
  static const Color orange950 = Color(0xFF511C10);

  // Utility — indigo.
  /// Indigo 50 from the design system palette.
  static const Color indigo50 = Color(0xFFEEF4FF);
  /// Indigo 100 from the design system palette.
  static const Color indigo100 = Color(0xFFE0EAFF);
  /// Indigo 200 from the design system palette.
  static const Color indigo200 = Color(0xFFC7D7FE);
  /// Indigo 300 from the design system palette.
  static const Color indigo300 = Color(0xFFA4BCFD);
  /// Indigo 400 from the design system palette.
  static const Color indigo400 = Color(0xFF8098F9);
  /// Indigo 500 from the design system palette.
  static const Color indigo500 = Color(0xFF6172F3);
  /// Indigo 600 from the design system palette.
  static const Color indigo600 = Color(0xFF444CE7);
  /// Indigo 700 from the design system palette.
  static const Color indigo700 = Color(0xFF3538CD);
  /// Indigo 800 from the design system palette.
  static const Color indigo800 = Color(0xFF2D31A6);
  /// Indigo 900 from the design system palette.
  static const Color indigo900 = Color(0xFF2D3282);
  /// Indigo 950 from the design system palette.
  static const Color indigo950 = Color(0xFF1F235B);

  // Utility — fuchsia.
  /// Fuchsia 50 from the design system palette.
  static const Color fuchsia50 = Color(0xFFFDF4FF);
  /// Fuchsia 100 from the design system palette.
  static const Color fuchsia100 = Color(0xFFFBE8FF);
  /// Fuchsia 200 from the design system palette.
  static const Color fuchsia200 = Color(0xFFF6D0FE);
  /// Fuchsia 300 from the design system palette.
  static const Color fuchsia300 = Color(0xFFEEAAFD);
  /// Fuchsia 400 from the design system palette.
  static const Color fuchsia400 = Color(0xFFE478FA);
  /// Fuchsia 500 from the design system palette.
  static const Color fuchsia500 = Color(0xFFD444F1);
  /// Fuchsia 600 from the design system palette.
  static const Color fuchsia600 = Color(0xFFBA24D5);
  /// Fuchsia 700 from the design system palette.
  static const Color fuchsia700 = Color(0xFF9F1AB1);
  /// Fuchsia 800 from the design system palette.
  static const Color fuchsia800 = Color(0xFF821890);
  /// Fuchsia 900 from the design system palette.
  static const Color fuchsia900 = Color(0xFF6F1877);
  /// Fuchsia 950 from the design system palette.
  static const Color fuchsia950 = Color(0xFF47104C);

  // Utility — pink.
  /// Pink 50 from the design system palette.
  static const Color pink50 = Color(0xFFFDF2FA);
  /// Pink 100 from the design system palette.
  static const Color pink100 = Color(0xFFFCE7F6);
  /// Pink 200 from the design system palette.
  static const Color pink200 = Color(0xFFFCCEEE);
  /// Pink 300 from the design system palette.
  static const Color pink300 = Color(0xFFFAA7E0);
  /// Pink 400 from the design system palette.
  static const Color pink400 = Color(0xFFF670C7);
  /// Pink 500 from the design system palette.
  static const Color pink500 = Color(0xFFEE46BC);
  /// Pink 600 from the design system palette.
  static const Color pink600 = Color(0xFFDD2590);
  /// Pink 700 from the design system palette.
  static const Color pink700 = Color(0xFFC11574);
  /// Pink 800 from the design system palette.
  static const Color pink800 = Color(0xFF9E165F);
  /// Pink 900 from the design system palette.
  static const Color pink900 = Color(0xFF851651);
  /// Pink 950 from the design system palette.
  static const Color pink950 = Color(0xFF4E0D30);

  // Utility — purple.
  /// Purple 50 from the design system palette.
  static const Color purple50 = Color(0xFFF4F3FF);
  /// Purple 100 from the design system palette.
  static const Color purple100 = Color(0xFFEBE9FE);
  /// Purple 200 from the design system palette.
  static const Color purple200 = Color(0xFFD9D6FE);
  /// Purple 300 from the design system palette.
  static const Color purple300 = Color(0xFFBDB4FE);
  /// Purple 400 from the design system palette.
  static const Color purple400 = Color(0xFF9B8AFB);
  /// Purple 500 from the design system palette.
  static const Color purple500 = Color(0xFF7A5AF8);
  /// Purple 600 from the design system palette.
  static const Color purple600 = Color(0xFF6938EF);
  /// Purple 700 from the design system palette.
  static const Color purple700 = Color(0xFF5925DC);
  /// Purple 800 from the design system palette.
  static const Color purple800 = Color(0xFF4A1FB8);
  /// Purple 900 from the design system palette.
  static const Color purple900 = Color(0xFF3E1C96);
  /// Purple 950 from the design system palette.
  static const Color purple950 = Color(0xFF27115F);

  // Utility — sky.
  /// Sky 50 from the design system palette.
  static const Color sky50 = Color(0xFFF0F9FF);
  /// Sky 100 from the design system palette.
  static const Color sky100 = Color(0xFFE0F2FE);
  /// Sky 200 from the design system palette.
  static const Color sky200 = Color(0xFFB9E6FE);
  /// Sky 300 from the design system palette.
  static const Color sky300 = Color(0xFF7CD4FD);
  /// Sky 400 from the design system palette.
  static const Color sky400 = Color(0xFF36BFFA);
  /// Sky 500 from the design system palette.
  static const Color sky500 = Color(0xFF0BA5EC);
  /// Sky 600 from the design system palette.
  static const Color sky600 = Color(0xFF0086C9);
  /// Sky 700 from the design system palette.
  static const Color sky700 = Color(0xFF026AA2);
  /// Sky 800 from the design system palette.
  static const Color sky800 = Color(0xFF065986);
  /// Sky 900 from the design system palette.
  static const Color sky900 = Color(0xFF0B4A6F);
  /// Sky 950 from the design system palette.
  static const Color sky950 = Color(0xFF062C41);

  // Utility — slate.
  /// Slate 50 from the design system palette.
  static const Color slate50 = Color(0xFFF8FAFC);
  /// Slate 100 from the design system palette.
  static const Color slate100 = Color(0xFFF1F5F9);
  /// Slate 200 from the design system palette.
  static const Color slate200 = Color(0xFFE2E8F0);
  /// Slate 300 from the design system palette.
  static const Color slate300 = Color(0xFFCBD5E1);
  /// Slate 400 from the design system palette.
  static const Color slate400 = Color(0xFF94A3B8);
  /// Slate 500 from the design system palette.
  static const Color slate500 = Color(0xFF64748B);
  /// Slate 600 from the design system palette.
  static const Color slate600 = Color(0xFF475569);
  /// Slate 700 from the design system palette.
  static const Color slate700 = Color(0xFF334155);
  /// Slate 800 from the design system palette.
  static const Color slate800 = Color(0xFF1E293B);
  /// Slate 900 from the design system palette.
  static const Color slate900 = Color(0xFF0F172A);
  /// Slate 950 from the design system palette.
  static const Color slate950 = Color(0xFF020617);

  // Utility — emerald.
  /// Emerald 50 from the design system palette.
  static const Color emerald50 = Color(0xFFECFDF5);
  /// Emerald 100 from the design system palette.
  static const Color emerald100 = Color(0xFFD1FADF);
  /// Emerald 200 from the design system palette.
  static const Color emerald200 = Color(0xFFA6F4C5);
  /// Emerald 300 from the design system palette.
  static const Color emerald300 = Color(0xFF6CE9A6);
  /// Emerald 400 from the design system palette.
  static const Color emerald400 = Color(0xFF32D583);
  /// Emerald 500 from the design system palette.
  static const Color emerald500 = Color(0xFF12B76A);
  /// Emerald 600 from the design system palette.
  static const Color emerald600 = Color(0xFF039855);
  /// Emerald 700 from the design system palette.
  static const Color emerald700 = Color(0xFF027A48);
  /// Emerald 800 from the design system palette.
  static const Color emerald800 = Color(0xFF05603A);
  /// Emerald 900 from the design system palette.
  static const Color emerald900 = Color(0xFF054F31);
  /// Emerald 950 from the design system palette.
  static const Color emerald950 = Color(0xFF053321);

  // Utility — amber.
  /// Amber 50 from the design system palette.
  static const Color amber50 = Color(0xFFFFFAEB);
  /// Amber 100 from the design system palette.
  static const Color amber100 = Color(0xFFFEF0C7);
  /// Amber 200 from the design system palette.
  static const Color amber200 = Color(0xFFFEDF89);
  /// Amber 300 from the design system palette.
  static const Color amber300 = Color(0xFFFEC84B);
  /// Amber 400 from the design system palette.
  static const Color amber400 = Color(0xFFFDB022);
  /// Amber 500 from the design system palette.
  static const Color amber500 = Color(0xFFF79009);
  /// Amber 600 from the design system palette.
  static const Color amber600 = Color(0xFFDC6803);
  /// Amber 700 from the design system palette.
  static const Color amber700 = Color(0xFFB54708);
  /// Amber 800 from the design system palette.
  static const Color amber800 = Color(0xFF93370D);
  /// Amber 900 from the design system palette.
  static const Color amber900 = Color(0xFF7A2E0E);
  /// Amber 950 from the design system palette.
  static const Color amber950 = Color(0xFF4E1D09);

  // Sunshine — the golden-hour brand scale. Reserved for BOUNDED brand
  // graphics only (the 3x3 logo mosaic, the golden-hour horizon, the sunset
  // CTA). Never use as text or as a page background.
  /// Sunshine 900 — deep golden amber.
  static const Color sunshine900 = Color(0xFFFF8A00);
  /// Sunshine 700 — golden amber.
  static const Color sunshine700 = Color(0xFFFFA110);
  /// Sunshine 500 — warm gold.
  static const Color sunshine500 = Color(0xFFFFB83E);
  /// Sunshine 300 — light gold.
  static const Color sunshine300 = Color(0xFFFFD06A);
  /// Bright yellow — the highest note of the mosaic.
  static const Color brightYellow = Color(0xFFFFD900);
  /// Block-edge — burnt-orange terminus of the block mosaic.
  static const Color blockEdge = Color(0xFFC0400F);

  /// White from the design system palette.
  static const Color white = Color(0xFFFFFFFF);
  /// Black from the design system palette.
  static const Color black = Color(0xFF000000);
}
