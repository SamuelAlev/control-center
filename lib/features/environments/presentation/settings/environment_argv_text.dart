/// [argv] as one line, quoting what needs it.
String environmentArgvToText(List<String> argv) => argv
    .map(
      (argument) =>
          // A backslash is an escape to the reader, so it is quoted too.
          argument.isEmpty || argument.contains(RegExp(r'''[\s"'\\]'''))
          ? '"${argument.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"'
          : argument,
    )
    .join(' ');

/// Splits [text] into arguments, honouring quotes and backslashes.
///
/// This is how the field reads what a person typed. No shell ever sees it: the
/// result is stored as an argv array.
List<String> environmentTextToArgv(String text) {
  final out = <String>[];
  final current = StringBuffer();
  String? quote;
  var escaped = false;
  var started = false;
  for (final char in text.split('')) {
    if (escaped) {
      current.write(char);
      escaped = false;
    } else if (char == r'\' && quote != "'") {
      escaped = true;
      started = true;
    } else if (quote != null) {
      if (char == quote) {
        quote = null;
      } else {
        current.write(char);
      }
    } else if (char == '"' || char == "'") {
      quote = char;
      started = true;
    } else if (char.trim().isEmpty) {
      if (started) {
        out.add(current.toString());
        current.clear();
        started = false;
      }
    } else {
      current.write(char);
      started = true;
    }
  }
  if (started) {
    out.add(current.toString());
  }
  return out;
}
