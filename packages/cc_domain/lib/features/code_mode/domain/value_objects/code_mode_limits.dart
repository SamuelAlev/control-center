import 'dart:math' as math;

import 'package:cc_domain/src/errors/app_exceptions.dart';

/// The `workspace_settings` key holding a workspace's limit overrides, as the
/// JSON object [CodeModeLimits.overridesToJson] writes.
const String kCodeModeLimitsSettingKey = 'code_mode_limits';

/// One adjustable limit: its default, the lowest value a workspace may set and
/// the highest.
class CodeModeLimitBound {
  /// Creates a bound.
  const CodeModeLimitBound({
    required this.key,
    required this.defaultValue,
    required this.floor,
    required this.ceiling,
  });

  /// The JSON key, in [CodeModeLimits.toJson] and in workspace overrides.
  final String key;

  /// What a workspace that set nothing gets.
  final int defaultValue;

  /// The lowest value a workspace may set. Below it a script cannot do
  /// anything useful, so a lower value is a configuration mistake.
  final int floor;

  /// The highest value a workspace may set.
  final int ceiling;

  /// Whether [value] is inside the bound.
  bool admits(int value) => value >= floor && value <= ceiling;
}

/// Every resource limit a script runs under.
///
/// Six limits are adjustable: a workspace may lower them or raise them up to
/// their ceiling ([withOverrides]), and the model may ask for less wall-clock
/// time or fewer output tokens per call ([clamp]). The rest are fixed by the
/// runner and the protocol and exist here as constants so the runner's `init`
/// frame, the host's checks and the audit row read one table.
///
/// Sizes are bytes, durations are milliseconds.
class CodeModeLimits {
  /// Creates limits. Every value defaults to the plan's default.
  ///
  /// Throws [ArgumentError] when a value is outside its bound: a constructor
  /// call with an out-of-range value is a programming error. Values that come
  /// from a person or the model go through [withOverrides] or [clamp].
  CodeModeLimits({
    int? wallClockMs,
    int? cpuMs,
    int? heapBytes,
    int? maxNestedCalls,
    int? maxInFlightCalls,
    int? maxOutputTokens,
  }) : wallClockMs = wallClockMs ?? wallClock.defaultValue,
       cpuMs = cpuMs ?? cpu.defaultValue,
       heapBytes = heapBytes ?? heap.defaultValue,
       maxNestedCalls = maxNestedCalls ?? nestedCalls.defaultValue,
       maxInFlightCalls = maxInFlightCalls ?? inFlightCalls.defaultValue,
       maxOutputTokens = maxOutputTokens ?? outputTokens.defaultValue {
    for (final (bound, value) in _pairs) {
      if (!bound.admits(value)) {
        throw ArgumentError.value(
          value,
          bound.key,
          'must be between ${bound.floor} and ${bound.ceiling}',
        );
      }
    }
  }

  /// Rebuilds the adjustable values from [toJson]'s output (an audit row).
  /// Fixed keys are ignored; they are constants, not state.
  factory CodeModeLimits.fromJson(Map<String, dynamic> json) {
    int? read(CodeModeLimitBound bound) => (json[bound.key] as num?)?.toInt();
    return CodeModeLimits(
      wallClockMs: read(wallClock),
      cpuMs: read(cpu),
      heapBytes: read(heap),
      maxNestedCalls: read(nestedCalls),
      maxInFlightCalls: read(inFlightCalls),
      maxOutputTokens: read(outputTokens),
    );
  }

  /// The plan's defaults.
  static final CodeModeLimits defaults = CodeModeLimits();

  /// Wall-clock deadline, enforced by the host killing the runner. Time spent
  /// waiting on a person is not counted.
  static const CodeModeLimitBound wallClock = CodeModeLimitBound(
    key: 'wall_clock_ms',
    defaultValue: 300000,
    floor: 1000,
    ceiling: 1500000,
  );

  /// Interpreter CPU time, enforced by the runner's interrupt handler.
  static const CodeModeLimitBound cpu = CodeModeLimitBound(
    key: 'cpu_ms',
    defaultValue: 30000,
    floor: 1000,
    ceiling: 120000,
  );

  /// Interpreter heap, enforced by the QuickJS allocator.
  static const CodeModeLimitBound heap = CodeModeLimitBound(
    key: 'heap_bytes',
    defaultValue: 256 * _mib,
    floor: 16 * _mib,
    ceiling: 1024 * _mib,
  );

  /// Nested tool calls per script.
  static const CodeModeLimitBound nestedCalls = CodeModeLimitBound(
    key: 'max_nested_calls',
    defaultValue: 500,
    floor: 1,
    ceiling: 5000,
  );

  /// Parallel-safe nested calls in flight at once.
  static const CodeModeLimitBound inFlightCalls = CodeModeLimitBound(
    key: 'max_in_flight_calls',
    defaultValue: 8,
    floor: 1,
    ceiling: 32,
  );

  /// Tokens of script output the model reads; the rest is kept as head and
  /// tail with a `read_output` reference.
  static const CodeModeLimitBound outputTokens = CodeModeLimitBound(
    key: 'max_output_tokens',
    defaultValue: 10000,
    floor: 100,
    ceiling: 50000,
  );

  /// Every adjustable bound, in [toJson] order.
  static const List<CodeModeLimitBound> adjustable = [
    wallClock,
    cpu,
    heap,
    nestedCalls,
    inFlightCalls,
    outputTokens,
  ];

  /// The interpreter's stack. Overflow is a catchable `RangeError`.
  static const int stackBytes = 512 * _kib;

  /// Output the script may produce inside the interpreter, in bytes. Past it
  /// the prelude ends the script and the script cannot catch that.
  static const int interpreterOutputBytes = 16 * _mib;

  /// Output items the script may produce inside the interpreter.
  static const int interpreterOutputItems = 100000;

  /// Script source, checked by the host before it starts a runner.
  static const int maxSourceBytes = 256 * _kib;

  /// One stored value, as UTF-8 JSON.
  static const int maxStoreValueBytes = 256 * _kib;

  /// Every stored value of one conversation and agent, keys included.
  static const int maxStoreTotalBytes = 1 * _mib;

  /// A store key, as UTF-8.
  static const int maxStoreKeyBytes = 512;

  /// `store` frames (writes and deletes) one script may send: the runner's
  /// own limit (`MAX_STORE_OPS`), past which a script's `store()` throws in
  /// the script. A runner that sends more broke the protocol. With the
  /// per-key and total caps this bounds what a script makes the host parse
  /// and hold.
  static const int maxStoreFrames = 2000;

  /// Questions to a person per script. The next one rejects without showing
  /// a form.
  static const int maxQuestions = 10;

  /// Calls of one script that may reach a person for approval. The next one
  /// that would need a person is refused without a card
  /// (`ScriptApprovalBudget`).
  static const int maxApprovalAsks = 10;

  /// Arguments of one call frame from the runner.
  static const int maxCallArgumentBytes = 1 * _mib;

  /// Objects, arrays, members and other values in one call's arguments.
  /// Decoded JSON can take far more memory than its text (one MiB of `{}`
  /// about 82 MiB), so a call past it is refused to the script before its
  /// arguments are decoded.
  static const int maxCallArgumentItems = 16384;

  /// The tool or host function name in one call frame, as UTF-8. No catalog
  /// name comes near it; a longer one is refused before any lookup.
  static const int maxCallNameBytes = 256;

  /// A nested call's result handed to the script. Larger results reject with
  /// their size and advice to narrow the request.
  static const int maxNestedResultBytes = 4 * _mib;

  /// Values in a tool's JSON text result that a script receives decoded.
  /// A text holding more (or over twice [maxNestedResultBytes]) reaches the
  /// script as the text, which it can parse in its own heap. The text is
  /// decoded only while it is encoded for the script, one result at a time
  /// per isolate, so this bounds a transient, not what the server keeps.
  static const int maxNestedResultItems = 131072;

  /// One protocol frame, in either direction.
  static const int maxFrameBytes = 8 * _mib;

  /// Images from one script that reach the model.
  static const int maxImagesToModel = 4;

  /// The media types an image output may have: the ones every model
  /// provider accepts.
  static const Set<String> imageMediaTypes = {
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  };

  /// One image output, decoded.
  static const int maxImageBytes = 5 * _mib;

  /// Texts in one `models.*` call.
  static const int maxModelBatch = 256;

  /// One text in a `models.*` call, as UTF-8. The embedding model reads only
  /// the start of a text anyway.
  static const int maxModelTextBytes = 8 * _kib;

  /// Text of every `models.*` call of one script together, as UTF-8.
  static const int maxModelBytesPerScript = 4 * _mib;

  /// `models.*` batches started by scripts that run at once on the whole
  /// server. Embeddings run on one worker the code index shares, so
  /// scripts must not fill its queue.
  static const int maxServerModelBatches = 2;

  /// `models.*` calls in flight at once per script.
  static const int maxConcurrentModelCalls = 2;

  /// A `searchTools` query, in UTF-16 code units. Lookups are answered on
  /// the isolate that serves every workspace, and a query's cost grows with
  /// its distinct words; a longer query is refused to the script before any
  /// work.
  static const int maxLookupQueryUnits = 1024;

  /// A `describeTool` / `describeNamespace` name and a `searchTools`
  /// namespace, in UTF-16 code units.
  static const int maxLookupNameUnits = 256;

  /// Lookups (`searchTools`, `describeTool`, `describeNamespace`) one
  /// script may make. Past it every lookup of the script is refused without
  /// any work.
  static const int maxLookups = 200;

  /// Server time the lookups of one script may take together, measured per
  /// lookup. Once the sum passes it every further lookup of the script is
  /// refused without any work, so it is overshot by at most one lookup.
  static const int maxLookupMs = 2000;

  /// Server time the lookups of all of one workspace's scripts may take
  /// together, as a bucket that refills at [workspaceLookupRefillMsPerS]:
  /// scripts started one after another cannot repeat [maxLookupMs] without
  /// end. A lookup that finds the bucket empty is refused without any work,
  /// so the bucket goes below zero by at most one lookup.
  static const int workspaceLookupMs = 2000;

  /// Server time added back to a workspace's lookup bucket per second of
  /// wall time: a quarter of the server's main isolate, over time.
  static const int workspaceLookupRefillMsPerS = 250;

  /// Reads of the run's past (`history`, `outputs`, `loadOutput`) one
  /// script may make. They are answered one at a time, on the isolate that
  /// serves every workspace, and their time is charged to the workspace's
  /// lookup bucket ([workspaceLookupMs]); past this count every further read
  /// of the script is refused without any work.
  static const int maxPastReads = 100;

  /// Rows one `history` call returns: the transcript port's page
  /// (`ConversationTranscriptPort.maxPageRows`).
  static const int maxHistoryRows = 50;

  /// Messages one `history` read scans, at most
  /// (`ConversationTranscriptPort.maxScanMessages`): the transcript reader
  /// pages the database by message position and reads only these messages'
  /// stored facts (no content), so a read costs the same in a conversation
  /// of any length. Whole-message role filters apply over this window; the
  /// tool filter and the segment kinds a role filter keeps are applied by
  /// the query. A window that ends before the page is full returns what it
  /// found with `next_start` set, and the script reads on from there (one
  /// more message's facts are read to know where that is). `next_start`
  /// names a place in the conversation's order (a message's `created_at`
  /// and row id, and its id when the page resumes inside it), so a message
  /// reverted or deleted between two pages neither skips nor repeats a
  /// row.
  ///
  /// Besides the window, one read lists at most [maxHistoryRows] row
  /// segments (their facts) and reads the text of at most [maxHistoryRows]
  /// rows, one at a time, stopping past 64 KiB: at most
  /// [historyReadTextBytes] of text.
  static const int historyScanMessages = 200;

  /// UTF-8 bytes of row text one `history` read takes from the database, at
  /// most: a 64 KiB page plus the one row (at most 16,384 characters, so
  /// 64 KiB) whose text ended it.
  static const int historyReadTextBytes = 128 * 1024;

  /// Characters one `loadOutput` call returns. At most four UTF-8 bytes a
  /// character, so a call returns at most 64 KiB of text, as one `history`
  /// page does (`ConversationTranscriptPort.maxPageBytes`).
  static const int maxLoadOutputChars = 16 * 1024;

  /// UTF-8 bytes of text the past reads of one script return together:
  /// what one nested tool result may hand a script
  /// ([maxNestedResultBytes]).
  static const int maxPastReadBytesPerScript = maxNestedResultBytes;

  /// UTF-8 bytes of text the past reads of all of one run's scripts return
  /// together: what the run's output store keeps of one output
  /// (`FileToolOutputStore.maxBytes`, 16 MiB).
  static const int maxPastReadBytesPerRun = 16 * _mib;

  /// Values one run's scripts may `keep`. The output store keeps at most
  /// 1,024 outputs per conversation and agent; a run's keeps take at most
  /// this many of them.
  static const int maxKeepsPerRun = 64;

  /// UTF-8 bytes one run's scripts may `keep` together: the output store's
  /// ceiling for one output (`FileToolOutputStore.maxBytes`). One value is
  /// at most [maxCallArgumentBytes], since it reaches the host as a call's
  /// arguments.
  static const int maxKeptBytesPerRun = 16 * _mib;

  /// A `keep` label, in UTF-16 code units.
  static const int maxKeepLabelUnits = 200;

  /// Delay between asking a runner to stop and killing it.
  static const int cancelKillGraceMs = 250;

  /// How long the host waits for in-flight nested calls to settle after a
  /// script ends abnormally, before it reports them as they stand.
  static const int nestedSettleGraceMs = 5000;

  /// The shortest wall clock a model may ask for with `timeout_ms`.
  static int get minTimeoutMs => wallClock.floor;

  /// The server-wide runner process cap when the operator sets none:
  /// `min(16, 2 × cores)`, and at least one.
  static int defaultServerProcessCap(int cores) =>
      math.max(1, math.min(16, 2 * cores));

  /// Wall-clock deadline in milliseconds.
  final int wallClockMs;

  /// Interpreter CPU budget in milliseconds.
  final int cpuMs;

  /// Interpreter heap in bytes.
  final int heapBytes;

  /// Nested calls per script.
  final int maxNestedCalls;

  /// Parallel-safe nested calls in flight.
  final int maxInFlightCalls;

  /// Output tokens the model reads.
  final int maxOutputTokens;

  List<(CodeModeLimitBound, int)> get _pairs => [
    (wallClock, wallClockMs),
    (cpu, cpuMs),
    (heap, heapBytes),
    (nestedCalls, maxNestedCalls),
    (inFlightCalls, maxInFlightCalls),
    (outputTokens, maxOutputTokens),
  ];

  /// Applies a workspace's overrides on top of these limits.
  ///
  /// A workspace may lower any adjustable limit or raise it up to its
  /// ceiling. Null keeps the current value. Throws [ValidationException]
  /// naming the key when a value is outside its bound, because these come
  /// from a person's settings write and the refusal is client-safe.
  CodeModeLimits withOverrides({
    int? wallClockMs,
    int? cpuMs,
    int? heapBytes,
    int? maxNestedCalls,
    int? maxInFlightCalls,
    int? maxOutputTokens,
  }) {
    int pick(CodeModeLimitBound bound, int? value, int current) {
      if (value == null) {
        return current;
      }
      if (!bound.admits(value)) {
        throw ValidationException(
          '${bound.key} must be between ${bound.floor} and ${bound.ceiling}.',
          code: 'code_mode_limit_out_of_range',
        );
      }
      return value;
    }

    return CodeModeLimits(
      wallClockMs: pick(wallClock, wallClockMs, this.wallClockMs),
      cpuMs: pick(cpu, cpuMs, this.cpuMs),
      heapBytes: pick(heap, heapBytes, this.heapBytes),
      maxNestedCalls: pick(nestedCalls, maxNestedCalls, this.maxNestedCalls),
      maxInFlightCalls: pick(
        inFlightCalls,
        maxInFlightCalls,
        this.maxInFlightCalls,
      ),
      maxOutputTokens: pick(
        outputTokens,
        maxOutputTokens,
        this.maxOutputTokens,
      ),
    );
  }

  /// Applies the overrides object stored under [kCodeModeLimitsSettingKey].
  ///
  /// Unknown keys are refused rather than ignored, so a typo in a settings
  /// write is reported instead of silently leaving the default in place. A
  /// value that is not an integer is refused the same way.
  CodeModeLimits withOverridesJson(Map<String, dynamic> json) {
    final known = {for (final b in adjustable) b.key};
    for (final key in json.keys) {
      if (!known.contains(key)) {
        throw ValidationException(
          'Unknown code mode limit: $key.',
          code: 'code_mode_limit_unknown',
        );
      }
    }
    int? read(CodeModeLimitBound bound) {
      final raw = json[bound.key];
      if (raw == null) {
        return null;
      }
      if (raw is int) {
        return raw;
      }
      if (raw is double && raw == raw.truncateToDouble()) {
        return raw.toInt();
      }
      throw ValidationException(
        '${bound.key} must be an integer.',
        code: 'code_mode_limit_out_of_range',
      );
    }

    return withOverrides(
      wallClockMs: read(wallClock),
      cpuMs: read(cpu),
      heapBytes: read(heap),
      maxNestedCalls: read(nestedCalls),
      maxInFlightCalls: read(inFlightCalls),
      maxOutputTokens: read(outputTokens),
    );
  }

  /// The values that differ from [defaults], keyed as
  /// [withOverridesJson] reads them. What a settings write stores.
  Map<String, int> overridesToJson() => {
    for (final (bound, value) in _pairs)
      if (value != bound.defaultValue) bound.key: value,
  };

  /// Applies the model's per-call `timeout_ms` and `max_output_tokens`.
  ///
  /// These limits (the workspace's) are the ceiling: a model may ask for
  /// less time or a smaller output budget, never more. A workspace that
  /// wants its models to have more room raises its own value. A value below
  /// the floor is raised to the floor, and a missing or non-positive value
  /// keeps the current one, so a model can neither fail a call nor escape a
  /// limit with an odd number.
  CodeModeLimits clamp({int? timeoutMs, int? maxOutputTokens}) {
    int fit(CodeModeLimitBound bound, int? asked, int current) {
      if (asked == null || asked <= 0) {
        return current;
      }
      return math.min(current, math.max(bound.floor, asked));
    }

    return CodeModeLimits(
      wallClockMs: fit(wallClock, timeoutMs, wallClockMs),
      cpuMs: cpuMs,
      heapBytes: heapBytes,
      maxNestedCalls: maxNestedCalls,
      maxInFlightCalls: maxInFlightCalls,
      maxOutputTokens: fit(outputTokens, maxOutputTokens, this.maxOutputTokens),
    );
  }

  /// Every limit, adjustable and fixed, for the audit row and the runner's
  /// `init` frame.
  Map<String, int> toJson() => {
    for (final (bound, value) in _pairs) bound.key: value,
    'stack_bytes': stackBytes,
    'interpreter_output_bytes': interpreterOutputBytes,
    'interpreter_output_items': interpreterOutputItems,
    'max_source_bytes': maxSourceBytes,
    'max_store_value_bytes': maxStoreValueBytes,
    'max_store_total_bytes': maxStoreTotalBytes,
    'max_questions': maxQuestions,
    'max_call_argument_bytes': maxCallArgumentBytes,
    'max_nested_result_bytes': maxNestedResultBytes,
    'max_images_to_model': maxImagesToModel,
    'max_model_batch': maxModelBatch,
    'max_concurrent_model_calls': maxConcurrentModelCalls,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeModeLimits &&
          other.wallClockMs == wallClockMs &&
          other.cpuMs == cpuMs &&
          other.heapBytes == heapBytes &&
          other.maxNestedCalls == maxNestedCalls &&
          other.maxInFlightCalls == maxInFlightCalls &&
          other.maxOutputTokens == maxOutputTokens;

  @override
  int get hashCode => Object.hash(
    wallClockMs,
    cpuMs,
    heapBytes,
    maxNestedCalls,
    maxInFlightCalls,
    maxOutputTokens,
  );

  @override
  String toString() => 'CodeModeLimits(${overridesToJson()})';
}

const int _kib = 1024;
const int _mib = 1024 * 1024;
