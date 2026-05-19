// Desktop binding for the composer's file/folder mention source.
//
// File mentions are powered by the native `FileSearch` (cc_natives) over the
// workspace's local repo checkouts — desktop-only. This builds the real
// `FileMentionSource` from `fileSearchProvider`.
library;

import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/di/server_providers.dart' show fileSearchProvider;
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/file_mention_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the local-file mention source over [roots], or null when there are
/// no roots to search.
MentionSource? buildFileMentionSource(WidgetRef ref, List<String> roots) {
  if (roots.isEmpty) {
    return null;
  }
  return FileMentionSource(search: ref.watch(fileSearchProvider), roots: roots);
}

/// The composer's voice-dictation transcriber (native on desktop; null when no
/// voice model is installed).
SpeechTranscriber? composerTranscriber(WidgetRef ref) =>
    ref.watch(speechTranscriberProvider);
