// Where a composer attachment lives while something else looks at it.
//
// An editor tab is addressed by its `args`, which must be JSON primitives (the
// layout codec persists them), so a preview tab cannot carry an attachment —
// let alone its bytes. It carries an ID, and resolves it here.
//
// The registry is deliberately BOUNDED. Entries hold picture bytes, and a
// session that drags forty screenshots through a conversation would otherwise
// pin every one of them for as long as the app runs. Eviction is oldest-first
// past either ceiling, and a preview whose entry is gone says so — the same
// shape as the artifact and run-activity tabs, which also degrade to one
// closeable tab rather than pretending.
library;

import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Most attachments retained for preview at once.
const int kAttachmentRegistryMaxEntries = 32;

/// Most bytes retained across all registered attachments.
///
/// Sized at four full-resolution screenshots' worth of headroom: enough that
/// previewing what you just dropped always works, small enough that it is not a
/// leak with a long name.
const int kAttachmentRegistryMaxBytes = 64 * 1024 * 1024;

/// Attachments currently previewable, oldest insertion first.
class AttachmentRegistry extends Notifier<Map<String, ComposerAttachment>> {
  @override
  Map<String, ComposerAttachment> build() => const {};

  /// Registers [attachments], evicting the oldest entries past either ceiling.
  ///
  /// Re-registering a known id refreshes it in place WITHOUT moving it to the
  /// end: an attachment being re-registered (a mime type resolved, a size
  /// learned) is the same attachment, not a fresher one, and promoting it would
  /// let a repeatedly-touched entry outlive newer ones.
  void register(Iterable<ComposerAttachment> attachments) {
    if (attachments.isEmpty) {
      return;
    }
    final next = Map<String, ComposerAttachment>.of(state);
    for (final attachment in attachments) {
      next[attachment.id] = attachment;
    }
    state = _evict(next);
  }

  /// Drops [id] — the user removed the attachment before sending.
  void unregister(String id) {
    if (!state.containsKey(id)) {
      return;
    }
    state = Map<String, ComposerAttachment>.of(state)..remove(id);
  }

  /// The attachment behind [id], or null when it was never registered or has
  /// since been evicted.
  ComposerAttachment? resolve(String id) => state[id];

  static Map<String, ComposerAttachment> _evict(
    Map<String, ComposerAttachment> entries,
  ) {
    var total = 0;
    for (final entry in entries.values) {
      total += entry.bytes?.length ?? 0;
    }
    if (entries.length <= kAttachmentRegistryMaxEntries &&
        total <= kAttachmentRegistryMaxBytes) {
      return entries;
    }
    // Dart preserves insertion order, so the head of the key list is the
    // oldest entry.
    final keys = entries.keys.toList();
    var index = 0;
    while (index < keys.length &&
        (entries.length > kAttachmentRegistryMaxEntries ||
            total > kAttachmentRegistryMaxBytes)) {
      final removed = entries.remove(keys[index]);
      total -= removed?.bytes?.length ?? 0;
      index++;
    }
    return entries;
  }
}

/// The app-wide attachment registry.
final attachmentRegistryProvider =
    NotifierProvider<AttachmentRegistry, Map<String, ComposerAttachment>>(
      AttachmentRegistry.new,
    );
