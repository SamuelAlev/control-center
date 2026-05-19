import 'package:cc_domain/features/settings/domain/services/branch_template_resolver.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User-configurable branch-name template used when an isolated worktree is
/// provisioned for a ticket. Persisted as a non-sensitive preference.
///
/// Supports `{type}`, `{ticket-key}`, `{slug}` placeholders. Default:
/// [BranchTemplateResolver.defaultTemplate].
final branchTemplateProvider =
    NotifierProvider<BranchTemplateNotifier, String>(BranchTemplateNotifier.new);

/// Loads and persists the branch-name template.
class BranchTemplateNotifier extends Notifier<String> {
  late AppPreferences _prefs;

  @override
  String build() {
    _prefs = ref.watch(appPreferencesProvider);
    final stored = _prefs.getString(branchTemplateKey);
    return (stored == null || stored.trim().isEmpty)
        ? BranchTemplateResolver.defaultTemplate
        : stored;
  }

  /// Sets the template and persists it. Empty input resets to the default.
  void setTemplate(String template) {
    final value = template.trim().isEmpty
        ? BranchTemplateResolver.defaultTemplate
        : template.trim();
    _prefs.setString(branchTemplateKey, value);
    state = value;
  }
}
