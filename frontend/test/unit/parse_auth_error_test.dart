import 'package:flutter_test/flutter_test.dart';
import 'package:vedgy/widgets/error_banner.dart';

void main() {
  const fallback = 'Something went wrong. Please try again.';

  group('parseAuthError', () {
    // --- Map with "detail" key ---

    test('Map with detail returns the detail string', () {
      final data = <String, dynamic>{'detail': 'Custom error.'};
      expect(parseAuthError(data, fallback: fallback), 'Custom error.');
    });

    test('Map with detail converts non-string to string', () {
      final data = <String, dynamic>{'detail': 42};
      expect(parseAuthError(data, fallback: fallback), '42');
    });

    // --- Map without "detail" key (e.g., non_field_errors, field errors) ---

    test('Map with non_field_errors but no detail returns fallback', () {
      final data = <String, dynamic>{
        'non_field_errors': ['Password too short.'],
      };
      expect(parseAuthError(data, fallback: fallback), fallback);
    });

    test('Map with field errors but no detail returns fallback', () {
      final data = <String, dynamic>{
        'email': ['This email is taken.'],
      };
      expect(parseAuthError(data, fallback: fallback), fallback);
    });

    test('Map with null detail returns fallback', () {
      final data = <String, dynamic>{'detail': null};
      expect(parseAuthError(data, fallback: fallback), fallback);
    });

    test('Empty map returns fallback', () {
      final data = <String, dynamic>{};
      expect(parseAuthError(data, fallback: fallback), fallback);
    });

    // --- List format (Django Ninja validation errors) ---

    test('Non-empty List with msg key returns the msg string', () {
      final data = [
        <String, dynamic>{'msg': 'Password too short.'},
      ];
      expect(parseAuthError(data, fallback: fallback), 'Password too short.');
    });

    test('Non-empty List with null msg returns fallback', () {
      final data = [
        <String, dynamic>{'msg': null},
      ];
      expect(parseAuthError(data, fallback: fallback), fallback);
    });

    test('Non-empty List whose first element has no msg key returns fallback',
        () {
      final data = [
        <String, dynamic>{'type': 'value_error'},
      ];
      expect(parseAuthError(data, fallback: fallback), fallback);
    });

    test('Empty list returns fallback', () {
      final data = <dynamic>[];
      expect(parseAuthError(data, fallback: fallback), fallback);
    });

    test('List whose first element is not a Map returns fallback', () {
      final data = ['just a string'];
      expect(parseAuthError(data, fallback: fallback), fallback);
    });

    // --- Null response / non-Map non-List types ---

    test('Null data returns fallback', () {
      expect(parseAuthError(null, fallback: fallback), fallback);
    });

    test('String data returns fallback', () {
      expect(parseAuthError('Internal Server Error', fallback: fallback),
          fallback);
    });

    test('Integer data returns fallback', () {
      expect(parseAuthError(500, fallback: fallback), fallback);
    });
  });
}
