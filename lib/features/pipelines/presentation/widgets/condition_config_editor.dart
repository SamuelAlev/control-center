import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The authoring shape currently selected in the condition editor.
enum _ConditionMode { filesAny, filesAll, comparison, switchOn }

/// Editor for a router node's branching condition (`config.extras`).
///
/// Surfaces the four practical shapes the `pipeline.condition` body understands
/// and writes them back as a normalized `extras` map:
/// - **Files exist (any)** → `predicate: {type: fileExists, paths, …}` — routes
///   `true` when any path exists (or, inverted, when none do).
/// - **Files exist (all)** → `predicate: {type: and, of: [fileExists…]}`.
/// - **Comparison** → `predicate: {type: comparison, left, op, right}`.
/// - **Switch** → top-level `switchKey` / `cases` / `default` (multi-way).
///
/// Either way the router emits a route key (`true`/`false`, or the matched
/// case) that an outgoing edge must carry.
class ConditionConfigEditor extends StatefulWidget {
  /// Creates a [ConditionConfigEditor].
  const ConditionConfigEditor({
    super.key,
    required this.extras,
    required this.onChanged,
  });

  /// The node's current `config.extras`.
  final Map<String, dynamic> extras;

  /// Called with the rebuilt `extras` whenever the user edits a field.
  final void Function(Map<String, dynamic> extras) onChanged;

  @override
  State<ConditionConfigEditor> createState() => _ConditionConfigEditorState();
}

class _ConditionConfigEditorState extends State<ConditionConfigEditor> {
  static const _ops = [
    'exists',
    'notExists',
    'equals',
    'notEquals',
    'contains',
    'gt',
    'lt',
  ];

  late _ConditionMode _mode;
  late final TextEditingController _pathsCtrl;
  late final TextEditingController _baseKeyCtrl;
  late final TextEditingController _leftCtrl;
  late final TextEditingController _rightCtrl;
  late final TextEditingController _switchKeyCtrl;
  late final TextEditingController _casesCtrl;
  late final TextEditingController _defaultCtrl;
  String _op = 'exists';
  bool _negate = false;
  bool _recursive = false;

  @override
  void initState() {
    super.initState();
    _pathsCtrl = TextEditingController();
    _baseKeyCtrl = TextEditingController(text: 'repoLocalPath');
    _leftCtrl = TextEditingController();
    _rightCtrl = TextEditingController();
    _switchKeyCtrl = TextEditingController();
    _casesCtrl = TextEditingController();
    _defaultCtrl = TextEditingController();
    _hydrate(widget.extras);
    for (final c in [
      _pathsCtrl,
      _baseKeyCtrl,
      _leftCtrl,
      _rightCtrl,
      _switchKeyCtrl,
      _casesCtrl,
      _defaultCtrl,
    ]) {
      c.addListener(_emit);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _pathsCtrl,
      _baseKeyCtrl,
      _leftCtrl,
      _rightCtrl,
      _switchKeyCtrl,
      _casesCtrl,
      _defaultCtrl,
    ]) {
      c
        ..removeListener(_emit)
        ..dispose();
    }
    super.dispose();
  }

  /// Reads [extras] into the controllers and selects the matching mode.
  void _hydrate(Map<String, dynamic> extras) {
    final predicate = extras['predicate'];
    if (predicate is Map) {
      final type = predicate['type'];
      if (type == 'and') {
        _mode = _ConditionMode.filesAll;
        _pathsCtrl.text = _leafPaths(predicate['of']).join('\n');
        final first = _firstLeaf(predicate['of']);
        _baseKeyCtrl.text = (first?['baseKey'] as String?) ?? 'repoLocalPath';
        _recursive = first?['recursive'] == true;
        return;
      }
      if (type == 'comparison') {
        _mode = _ConditionMode.comparison;
        _leftCtrl.text = (predicate['left'] as String?) ?? '';
        _op = (predicate['op'] as String?) ?? 'exists';
        _rightCtrl.text = _stringify(predicate['right']);
        return;
      }
      // Default predicate shape: fileExists (also flatten an `or` group).
      _mode = _ConditionMode.filesAny;
      if (type == 'or') {
        _pathsCtrl.text = _leafPaths(predicate['of']).join('\n');
        final first = _firstLeaf(predicate['of']);
        _baseKeyCtrl.text = (first?['baseKey'] as String?) ?? 'repoLocalPath';
        _negate = false;
        _recursive = first?['recursive'] == true;
      } else {
        _pathsCtrl.text = _pathList(predicate['paths'], predicate['path']).join('\n');
        _baseKeyCtrl.text = (predicate['baseKey'] as String?) ?? 'repoLocalPath';
        _negate = predicate['negate'] == true;
        _recursive = predicate['recursive'] == true;
      }
      return;
    }
    if (extras['switchKey'] is String) {
      _mode = _ConditionMode.switchOn;
      _switchKeyCtrl.text = extras['switchKey'] as String;
      _casesCtrl.text =
          ((extras['cases'] as List?)?.cast<String>() ?? const []).join(', ');
      _defaultCtrl.text = (extras['default'] as String?) ?? '';
      return;
    }
    // Legacy top-level comparison (left/op/right).
    _mode = _ConditionMode.comparison;
    _leftCtrl.text = (extras['left'] as String?) ?? '';
    _op = (extras['op'] as String?) ?? 'exists';
    _rightCtrl.text = _stringify(extras['right']);
  }

  List<String> _pathList(Object? paths, Object? singlePath) => [
        if (paths is String && paths.trim().isNotEmpty) paths.trim(),
        if (paths is List)
          for (final v in paths)
            if (v is String && v.trim().isNotEmpty) v.trim(),
        if (singlePath is String && singlePath.trim().isNotEmpty)
          singlePath.trim(),
      ];

  List<String> _leafPaths(Object? of) {
    if (of is! List) {
      return const [];
    }
    return [
      for (final leaf in of)
        if (leaf is Map) ..._pathList(leaf['paths'], leaf['path']),
    ];
  }

  Map<String, dynamic>? _firstLeaf(Object? of) {
    if (of is List) {
      for (final leaf in of) {
        if (leaf is Map) {
          return leaf.cast<String, dynamic>();
        }
      }
    }
    return null;
  }

  String _stringify(Object? v) => v == null ? '' : '$v';

  List<String> get _paths => _pathsCtrl.text
      .split(RegExp(r'[\n,]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList(growable: false);

  void _emit() {
    // Preserve any extras unrelated to the condition (e.g. idempotent).
    final next = <String, dynamic>{...widget.extras}
      ..remove('predicate')
      ..remove('switchKey')
      ..remove('cases')
      ..remove('default')
      ..remove('left')
      ..remove('op')
      ..remove('right');
    final baseKey = _baseKeyCtrl.text.trim().isEmpty
        ? 'repoLocalPath'
        : _baseKeyCtrl.text.trim();

    switch (_mode) {
      case _ConditionMode.filesAny:
        next['predicate'] = <String, dynamic>{
          'type': 'fileExists',
          'paths': _paths,
          'baseKey': baseKey,
          if (_negate) 'negate': true,
          if (_recursive) 'recursive': true,
        };
      case _ConditionMode.filesAll:
        next['predicate'] = <String, dynamic>{
          'type': 'and',
          'of': [
            for (final path in _paths)
              <String, dynamic>{
                'type': 'fileExists',
                'paths': [path],
                'baseKey': baseKey,
                if (_recursive) 'recursive': true,
              },
          ],
        };
      case _ConditionMode.comparison:
        next['predicate'] = <String, dynamic>{
          'type': 'comparison',
          'left': _leftCtrl.text,
          'op': _op,
          'right': _rightCtrl.text,
        };
      case _ConditionMode.switchOn:
        next['switchKey'] = _switchKeyCtrl.text.trim();
        next['cases'] = _casesCtrl.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(growable: false);
        if (_defaultCtrl.text.trim().isNotEmpty) {
          next['default'] = _defaultCtrl.text.trim();
        }
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final isFiles =
        _mode == _ConditionMode.filesAny || _mode == _ConditionMode.filesAll;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.conditionSectionTitle,
          style: TextStyle(
            color: ds.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _Labeled(
          label: l10n.conditionMode,
          child: CcSelect<_ConditionMode>(
            options: [
              CcSelectOption(
                value: _ConditionMode.filesAny,
                label: l10n.conditionModeFilesAny,
              ),
              CcSelectOption(
                value: _ConditionMode.filesAll,
                label: l10n.conditionModeFilesAll,
              ),
              CcSelectOption(
                value: _ConditionMode.comparison,
                label: l10n.conditionModeComparison,
              ),
              CcSelectOption(
                value: _ConditionMode.switchOn,
                label: l10n.conditionModeSwitch,
              ),
            ],
            value: _mode,
            onChanged: (m) {
              setState(() => _mode = m);
              _emit();
            },
          ),
        ),
        if (isFiles) ...[
          const SizedBox(height: 12),
          _Labeled(
            label: l10n.conditionFilePaths,
            description: _mode == _ConditionMode.filesAll
                ? l10n.conditionFilePathsAllHelp
                : l10n.conditionFilePathsAnyHelp,
            child: CcTextArea(
              controller: _pathsCtrl,
              hintText: 'Cargo.toml\npubspec.yaml',
              minLines: 2,
              maxLines: 8,
            ),
          ),
          const SizedBox(height: 12),
          _Labeled(
            label: l10n.conditionBaseKey,
            description: l10n.conditionBaseKeyHelp,
            child: CcTextField(controller: _baseKeyCtrl),
          ),
          const SizedBox(height: 8),
          _Check(
            value: _recursive,
            label: l10n.conditionRecursive,
            onChanged: (v) {
              setState(() => _recursive = v);
              _emit();
            },
          ),
          if (_mode == _ConditionMode.filesAny)
            _Check(
              value: _negate,
              label: l10n.conditionNegate,
              onChanged: (v) {
                setState(() => _negate = v);
                _emit();
              },
            ),
        ],
        if (_mode == _ConditionMode.comparison) ...[
          const SizedBox(height: 12),
          _Labeled(
            label: l10n.conditionLeft,
            child: CcTextField(controller: _leftCtrl, hintText: '{{score}}'),
          ),
          const SizedBox(height: 12),
          _Labeled(
            label: l10n.conditionOperator,
            child: CcSelect<String>(
              options: [
                for (final op in _ops) CcSelectOption(value: op, label: op),
              ],
              value: _op,
              onChanged: (v) {
                setState(() => _op = v);
                _emit();
              },
            ),
          ),
          const SizedBox(height: 12),
          _Labeled(
            label: l10n.conditionRight,
            child: CcTextField(controller: _rightCtrl, hintText: '80'),
          ),
        ],
        if (_mode == _ConditionMode.switchOn) ...[
          const SizedBox(height: 12),
          _Labeled(
            label: l10n.conditionSwitchKey,
            child: CcTextField(controller: _switchKeyCtrl, hintText: 'prClass'),
          ),
          const SizedBox(height: 12),
          _Labeled(
            label: l10n.conditionCases,
            description: l10n.conditionCasesHelp,
            child: CcTextField(
              controller: _casesCtrl,
              hintText: 'docs, security, standard',
            ),
          ),
          const SizedBox(height: 12),
          _Labeled(
            label: l10n.conditionDefaultCase,
            child: CcTextField(controller: _defaultCtrl),
          ),
        ],
      ],
    );
  }
}

/// Stacks a field label (and optional help text) above a form control, giving
/// every field a consistent label/description layout.
class _Labeled extends StatelessWidget {
  const _Labeled({
    required this.label,
    required this.child,
    this.description,
  });

  final String label;
  final Widget child;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: ds.textPrimary, fontSize: 13)),
        const SizedBox(height: 6),
        child,
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(color: ds.textTertiary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          CcCheckbox(value: value, onChanged: onChanged),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: ds.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
