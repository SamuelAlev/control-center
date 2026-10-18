// Configure highlighting before use; compile common grammars only after a
// frame has painted and the scheduler has no higher-priority interactive work.

import 'dart:async';

import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:flutter/scheduler.dart';
import 'package:shiki_flutter/engine.dart';

bool _warmUpScheduled = false;

/// Configures shiki and schedules one idle task per common grammar, each
/// compiling it on the UI isolate (see [CcShikiTokenizer.compile]).
/// Repeated bootstrap calls do not queue another warm-up. On-demand tokenizer
/// initialization remains authoritative if code appears before an idle slot.
void initializeShikiHighlighting() {
  ShikiHighlighter.config = ShikiHighlighter.config.copyWith(
    // Web: use the prebuilt tokenize Web Worker (web/shiki_tokenize_worker.js,
    // installed by tool/gen_workers.sh). Falls back to inline transparently
    // when the asset is missing or CSP-blocked.
    asyncWeb: true,
  );
  if (_warmUpScheduled) {
    return;
  }
  _warmUpScheduled = true;
  SchedulerBinding.instance.addPostFrameCallback((_) {
    unawaited(_warmCommonLanguages());
  });
}

Future<void> _warmCommonLanguages() async {
  for (final language in const [
    'dart',
    'javascript',
    'typescript',
    'json',
    'yaml',
    'shellscript',
  ]) {
    await SchedulerBinding.instance.scheduleTask<void>(
      () => CcShikiTokenizer.instance.compile(language),
      Priority.idle,
      debugLabel: 'Compile syntax: $language',
    );
  }
}
