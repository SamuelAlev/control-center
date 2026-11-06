import 'dart:async';
import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/features/environments/presentation/settings/environment_form_fields.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/shared/syntax/grammar_registry.dart';
import 'package:flutter/widgets.dart';

const String _language = 'json';

/// The definition as JSON, so every field stays reachable. Fills whatever
/// height it is given, so the parent must bound it.
class EnvironmentJsonView extends StatefulWidget {
  /// Creates an [EnvironmentJsonView].
  const EnvironmentJsonView({super.key, required this.form});

  /// The draft.
  final EnvironmentForm form;

  @override
  State<EnvironmentJsonView> createState() => _EnvironmentJsonViewState();
}

class _EnvironmentJsonViewState extends State<EnvironmentJsonView> {
  late final _text = DiffSyntaxTextEditingController(
    text: environmentPrettyJson(widget.form.state.draft),
    languageId: _language,
  );

  @override
  void initState() {
    super.initState();
    unawaited(
      ensureLanguageAvailable(_language).then((available) {
        if (available && mounted) {
          _text.refreshHighlighting();
        }
      }),
    );
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _apply(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const FormatException('{ }');
      }
      widget.form.notifier.replace(Map<String, dynamic>.from(decoded));
    } on FormatException catch (error) {
      // Held in the editor's state: the save bar says so and disables Save.
      // Not on this field too, where a full-page error wash would bury the
      // text being fixed.
      widget.form.notifier.setJsonError(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    _text.configure(
      languageId: _language,
      dark: context.ccTheme?.isDark ?? false,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      // RTL carve-out: JSON reads left to right in every locale.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CcTextField(
          controller: _text,
          enabled: widget.form.enabled,
          expands: true,
          minLines: null,
          maxLines: null,
          textStyle: environmentCodeStyle(),
          onChanged: _apply,
        ),
      ),
    );
  }
}
