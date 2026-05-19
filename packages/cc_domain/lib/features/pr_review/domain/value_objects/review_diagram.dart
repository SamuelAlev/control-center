// Typed review diagrams (PRD 18 §3). Diagrams are STRUCTURED DATA, never
// mermaid text: agents emit schema-validated JSON that is cross-checked against
// real `code_graph` edges, so a diagram is a *view of verified edges*, not
// prose with arrows. Mermaid is supported only as an EXPORT format for the
// GitHub-published review body (where GitHub renders it).
//
// ignore_for_file: sort_constructors_first

import 'package:collection/collection.dart';

/// The kind of a [ReviewDiagram].
enum ReviewDiagramKind {
  /// Call flow across participants — derived from code-graph call edges.
  sequence,

  /// Entity-relationship diagram for schema/table changes.
  entityRelation,

  /// State machine for a status/enum change.
  stateMachine;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored/wire name, defaulting to [sequence].
  static ReviewDiagramKind fromName(String? name) =>
      ReviewDiagramKind.values.firstWhere(
        (k) => k.name == name,
        orElse: () => ReviewDiagramKind.sequence,
      );
}

/// Base type for a generated, graph-verifiable review diagram.
///
/// Concrete subtypes carry typed nodes/edges. Every subtype can (a) round-trip
/// JSON, (b) export to mermaid for the GitHub body, and (c) report whether all
/// its edges are corroborated by the code graph.
sealed class ReviewDiagram {
  /// Creates a [ReviewDiagram].
  const ReviewDiagram({required this.title});

  /// Human-readable diagram title.
  final String title;

  /// The diagram kind discriminator.
  ReviewDiagramKind get kind;

  /// Whether every edge in this diagram is corroborated by the code graph.
  /// A diagram with any uncorroborated edge (`corroborated == false`) is
  /// flagged in the UI.
  bool get isFullyCorroborated;

  /// Serializes to JSON (with a `kind` discriminator).
  Map<String, dynamic> toJson();

  /// Renders this diagram as mermaid source for the GitHub export path.
  String toMermaid();

  /// Parses any diagram subtype from JSON by its `kind` discriminator.
  static ReviewDiagram fromJson(Map<String, dynamic> json) {
    switch (ReviewDiagramKind.fromName(json['kind'] as String?)) {
      case ReviewDiagramKind.sequence:
        return SequenceDiagram.fromJson(json);
      case ReviewDiagramKind.entityRelation:
        return EntityRelationDiagram.fromJson(json);
      case ReviewDiagramKind.stateMachine:
        return StateMachineDiagram.fromJson(json);
    }
  }
}

/// One message (arrow) in a [SequenceDiagram].
class SequenceMessage {
  /// Creates a [SequenceMessage].
  const SequenceMessage({
    required this.from,
    required this.to,
    required this.label,
    this.symbolRef,
    this.corroborated = true,
  });

  /// Source participant name.
  final String from;

  /// Destination participant name.
  final String to;

  /// Message/call label.
  final String label;

  /// The code-graph symbol id this call edge maps to, when known. Used by the
  /// verifier to cross-check against real call edges.
  final String? symbolRef;

  /// Whether the code graph corroborates this call edge. Set by the verifier;
  /// an uncorroborated edge is rendered dashed and flagged (never silently
  /// shown as fact).
  final bool corroborated;

  /// Builds from JSON.
  factory SequenceMessage.fromJson(Map<String, dynamic> json) =>
      SequenceMessage(
        from: json['from'] as String? ?? '',
        to: json['to'] as String? ?? '',
        label: json['label'] as String? ?? '',
        symbolRef: json['symbolRef'] as String?,
        corroborated: json['corroborated'] as bool? ?? true,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'label': label,
    if (symbolRef != null) 'symbolRef': symbolRef,
    'corroborated': corroborated,
  };

  /// Returns a copy with [corroborated] overridden (used by the verifier).
  SequenceMessage withCorroboration({required bool value}) => SequenceMessage(
    from: from,
    to: to,
    label: label,
    symbolRef: symbolRef,
    corroborated: value,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequenceMessage &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          label == other.label &&
          symbolRef == other.symbolRef &&
          corroborated == other.corroborated;

  @override
  int get hashCode => Object.hash(from, to, label, symbolRef, corroborated);
}

/// A sequence diagram for a new call flow (PRD 18 §3), derived from code-graph
/// call edges.
class SequenceDiagram extends ReviewDiagram {
  /// Creates a [SequenceDiagram].
  const SequenceDiagram({
    required super.title,
    required this.participants,
    required this.messages,
  });

  /// Ordered participant lanes.
  final List<String> participants;

  /// Ordered messages (arrows) between participants.
  final List<SequenceMessage> messages;

  @override
  ReviewDiagramKind get kind => ReviewDiagramKind.sequence;

  @override
  bool get isFullyCorroborated => messages.every((m) => m.corroborated);

  /// Builds from JSON.
  factory SequenceDiagram.fromJson(Map<String, dynamic> json) =>
      SequenceDiagram(
        title: json['title'] as String? ?? '',
        participants:
            (json['participants'] as List?)?.whereType<String>().toList() ??
            const [],
        messages: (json['messages'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => SequenceMessage.fromJson(m.cast<String, dynamic>()))
            .toList(),
      );

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.wireName,
    'title': title,
    'participants': participants,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  @override
  String toMermaid() {
    final buf = StringBuffer('sequenceDiagram\n');
    for (final p in participants) {
      buf.writeln('  participant ${_mermaidId(p)} as $p');
    }
    for (final m in messages) {
      final arrow = m.corroborated ? '->>' : '-->>';
      buf.writeln(
        '  ${_mermaidId(m.from)}$arrow${_mermaidId(m.to)}: ${m.label}'
        '${m.corroborated ? '' : ' (unverified)'}',
      );
    }
    return buf.toString().trimRight();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SequenceDiagram &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          const ListEquality<String>().equals(
            participants,
            other.participants,
          ) &&
          const ListEquality<SequenceMessage>().equals(
            messages,
            other.messages,
          );

  @override
  int get hashCode => Object.hash(
    title,
    Object.hashAll(participants),
    Object.hashAll(messages),
  );
}

/// A field of an [ErEntity].
class ErField {
  /// Creates an [ErField].
  const ErField({required this.name, required this.type, this.isKey = false});

  /// Field name.
  final String name;

  /// Field type.
  final String type;

  /// Whether this field is (part of) the primary key.
  final bool isKey;

  /// Builds from JSON.
  factory ErField.fromJson(Map<String, dynamic> json) => ErField(
    name: json['name'] as String? ?? '',
    type: json['type'] as String? ?? '',
    isKey: json['isKey'] as bool? ?? false,
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    if (isKey) 'isKey': true,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErField &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          isKey == other.isKey;

  @override
  int get hashCode => Object.hash(name, type, isKey);
}

/// An entity (table) in an [EntityRelationDiagram].
class ErEntity {
  /// Creates an [ErEntity].
  const ErEntity({required this.name, this.fields = const []});

  /// Entity/table name.
  final String name;

  /// Entity fields/columns.
  final List<ErField> fields;

  /// Builds from JSON.
  factory ErEntity.fromJson(Map<String, dynamic> json) => ErEntity(
    name: json['name'] as String? ?? '',
    fields: (json['fields'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => ErField.fromJson(m.cast<String, dynamic>()))
        .toList(),
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    'fields': fields.map((f) => f.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErEntity &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          const ListEquality<ErField>().equals(fields, other.fields);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(fields));
}

/// A relationship between two entities in an [EntityRelationDiagram].
class ErRelation {
  /// Creates an [ErRelation].
  const ErRelation({
    required this.from,
    required this.to,
    this.label = '',
    this.cardinality = '||--o{',
  });

  /// Source entity name.
  final String from;

  /// Destination entity name.
  final String to;

  /// Relationship label.
  final String label;

  /// Mermaid ER cardinality token (e.g. `||--o{`).
  final String cardinality;

  /// Builds from JSON.
  factory ErRelation.fromJson(Map<String, dynamic> json) => ErRelation(
    from: json['from'] as String? ?? '',
    to: json['to'] as String? ?? '',
    label: json['label'] as String? ?? '',
    cardinality: json['cardinality'] as String? ?? '||--o{',
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    if (label.isNotEmpty) 'label': label,
    'cardinality': cardinality,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErRelation &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          label == other.label &&
          cardinality == other.cardinality;

  @override
  int get hashCode => Object.hash(from, to, label, cardinality);
}

/// An entity-relationship diagram for schema/table changes (PRD 18 §3).
class EntityRelationDiagram extends ReviewDiagram {
  /// Creates an [EntityRelationDiagram].
  const EntityRelationDiagram({
    required super.title,
    required this.entities,
    this.relations = const [],
  });

  /// Entities (tables).
  final List<ErEntity> entities;

  /// Relationships between entities.
  final List<ErRelation> relations;

  @override
  ReviewDiagramKind get kind => ReviewDiagramKind.entityRelation;

  /// ER diagrams describe schema, not call edges, so corroboration does not
  /// apply — they are always considered corroborated.
  @override
  bool get isFullyCorroborated => true;

  /// Builds from JSON.
  factory EntityRelationDiagram.fromJson(Map<String, dynamic> json) =>
      EntityRelationDiagram(
        title: json['title'] as String? ?? '',
        entities: (json['entities'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => ErEntity.fromJson(m.cast<String, dynamic>()))
            .toList(),
        relations: (json['relations'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => ErRelation.fromJson(m.cast<String, dynamic>()))
            .toList(),
      );

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.wireName,
    'title': title,
    'entities': entities.map((e) => e.toJson()).toList(),
    'relations': relations.map((r) => r.toJson()).toList(),
  };

  @override
  String toMermaid() {
    final buf = StringBuffer('erDiagram\n');
    for (final r in relations) {
      final label = r.label.isEmpty ? 'relates' : r.label;
      buf.writeln(
        '  ${_mermaidId(r.from)} ${r.cardinality} ${_mermaidId(r.to)} : $label',
      );
    }
    for (final e in entities) {
      buf.writeln('  ${_mermaidId(e.name)} {');
      for (final f in e.fields) {
        buf.writeln(
          '    ${_mermaidId(f.type)} ${_mermaidId(f.name)}'
          '${f.isKey ? ' PK' : ''}',
        );
      }
      buf.writeln('  }');
    }
    return buf.toString().trimRight();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityRelationDiagram &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          const ListEquality<ErEntity>().equals(entities, other.entities) &&
          const ListEquality<ErRelation>().equals(relations, other.relations);

  @override
  int get hashCode =>
      Object.hash(title, Object.hashAll(entities), Object.hashAll(relations));
}

/// A transition in a [StateMachineDiagram].
class StateTransition {
  /// Creates a [StateTransition].
  const StateTransition({
    required this.from,
    required this.to,
    this.label = '',
    this.corroborated = true,
  });

  /// Source state.
  final String from;

  /// Destination state.
  final String to;

  /// Transition label (trigger/guard).
  final String label;

  /// Whether the code graph corroborates this transition existing in code.
  final bool corroborated;

  /// Builds from JSON.
  factory StateTransition.fromJson(Map<String, dynamic> json) =>
      StateTransition(
        from: json['from'] as String? ?? '',
        to: json['to'] as String? ?? '',
        label: json['label'] as String? ?? '',
        corroborated: json['corroborated'] as bool? ?? true,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    if (label.isNotEmpty) 'label': label,
    'corroborated': corroborated,
  };

  /// Returns a copy with [corroborated] overridden.
  StateTransition withCorroboration({required bool value}) =>
      StateTransition(from: from, to: to, label: label, corroborated: value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateTransition &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          label == other.label &&
          corroborated == other.corroborated;

  @override
  int get hashCode => Object.hash(from, to, label, corroborated);
}

/// A state-machine diagram for a status/enum change (PRD 18 §3).
class StateMachineDiagram extends ReviewDiagram {
  /// Creates a [StateMachineDiagram].
  const StateMachineDiagram({
    required super.title,
    required this.states,
    required this.transitions,
    this.initialState,
  });

  /// Ordered states.
  final List<String> states;

  /// Transitions between states.
  final List<StateTransition> transitions;

  /// The initial state, if any (rendered as `[*] --> initial`).
  final String? initialState;

  @override
  ReviewDiagramKind get kind => ReviewDiagramKind.stateMachine;

  @override
  bool get isFullyCorroborated => transitions.every((t) => t.corroborated);

  /// Builds from JSON.
  factory StateMachineDiagram.fromJson(Map<String, dynamic> json) =>
      StateMachineDiagram(
        title: json['title'] as String? ?? '',
        states:
            (json['states'] as List?)?.whereType<String>().toList() ?? const [],
        transitions: (json['transitions'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => StateTransition.fromJson(m.cast<String, dynamic>()))
            .toList(),
        initialState: json['initialState'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.wireName,
    'title': title,
    'states': states,
    'transitions': transitions.map((t) => t.toJson()).toList(),
    if (initialState != null) 'initialState': initialState,
  };

  @override
  String toMermaid() {
    final buf = StringBuffer('stateDiagram-v2\n');
    if (initialState != null) {
      buf.writeln('  [*] --> ${_mermaidId(initialState!)}');
    }
    for (final t in transitions) {
      final label = t.label.isEmpty
          ? (t.corroborated ? '' : ' : unverified')
          : ' : ${t.label}${t.corroborated ? '' : ' (unverified)'}';
      buf.writeln('  ${_mermaidId(t.from)} --> ${_mermaidId(t.to)}$label');
    }
    return buf.toString().trimRight();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateMachineDiagram &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          const ListEquality<String>().equals(states, other.states) &&
          const ListEquality<StateTransition>().equals(
            transitions,
            other.transitions,
          ) &&
          initialState == other.initialState;

  @override
  int get hashCode => Object.hash(
    title,
    Object.hashAll(states),
    Object.hashAll(transitions),
    initialState,
  );
}

/// Sanitizes an arbitrary label into a mermaid-safe identifier.
String _mermaidId(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
  if (cleaned.isEmpty) {
    return 'n';
  }
  return RegExp(r'^[0-9]').hasMatch(cleaned) ? 'n$cleaned' : cleaned;
}
