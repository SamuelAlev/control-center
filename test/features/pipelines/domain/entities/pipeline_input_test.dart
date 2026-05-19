import 'package:control_center/features/pipelines/domain/entities/pipeline_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineInputType', () {
    test('fromName parses known names', timeout: const Timeout.factor(2), () {
      expect(PipelineInputType.fromName('text'), PipelineInputType.text);
      expect(PipelineInputType.fromName('multiline'), PipelineInputType.multiline);
      expect(PipelineInputType.fromName('number'), PipelineInputType.number);
      expect(PipelineInputType.fromName('boolean'), PipelineInputType.boolean);
      expect(PipelineInputType.fromName('select'), PipelineInputType.select);
      expect(PipelineInputType.fromName('repo'), PipelineInputType.repo);
    });

    test('fromName defaults to text for null or unknown', timeout: const Timeout.factor(2), () {
      expect(PipelineInputType.fromName(null), PipelineInputType.text);
      expect(PipelineInputType.fromName('unknown'), PipelineInputType.text);
      expect(PipelineInputType.fromName(''), PipelineInputType.text);
    });
  });

  group('PipelineInput', () {
    test('constructor requires non-empty key', timeout: const Timeout.factor(2), () {
      expect(
        () => PipelineInput(key: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('label defaults to key when not provided', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(key: 'repoFullName');
      expect(input.label, 'repoFullName');
    });

    test('label defaults to key when empty string', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(key: 'repoFullName', label: '');
      expect(input.label, 'repoFullName');
    });

    test('label uses provided value when non-empty', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(key: 'repoFullName', label: 'Repository');
      expect(input.label, 'Repository');
    });

    test('default values', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(key: 'k');
      expect(input.type, PipelineInputType.text);
      expect(input.required, isFalse);
      expect(input.defaultValue, isNull);
      expect(input.helpText, isNull);
      expect(input.placeholder, isNull);
      expect(input.options, isEmpty);
    });

    test('fromJson parses all fields', timeout: const Timeout.factor(2), () {
      final json = {
        'key': 'prNumber',
        'label': 'PR Number',
        'type': 'number',
        'required': true,
        'defaultValue': 42,
        'helpText': 'Enter PR number',
        'placeholder': 'e.g. 123',
        'options': ['a', 'b'],
      };
      final input = PipelineInput.fromJson(json);
      expect(input.key, 'prNumber');
      expect(input.label, 'PR Number');
      expect(input.type, PipelineInputType.number);
      expect(input.required, isTrue);
      expect(input.defaultValue, 42);
      expect(input.helpText, 'Enter PR number');
      expect(input.placeholder, 'e.g. 123');
      expect(input.options, ['a', 'b']);
    });

    test('fromJson defaults missing fields', timeout: const Timeout.factor(2), () {
      final input = PipelineInput.fromJson({'key': 'x'});
      expect(input.label, 'x');
      expect(input.type, PipelineInputType.text);
      expect(input.required, isFalse);
      expect(input.defaultValue, isNull);
      expect(input.helpText, isNull);
      expect(input.placeholder, isNull);
      expect(input.options, isEmpty);
    });

    test('toJson round-trips', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(
        key: 'status',
        label: 'Status',
        type: PipelineInputType.select,
        required: true,
        options: ['open', 'closed'],
      );
      final json = input.toJson();
      final restored = PipelineInput.fromJson(json);
      expect(restored, equals(input));
    });

    test('toJson omits default values', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(key: 'k');
      final json = input.toJson();
      expect(json.containsKey('required'), isFalse);
      expect(json.containsKey('defaultValue'), isFalse);
      expect(json.containsKey('helpText'), isFalse);
      expect(json.containsKey('placeholder'), isFalse);
      expect(json.containsKey('options'), isFalse);
    });

    test('copyWith overrides fields', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(key: 'k', label: 'K');
      final copy = input.copyWith(
        label: 'New',
        type: PipelineInputType.number,
        required: true,
      );
      expect(copy.key, 'k');
      expect(copy.label, 'New');
      expect(copy.type, PipelineInputType.number);
      expect(copy.required, isTrue);
    });

    test('equality compares all fields', timeout: const Timeout.factor(2), () {
      final a = PipelineInput(key: 'k', options: ['a', 'b']);
      final b = PipelineInput(key: 'k', options: ['a', 'b']);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = PipelineInput(key: 'k', options: ['b', 'a']);
      expect(a, isNot(equals(c)));
    });

    test('identical inputs are equal', timeout: const Timeout.factor(2), () {
      final input = PipelineInput(key: 'k');
      expect(input, equals(input));
    });
  });
}
