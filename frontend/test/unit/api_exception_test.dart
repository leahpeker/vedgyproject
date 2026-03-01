import 'package:flutter_test/flutter_test.dart';
import 'package:vedgy/services/api_client.dart';

void main() {
  group('ApiException', () {
    // --- Constructor and field access ---

    test('stores statusCode and detail', () {
      const e = ApiException(statusCode: 404, detail: 'Not found.');
      expect(e.statusCode, 404);
      expect(e.detail, 'Not found.');
    });

    test('implements Exception', () {
      const e = ApiException(statusCode: 500, detail: 'Server error.');
      expect(e, isA<Exception>());
    });

    // --- toString ---

    test('toString formats as "ApiException(<code>): <detail>"', () {
      const e = ApiException(statusCode: 400, detail: 'Bad request.');
      expect(e.toString(), 'ApiException(400): Bad request.');
    });

    test('toString includes correct status code', () {
      const e = ApiException(statusCode: 401, detail: 'Unauthorized.');
      expect(e.toString(), 'ApiException(401): Unauthorized.');
    });

    test('toString includes full detail string', () {
      const e = ApiException(
        statusCode: 422,
        detail: 'Validation failed: email is required.',
      );
      expect(
        e.toString(),
        'ApiException(422): Validation failed: email is required.',
      );
    });

    test('toString with empty detail string', () {
      const e = ApiException(statusCode: 403, detail: '');
      expect(e.toString(), 'ApiException(403): ');
    });

    // --- Status code passthrough ---

    test('statusCode 200 is stored as-is', () {
      const e = ApiException(statusCode: 200, detail: 'OK');
      expect(e.statusCode, 200);
    });

    test('statusCode 503 is stored as-is', () {
      const e = ApiException(statusCode: 503, detail: 'Service unavailable.');
      expect(e.statusCode, 503);
    });

    // --- Equality (const constructor) ---

    test('identical const instances are equal', () {
      const a = ApiException(statusCode: 404, detail: 'Not found.');
      const b = ApiException(statusCode: 404, detail: 'Not found.');
      expect(identical(a, b), isTrue);
    });
  });
}
