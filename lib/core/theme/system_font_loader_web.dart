/// Web: there are no local "system fonts" to read from disk — the web build
/// ships only bundled assets and Google Fonts. A user's saved system-font
/// selection therefore never resolves on web (it falls back to the bundled
/// family), so both operations report "not present" / "nothing loaded".
bool systemFontFileExists(String filePath) => false;

/// Web no-op: loading a font from a local file path is not possible in the
/// browser sandbox.
Future<bool> loadSystemFontFromFile(String family, String filePath) async =>
    false;
