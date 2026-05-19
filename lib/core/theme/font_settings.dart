import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/system_font_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Whether a font came from Google Fonts or was loaded from the OS file system.
enum FontSource {
  /// Google Fonts source.
  google,
  /// System font file source.
  system,
}

/// A selected font with its origin and optional system file path.
@immutable
class FontSelection {
  /// Creates a font selection.
  const FontSelection({
    required this.family,
    this.source = FontSource.google,
    this.filePath,
  });

  /// Font family name.
  final String family;
  /// Font source (Google Fonts or system).
  final FontSource source;
  /// Optional system font file path.
  final String? filePath;

  /// Copy with.
  FontSelection copyWith({
    String? family,
    FontSource? source,
    String? filePath,
  }) => FontSelection(
    family: family ?? this.family,
    source: source ?? this.source,
    filePath: filePath ?? this.filePath,
  );

  @override
  bool operator ==(Object other) =>
      other is FontSelection &&
      other.family == family &&
      other.source == source &&
      other.filePath == filePath;

  @override
  int get hashCode => Object.hash(family, source, filePath);
}

/// Combined font settings for both app (UI) and code fonts.
@immutable
class FontSettings {
  /// Creates font settings with defaults.
  const FontSettings({
    this.appFontSelection = const FontSelection(family: AppFonts.uiFamily),
    this.codeFontSelection = const FontSelection(family: AppFonts.codeFamily),
    this.codeFontLigatures = true,
  });

  /// Selected app (UI) font.
  final FontSelection appFontSelection;
  /// Selected code font.
  final FontSelection codeFontSelection;
  /// Whether programming ligatures (e.g. Fira Code's `=>`, `!=`) are rendered
  /// in code and diff text. On by default.
  final bool codeFontLigatures;

  /// Copy with.
  FontSettings copyWith({
    FontSelection? appFontSelection,
    FontSelection? codeFontSelection,
    bool? codeFontLigatures,
  }) => FontSettings(
    appFontSelection: appFontSelection ?? this.appFontSelection,
    codeFontSelection: codeFontSelection ?? this.codeFontSelection,
    codeFontLigatures: codeFontLigatures ?? this.codeFontLigatures,
  );

  @override
  bool operator ==(Object other) =>
      other is FontSettings &&
      other.appFontSelection == appFontSelection &&
      other.codeFontSelection == codeFontSelection &&
      other.codeFontLigatures == codeFontLigatures;

  @override
  int get hashCode =>
      Object.hash(appFontSelection, codeFontSelection, codeFontLigatures);
}

/// Riverpod provider for the user's font selections.
final fontSettingsProvider =
    NotifierProvider<FontSettingsNotifier, FontSettings>(
      FontSettingsNotifier.new,
    );

/// Simple provider that exposes just the current code font family name.
final codeFontFamilyProvider = Provider<String>((ref) {
  return ref.watch(fontSettingsProvider).codeFontSelection.family;
});

/// Whether programming ligatures are enabled for code/diff text.
final codeFontLigaturesProvider = Provider<bool>((ref) {
  return ref.watch(fontSettingsProvider).codeFontLigatures;
});

/// Resolves when all selected system fonts have been loaded via FontLoader.
final fontsReadyProvider = FutureProvider<void>((ref) async {
  final settings = ref.watch(fontSettingsProvider);
  final notifier = ref.read(fontSettingsProvider.notifier);
  await notifier.loadSystemFont(settings.appFontSelection);
  await notifier.loadSystemFont(settings.codeFontSelection);
});

/// Manages loading and updating font preferences from persistent storage.
class FontSettingsNotifier extends Notifier<FontSettings> {
  late AppPreferences _prefs;

  /// Cache of already loaded system fonts so we do not load them again.
  final Set<String> _loadedFonts = {};

  @override
  FontSettings build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _loadFromPrefs();
  }

  FontSettings _loadFromPrefs() {
    final appFamily = _prefs.getString(appFontFamilyKey) ?? AppFonts.uiFamily;
    final appSourceStr = _prefs.getString(appFontSourceKey) ?? 'google';
    final appPath = _prefs.getString(appFontPathKey);
    final codeFamily =
        _prefs.getString(codeFontFamilyKey) ?? AppFonts.codeFamily;
    final codeSourceStr = _prefs.getString(codeFontSourceKey) ?? 'google';
    final codePath = _prefs.getString(codeFontPathKey);

    final appSource = _parseSource(appSourceStr);
    final codeSource = _parseSource(codeSourceStr);

    var appSelection = FontSelection(
      family: appFamily,
      source: appSource,
      filePath: appPath,
    );
    var codeSelection = FontSelection(
      family: codeFamily,
      source: codeSource,
      filePath: codePath,
    );

    // If a system font file no longer exists, fall back to defaults. (On web
    // there are no local font files, so a saved `system` selection always falls
    // back here — see the `system_font_loader.dart` seam.)
    if (appSelection.source == FontSource.system &&
        (appSelection.filePath == null ||
            !systemFontFileExists(appSelection.filePath!))) {
      appSelection = const FontSelection(family: AppFonts.uiFamily);
    }
    if (codeSelection.source == FontSource.system &&
        (codeSelection.filePath == null ||
            !systemFontFileExists(codeSelection.filePath!))) {
      codeSelection = const FontSelection(family: AppFonts.codeFamily);
    }

    return FontSettings(
      appFontSelection: appSelection,
      codeFontSelection: codeSelection,
      codeFontLigatures: _prefs.getBool(codeFontLigaturesKey) ?? true,
    );
  }

  FontSource _parseSource(String value) {
    switch (value) {
      case 'system':
        return FontSource.system;
      case 'google':
      default:
        return FontSource.google;
    }
  }

  /// Set app font.
  Future<void> setAppFont(FontSelection selection) async {
    await loadSystemFont(selection);
    await _saveFont(
      familyKey: appFontFamilyKey,
      sourceKey: appFontSourceKey,
      pathKey: appFontPathKey,
      selection: selection,
    );
    state = state.copyWith(appFontSelection: selection);
  }

  /// Set code font.
  Future<void> setCodeFont(FontSelection selection) async {
    await loadSystemFont(selection);
    await _saveFont(
      familyKey: codeFontFamilyKey,
      sourceKey: codeFontSourceKey,
      pathKey: codeFontPathKey,
      selection: selection,
    );
    state = state.copyWith(codeFontSelection: selection);
  }

  /// Enable or disable programming ligatures in code/diff text.
  Future<void> setCodeFontLigatures(bool enabled) async {
    await _prefs.setBool(codeFontLigaturesKey, enabled);
    state = state.copyWith(codeFontLigatures: enabled);
  }

  Future<void> _saveFont({
    required String familyKey,
    required String sourceKey,
    required String pathKey,
    required FontSelection selection,
  }) async {
    await _prefs.setString(familyKey, selection.family);
    await _prefs.setString(sourceKey, selection.source.name);
    if (selection.filePath != null) {
      await _prefs.setString(pathKey, selection.filePath!);
    } else {
      await _prefs.remove(pathKey);
    }
  }

  /// Pre-load a system font so it is ready for Flutter's text engine.
  /// Safe to call multiple times – returns immediately if already loaded.
  Future<void> loadSystemFont(FontSelection selection) async {
    if (selection.source != FontSource.system || selection.filePath == null) {
      return;
    }
    final cacheKey = '${selection.filePath!}#${selection.family}';
    if (_loadedFonts.contains(cacheKey)) {
      return;
    }

    final loaded =
        await loadSystemFontFromFile(selection.family, selection.filePath!);
    if (loaded) {
      _loadedFonts.add(cacheKey);
    }
  }

  /// Whether the given family is a known Google Fonts family.
  bool isGoogleFont(String family) => GoogleFonts.asMap().containsKey(family);
}
