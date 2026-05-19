import 'package:collection/collection.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_definition.dart' show PipelineDefinition;

/// The widget kind used to collect a [PipelineInput] value in the run form.
enum PipelineInputType {
  /// Single-line free text.
  text,

  /// Multi-line free text (rendered as a textarea).
  multiline,

  /// Numeric value. Coerced to a [num] on submit.
  number,

  /// On/off toggle. Coerced to a [bool] on submit.
  boolean,

  /// One choice from a fixed list ([PipelineInput.options]).
  select,

  /// A repository chosen from the workspace's repos. Selecting one populates
  /// the trigger payload with the repo's derived keys (`repoId`,
  /// `repoLocalPath`, `repoFullName`, and `repoOwner`/`repoName` when the repo
  /// has a GitHub remote) so any downstream step can read what it needs.
  repo;

  /// Parses a [PipelineInputType] from its wire name, defaulting to `text`.
  static PipelineInputType fromName(String? name) {
    return PipelineInputType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => PipelineInputType.text,
    );
  }
}

/// A single declared input field of a [PipelineDefinition].
///
/// Manual runs render one form control per input and submit the collected
/// values as the run's trigger payload. The value lands in pipeline state /
/// trigger payload under [key], where step bodies read it via `{{key}}`
/// substitution or `inputKeys`.
class PipelineInput {
  /// Creates a [PipelineInput].
  PipelineInput({
    required this.key,
    String? label,
    this.type = PipelineInputType.text,
    this.required = false,
    this.defaultValue,
    this.helpText,
    this.placeholder,
    this.options = const [],
  })  : assert(key.isNotEmpty, 'input key must not be empty'),
        label = (label == null || label.isEmpty) ? key : label;

  /// Decodes a [PipelineInput] from JSON.
  factory PipelineInput.fromJson(Map<String, dynamic> json) {
    return PipelineInput(
      key: json['key'] as String,
      label: json['label'] as String?,
      type: PipelineInputType.fromName(json['type'] as String?),
      required: json['required'] as bool? ?? false,
      defaultValue: json['defaultValue'],
      helpText: json['helpText'] as String?,
      placeholder: json['placeholder'] as String?,
      options: (json['options'] as List?)?.cast<String>() ?? const [],
    );
  }

  /// State / trigger-payload key this input writes to (e.g. `repoFullName`).
  final String key;

  /// Human-readable label shown above the form control. Defaults to [key].
  final String label;

  /// Which form control to render.
  final PipelineInputType type;

  /// Whether the run form must be filled before submit is allowed.
  final bool required;

  /// Pre-filled value. String / num / bool depending on [type]. Null means
  /// the control starts empty (or, for [PipelineInputType.boolean], false).
  final Object? defaultValue;

  /// Optional help text rendered as the control's description.
  final String? helpText;

  /// Optional placeholder / hint for text controls.
  final String? placeholder;

  /// Allowed choices for [PipelineInputType.select]. Ignored otherwise.
  final List<String> options;

  /// JSON-encodes this input.
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'type': type.name,
      if (required) 'required': true,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (helpText != null) 'helpText': helpText,
      if (placeholder != null) 'placeholder': placeholder,
      if (options.isNotEmpty) 'options': options,
    };
  }

  /// Returns a copy with the given fields overridden.
  PipelineInput copyWith({
    String? key,
    String? label,
    PipelineInputType? type,
    bool? required,
    Object? defaultValue,
    String? helpText,
    String? placeholder,
    List<String>? options,
  }) {
    return PipelineInput(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
      helpText: helpText ?? this.helpText,
      placeholder: placeholder ?? this.placeholder,
      options: options ?? this.options,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineInput &&
          key == other.key &&
          label == other.label &&
          type == other.type &&
          required == other.required &&
          defaultValue == other.defaultValue &&
          helpText == other.helpText &&
          placeholder == other.placeholder &&
          const DeepCollectionEquality().equals(options, other.options);

  @override
  int get hashCode => Object.hash(
        key,
        label,
        type,
        required,
        defaultValue,
        helpText,
        placeholder,
        const DeepCollectionEquality().hash(options),
      );
}
