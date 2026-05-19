// Web binding for the composer's file/folder mention source.
//
// File mentions need the native `FileSearch` (cc_natives) over LOCAL repo
// checkouts, which a web thin client does not have. So there is no file-mention
// source on web (returns null and the composer simply omits it); `#`-mentions of
// agents, channels, tickets, PRs and meetings — all served over RPC — still work.
library;

import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No local file search on web — the composer omits the file-mention source.
MentionSource? buildFileMentionSource(WidgetRef ref, List<String> roots) => null;

/// No native voice transcriber on web — the composer's mic button is disabled.
SpeechTranscriber? composerTranscriber(WidgetRef ref) => null;
