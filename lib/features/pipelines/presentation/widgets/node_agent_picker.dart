import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A typeahead agent picker. [agents] maps each agent's display label to its
/// id. The field is seeded with the label of [selectedAgentId] (when present),
/// and selecting a row emits that agent's id.
class NodeAgentPicker extends StatefulWidget {
  /// Creates the picker.
  const NodeAgentPicker({
    super.key,
    required this.agents,
    required this.selectedAgentId,
    required this.hint,
    required this.onSelected,
  });

  /// Maps each agent's display label to its id.
  final Map<String, String> agents;

  /// The agent the node has, if any.
  final String? selectedAgentId;

  /// The field's hint.
  final String hint;

  /// Called with the picked agent's id.
  final ValueChanged<String> onSelected;

  @override
  State<NodeAgentPicker> createState() => _NodeAgentPickerState();
}

class _NodeAgentPickerState extends State<NodeAgentPicker> {
  late final TextEditingController _controller = TextEditingController(
    text: _initialLabel(),
  );

  String _initialLabel() {
    for (final entry in widget.agents.entries) {
      if (entry.value == widget.selectedAgentId) {
        return entry.key;
      }
    }
    return '';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcAutocomplete<String>(
      controller: _controller,
      hintText: widget.hint,
      options: [
        for (final entry in widget.agents.entries)
          CcSelectOption<String>(value: entry.value, label: entry.key),
      ],
      onSelected: widget.onSelected,
    );
  }
}
