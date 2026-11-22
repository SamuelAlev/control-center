import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:collection/collection.dart';

const JsonEncoder _indentedJson = JsonEncoder.withIndent('  ');

/// One piece of output a script produced, in call order.
///
/// What the runner streams in `output` frames, and what the result text the
/// model reads is assembled from.
sealed class ScriptOutputItem {
  const ScriptOutputItem();

  /// The text form of a `text(value)` argument or a top-level `return` value:
  /// a string as written, anything else as indented JSON.
  ///
  /// The runner sends values as JSON, so every value that reaches the host is
  /// JSON-serialisable.
  factory ScriptOutputItem.value(Object? value) =>
      ScriptTextOutput(value is String ? value : _indentedJson.convert(value));

  /// Rebuilds from [toJson]'s output. Throws [FormatException] for an
  /// unknown kind or console level.
  factory ScriptOutputItem.fromJson(Map<String, dynamic> json) {
    switch (json['kind']) {
      case 'text':
        return ScriptTextOutput(json['text'] as String? ?? '');
      case 'console':
        return ScriptConsoleOutput(
          level:
              ScriptConsoleLevel.tryParse(json['level'] as String?) ??
              (throw FormatException(
                'Unknown console level "${json['level']}".',
              )),
          text: json['text'] as String? ?? '',
        );
      case 'image':
        return ScriptImageOutput(
          mediaType: json['media_type'] as String? ?? '',
          data: json['data'] as String? ?? '',
        );
      default:
        throw FormatException('Unknown script output kind: ${json['kind']}');
    }
  }

  /// The wire form.
  Map<String, dynamic> toJson();
}

/// Text from `text(value)` or the script's return value.
final class ScriptTextOutput extends ScriptOutputItem {
  /// Creates text output.
  const ScriptTextOutput(this.text);

  /// The text.
  final String text;

  @override
  Map<String, dynamic> toJson() => {'kind': 'text', 'text': text};

  @override
  bool operator ==(Object other) =>
      other is ScriptTextOutput && other.text == text;

  @override
  int get hashCode => Object.hash('text', text);
}

/// The `console` method a line came from.
enum ScriptConsoleLevel {
  /// `console.log`.
  log('log'),

  /// `console.info`.
  info('info'),

  /// `console.warn`.
  warn('warn'),

  /// `console.error`.
  error('error'),

  /// `console.debug`.
  debug('debug');

  const ScriptConsoleLevel(this.wire);

  /// The stable wire name.
  final String wire;

  /// Parses [value], or returns null when it is not a known level.
  static ScriptConsoleLevel? tryParse(String? value) {
    for (final l in values) {
      if (l.wire == value) {
        return l;
      }
    }
    return null;
  }
}

/// One `console.*` line, its arguments already joined by the runner.
final class ScriptConsoleOutput extends ScriptOutputItem {
  /// Creates a console line.
  const ScriptConsoleOutput({required this.level, required this.text});

  /// Which method wrote it.
  final ScriptConsoleLevel level;

  /// The line.
  final String text;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'console',
    'level': level.wire,
    'text': text,
  };

  @override
  bool operator ==(Object other) =>
      other is ScriptConsoleOutput &&
      other.level == level &&
      other.text == text;

  @override
  int get hashCode => Object.hash(level, text);
}

/// An image block a tool returned, passed to `image(block)`.
final class ScriptImageOutput extends ScriptOutputItem {
  /// Creates image output.
  const ScriptImageOutput({required this.mediaType, required this.data});

  /// The MIME type (`image/png`).
  final String mediaType;

  /// The base64 bytes.
  final String data;

  /// Approximate decoded size in bytes.
  int get approximateBytes => data.length * 3 ~/ 4;

  @override
  Map<String, dynamic> toJson() => {
    'kind': 'image',
    'media_type': mediaType,
    'data': data,
  };

  @override
  bool operator ==(Object other) =>
      other is ScriptImageOutput &&
      other.mediaType == mediaType &&
      other.data == data;

  @override
  int get hashCode => Object.hash(mediaType, data);
}

/// The uncaught error that ended a script, with positions already mapped to
/// the script as written.
class ScriptError {
  /// Creates an error.
  const ScriptError({
    required this.name,
    required this.message,
    this.line,
    this.column,
    this.stack,
  });

  /// Rebuilds from [toJson]'s output (also the runner's `done.error`).
  ///
  /// The script chooses its error's name, message and stack, at any length,
  /// so each is cut here: the name to one line of [maxNameChars], the
  /// message to [maxMessageBytes] and the stack to [maxStackBytes]. None of
  /// them ever decides how the script is recorded.
  factory ScriptError.fromJson(Map<String, dynamic> json) {
    final name = oneLineLabel(json['name'] as String? ?? '', maxNameChars);
    final stack = json['stack'] as String?;
    return ScriptError(
      name: name.isEmpty ? 'Error' : name,
      message: boundUtf8(json['message'] as String? ?? '', maxMessageBytes),
      line: (json['line'] as num?)?.toInt(),
      column: (json['column'] as num?)?.toInt(),
      stack: stack == null ? null : boundUtf8(stack, maxStackBytes),
    );
  }

  /// The longest [name] kept, in characters.
  static const int maxNameChars = 100;

  /// The most of [message] kept, in UTF-8 bytes.
  static const int maxMessageBytes = 4 * 1024;

  /// The most of [stack] kept, in UTF-8 bytes.
  static const int maxStackBytes = 8 * 1024;

  /// The error's constructor name (`TypeError`, `SyntaxError`).
  final String name;

  /// The error's message.
  final String message;

  /// One-based line in the script, when known.
  final int? line;

  /// One-based column in the script, when known.
  final int? column;

  /// The stack frames, one per line, each already in `    at repl.js:L:C`
  /// form, when the runner had them.
  final String? stack;

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'name': name,
    'message': message,
    if (line != null) 'line': line,
    if (column != null) 'column': column,
    if (stack != null) 'stack': stack,
  };

  @override
  bool operator ==(Object other) =>
      other is ScriptError &&
      other.name == name &&
      other.message == message &&
      other.line == line &&
      other.column == column &&
      other.stack == stack;

  @override
  int get hashCode => Object.hash(name, message, line, column, stack);
}

/// A nested call as the result text lists it: name and how it ended.
class ScriptCallSummary {
  /// Creates a summary.
  const ScriptCallSummary({required this.name, required this.status});

  /// The tool's raw name.
  final String name;

  /// How it ended.
  final NestedCallStatus status;

  @override
  bool operator ==(Object other) =>
      other is ScriptCallSummary &&
      other.name == name &&
      other.status == status;

  @override
  int get hashCode => Object.hash(name, status);
}

/// A question a script put to a person and what they answered.
///
/// Appended verbatim to the result whatever the script returned, because the
/// model sees only what a script returns and must still read what the person
/// said.
class ScriptQuestionRecord {
  /// Creates a record.
  const ScriptQuestionRecord({
    required this.question,
    this.options = const [],
    this.selected = const [],
    this.text,
    this.skipped = false,
    this.answered = true,
  });

  /// Builds the record for one `ask_user` nested call from its [arguments]
  /// and its outcome.
  ///
  /// The script chose the arguments, so what is kept of them is bounded:
  /// [maxTextBytes] of the question and the answer, [maxOptions] options of
  /// [maxOptionBytes] each. A script's ten questions keep at most about
  /// 1 MiB of memory however long the script made them.
  ///
  /// A completed call's [value] is the structured answer
  /// `{ selected, text, skipped }`; a plain string is read as typed text. A
  /// call that did not complete (timed out, dismissed, cancelled) reads as
  /// not answered.
  factory ScriptQuestionRecord.fromNestedCall({
    required Map<String, dynamic> arguments,
    required NestedCallStatus status,
    Object? value,
  }) {
    // A JSON text answer is decoded here, synchronously, and not kept.
    if (value is ScriptJsonText) {
      value = value.toJson();
    }
    final question = cutToUtf8Bytes(
      (arguments['question'] as String?)?.trim() ?? '',
      maxTextBytes,
    );
    final options = [
      for (final o in (arguments['options'] as List?) ?? const [])
        if (o is Map && o['label'] is String)
          cutToUtf8Bytes(o['label'] as String, maxOptionBytes),
    ].take(maxOptions).toList();
    if (status != NestedCallStatus.completed) {
      return ScriptQuestionRecord(
        question: question,
        options: options,
        answered: false,
      );
    }
    if (value is Map) {
      final selected = value['selected'];
      final text = value['text'];
      return ScriptQuestionRecord(
        question: question,
        options: options,
        selected: [
          if (selected is List)
            for (final s in selected.take(maxOptions))
              cutToUtf8Bytes('$s', maxOptionBytes)
          else if (selected is String && selected.isNotEmpty)
            cutToUtf8Bytes(selected, maxOptionBytes),
        ],
        text: text is String && text.isNotEmpty
            ? cutToUtf8Bytes(text, maxTextBytes)
            : null,
        skipped: value['skipped'] == true,
      );
    }
    return ScriptQuestionRecord(
      question: question,
      options: options,
      text: value is String && value.isNotEmpty
          ? cutToUtf8Bytes(value, maxTextBytes)
          : null,
    );
  }

  /// Rebuilds from [toJson]'s output.
  factory ScriptQuestionRecord.fromJson(Map<String, dynamic> json) =>
      ScriptQuestionRecord(
        question: json['question'] as String? ?? '',
        options: [for (final o in (json['options'] as List?) ?? const []) '$o'],
        selected: [
          for (final s in (json['selected'] as List?) ?? const []) '$s',
        ],
        text: json['text'] as String?,
        skipped: json['skipped'] == true,
        answered: json['answered'] != false,
      );

  /// The most UTF-8 bytes of the question and of the typed answer a record
  /// keeps.
  static const int maxTextBytes = 8 * 1024;

  /// The most options, and selected options, a record keeps.
  static const int maxOptions = 64;

  /// The most UTF-8 bytes of one option a record keeps.
  static const int maxOptionBytes = 512;

  /// The question as asked.
  final String question;

  /// The option labels offered.
  final List<String> options;

  /// What the person selected.
  final List<String> selected;

  /// What the person typed.
  final String? text;

  /// Whether the person skipped the question.
  final bool skipped;

  /// False when the form timed out, was dismissed or the script ended before
  /// an answer.
  final bool answered;

  /// The wire form.
  Map<String, dynamic> toJson() => {
    'question': question,
    if (options.isNotEmpty) 'options': options,
    if (selected.isNotEmpty) 'selected': selected,
    if (text != null) 'text': text,
    if (skipped) 'skipped': true,
    if (!answered) 'answered': false,
  };

  @override
  bool operator ==(Object other) =>
      other is ScriptQuestionRecord &&
      other.question == question &&
      const ListEquality<String>().equals(other.options, options) &&
      const ListEquality<String>().equals(other.selected, selected) &&
      other.text == text &&
      other.skipped == skipped &&
      other.answered == answered;

  @override
  int get hashCode => Object.hash(
    question,
    const ListEquality<String>().hash(options),
    const ListEquality<String>().hash(selected),
    text,
    skipped,
    answered,
  );
}

/// Everything the result text is built from: how the script ended, what it
/// wrote, the calls it made and the questions it asked.
///
/// Assembled by the execution service from the runner's frames and its own
/// bookkeeping, then handed to `ScriptResultFormatter`.
class CodeExecutionOutcome {
  /// Creates an outcome. Throws [ArgumentError] when [durationMs] is
  /// negative, [status] is [CodeExecutionStatus.running] (a script that is
  /// still running has no result), or a [CodeExecutionStatus.refused]
  /// outcome carries calls or output.
  ///
  /// [notes] are bounded here ([boundNotes]), so whoever adds them cannot
  /// make the result longer than the caps allow.
  CodeExecutionOutcome({
    required this.status,
    required this.durationMs,
    List<ScriptOutputItem> output = const [],
    this.returnValue,
    this.error,
    List<ScriptCallSummary> calls = const [],
    List<ScriptQuestionRecord> questions = const [],
    this.detail,
    this.source,
    Iterable<String> notes = const [],
  }) : output = List.unmodifiable(output),
       calls = List.unmodifiable(calls),
       questions = List.unmodifiable(questions),
       notes = List.unmodifiable(boundNotes(notes)) {
    if (status == CodeExecutionStatus.running) {
      throw ArgumentError.value(
        status,
        'status',
        'a running script has no result to format',
      );
    }
    if (durationMs < 0) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        'must not be negative',
      );
    }
    if (status == CodeExecutionStatus.refused &&
        (calls.isNotEmpty || output.isNotEmpty || returnValue != null)) {
      throw ArgumentError.value(
        status,
        'status',
        'a refused script never ran, so it has no calls or output',
      );
    }
  }

  /// How it ended.
  final CodeExecutionStatus status;

  /// Wall-clock milliseconds, waits included.
  final int durationMs;

  /// Output items in call order.
  final List<ScriptOutputItem> output;

  /// The top-level return value as text ([ScriptOutputItem.value]), or null
  /// when the script returned nothing (`undefined`).
  final ScriptTextOutput? returnValue;

  /// The uncaught error, for [CodeExecutionStatus.failed].
  final ScriptError? error;

  /// Nested calls in call order.
  final List<ScriptCallSummary> calls;

  /// Questions asked of a person, in order.
  final List<ScriptQuestionRecord> questions;

  /// The host's reason for an abnormal end, in a sentence: which limit ran
  /// out, why the script was refused, what the runner did wrong.
  final String? detail;

  /// The script source, used to recognise TypeScript and `import` in a
  /// `SyntaxError`.
  final String? source;

  /// What the host has to tell the model besides the script's own output
  /// (a value that was not saved, a record that could not be written), as
  /// [boundNotes] keeps them.
  final List<String> notes;

  /// The most notes one result carries.
  static const int maxNotes = 5;

  /// The longest note, in characters.
  static const int maxNoteChars = 300;

  /// [notes] without repeats, each cut to [maxNoteChars] on one line, at most
  /// [maxNotes] of them; a last line says how many more were dropped.
  ///
  /// A note can quote what a script or a runner sent, and a hostile runner
  /// can make the host write one per frame, so nothing about them is left to
  /// the caller.
  static List<String> boundNotes(Iterable<String> notes) {
    final unique = <String>{
      for (final note in notes)
        if (oneLineLabel(note, maxNoteChars) case final line
            when line.isNotEmpty)
          line,
    }.toList();
    if (unique.length <= maxNotes) {
      return unique;
    }
    final dropped = unique.length - (maxNotes - 1);
    return [...unique.take(maxNotes - 1), '$dropped more notes were left out.'];
  }
}
