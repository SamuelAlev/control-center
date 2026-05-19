import 'dart:async';
import 'dart:convert';

import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';

/// Runs code in a persistent interpreter that keeps its variables between
/// calls.
///
/// **Why this is not `bash python -c`.** Loading a dataframe costs seconds and
/// a hundred megabytes; charting it costs milliseconds. A one-shot command pays
/// the load on every question, so an agent exploring data asks fewer questions
/// than it should — and each answer arrives as text it then has to re-parse.
/// Here the second cell starts where the first stopped, and a figure comes back
/// as an image the transcript renders.
///
/// **Code inside a cell can call the agent's own tools.** `tool("read", {...})`
/// re-enters the harness registry, so a cell can fan out over a hundred files
/// through `read` or delegate through `task` without the model spending a turn
/// per item. Those calls pass the same `ActionClass` guardrails and approval a
/// model-issued call does — the bridge re-enters the registry, it does not go
/// around it.
class EvalTool extends HarnessTool {
  /// Creates an [EvalTool].
  EvalTool({
    required EvalKernel Function(KernelLanguage language) kernelFor,
    this.maxImages = 4,
  }) : _kernelFor = kernelFor;

  final EvalKernel Function(KernelLanguage language) _kernelFor;

  /// How many images one cell may return.
  ///
  /// A plotting loop can emit a figure per iteration, and every image is a
  /// large fixed cost in the request that carries it.
  final int maxImages;

  @override
  String get name => 'eval';

  @override
  String get description =>
      'Run code in a persistent interpreter. Variables, imports and loaded '
      'data survive between calls, so load once and explore in later cells. '
      'The last expression is echoed like a notebook; matplotlib figures come '
      'back as images. Inside a cell, `tool("read", {"path": ...})` calls your '
      'own tools. Use `reset` to start over with a clean interpreter.';

  /// Exec tier: a kernel runs arbitrary code and holds a process.
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;

  @override
  Set<ActionClass> get actionClasses => const {ActionClass.processSpawn};

  /// One kernel, one cell at a time: two cells racing in one interpreter is
  /// two halves of two programs interleaved in one namespace.
  @override
  bool get parallelSafe => false;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'code': {'type': 'string', 'description': 'The cell to run.'},
      'language': {
        'type': 'string',
        'enum': ['python', 'javascript'],
        'description': 'Which interpreter. Default python.',
      },
      'reset': {
        'type': 'boolean',
        'description':
            'Discard the interpreter and start a clean one before running.',
      },
    },
    'required': ['code'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final code = args['code'];
    if (code is! String || code.trim().isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: code');
    }
    final language = args['language'] == 'javascript'
        ? KernelLanguage.javascript
        : KernelLanguage.python;

    final kernel = _kernelFor(language);
    if (args['reset'] == true) {
      await kernel.dispose();
    }

    final KernelRunOutcome outcome;
    try {
      outcome = await kernel.run(code);
    } on StateError catch (e) {
      return HarnessToolResult.error(e.message);
    } on Object catch (e) {
      return HarnessToolResult.error('The kernel could not run that cell: $e');
    }

    return _render(outcome, language);
  }

  HarnessToolResult _render(KernelRunOutcome outcome, KernelLanguage language) {
    final buffer = StringBuffer();
    final images = <HarnessImageBlock>[];
    for (final output in outcome.outputs) {
      switch (output) {
        case KernelText(:final text):
          buffer.write(text);
        case KernelResult(:final text):
          buffer.writeln(text);
        case KernelImage(:final mediaType, :final base64Data):
          if (mediaType == 'image/png') {
            if (images.length < maxImages) {
              images.add(
                HarnessImageBlock(
                  mediaType: mediaType,
                  data: base64Data,
                ),
              );
            }
          } else {
            // A non-image bundle (an HTML table, typically) is worth its text
            // and not worth a renderer: the model reads it either way.
            buffer.writeln(_stripHtml(base64Data));
          }
      }
    }
    if (outcome.timedOut) {
      return HarnessToolResult.error(
        '${buffer.toString().trimRight()}\n\n'
        'The cell produced nothing for the inactivity budget and was left '
        'running. The interpreter still holds its variables — check what it '
        'is waiting on, or pass reset:true to start clean.',
      );
    }
    final error = outcome.error;
    if (error != null) {
      return HarnessToolResult.error(
        '${buffer.toString().trimRight()}\n$error'.trim(),
      );
    }
    final text = buffer.toString().trimRight();
    return HarnessToolResult.success(
      text.isEmpty
          ? '(${language.name} cell ran with no output)'
          : text,
      images: images,
    );
  }

  /// A crude de-HTML for a `_repr_html_` bundle.
  ///
  /// Not a parser and not trying to be: the point is that a pandas table
  /// arrives as readable rows instead of a wall of `<td>`, and anything more
  /// faithful would be a second markdown renderer inside a tool.
  static String _stripHtml(String html) {
    final unescaped = const HtmlEscape().convert('') == ''
        ? html
        : html; // no-op; kept explicit for clarity
    return unescaped
        .replaceAll(RegExp(r'<(br|tr)\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(td|th)>', caseSensitive: false), '\t')
        .replaceAll(RegExp('<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
}
