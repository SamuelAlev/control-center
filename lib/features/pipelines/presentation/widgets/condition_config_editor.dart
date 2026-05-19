import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

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
    final colors = context.theme.colors;
    final isFiles =
        _mode == _ConditionMode.filesAny || _mode == _ConditionMode.filesAll;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.conditionSectionTitle,
          style: TextStyle(
            color: colors.foreground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        FSelect<_ConditionMode>(
          items: {
            l10n.conditionModeFilesAny: _ConditionMode.filesAny,
            l10n.conditionModeFilesAll: _ConditionMode.filesAll,
            l10n.conditionModeComparison: _ConditionMode.comparison,
            l10n.conditionModeSwitch: _ConditionMode.switchOn,
          },
          label: Text(l10n.conditionMode),
          control: FSelectControl<_ConditionMode>.lifted(
            value: _mode,
            onChange: (m) {
              if (m == null) {
                return;
              }
              setState(() => _mode = m);
              _emit();
            },
          ),
        ),
        if (isFiles) ...[
          const SizedBox(height: 12),
          FTextField.multiline(
            control: FTextFieldControl.managed(controller: _pathsCtrl),
            label: Text(l10n.conditionFilePaths),
            description: Text(_mode == _ConditionMode.filesAll
                ? l10n.conditionFilePathsAllHelp
                : l10n.conditionFilePathsAnyHelp),
            hint: 'Cargo.toml\npubspec.yaml',
            minLines: 2,
            maxLines: 8,
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _baseKeyCtrl),
            label: Text(l10n.conditionBaseKey),
            description: Text(l10n.conditionBaseKeyHelp),
            size: FTextFieldSizeVariant.sm,
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
          FTextField(
            control: FTextFieldControl.managed(controller: _leftCtrl),
            label: Text(l10n.conditionLeft),
            hint: '{{score}}',
            size: FTextFieldSizeVariant.sm,
          ),
          const SizedBox(height: 12),
          FSelect<String>(
            items: {for (final op in _ops) op: op},
            label: Text(l10n.conditionOperator),
            control: FSelectControl<String>.lifted(
              value: _op,
              onChange: (v) {
                if (v == null) {
                  return;
                }
                setState(() => _op = v);
                _emit();
              },
            ),
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _rightCtrl),
            label: Text(l10n.conditionRight),
            hint: '80',
            size: FTextFieldSizeVariant.sm,
          ),
        ],
        if (_mode == _ConditionMode.switchOn) ...[
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _switchKeyCtrl),
            label: Text(l10n.conditionSwitchKey),
            hint: 'prClass',
            size: FTextFieldSizeVariant.sm,
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _casesCtrl),
            label: Text(l10n.conditionCases),
            description: Text(l10n.conditionCasesHelp),
            hint: 'docs, security, standard',
            size: FTextFieldSizeVariant.sm,
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _defaultCtrl),
            label: Text(l10n.conditionDefaultCase),
            size: FTextFieldSizeVariant.sm,
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
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          FCheckbox(value: value, onChange: onChanged),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colors.foreground, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
