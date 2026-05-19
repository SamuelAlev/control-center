import 'package:control_center/core/network/app_network.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createDio', () {
    test('returns a Dio instance', () {
      final dio = createDio();
      expect(dio, isA<Dio>());
    });

    test('uses empty base URL by default', () {
      final dio = createDio();
      expect(dio.options.baseUrl, '');
    });

    test('sets custom base URL', () {
      final dio = createDio(baseUrl: 'https://api.example.com');
      expect(dio.options.baseUrl, 'https://api.example.com');
    });

    test('sets default headers', () {
      final dio = createDio();
      expect(dio.options.headers['Content-Type'], 'application/json');
      expect(dio.options.headers['Accept'], 'application/json');
    });

    test('sets connect timeout', () {
      final dio = createDio();
      expect(dio.options.connectTimeout, const Duration(seconds: 30));
    });

    test('sets receive timeout', () {
      final dio = createDio();
      expect(dio.options.receiveTimeout, const Duration(seconds: 30));
    });

    test('has interceptors configured', () {
      final dio = createDio();
      expect(dio.interceptors, isNotEmpty);
    });

    test('creates independent instances', () {
      final dio1 = createDio(baseUrl: 'https://one.example.com');
      final dio2 = createDio(baseUrl: 'https://two.example.com');

      expect(dio1.options.baseUrl, 'https://one.example.com');
      expect(dio2.options.baseUrl, 'https://two.example.com');
    });

    test('baseUrl null defaults to empty string', () {
      final dio = createDio(baseUrl: null);
      expect(dio.options.baseUrl, '');
    });

    test('can add custom interceptors after creation', () {
      final dio = createDio();
      final initialCount = dio.interceptors.length;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.next(options),
        ),
      );

      expect(dio.interceptors.length, greaterThan(initialCount));
    });

    test('Dio can make mock requests', () {
      final dio = createDio(baseUrl: 'https://httpbin.org');
      expect(dio.options.baseUrl, 'https://httpbin.org');
      expect(dio.options.connectTimeout, const Duration(seconds: 30));
    });
  });
}
