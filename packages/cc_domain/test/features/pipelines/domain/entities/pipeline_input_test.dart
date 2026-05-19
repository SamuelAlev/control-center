import 'package:cc_domain/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:test/test.dart';

/// Covers [PipelineInput] and the [PipelineInputType] wire enum: enum parsing
/// with fallback, construction (incl. the empty-key/empty-label handling),
/// JSON round-trips with conditional field emission, copyWith, and
/// equality/hashCode including the deep options-list comparison.
void main() {
  group('PipelineInputType', () {
    test('fromName parses each wire name', () {
      expect(PipelineInputType.fromName('text'), PipelineInputType.text);
      expect(
        PipelineInputType.fromName('multiline'),
        PipelineInputType.multiline,
      );
      expect(PipelineInputType.fromName('number'), PipelineInputType.number);
      expect(PipelineInputType.fromName('boolean'), PipelineInputType.boolean);
      expect(PipelineInputType.fromName('select'), PipelineInputType.select);
      expect(PipelineInputType.fromName('repo'), PipelineInputType.repo);
    });

    test('fromName defaults to text for null or unknown names', () {
      expect(PipelineInputType.fromName(null), PipelineInputType.text);
      expect(PipelineInputType.fromName(''), PipelineInputType.text);
      expect(PipelineInputType.fromName('nope'), PipelineInputType.text);
    });
  });

  group('PipelineInput construction', () {
    test('defaults label to key when no label is supplied', () {
      final input = PipelineInput(key: 'repoId');
      expect(input.key, 'repoId');
      expect(input.label, 'repoId');
      expect(input.type, PipelineInputType.text);
      expect(input.required, isFalse);
      expect(input.defaultValue, isNull);
      expect(input.helpText, isNull);
      expect(input.placeholder, isNull);
      expect(input.options, isEmpty);
    });

    test('defaults label to key when an empty label is supplied', () {
      final input = PipelineInput(key: 'repoId', label: '');
      expect(input.label, 'repoId');
    });

    test('round-trips every field through the constructor', () {
      final input = PipelineInput(
        key: 'k',
        label: 'Custom label',
        type: PipelineInputType.select,
        required: true,
        defaultValue: 'v',
        helpText: 'help',
        placeholder: 'hint',
        options: const ['a', 'b'],
      );
      expect(input.key, 'k');
      expect(input.label, 'Custom label');
      expect(input.type, PipelineInputType.select);
      expect(input.required, isTrue);
      expect(input.defaultValue, 'v');
      expect(input.helpText, 'help');
      expect(input.placeholder, 'hint');
      expect(input.options, ['a', 'b']);
    });

    test('throws an assertion error when the key is empty', () {
      expect(() => PipelineInput(key: ''), throwsA(isA<AssertionError>()));
    });
  });

  group('PipelineInput JSON', () {
    test('toJson emits only conditional fields when set', () {
      final json = PipelineInput(
        key: 'k',
        type: PipelineInputType.boolean,
        required: true,
        defaultValue: true,
        helpText: 'h',
        placeholder: 'p',
        options: const ['x', 'y'],
      ).toJson();
      expect(json['key'], 'k');
      expect(json['label'], 'k');
      expect(json['type'], 'boolean');
      expect(json['required'], isTrue);
      expect(json['defaultValue'], isTrue);
      expect(json['helpText'], 'h');
      expect(json['placeholder'], 'p');
      expect(json['options'], ['x', 'y']);
    });

    test('toJson omits optional fields when unset', () {
      final json = PipelineInput(key: 'k').toJson();
      expect(json['key'], 'k');
      expect(json['label'], 'k');
      expect(json['type'], 'text');
      expect(json.containsKey('required'), isFalse);
      expect(json.containsKey('defaultValue'), isFalse);
      expect(json.containsKey('helpText'), isFalse);
      expect(json.containsKey('placeholder'), isFalse);
      expect(json.containsKey('options'), isFalse);
    });

    test('round-trips a fully populated input through fromJson', () {
      final input = PipelineInput(
        key: 'k',
        label: 'L',
        type: PipelineInputType.select,
        required: true,
        defaultValue: 'a',
        helpText: 'h',
        placeholder: 'p',
        options: const ['a', 'b'],
      );
      final decoded = PipelineInput.fromJson(input.toJson());
      expect(decoded, input);
    });

    test('fromJson tolerates missing optional fields', () {
      final decoded = PipelineInput.fromJson(const {'key': 'k'});
      expect(decoded.key, 'k');
      expect(decoded.label, 'k');
      expect(decoded.type, PipelineInputType.text);
      expect(decoded.required, isFalse);
      expect(decoded.defaultValue, isNull);
      expect(decoded.options, isEmpty);
    });

    test('fromJson defaults an unknown type to text', () {
      final decoded = PipelineInput.fromJson(const {
        'key': 'k',
        'type': 'mystery',
      });
      expect(decoded.type, PipelineInputType.text);
    });

    test('fromJson tolerates a null options list', () {
      final decoded = PipelineInput.fromJson(const {
        'key': 'k',
        'options': null,
      });
      expect(decoded.options, isEmpty);
    });
  });

  group('PipelineInput.copyWith', () {
    final base = PipelineInput(
      key: 'k',
      label: 'L',
      type: PipelineInputType.select,
      required: true,
      defaultValue: 'v',
      helpText: 'h',
      placeholder: 'p',
      options: const ['a', 'b'],
    );

    test('returns an equal instance when called with no overrides', () {
      expect(base.copyWith(), base);
    });

    test('overrides each field independently', () {
      expect(base.copyWith(key: 'k2').key, 'k2');
      expect(base.copyWith(label: 'L2').label, 'L2');
      expect(
        base.copyWith(type: PipelineInputType.number).type,
        PipelineInputType.number,
      );
      expect(base.copyWith(required: false).required, isFalse);
      expect(base.copyWith(defaultValue: 5).defaultValue, 5);
      expect(base.copyWith(helpText: 'h2').helpText, 'h2');
      expect(base.copyWith(placeholder: 'p2').placeholder, 'p2');
      expect(base.copyWith(options: const ['c']).options, ['c']);
    });

    test('preserves every untouched field when one is overridden', () {
      final next = base.copyWith(required: false);
      expect(next.key, 'k');
      expect(next.label, 'L');
      expect(next.type, PipelineInputType.select);
      expect(next.defaultValue, 'v');
      expect(next.helpText, 'h');
      expect(next.placeholder, 'p');
      expect(next.options, ['a', 'b']);
    });
  });

  group('PipelineInput equality and hashCode', () {
    test('equal by value across every field including the options list', () {
      final a = PipelineInput(
        key: 'k',
        label: 'L',
        type: PipelineInputType.number,
        required: true,
        defaultValue: 1,
        helpText: 'h',
        placeholder: 'p',
        options: const ['a', 'b'],
      );
      final b = PipelineInput(
        key: 'k',
        label: 'L',
        type: PipelineInputType.number,
        required: true,
        defaultValue: 1,
        helpText: 'h',
        placeholder: 'p',
        options: const ['a', 'b'],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differ when any scalar field changes', () {
      final base = PipelineInput(
        key: 'k',
        label: 'L',
        type: PipelineInputType.number,
        required: true,
        defaultValue: 1,
        helpText: 'h',
        placeholder: 'p',
        options: const ['a', 'b'],
      );
      expect(base == PipelineInput(key: 'k2'), isFalse);
      expect(
        base ==
            PipelineInput(
              key: 'k',
              label: 'L2',
              type: PipelineInputType.number,
            ),
        isFalse,
      );
      expect(
        base ==
            PipelineInput(
              key: 'k',
              label: 'L',
              type: PipelineInputType.boolean,
              required: true,
              defaultValue: 1,
              helpText: 'h',
              placeholder: 'p',
              options: const ['a', 'b'],
            ),
        isFalse,
      );
      expect(
        base ==
            PipelineInput(
              key: 'k',
              label: 'L',
              type: PipelineInputType.number,
              required: false,
              defaultValue: 1,
              helpText: 'h',
              placeholder: 'p',
              options: const ['a', 'b'],
            ),
        isFalse,
      );
      expect(
        base ==
            PipelineInput(
              key: 'k',
              label: 'L',
              type: PipelineInputType.number,
              required: true,
              defaultValue: 2,
              helpText: 'h',
              placeholder: 'p',
              options: const ['a', 'b'],
            ),
        isFalse,
      );
      expect(
        base ==
            PipelineInput(
              key: 'k',
              label: 'L',
              type: PipelineInputType.number,
              required: true,
              defaultValue: 1,
              helpText: 'h2',
              placeholder: 'p',
              options: const ['a', 'b'],
            ),
        isFalse,
      );
      expect(
        base ==
            PipelineInput(
              key: 'k',
              label: 'L',
              type: PipelineInputType.number,
              required: true,
              defaultValue: 1,
              helpText: 'h',
              placeholder: 'p2',
              options: const ['a', 'b'],
            ),
        isFalse,
      );
    });

    test('differ when the options list contents differ', () {
      final a = PipelineInput(key: 'k', label: 'L', options: const ['a', 'b']);
      final b = PipelineInput(key: 'k', label: 'L', options: const ['a']);
      expect(a == b, isFalse);
    });

    test('refuses non-PipelineInput operands', () {
      final input = PipelineInput(key: 'k');
      expect(input == Object(), isFalse);
    });
  });
}
